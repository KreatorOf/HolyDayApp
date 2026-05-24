//
//  TipView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import StoreKit
import SwiftUI

struct TipView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var tipService = TipService.shared

  private var tiers: [(emoji: String, label: String, color: Color)] {
    [
      ("☕", String(localized: "tip.tier.0.label"), AppTheme.thanksgivingGold),
      ("🙏", String(localized: "tip.tier.1.label"), AppTheme.confessionBlue),
      ("✨", String(localized: "tip.tier.2.label"), AppTheme.adorationPurple),
    ]
  }

  var body: some View {
    NavigationStack {
      Group {
        if tipService.purchaseState == .success {
          successView
        } else {
          tipOptionsView
        }
      }
      .navigationTitle(Text("tip.nav.title"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("common.close") { dismiss() }
            .foregroundStyle(AppTheme.textSecondary)
        }
      }
    }
    .background(AppTheme.backgroundPrimary.ignoresSafeArea())
    .task {
      // Reset stale success state from a previous session
      if tipService.purchaseState == .success { tipService.resetState() }
      await tipService.loadProducts()
    }
  }

  // MARK: Options

  private var tipOptionsView: some View {
    ScrollView {
      VStack(spacing: 28) {
        header
        productsContent
        legalFooter
      }
      .padding(20)
    }
  }

  private var header: some View {
    VStack(spacing: 14) {
      Image(systemName: "heart.fill")
        .font(.system(size: 48))
        .foregroundStyle(AppTheme.adorationPurple)
        .padding(.top, 8)

      Text("tip.header.title")
        .font(.title2)
        .fontWeight(.bold)
        .foregroundStyle(AppTheme.textPrimary)

      Text("tip.header.subtitle")
        .font(.subheadline)
        .foregroundStyle(AppTheme.textSecondary)
        .multilineTextAlignment(.center)
        .lineSpacing(4)
    }
  }

  @ViewBuilder
  private var productsContent: some View {
    if tipService.isLoading {
      ProgressView()
        .tint(AppTheme.adorationPurple)
        .padding(.vertical, 24)
    } else if tipService.products.isEmpty {
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
      ForEach(Array(tipService.products.enumerated()), id: \.element.id) { index, product in
        let tier = tiers[min(index, tiers.count - 1)]
        TipProductCard(
          emoji: tier.emoji,
          label: tier.label,
          price: product.displayPrice,
          color: tier.color,
          isPurchasing: tipService.purchaseState == .purchasing
        ) {
          Task { await tipService.purchase(product) }
        }
      }
    }
  }

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
          (.ami, "2,99 €"),
          (.bienfaiteur, "5,99 €"),
          (.pelerin, "9,99 €"),
        ]
        ForEach(mockTiers.indices, id: \.self) { i in
          let mock = mockTiers[i]
          let ui = tiers[i]
          TipProductCard(
            emoji: ui.emoji,
            label: ui.label,
            price: mock.price,
            color: ui.color,
            isPurchasing: false
          ) {
            tipService.debugPurchase(tier: mock.tier)
          }
        }
      }
    }
  #endif

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
          }

          Text("tip.success.subtitle")
            .font(.body)
            .foregroundStyle(AppTheme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .lineSpacing(4)
        }

        Spacer()
      }
    }
  }
}

// MARK: Product card

private struct TipProductCard: View {
  let emoji: String
  let label: String
  let price: String
  let color: Color
  let isPurchasing: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 16) {
        Text(emoji)
          .font(.title3)
          .frame(width: 44, height: 44)
          .background(color.opacity(0.15))
          .clipShape(Circle())

        Text(label)
          .font(.body)
          .fontWeight(.semibold)
          .foregroundStyle(AppTheme.textPrimary)

        Spacer()

        if isPurchasing {
          ProgressView()
            .tint(color)
            .frame(width: 44)
        } else {
          Text(price)
            .font(.body)
            .fontWeight(.bold)
            .foregroundStyle(color)
        }
      }
      .padding(16)
      .background {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(.ultraThinMaterial)
          .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
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
