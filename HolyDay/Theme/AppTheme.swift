//
//  AppTheme.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import SwiftUI

struct AppTheme {
  // MARK: - Gradients

  static let primaryGradient = LinearGradient(
    colors: [
      Color(red: 0.4, green: 0.3, blue: 0.8),
      Color(red: 0.6, green: 0.4, blue: 0.9),
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )

  // MARK: - Prayer step / brand colors
  // Tons de marque conservés. Variantes light/dark définies dans Assets.xcassets (WCAG AA).

  static let adorationPurple = Color("adorationPurple")
  static let confessionBlue = Color("confessionBlue")
  static let thanksgivingGold = Color("thanksgivingGold")
  static let supplicationGreen = Color("supplicationGreen")
  static let adaptiveOrange = Color("adaptiveOrange")

  // MARK: - Backgrounds
  // Light = blanc neutre, dark = violet profond (variantes définies dans Assets.xcassets).

  static let backgroundPrimary = Color("backgroundPrimary")
  static let backgroundSecondary = Color(uiColor: .secondarySystemBackground)
  static let backgroundTertiary = Color(uiColor: .tertiarySystemBackground)

  // MARK: - Text
  // Couleurs système : contraste et « Augmenter le contraste » gérés automatiquement (HIG Apple).

  static let textPrimary = Color(uiColor: .label)
  static let textSecondary = Color(uiColor: .secondaryLabel)
  static let textTertiary = Color(uiColor: .tertiaryLabel)

  // MARK: - Shadows

  static let premiumShadow = Color("premiumShadow")

  // MARK: - Adaptive surfaces
  // Translucides : se superposent proprement sur le blanc comme sur le violet profond.

  static let cardStroke = Color("cardStroke")
  static let cardFill = Color("cardFill")
  static let divider = Color("divider")
  static let buttonFillSubtle = Color("buttonFillSubtle")

  // MARK: - Helpers

  static func color(for name: String) -> Color {
    switch name {
    case "adorationPurple": return adorationPurple
    case "confessionBlue": return confessionBlue
    case "thanksgivingGold": return thanksgivingGold
    case "supplicationGreen": return supplicationGreen
    default: return .blue
    }
  }
}
