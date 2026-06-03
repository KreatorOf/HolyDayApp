//
//  DonationThankYouView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 03/06/2026.
//

import SwiftUI

/// Célébration plein écran affichée après un don : remercie avec des éléments de joie (étincelles,
/// symbole rebondissant, badge gagné) puis se referme seule au bout de 3 secondes. Aucun bouton —
/// remplace la notification de remerciement.
struct DonationThankYouView: View {
  let tier: SupporterTier?
  var onComplete: () -> Void

  // Durée d'affichage avant fermeture automatique.
  private static let displayDuration: Duration = .seconds(3)

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var appeared = false

  // MARK: - Body

  var body: some View {
    ZStack {
      AppBackground()
      SparksView()
        .ignoresSafeArea()

      VStack(spacing: 18) {
        icon
        Text("donation.thankyou.title")
          .font(.system(.title, design: .serif, weight: .bold).italic())
          .foregroundStyle(AppTheme.textPrimary)
          .multilineTextAlignment(.center)
        Text("donation.thankyou.subtitle")
          .font(.body)
          .foregroundStyle(AppTheme.textSecondary)
          .multilineTextAlignment(.center)
        if let tier {
          SupporterBadge(tier: tier, size: .large)
            .padding(.top, 6)
        }
      }
      .padding(.horizontal, 40)
      .scaleEffect(appeared ? 1 : 0.85)
      .opacity(appeared ? 1 : 0)
    }
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.isStaticText)
    .sensoryFeedback(.success, trigger: appeared)
    .task {
      if reduceMotion {
        appeared = true
      } else {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { appeared = true }
      }
      try? await Task.sleep(for: Self.displayDuration)
      onComplete()
    }
  }

  // MARK: - Icon

  private var iconColor: Color { tier?.color ?? AppTheme.thanksgivingGold }
  private var iconName: String { tier?.icon ?? "heart.fill" }

  private var icon: some View {
    ZStack {
      Circle()
        .fill(iconColor.opacity(0.15))
        .frame(width: 112, height: 112)
      Image(systemName: iconName)
        .font(.system(size: 46, weight: .semibold))
        .foregroundStyle(iconColor)
        .symbolEffect(.bounce, value: appeared)
    }
  }
}

#Preview {
  DonationThankYouView(tier: .bienfaiteur) {}
    .preferredColorScheme(.dark)
}
