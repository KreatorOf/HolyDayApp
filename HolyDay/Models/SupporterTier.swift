//
//  SupporterTier.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import SwiftUI

enum SupporterTier: Int {
    case ami = 0
    case bienfaiteur = 1
    case pelerin = 2

    var title: String {
        switch self {
        case .ami:          return String(localized: "tier.ami")
        case .bienfaiteur:  return String(localized: "tier.bienfaiteur")
        case .pelerin:      return String(localized: "tier.pelerin")
        }
    }

    var icon: String {
        switch self {
        case .ami:          return "heart.fill"
        case .bienfaiteur:  return "star.fill"
        case .pelerin:      return "figure.walk"
        }
    }

    var color: Color {
        switch self {
        case .ami:          return AppTheme.thanksgivingGold
        case .bienfaiteur:  return AppTheme.confessionBlue
        case .pelerin:      return AppTheme.adorationPurple
        }
    }
}
