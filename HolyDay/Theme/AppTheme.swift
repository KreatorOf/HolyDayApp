//
//  AppTheme.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import SwiftUI
import UIKit

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

  // MARK: - Prayer step colors (unchanged — contrast correct on both themes)

  static let adorationPurple = Color(red: 0.55, green: 0.35, blue: 0.85)
  static let confessionBlue = Color(red: 0.3, green: 0.6, blue: 0.95)
  static let thanksgivingGold = Color(red: 0.95, green: 0.7, blue: 0.3)
  static let supplicationGreen = Color(red: 0.3, green: 0.8, blue: 0.6)

  // MARK: - Backgrounds
  // Dark:  deep navy-violet #0D0D1F / #141426 / #1F1F33
  // Light: warm cream "Aube" #F8F3EC / #EFE9DF / #E3DDD3

  static let backgroundPrimary = Color(
    UIColor { t in
      t.userInterfaceStyle == .dark
        ? UIColor(red: 0.05, green: 0.05, blue: 0.12, alpha: 1)
        : UIColor(red: 0.973, green: 0.953, blue: 0.925, alpha: 1)
    })

  static let backgroundSecondary = Color(
    UIColor { t in
      t.userInterfaceStyle == .dark
        ? UIColor(red: 0.08, green: 0.08, blue: 0.15, alpha: 1)
        : UIColor(red: 0.937, green: 0.914, blue: 0.875, alpha: 1)
    })

  static let backgroundTertiary = Color(
    UIColor { t in
      t.userInterfaceStyle == .dark
        ? UIColor(red: 0.12, green: 0.12, blue: 0.20, alpha: 1)
        : UIColor(red: 0.890, green: 0.867, blue: 0.827, alpha: 1)
    })

  // MARK: - Text
  // Dark:  white hierarchy (1.0 / 0.70 / 0.50)
  // Light: warm near-black #1C1712 hierarchy (1.0 / 0.70 / 0.65)
  //        Contrast on #F8F3EC → primary 13:1 AAA / secondary 6.3:1 AA / tertiary 5.3:1 AA

  static let textPrimary = Color(
    UIColor { t in
      t.userInterfaceStyle == .dark
        ? .white
        : UIColor(red: 0.110, green: 0.090, blue: 0.071, alpha: 1.0)
    })

  static let textSecondary = Color(
    UIColor { t in
      t.userInterfaceStyle == .dark
        ? UIColor.white.withAlphaComponent(0.70)
        : UIColor(red: 0.110, green: 0.090, blue: 0.071, alpha: 0.70)
    })

  static let textTertiary = Color(
    UIColor { t in
      t.userInterfaceStyle == .dark
        ? UIColor.white.withAlphaComponent(0.50)
        : UIColor(red: 0.110, green: 0.090, blue: 0.071, alpha: 0.65)
    })

  // MARK: - Shadows

  static let premiumShadow = Color(
    UIColor { t in
      t.userInterfaceStyle == .dark
        ? UIColor.black.withAlphaComponent(0.30)
        : UIColor.black.withAlphaComponent(0.08)
    })

  // MARK: - Adaptive surfaces
  // Used for card strokes, dividers, and subtle fills — visible on both cream and dark navy.

  static let cardStroke = Color(
    UIColor { t in
      t.userInterfaceStyle == .dark
        ? UIColor.white.withAlphaComponent(0.08)
        : UIColor.black.withAlphaComponent(0.10)
    })

  static let cardFill = Color(
    UIColor { t in
      t.userInterfaceStyle == .dark
        ? UIColor.white.withAlphaComponent(0.05)
        : UIColor.black.withAlphaComponent(0.04)
    })

  static let divider = Color(
    UIColor { t in
      t.userInterfaceStyle == .dark
        ? UIColor.white.withAlphaComponent(0.07)
        : UIColor.black.withAlphaComponent(0.08)
    })

  static let buttonFillSubtle = Color(
    UIColor { t in
      t.userInterfaceStyle == .dark
        ? UIColor.white.withAlphaComponent(0.08)
        : UIColor.black.withAlphaComponent(0.07)
    })

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
