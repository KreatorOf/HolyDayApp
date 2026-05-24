//
//  PrayerStep.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import Foundation
import SwiftUI

struct PrayerStep: Identifiable {
  let id: UUID
  let title: String
  let description: String
  let icon: String
  let colorName: String
  let order: Int

  var color: Color {
    AppTheme.color(for: colorName)
  }

  init(
    id: UUID = UUID(), title: String, description: String, icon: String, colorName: String,
    order: Int
  ) {
    self.id = id
    self.title = title
    self.description = description
    self.icon = icon
    self.colorName = colorName
    self.order = order
  }

  static let defaultSteps: [PrayerStep] = [
    PrayerStep(
      title: String(localized: "step.adoration.title"),
      description: String(localized: "step.adoration.description"),
      icon: "hands.sparkles",
      colorName: "adorationPurple",
      order: 1
    ),
    PrayerStep(
      title: String(localized: "step.confession.title"),
      description: String(localized: "step.confession.description"),
      icon: "heart.circle",
      colorName: "confessionBlue",
      order: 2
    ),
    PrayerStep(
      title: String(localized: "step.thanksgiving.title"),
      description: String(localized: "step.thanksgiving.description"),
      icon: "star.circle",
      colorName: "thanksgivingGold",
      order: 3
    ),
    PrayerStep(
      title: String(localized: "step.supplication.title"),
      description: String(localized: "step.supplication.description"),
      icon: "bubble.left.and.bubble.right",
      colorName: "supplicationGreen",
      order: 4
    ),
  ]
}
