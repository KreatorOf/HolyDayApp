//
//  TipView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import RevenueCat
import SwiftUI

struct TipView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var tipService = TipService.shared

  private let tierStyles: [(emoji: String, color: Color, thankKey: LocalizedStringKey)] = [
    ("☕", AppTheme.thanksgivingGold, "tip.tier.thank.0"),
    ("🙏", AppTheme.confessionBlue, "tip.tier.thank.1"),
    ("✨", AppTheme.adorationPurple, "tip.tier.thank.2"),
  ]

  private let comingSoonItems: [(icon: String, key: LocalizedStringKey)] = [
    ("paintpalette.fill", "tip.coming.soon.themes"),
    ("app.fill", "tip.coming.soon.icons"),
    ("bolt.fill", "tip.coming.soon.earlyaccess"),
  ]

  var body: some View {
    NavigationStack {
      Group {
        if tipService.purchaseState == .success {
          successView
        } else {
          supportOptionsView
        }
      }
      .navigationTitle(Text("tip.nav.title"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(role: .close) { dismiss() }
        }
      }
    }
    .background(AppTheme.backgroundPrimary.ignoresSafeArea())
    .task {
      if tipService.purchaseState == .success { tipService.resetState() }
      await tipService.loadProducts()
    }
  }

  // MARK: Support options

  private var supportOptionsView: some View {
    ScrollView {
      VStack(spacing: 28) {
        headerSection
        impactSection
        productsContent
        comingSoonSection
        if tipService.purchaseState == .failed {
          purchaseErrorBanner
        }
        restoreButton
        legalFooter
      }
      .padding(20)
    }
    .scrollIndicators(.hidden)
  }

  private var purchaseErrorBanner: some View {
    HStack(spacing: 10) {
      Image(systemName: "exclamationmark.circle")
        .foregroundStyle(.red.opacity(0.8))
      Text("tip.error.purchase")
        .font(.footnote)
        .foregroundStyle(.red.opacity(0.9))
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    .overlay {
      RoundedRectangle(cornerRadius: 10)
        .strokeBorder(.red.opacity(0.2), lineWidth: 1)
    }
    .transition(.opacity.combined(with: .scale(scale: 0.97)))
  }

  // MARK: Header

  private var headerSection: some View {
    VStack(spacing: 16) {
      Image(systemName: "heart.fill")
        .font(.system(size: 44))
        .foregroundStyle(AppTheme.adorationPurple)
        .padding(.top, 8)

      Text("tip.header.title")
        .font(.title2)
        .fontWeight(.bold)
        .foregroundStyle(AppTheme.textPrimary)
        .multilineTextAlignment(.center)

      Text("tip.header.creator.message")
        .font(.subheadline)
        .foregroundStyle(AppTheme.textSecondary)
        .multilineTextAlignment(.center)
        .lineSpacing(5)
        .frame(maxWidth: 320)
    }
  }

  // MARK: Impact

  private var impactSection: some View {
    VStack(spacing: 0) {
      impactRow(icon: "gift.fill", color: AppTheme.supplicationGreen, key: "tip.impact.1")
      AppTheme.divider.frame(height: 1).padding(.horizontal, 16)
      impactRow(icon: "sparkles", color: AppTheme.adorationPurple, key: "tip.impact.2")
      AppTheme.divider.frame(height: 1).padding(.horizontal, 16)
      impactRow(icon: "arrow.up.heart.fill", color: AppTheme.confessionBlue, key: "tip.impact.3")
    }
    .background {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(.ultraThinMaterial)
        .overlay {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
        }
    }
  }

  private func impactRow(icon: String, color: Color, key: LocalizedStringKey) -> some View {
    HStack(spacing: 14) {
      Image(systemName: icon)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(color)
        .frame(width: 32, height: 32)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      Text(key)
        .font(.subheadline)
        .foregroundStyle(AppTheme.textPrimary)
      Spacer()
      Image(systemName: "checkmark")
        .font(.caption.weight(.bold))
        .foregroundStyle(color.opacity(0.7))
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 13)
  }

  // MARK: Products

  @ViewBuilder
  private var productsContent: some View {
    if tipService.isLoading {
      ProgressView()
        .tint(AppTheme.adorationPurple)
        .padding(.vertical, 24)
    } else if tipService.packages.isEmpty {
      #if DEBUG
        debugProductsStack
      #else
        unavailableView
      #endif
    } else {
      productsStack
    }
  }

  private var productsStack: some View {
    VStack(spacing: 12) {
      ForEach(Array(tipService.packages.enumerated()), id: \.element.identifier) { index, package in
        let style = tierStyles[min(index, tierStyles.count - 1)]
        let tier = SupporterTier(rawValue: index)
        SupporterTierCard(
          emoji: style.emoji,
          tierName: tier?.title ?? "",
          thankKey: style.thankKey,
          price: package.storeProduct.localizedPriceString,
          color: style.color,
          isPurchasing: tipService.purchaseState == .purchasing
        ) {
          Task { await tipService.purchase(package) }
        }
      }
    }
  }

  // MARK: Coming soon

  private var comingSoonSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 6) {
        Image(systemName: "lock.fill")
          .font(.caption.weight(.semibold))
          .foregroundStyle(AppTheme.textTertiary)
        Text("tip.coming.soon.title")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(AppTheme.textTertiary)
          .textCase(.uppercase)
          .tracking(0.8)
      }

      VStack(spacing: 0) {
        ForEach(comingSoonItems.indices, id: \.self) { i in
          HStack(spacing: 12) {
            Image(systemName: comingSoonItems[i].icon)
              .font(.system(size: 13, weight: .medium))
              .foregroundStyle(AppTheme.textTertiary)
              .frame(width: 28, height: 28)
              .background(AppTheme.textTertiary.opacity(0.08))
              .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            Text(comingSoonItems[i].key)
              .font(.subheadline)
              .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text("tip.coming.soon.badge")
              .font(.caption2)
              .fontWeight(.semibold)
              .foregroundStyle(AppTheme.adorationPurple)
              .padding(.horizontal, 8)
              .padding(.vertical, 3)
              .background(AppTheme.adorationPurple.opacity(0.12), in: Capsule())
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          if i < comingSoonItems.count - 1 {
            AppTheme.divider.frame(height: 1).padding(.horizontal, 16)
          }
        }
      }
      .background {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(.ultraThinMaterial)
          .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
          }
      }
      .opacity(0.75)
    }
  }

  // MARK: Buttons / footer

  private var restoreButton: some View {
    Button {
      Task { await tipService.restorePurchases() }
    } label: {
      Text("tip.restore")
        .font(.footnote)
        .foregroundStyle(AppTheme.textTertiary)
    }
    .buttonStyle(.plain)
    .sensoryFeedback(.selection, trigger: tipService.purchaseState)
    .disabled(tipService.purchaseState == .purchasing)
  }

  private var legalFooter: some View {
    Text("tip.legal.footer")
      .font(.caption2)
      .foregroundStyle(AppTheme.textTertiary)
      .multilineTextAlignment(.center)
      .padding(.horizontal, 8)
  }

  // MARK: Success

  private var successView: some View {
    ZStack {
      ConfettiView()
        .ignoresSafeArea()
        .allowsHitTesting(false)

      VStack(spacing: 20) {
        Spacer()

        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 80))
          .foregroundStyle(.green)
          .symbolEffect(.bounce, value: tipService.purchaseState == .success)

        VStack(spacing: 14) {
          Text("tip.success.title")
            .font(.title)
            .fontWeight(.bold)
            .foregroundStyle(AppTheme.textPrimary)

          if let tier = tipService.supporterTier {
            SupporterBadge(tier: tier, size: .large)

            Text(successMessage(for: tier))
              .font(.body)
              .foregroundStyle(AppTheme.textSecondary)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 32)
              .lineSpacing(4)
          }
        }

        Spacer()

        VStack(spacing: 10) {
          Text("tip.success.coming.title")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(AppTheme.textTertiary)
            .textCase(.uppercase)
            .tracking(0.8)

          HStack(spacing: 20) {
            ForEach(comingSoonItems.indices, id: \.self) { i in
              VStack(spacing: 4) {
                Image(systemName: comingSoonItems[i].icon)
                  .font(.footnote)
                  .foregroundStyle(AppTheme.adorationPurple.opacity(0.7))
                Text(comingSoonItems[i].key)
                  .font(.caption2)
                  .foregroundStyle(AppTheme.textTertiary)
                  .multilineTextAlignment(.center)
              }
            }
          }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
      }
    }
  }

  private func successMessage(for tier: SupporterTier) -> String {
    switch tier {
    case .ami: return String(localized: "tip.success.tier.message.0")
    case .genereux: return String(localized: "tip.success.tier.message.1")
    case .bienfaiteur: return String(localized: "tip.success.tier.message.2")
    }
  }

  // MARK: Debug

  #if DEBUG
    private var debugProductsStack: some View {
      VStack(spacing: 12) {
        HStack(spacing: 6) {
          Image(systemName: "wrench.and.screwdriver.fill")
            .font(.caption)
            .foregroundStyle(.orange)
          Text("Mode test — aucun paiement réel")
            .font(.caption)
            .foregroundStyle(.orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.orange.opacity(0.12), in: Capsule())

        let mockTiers: [(tier: SupporterTier, price: String)] = [
          (.ami, "4,99 €"),
          (.genereux, "9,99 €"),
          (.bienfaiteur, "19,99 €"),
        ]
        ForEach(mockTiers.indices, id: \.self) { i in
          let mock = mockTiers[i]
          let style = tierStyles[i]
          SupporterTierCard(
            emoji: style.emoji,
            tierName: mock.tier.title,
            thankKey: style.thankKey,
            price: mock.price,
            color: style.color,
            isPurchasing: false
          ) {
            tipService.debugPurchase(tier: mock.tier)
          }
        }
      }
    }
  #endif

  // MARK: Unavailable

  private var unavailableView: some View {
    VStack(spacing: 12) {
      Image(systemName: "wifi.slash")
        .font(.title)
        .foregroundStyle(AppTheme.textTertiary)
      Text("tip.unavailable")
        .font(.subheadline)
        .foregroundStyle(AppTheme.textSecondary)
        .multilineTextAlignment(.center)
    }
    .padding(.vertical, 16)
  }
}

