//
//  HolyDayPaywallView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 30/05/2026.
//

import RevenueCat
import SwiftUI

// MARK: - View

struct HolyDayPaywallView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var tipService = TipService.shared
  @State private var isPurchasing = false
  @State private var showError = false
  @State private var showThankYou = false
  // Palier du don qui vient d'être effectué : la célébration reflète CE don précis (indépendamment
  // de l'état du badge persistant exposé par tipService.supporterTier).
  @State private var purchasedTier: SupporterTier?

  var body: some View {
    NavigationStack {
      ZStack {
        AppBackground()
        scrollContent
        if isPurchasing { purchasingOverlay }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(role: .close) { dismiss() }
        }
        ToolbarItem(placement: .principal) {
          Text("paywall.header.title")
            .font(.system(.callout, design: .serif, weight: .bold))
            .foregroundStyle(AppTheme.textPrimary)
        }
      }
      .toolbarBackground(.hidden, for: .navigationBar)
    }
    .fullScreenCover(isPresented: $showThankYou) {
      DonationThankYouView(tier: purchasedTier) { dismiss() }
    }
    .alert("paywall.error.title", isPresented: $showError) {
      Button("common.cancel", role: .cancel) {}
    } message: {
      Text("paywall.error.message")
    }
  }

  // MARK: - Scroll content

  private var scrollContent: some View {
    ScrollView {
      VStack(spacing: 20) {
        heroHeader
        tipsSection
        footerSection
      }
      .padding(.horizontal, 20)
      .padding(.top, 8)
      .padding(.bottom, 48)
    }
    .scrollIndicators(.hidden)
  }

  // MARK: - Hero

  private var heroHeader: some View {
    VStack(spacing: 10) {
      ZStack {
        Circle()
          .fill(AppTheme.adorationPurple.opacity(0.12))
          .frame(width: 72, height: 72)
        Image(systemName: "hands.sparkles.fill")
          .font(.system(size: 30, weight: .medium))
          .foregroundStyle(AppTheme.adorationPurple)
      }
      Text("paywall.header.title")
        .font(.system(.title2, design: .serif, weight: .bold).italic())
        .foregroundStyle(AppTheme.textPrimary)
        .multilineTextAlignment(.center)
      Text("paywall.header.subtitle")
        .font(.subheadline)
        .foregroundStyle(AppTheme.textSecondary)
        .multilineTextAlignment(.center)
    }
    .padding(.top, 8)
  }

  // MARK: - Tips

  private var tipsSection: some View {
    // Le palier suit le rang de prix (le moins cher = Soutenir) plutôt que le nom du produit :
    // l'affichage reste cohérent même si les identifiants ou les prix changent sur l'App Store.
    let ranked =
      (tipService.tipsOffering?.availablePackages ?? [])
      .sorted { $0.storeProduct.price < $1.storeProduct.price }

    return VStack(spacing: 10) {
      ForEach(Array(ranked.enumerated()), id: \.element.identifier) { index, pkg in
        if let tier = SupporterTier(rawValue: index) {
          tipRow(package: pkg, tier: tier)
        }
      }
    }
  }

  private func tipRow(package: Package, tier: SupporterTier) -> some View {
    Button {
      Task { await purchase(package, tier: tier) }
    } label: {
      HStack(spacing: 14) {
        ZStack {
          Circle()
            .fill(tier.color.opacity(0.12))
            .frame(width: 44, height: 44)
          Text(tier.emoji)
            .font(.title3)
        }
        VStack(alignment: .leading, spacing: 3) {
          Text(tier.title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.textPrimary)
          Text(tier.phrase)
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)
        }
        Spacer()
        Text(package.storeProduct.localizedPriceString)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(tier.color)
      }
      .padding(14)
      .background {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(AppTheme.cardFill)
          .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .strokeBorder(tier.color.opacity(0.2), lineWidth: 1)
          }
      }
    }
    .buttonStyle(.plain)
  }

  // MARK: - Footer

  private var footerSection: some View {
    VStack(spacing: 12) {
      Button {
        Task { await restore() }
      } label: {
        Text("paywall.restore")
          .font(.caption)
          .foregroundStyle(AppTheme.textTertiary)
          .underline()
      }
      .buttonStyle(.plain)

      Text("paywall.legal.footer")
        .font(.caption2)
        .foregroundStyle(AppTheme.textTertiary)
        .multilineTextAlignment(.center)
    }
    .padding(.top, 4)
  }

  // MARK: - Purchasing overlay

  private var purchasingOverlay: some View {
    ZStack {
      Color.black.opacity(0.25).ignoresSafeArea()
      ProgressView()
        .tint(AppTheme.adorationPurple)
        .scaleEffect(1.4)
    }
  }

  // MARK: - Actions

  private func purchase(_ package: Package, tier: SupporterTier) async {
    isPurchasing = true
    defer { isPurchasing = false }
    do {
      let result = try await Purchases.shared.purchase(package: package)
      guard !result.userCancelled else { return }
      // Palier connu directement : les dons sont consommables et ne persistent pas dans CustomerInfo
      // (utilisateur anonyme), donc on enregistre le badge localement au lieu d'un aller-retour store.
      tipService.recordPurchase(tier: tier)
      await tipService.refreshCustomerInfo()
      // Célébration plein écran à la place de l'ancienne notification ; elle se ferme seule
      // au bout de 3 s et referme alors le paywall.
      purchasedTier = tier
      showThankYou = true
    } catch {
      showError = true
    }
  }

  private func restore() async {
    isPurchasing = true
    defer { isPurchasing = false }
    do {
      let info = try await Purchases.shared.restorePurchases()
      tipService.applyCustomerInfo(info)
      await tipService.refreshCustomerInfo()
      dismiss()
    } catch {
      showError = true
    }
  }
}
