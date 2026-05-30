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

  var emoji: String {
    switch self {
    case .ami: return "☕"
    case .genereux: return "🙏"
    case .bienfaiteur: return "✨"
    }
  }

  var tipLabel: LocalizedStringKey {
    switch self {
    case .ami: return "tip.tier.0.label"
    case .genereux: return "tip.tier.1.label"
    case .bienfaiteur: return "tip.tier.2.label"
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

  static func tier(for productIdentifier: String) -> SupporterTier? {
    if productIdentifier.contains("tip_large") { return .bienfaiteur }
    if productIdentifier.contains("tip_medium") { return .genereux }
    if productIdentifier.contains("tip_small") { return .ami }
    return nil
  }
}