// MARK: - Tier card

private struct SupporterTierCard: View {
  let emoji: String
  let tierName: String
  let thankKey: LocalizedStringKey
  let price: String
  let color: Color
  let isPurchasing: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 0) {
        HStack(spacing: 16) {
          Text(emoji)
            .font(.title3)
            .frame(width: 44, height: 44)
            .background(color.opacity(0.15))
            .clipShape(Circle())

          VStack(alignment: .leading, spacing: 3) {
            Text(tierName)
              .font(.body)
              .fontWeight(.semibold)
              .foregroundStyle(AppTheme.textPrimary)
            Text(thankKey)
              .font(.caption)
              .foregroundStyle(AppTheme.textSecondary)
              .lineLimit(2)
              .fixedSize(horizontal: false, vertical: true)
          }

          Spacer()

          if isPurchasing {
            ProgressView()
              .tint(color)
              .frame(width: 52)
          } else {
            Text(price)
              .font(.body)
              .fontWeight(.bold)
              .foregroundStyle(color)
          }
        }
        .padding(16)

        HStack(spacing: 8) {
          Image(systemName: "checkmark.circle.fill")
            .font(.caption.weight(.medium))
            .foregroundStyle(color.opacity(0.7))
          Text("tip.perk.badge")
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)
          Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
        .padding(.top, -4)
      }
      .background {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(.ultraThinMaterial)
          .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .strokeBorder(color.opacity(0.3), lineWidth: 1)
          }
      }
    }
    .buttonStyle(.plain)
    .disabled(isPurchasing)
  }
}

