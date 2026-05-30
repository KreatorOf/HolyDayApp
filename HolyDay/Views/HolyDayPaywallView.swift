//
//  HolyDayPaywallView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 30/05/2026.
//

import RevenueCat
import SwiftUI

// MARK: - Context

enum PaywallContext {
  case support
  case aiFeature
}

// MARK: - View

struct HolyDayPaywallView: View {
  let context: PaywallContext

  @Environment(\.dismiss) private var dismiss
  @State private var tipService = TipService.shared
  @State private var isPurchasing = false
  @State private var showError = false

  var body: some View {
    NavigationStack {
      ZStack {
        AnimatedMeshBackground().ignoresSafeArea()
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
        aiSection
        separatorView
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

  // MARK: - AI Feature Card

  @ViewBuilder
  private var aiSection: some View {
    if let pkg = tipService.aiOffering?.availablePackages.first {
      aiFeatureCard(package: pkg)
    } else {
      ProgressView()
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .task {
          if tipService.aiOffering == nil {
            await tipService.refreshCustomerInfo()
          }
        }
    }
  }

  private func aiFeatureCard(package: Package) -> some View {
    let showBadge = context == .aiFeature || tipService.hasAIFeature
    let alreadyOwned = tipService.hasAIFeature

    return VStack(alignment: .leading, spacing: 0) {
      if showBadge {
        HStack {
          Spacer()
          Text(alreadyOwned ? "paywall.ai.activated" : "paywall.ai.badge")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .tracking(0.8)
            .textCase(.uppercase)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
              alreadyOwned ? AppTheme.supplicationGreen : AppTheme.adorationPurple,
              in: Capsule()
            )
          Spacer()
        }
        .padding(.top, 14)
        .padding(.bottom, 4)
      }

      VStack(alignment: .leading, spacing: 14) {
        HStack(spacing: 12) {
          ZStack {
            Circle()
              .fill(
                alreadyOwned
                  ? AppTheme.supplicationGreen.opacity(0.15)
                  : AppTheme.adorationPurple.opacity(0.15)
              )
              .frame(width: 48, height: 48)
            Image(systemName: alreadyOwned ? "checkmark.seal.fill" : "sparkles")
              .font(.system(size: 20, weight: .semibold))
              .foregroundStyle(
                alreadyOwned ? AppTheme.supplicationGreen : AppTheme.adorationPurple
              )
          }
          VStack(alignment: .leading, spacing: 3) {
            Text(package.storeProduct.localizedTitle)
              .font(.headline)
              .foregroundStyle(AppTheme.textPrimary)
            if alreadyOwned {
              Text("paywall.ai.purchased")
                .font(.subheadline)
                .foregroundStyle(AppTheme.supplicationGreen)
            } else {
              Text(package.storeProduct.localizedPriceString)
                .font(.subheadline)
                .foregroundStyle(AppTheme.adorationPurple)
            }
          }
        }

        VStack(alignment: .leading, spacing: 6) {
          aiFeatureRow("paywall.ai.feature.questions", owned: alreadyOwned)
          aiFeatureRow("paywall.ai.feature.themes", owned: alreadyOwned)
          aiFeatureRow("paywall.ai.feature.analysis", owned: alreadyOwned)
          aiFeatureRow("paywall.ai.feature.answered", owned: alreadyOwned)
        }

        if !alreadyOwned {
          HStack(spacing: 6) {
            Image(systemName: "infinity")
              .font(.caption.weight(.semibold))
              .foregroundStyle(AppTheme.adorationPurple.opacity(0.7))
            Text("paywall.ai.lifetime")
              .font(.caption)
              .foregroundStyle(AppTheme.textTertiary)
          }

          Button {
            Task { await purchase(package) }
          } label: {
            Text(
              "\(String(localized: "paywall.cta.unlock")) · \(package.storeProduct.localizedPriceString)"
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.adorationPurple)
            }
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 16)
      .padding(.top, showBadge ? 8 : 16)
    }
    .background {
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .fill(AppTheme.adorationPurple.opacity(0.07))
        .overlay {
          RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(
              AppTheme.adorationPurple.opacity(showBadge ? 0.4 : 0.2),
              lineWidth: showBadge ? 1.5 : 1
            )
        }
    }
  }

  private func aiFeatureRow(_ key: LocalizedStringKey, owned: Bool = false) -> some View {
    let accent = owned ? AppTheme.supplicationGreen : AppTheme.adorationPurple
    return HStack(alignment: .top, spacing: 8) {
      Image(systemName: "checkmark")
        .font(.caption.weight(.bold))
        .foregroundStyle(accent)
        .frame(width: 16)
      Text(key)
        .font(.subheadline)
        .foregroundStyle(AppTheme.textSecondary)
    }
  }

  // MARK: - Separator

  private var separatorView: some View {
    HStack(spacing: 12) {
      AppTheme.divider.frame(height: 1)
      Text("paywall.separator")
        .font(.caption)
        .foregroundStyle(AppTheme.textTertiary)
        .fixedSize()
      AppTheme.divider.frame(height: 1)
    }
  }

  // MARK: - Tips

  private var tipsSection: some View {
    let sorted =
      (tipService.tipsOffering?.availablePackages ?? [])
      .sorted { $0.storeProduct.price < $1.storeProduct.price }

    return VStack(spacing: 10) {
      ForEach(sorted, id: \.identifier) { pkg in
        if let tier = SupporterTier.tier(for: pkg.storeProduct.productIdentifier) {
          tipRow(package: pkg, tier: tier)
        }
      }
    }
  }

  private func tipRow(package: Package, tier: SupporterTier) -> some View {
    Button {
      Task { await purchase(package) }
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

  private func purchase(_ package: Package) async {
    let isAIPackage =
      tipService.aiOffering?.availablePackages
      .contains { $0.identifier == package.identifier } == true

    isPurchasing = true
    defer { isPurchasing = false }
    do {
      let result = try await Purchases.shared.purchase(package: package)
      guard !result.userCancelled else { return }
      tipService.applyCustomerInfo(result.customerInfo)
      await tipService.refreshCustomerInfo()
      // If buying from the AI offering and entitlement not yet reflected
      // (sandbox delay or dashboard misconfiguration), force-grant access.
      if isAIPackage { tipService.grantAIFeatureAccess() }
      dismiss()
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
