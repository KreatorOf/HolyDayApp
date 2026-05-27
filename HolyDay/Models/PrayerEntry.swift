//
//  PrayerEntry.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import Foundation
import SwiftData

@Model
final class PrayerEntry {
  var stepTitle: String
  var stepIcon: String
  var stepColorName: String
  var text: String
  var date: Date
  var isAnswered: Bool = false
  var answeredAt: Date?
  var duration: TimeInterval = 0

  init(
    stepTitle: String,
    stepIcon: String,
    stepColorName: String,
    text: String,
    date: Date = .now,
    duration: TimeInterval = 0
  ) {
    self.stepTitle = stepTitle
    self.stepIcon = stepIcon
    self.stepColorName = stepColorName
    self.text = text
    self.date = date
    self.duration = duration
  }
}
