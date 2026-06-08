//
//  SupporterBadge.swift
//  Kairos
//
//  Created by Matthias Cadet on 14/05/2026.
//

import SwiftUI

struct SupporterBadge: View {
  let tier: SupporterTier

  enum Size { case small, large }
  var size: Size = .small

  // `.iconOnly` n'affiche que le symbole du palier (à côté du nom de l'utilisateur).
  enum Style { case full, iconOnly }
  var style: Style = .full

  private var font: Font { size == .small ? .caption : .subheadline }
  private var iconFont: Font { size == .small ? .caption : .body }
  private var hPadding: CGFloat { size == .small ? 8 : 14 }
  private var vPadding: CGFloat { size == .small ? 4 : 8 }

  var body: some View {
    HStack(spacing: 5) {
      Image(systemName: tier.icon)
        .font(iconFont)
      if style == .full {
        Text(tier.badgeName)
          .font(font)
          .fontWeight(.semibold)
      }
    }
    .foregroundStyle(tier.color)
    .padding(.horizontal, style == .iconOnly ? vPadding : hPadding)
    .padding(.vertical, vPadding)
    .background(tier.color.opacity(0.12), in: Capsule())
    .accessibilityLabel(tier.badgeName)
  }
}

#Preview {
  VStack(spacing: 16) {
    SupporterBadge(tier: .ami)
    SupporterBadge(tier: .genereux)
    SupporterBadge(tier: .bienfaiteur)
    SupporterBadge(tier: .bienfaiteur, size: .large)
    HStack(spacing: 6) {
      SupporterBadge(tier: .ami, style: .iconOnly)
      SupporterBadge(tier: .genereux, style: .iconOnly)
      SupporterBadge(tier: .bienfaiteur, style: .iconOnly)
    }
  }
  .padding()
  .preferredColorScheme(.dark)
}
