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

  // Verbe d'action affiché sur le paywall (« Soutenir », « Encourager », « Bénir »).
  var title: String {
    switch self {
    case .ami: return String(localized: "tier.ami")
    case .genereux: return String(localized: "tier.genereux")
    case .bienfaiteur: return String(localized: "tier.bienfaiteur")
    }
  }

  // Nom honorifique du badge gagné : plus chaleureux et distinct du verbe d'action du paywall.
  var badgeName: String {
    switch self {
    case .ami: return String(localized: "badge.name.ami")
    case .genereux: return String(localized: "badge.name.genereux")
    case .bienfaiteur: return String(localized: "badge.name.bienfaiteur")
    }
  }

  var emoji: String {
    switch self {
    case .ami: return "❤️"
    case .genereux: return "⭐️"
    case .bienfaiteur: return "✨"
    }
  }

  var phrase: LocalizedStringKey {
    switch self {
    case .ami: return "paywall.tip.ami.phrase"
    case .genereux: return "paywall.tip.genereux.phrase"
    case .bienfaiteur: return "paywall.tip.bienfaiteur.phrase"
    }
  }

  var icon: String {
    switch self {
    case .ami: return "heart.fill"
    case .genereux: return "star.fill"
    case .bienfaiteur: return "sparkles"
    }
  }

  var color: Color {
    switch self {
    case .ami: return AppTheme.thanksgivingGold
    case .genereux: return AppTheme.confessionBlue
    case .bienfaiteur: return AppTheme.adorationPurple
    }
  }

  static func tier(for productIdentifier: String) -> SupporterTier? {
    if productIdentifier.contains("tip_large") { return .bienfaiteur }
    if productIdentifier.contains("tip_medium") { return .genereux }
    if productIdentifier.contains("tip_small") { return .ami }
    return nil
  }
}
