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

  private var font: Font { size == .small ? .caption : .subheadline }
  private var iconFont: Font { size == .small ? .caption : .body }
  private var hPadding: CGFloat { size == .small ? 8 : 14 }
  private var vPadding: CGFloat { size == .small ? 4 : 8 }

  var body: some View {
    HStack(spacing: 5) {
      Image(systemName: tier.icon)
        .font(iconFont)
      Text(tier.title)
        .font(font)
        .fontWeight(.semibold)
    }
    .foregroundStyle(tier.color)
    .padding(.horizontal, hPadding)
    .padding(.vertical, vPadding)
    .background(tier.color.opacity(0.12), in: Capsule())
  }
}

#Preview {
  VStack(spacing: 16) {
    SupporterBadge(tier: .ami)
    SupporterBadge(tier: .genereux)
    SupporterBadge(tier: .bienfaiteur)
    SupporterBadge(tier: .bienfaiteur, size: .large)
  }
  .padding()
  .preferredColorScheme(.dark)
}
