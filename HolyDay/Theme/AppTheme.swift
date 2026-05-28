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

  // MARK: - Prayer step colors
  // Light/dark variants defined in Assets.xcassets colorsets (WCAG AA on cream #F8F3EC)

  static let adorationPurple = Color("adorationPurple")
  static let confessionBlue = Color("confessionBlue")
  static let thanksgivingGold = Color("thanksgivingGold")
  static let supplicationGreen = Color("supplicationGreen")
  static let adaptiveOrange = Color("adaptiveOrange")

  // MARK: - Backgrounds

  static let backgroundPrimary = Color("backgroundPrimary")
  static let backgroundSecondary = Color("backgroundSecondary")
  static let backgroundTertiary = Color("backgroundTertiary")

  // MARK: - Text

  static let textPrimary = Color("textPrimary")
  static let textSecondary = Color("textSecondary")
  static let textTertiary = Color("textTertiary")

  // MARK: - Shadows

  static let premiumShadow = Color("premiumShadow")

  // MARK: - Adaptive surfaces

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
