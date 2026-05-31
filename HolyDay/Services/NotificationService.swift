//
//  NotificationService.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import Foundation
import UserNotifications

@MainActor
@Observable
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
  static let shared = NotificationService()

  var isDailyReminderEnabled = false
  var isPermissionDenied = false
  var reminderTime: Date

  private static let notificationPrefix = "holyday.daily-prayer"
  // iOS caps pending local notifications at 64; a rolling 60-day window is refreshed on launch.
  private static let windowSize = 60
  private static let hourKey = "holyday.reminderHour"
  private static let minuteKey = "holyday.reminderMinute"

  // Gentle, rotating invitations — never an injunction. (Honors the onboarding promise.)
  private static let invitations: [LocalizedStringResource] = [
    "notification.invite.0",
    "notification.invite.1",
    "notification.invite.2",
    "notification.invite.3",
    "notification.invite.4",
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

  // Allows notifications (purchase thanks, etc.) to appear while the app is in the foreground
  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    return [.banner, .sound]
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

      let verse = VerseService.shared.verse(for: fireDate)
      let content = UNMutableNotificationContent()
      content.title = String(localized: Self.invitations[offset % Self.invitations.count])
      content.body = "« \(verse.text) » — \(verse.reference)"
      content.sound = .default

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
