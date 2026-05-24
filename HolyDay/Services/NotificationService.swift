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
class NotificationService {
  static let shared = NotificationService()

  var isDailyReminderEnabled = false
  var isPermissionDenied = false
  var reminderTime: Date = {
    var components = DateComponents()
    components.hour = 8
    components.minute = 0
    return Calendar.current.date(from: components) ?? Date()
  }()

  private static let notificationID = "holyday.daily-prayer"

  private init() {
    checkStatus()
  }

  func checkStatus() {
    Task {
      let settings = await UNUserNotificationCenter.current().notificationSettings()
      let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
      isPermissionDenied = settings.authorizationStatus == .denied
      isDailyReminderEnabled =
        settings.authorizationStatus == .authorized
        && pending.contains { $0.identifier == Self.notificationID }
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
      UNUserNotificationCenter.current()
        .removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
      isDailyReminderEnabled = false
    }
  }

  func reschedule(at time: Date) {
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: [Self.notificationID])

    let content = UNMutableNotificationContent()
    content.title = "HolyDay"
    content.body = String(localized: "notification.daily.body")
    content.sound = .default

    let components = Calendar.current.dateComponents([.hour, .minute], from: time)
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    let request = UNNotificationRequest(
      identifier: Self.notificationID,
      content: content,
      trigger: trigger
    )
    center.add(request)
  }
}
