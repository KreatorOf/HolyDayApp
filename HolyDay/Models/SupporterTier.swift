//
//  SupporterTier.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import SwiftUI

enum SupporterTier: Int {
  case ami = 0
  case genereux = 1
  case bienfaiteur = 2

  var title: String {
    switch self {
    case .ami: return String(localized: "tier.ami")
    case .genereux: return String(localized: "tier.genereux")
    case .bienfaiteur: return String(localized: "tier.bienfaiteur")
    }
  }

  var icon: String {
    switch self {
    case .ami: return "heart.fill"
    case .genereux: return "star.fill"
    case .bienfaiteur: return "crown.fill"
    }
  }

  var color: Color {
    switch self {
    case .ami: return AppTheme.thanksgivingGold
    case .genereux: return AppTheme.confessionBlue
    case .bienfaiteur: return AppTheme.adorationPurple
    }
  }
}
