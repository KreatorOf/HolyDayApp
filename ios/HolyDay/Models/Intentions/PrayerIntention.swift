//
//  PrayerIntention.swift
//  HolyDay
//
//  Created by Matthias Cadet on 31/05/2026.
//

import Foundation
import SwiftData

@Model
final class PrayerIntention {
  var text: String
  var createdAt: Date
  var isAnswered: Bool = false
  var answeredAt: Date?

  init(
    text: String,
    createdAt: Date = .now,
    isAnswered: Bool = false,
    answeredAt: Date? = nil
  ) {
    self.text = text
    self.createdAt = createdAt
    self.isAnswered = isAnswered
    self.answeredAt = answeredAt
  }
}
