//
//  SupporterTier.swift
//  Kairos
//
//  Created by Matthias Cadet on 14/05/2026.
//

import SwiftUI

enum SupporterTier: Int {
    case ami = 0
    case bienfaiteur = 1
    case mecene = 2

    var title: String {
        switch self {
        case .ami:          return "Ami"
        case .bienfaiteur:  return "Bienfaiteur"
        case .mecene:       return "Mécène"
        }
    }

    var icon: String {
        switch self {
        case .ami:          return "heart.fill"
        case .bienfaiteur:  return "star.fill"
        case .mecene:       return "crown.fill"
        }
    }

    var color: Color {
        switch self {
        case .ami:          return AppTheme.thanksgivingGold
        case .bienfaiteur:  return AppTheme.confessionBlue
        case .mecene:       return AppTheme.adorationPurple
        }
    }
}
