//
//  TipView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import SwiftUI
import StoreKit

struct TipView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tipService = TipService.shared

    private var tiers: [(emoji: String, label: String, color: Color)] {[
        ("☕", String(localized: "tip.tier.0.label"),  AppTheme.thanksgivingGold),
        ("🙏", String(localized: "tip.tier.1.label"),  AppTheme.confessionBlue),
        ("✨", String(localized: "tip.tier.2.label"),  AppTheme.adorationPurple),
    ]}

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
        .preferredColorScheme(.dark)
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
            unavailableView
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

            Button {
                dismiss()
            } label: {
                Text("common.close")
                    .font(.body)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
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

#Preview {
    TipView()
}
