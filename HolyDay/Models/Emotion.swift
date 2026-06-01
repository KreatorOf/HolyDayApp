//
//  Emotion.swift
//  HolyDay
//
//  Created by Matthias Cadet on 31/05/2026.
//

import SwiftUI

/// État intérieur que l'utilisateur déclare avant de prier.
/// La `rawValue` est stable et non localisée : c'est elle qui est persistée sur `PrayerEntry`.
enum Emotion: String, CaseIterable, Codable, Identifiable {
  case joy
  case peace
  case gratitude
  case sadness
  case fear
  case fatigue
  case anger
  case hope

  var id: String { rawValue }

  var titleKey: LocalizedStringKey {
    switch self {
    case .joy: "emotion.joy"
    case .peace: "emotion.peace"
    case .gratitude: "emotion.gratitude"
    case .sadness: "emotion.sadness"
    case .fear: "emotion.fear"
    case .fatigue: "emotion.fatigue"
    case .anger: "emotion.anger"
    case .hope: "emotion.hope"
    }
  }

  var accessibilityLabel: String {
    switch self {
    case .joy: String(localized: "emotion.joy")
    case .peace: String(localized: "emotion.peace")
    case .gratitude: String(localized: "emotion.gratitude")
    case .sadness: String(localized: "emotion.sadness")
    case .fear: String(localized: "emotion.fear")
    case .fatigue: String(localized: "emotion.fatigue")
    case .anger: String(localized: "emotion.anger")
    case .hope: String(localized: "emotion.hope")
    }
  }

  var icon: String {
    switch self {
    case .joy: "sun.max.fill"
    case .peace: "leaf.fill"
    case .gratitude: "hands.and.sparkles.fill"
    case .sadness: "cloud.rain.fill"
    case .fear: "wind"
    case .fatigue: "moon.zzz.fill"
    case .anger: "flame.fill"
    case .hope: "sunrise.fill"
    }
  }

  /// Nom de couleur résolu par `AppTheme.color(for:)`, aligné sur la palette ACTS.
  var colorName: String {
    switch self {
    case .joy, .gratitude: "thanksgivingGold"
    case .peace, .sadness: "confessionBlue"
    case .fear: "adorationPurple"
    case .fatigue, .hope: "supplicationGreen"
    case .anger: "adaptiveOrange"
    }
  }

  var color: Color { AppTheme.color(for: colorName) }
}
