//
//  NotificationService.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import Foundation
import SwiftData
import UserNotifications

@MainActor
@Observable
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
  static let shared = NotificationService()

  var isDailyReminderEnabled = false
  var isPermissionDenied = false
  var reminderTime: Date

  // Source du contexte des rappels (émotion récente, intentions ouvertes). `nil` en tests : les
  // rappels retombent alors sur les questions tournantes.
  @ObservationIgnored private var modelContainer: ModelContainer?
  private static let notificationPrefix = "holyday.daily-prayer"
  // iOS caps pending local notifications at 64; a rolling 60-day window is refreshed on launch.
  private static let windowSize = 60
  private static let hourKey = "holyday.reminderHour"
  private static let minuteKey = "holyday.reminderMinute"
  private static let userNameKey = "holyday.userName"
  private static let lastPrayerDateKey = "holyday.lastPrayerDate"
  nonisolated private static let routeKey = "route"
  nonisolated private static let intentionsRoute = "intentions"

  // Titres : invitations douces — jamais une injonction. (Honore la promesse de l'onboarding.)
  // Deux jeux parallèles : générique et personnalisé (`%@` = prénom) au même index.
  private static let titlesGeneric: [LocalizedStringResource] = [
    "notification.invite.0",
    "notification.invite.1",
    "notification.invite.2",
    "notification.invite.3",
    "notification.invite.4",
  ]
  private static let titlesNamed: [LocalizedStringResource] = [
    "notification.invite.named.0",
    "notification.invite.named.1",
    "notification.invite.named.2",
    "notification.invite.named.3",
    "notification.invite.named.4",
  ]

  // Corps : questions de réflexion intemporelles, qui invitent à ouvrir l'app et prier.
  private static let questions: [LocalizedStringResource] = [
    "notification.question.0",
    "notification.question.1",
    "notification.question.2",
    "notification.question.3",
    "notification.question.4",
    "notification.question.5",
    "notification.question.6",
    "notification.question.7",
    "notification.question.8",
    "notification.question.9",
  ]

  private override init() {
    let defaults = UserDefaults.standard
    var components = DateComponents()
    components.hour = defaults.object(forKey: Self.hourKey) as? Int ?? 8
    components.minute = defaults.object(forKey: Self.minuteKey) as? Int ?? 0
    reminderTime = Calendar.current.date(from: components) ?? Date()
    super.init()
    UNUserNotificationCenter.current().delegate = self
    checkStatus()
  }

  // Appelé depuis `HolyDayApp.init` : fournit le store ET pose le delegate avant la fin du
  // lancement, condition pour recevoir le tap qui a lancé l'app à froid.
  func attach(_ container: ModelContainer) {
    modelContainer = container
  }

  // Allows notifications (purchase thanks, etc.) to appear while the app is in the foreground
  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    return [.banner, .sound]
  }

  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async {
    let route = response.notification.request.content.userInfo[Self.routeKey] as? String
    guard route == Self.intentionsRoute else { return }
    await AppRouter.shared.open(.intentions)
  }

  func checkStatus() {
    Task {
      let settings = await UNUserNotificationCenter.current().notificationSettings()
      let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
      isPermissionDenied = settings.authorizationStatus == .denied
      isDailyReminderEnabled =
        settings.authorizationStatus == .authorized
        && pending.contains { $0.identifier.hasPrefix(Self.notificationPrefix) }
    }
  }

  func setReminder(enabled: Bool) async {
    if enabled {
      do {
        let granted = try await UNUserNotificationCenter.current()
          .requestAuthorization(options: [.alert, .badge, .sound])
        if granted {
          isDailyReminderEnabled = true
          isPermissionDenied = false
          reschedule(at: reminderTime)
        } else {
          isPermissionDenied = true
          isDailyReminderEnabled = false
        }
      } catch {
        isDailyReminderEnabled = false
      }
    } else {
      removeScheduledReminders()
      isDailyReminderEnabled = false
    }
  }

  // Tops up the rolling window when the app becomes active, only if reminders are already on.
  func refreshScheduledReminders() {
    Task {
      let settings = await UNUserNotificationCenter.current().notificationSettings()
      guard settings.authorizationStatus == .authorized else { return }
      let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
      guard pending.contains(where: { $0.identifier.hasPrefix(Self.notificationPrefix) }) else {
        return
      }
      reschedule(at: reminderTime)
    }
  }

  func reschedule(at time: Date) {
    let calendar = Calendar.current
    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
    persist(timeComponents)
    removeScheduledReminders()

    let center = UNUserNotificationCenter.current()
    let now = Date()
    let userName =
      UserDefaults.standard.string(forKey: Self.userNameKey)?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let context = currentContext()
    var scheduled = 0
    var offset = 0

    while scheduled < Self.windowSize && offset < Self.windowSize + 3 {
      defer { offset += 1 }
      guard
        let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now))
      else { continue }

      var fireComponents = calendar.dateComponents([.year, .month, .day], from: day)
      fireComponents.hour = timeComponents.hour
      fireComponents.minute = timeComponents.minute
      guard let fireDate = calendar.date(from: fireComponents), fireDate > now else { continue }
      guard let kind = ReminderPlanner.kind(for: fireDate, context: context) else { continue }

      let reminder = Self.reminderContent(for: fireDate, name: userName, kind: kind)
      let content = UNMutableNotificationContent()
      content.title = reminder.title
      content.body = reminder.body
      content.sound = .default
      if kind == .intentions {
        content.userInfo = [Self.routeKey: Self.intentionsRoute]
      }

      let trigger = UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)
      let request = UNNotificationRequest(
        identifier: "\(Self.notificationPrefix).\(scheduled)",
        content: content,
        trigger: trigger
      )
      center.add(request)
      scheduled += 1
    }
  }

  // Titre + corps déterministes par jour de l'année : un jour donné mappe toujours sur le même
  // couple, et deux jours consécutifs diffèrent toujours (titre mod 5, question mod 10). Le titre
  // est personnalisé avec le prénom s'il est connu, sinon repli sur la variante générique. Le corps
  // dépend du `kind` choisi par `ReminderPlanner`.
  static func reminderContent(
    for date: Date, name: String, kind: ReminderKind = .question
  ) -> (title: String, body: String) {
    let dayIndex = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
    let titleIndex = dayIndex % titlesGeneric.count

    let title: String
    if name.isEmpty {
      title = String(localized: titlesGeneric[titleIndex])
    } else {
      title = String(format: String(localized: titlesNamed[titleIndex]), name)
    }
    let body: String
    switch kind {
    case .question:
      body = String(localized: questions[dayIndex % questions.count])
    case .verse(let corpusIndex):
      body = verseBody(VerseCorpus.all[corpusIndex])
    case .intentions:
      body = String(localized: "notification.intentions.body")
    }
    return (title, body)
  }

  private static func verseBody(_ entry: CorpusVerse) -> String {
    let french = AppLanguage.isFrench
    let reference = "\(entry.reference(french: french)) (\(french ? "LSG" : "BSB"))"
    return String(
      format: String(localized: "notification.verse.body"), entry.text(french: french), reference)
  }

  // `mainContext` et non un contexte neuf : une prière tout juste insérée depuis une vue n'est pas
  // forcément encore sauvegardée, et le fetch inclut les changements en attente.
  private func currentContext() -> ReminderContext {
    var context = ReminderContext.empty
    context.lastPrayerDate = UserDefaults.standard.object(forKey: Self.lastPrayerDateKey) as? Date
    guard let modelContext = modelContainer?.mainContext else { return context }

    var emotionFetch = FetchDescriptor<PrayerEntry>(
      predicate: #Predicate { $0.emotionRaw != nil },
      sortBy: [SortDescriptor(\.date, order: .reverse)]
    )
    emotionFetch.fetchLimit = 1
    if let entry = try? modelContext.fetch(emotionFetch).first {
      context.lastEmotion = entry.emotion
      context.lastEmotionDate = entry.date
    }

    var intentionFetch = FetchDescriptor<PrayerIntention>(
      predicate: #Predicate { !$0.isAnswered },
      sortBy: [SortDescriptor(\.createdAt)]
    )
    intentionFetch.fetchLimit = 1
    context.oldestOpenIntentionDate = (try? modelContext.fetch(intentionFetch).first)?.createdAt
    return context
  }

  private func removeScheduledReminders() {
    var ids = (0..<Self.windowSize).map { "\(Self.notificationPrefix).\($0)" }
    ids.append(Self.notificationPrefix)  // legacy single repeating reminder
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
  }

  private func persist(_ components: DateComponents) {
    UserDefaults.standard.set(components.hour ?? 8, forKey: Self.hourKey)
    UserDefaults.standard.set(components.minute ?? 0, forKey: Self.minuteKey)
  }
}
