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
            Color(red: 0.6, green: 0.4, blue: 0.9)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Prayer step colors

    static let adorationPurple   = Color(red: 0.55, green: 0.35, blue: 0.85)
    static let confessionBlue    = Color(red: 0.3,  green: 0.6,  blue: 0.95)
    static let thanksgivingGold  = Color(red: 0.95, green: 0.7,  blue: 0.3)
    static let supplicationGreen = Color(red: 0.3,  green: 0.8,  blue: 0.6)

    // MARK: - Backgrounds

    static let backgroundPrimary   = Color(red: 0.05, green: 0.05, blue: 0.12)
    static let backgroundSecondary = Color(red: 0.08, green: 0.08, blue: 0.15)
    static let backgroundTertiary  = Color(red: 0.12, green: 0.12, blue: 0.20)

    // MARK: - Text

    static let textPrimary   = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary  = Color.white.opacity(0.5)

    // MARK: - Shadows

    static let premiumShadow = Color.black.opacity(0.3)

    // MARK: - Helpers

    static func color(for name: String) -> Color {
        switch name {
        case "adorationPurple":   return adorationPurple
        case "confessionBlue":    return confessionBlue
        case "thanksgivingGold":  return thanksgivingGold
        case "supplicationGreen": return supplicationGreen
        default:                  return .blue
        }
    }
}
