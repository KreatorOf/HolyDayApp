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

  /// Teinte pastel propre à chaque émotion, utilisée pour colorer sa bulle dans le ruban défilant.
  /// Une couleur distincte par émotion pour les différencier d'un coup d'œil. Rôle décoratif : le
  /// libellé reste en couleur de texte standard, donc la lisibilité ne dépend pas de cette teinte.
  var pastel: Color {
    switch self {
    case .joy: Color(red: 1.00, green: 0.82, blue: 0.25)
    case .peace: Color(red: 0.40, green: 0.80, blue: 0.58)
    case .gratitude: Color(red: 0.99, green: 0.58, blue: 0.42)
    case .sadness: Color(red: 0.40, green: 0.64, blue: 0.93)
    case .fear: Color(red: 0.70, green: 0.56, blue: 0.96)
    case .fatigue: Color(red: 0.46, green: 0.52, blue: 0.82)
    case .anger: Color(red: 0.93, green: 0.42, blue: 0.40)
    case .hope: Color(red: 0.26, green: 0.76, blue: 0.73)
    }
  }
}