// MARK: - Confetti

private struct ConfettiParticle: Identifiable {
  let id = UUID()
  let xRatio: CGFloat = .random(in: 0.02...0.98)
  let delay: Double = .random(in: 0...1.8)
  let duration: Double = .random(in: 2.5...4.5)
  let color: Color =
    [
      AppTheme.thanksgivingGold, AppTheme.adorationPurple, AppTheme.confessionBlue,
      Color(red: 0.95, green: 0.35, blue: 0.45), AppTheme.supplicationGreen,
    ].randomElement() ?? AppTheme.thanksgivingGold
  let size: CGFloat = .random(in: 7...14)
  let isCircle: Bool = .random()
  let xDrift: CGFloat = .random(in: -60...60)
  let rotationEnd: Double = .random(in: 270...720)
}

private struct ConfettiView: View {
  @State private var isAnimating = false
  @State private var particles: [ConfettiParticle] = (0..<80).map { _ in ConfettiParticle() }

  var body: some View {
    GeometryReader { geo in
      ZStack {
        ForEach(particles) { p in
          Group {
            if p.isCircle {
              Circle().fill(p.color)
            } else {
              RoundedRectangle(cornerRadius: 2).fill(p.color)
            }
          }
          .frame(width: p.size, height: p.isCircle ? p.size : p.size * 1.8)
          .position(
            x: geo.size.width * p.xRatio + (isAnimating ? p.xDrift : 0),
            y: isAnimating ? geo.size.height + 60 : -30
          )
          .rotationEffect(.degrees(isAnimating ? p.rotationEnd : 0))
          .animation(.easeIn(duration: p.duration).delay(p.delay), value: isAnimating)
        }
      }
    }
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        isAnimating = true
      }
    }
  }
}

#Preview {
  TipView()
}
