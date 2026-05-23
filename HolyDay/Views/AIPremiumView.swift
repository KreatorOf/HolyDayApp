//
//  AIPremiumView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 23/05/2026.
//

import SwiftUI

struct AIPremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showTipView = false
    @State private var tipService = TipService.shared

    private var isSupporter: Bool { tipService.supporterTier != nil }
    private var deviceSupported: Bool { AIAssistantService.shared.isAvailable }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    heroSection
                    featuresSection
                    previewSection
                    ctaSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .background { AnimatedMeshBackground() }
            .navigationTitle(String(localized: "ai.paywall.nav.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.close") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showTipView) {
            TipView()
        }
        .onChange(of: tipService.supporterTier) { _, newValue in
            if newValue != nil && deviceSupported { dismiss() }
        }
    }

    // MARK: Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.adorationPurple.opacity(0.15))
                    .frame(width: 110, height: 110)
                    .blur(radius: 16)

                Image(systemName: "sparkles")
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(AppTheme.adorationPurple)
            }
            .padding(.top, 8)

            VStack(spacing: 8) {
                Text("ai.paywall.title")
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("ai.paywall.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 300)
            }
        }
    }

    // MARK: Features

    private let features: [(icon: String, key: LocalizedStringKey, color: Color)] = [
        ("tag.fill",               "ai.paywall.feature.themes",   AppTheme.confessionBlue),
        ("checkmark.seal.fill",    "ai.paywall.feature.answered", AppTheme.thanksgivingGold),
        ("clock.arrow.circlepath", "ai.paywall.feature.history",  AppTheme.adorationPurple),
        ("lock.shield.fill",       "ai.paywall.feature.privacy",  AppTheme.supplicationGreen),
    ]

    private var featuresSection: some View {
        VStack(spacing: 0) {
            ForEach(features.indices, id: \.self) { i in
                let color = features[i].color
                HStack(spacing: 14) {
                    Image(systemName: features[i].icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(color)
                        .frame(width: 34, height: 34)
                        .background(color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                    Text(features[i].key)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Image(systemName: "checkmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(color.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)

                if i < features.count - 1 {
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
    }

    // MARK: Fictional preview

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("ai.paywall.preview.label")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                Text("ai.paywall.preview.example")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textTertiary.opacity(0.6))
                    .italic()
            }
            .padding(.horizontal, 4)

            ZStack(alignment: .bottom) {
                // Fictional content — mirrors exact JournalInsightView layout
                VStack(spacing: 16) {
                    fakeInsightSection(
                        title: "insight.themes.title",
                        icon: "tag.fill",
                        color: AppTheme.confessionBlue,
                        items: [
                            "ai.paywall.fake.theme1",
                            "ai.paywall.fake.theme2",
                            "ai.paywall.fake.theme3",
                        ]
                    )
                    fakeInsightSection(
                        title: "insight.answered.title",
                        icon: "checkmark.seal.fill",
                        color: AppTheme.thanksgivingGold,
                        items: [
                            "ai.paywall.fake.answered1",
                            "ai.paywall.fake.answered2",
                        ]
                    )
                    fakeInsightSection(
                        title: "insight.observations.title",
                        icon: "eye.fill",
                        color: AppTheme.adorationPurple,
                        items: [
                            "ai.paywall.fake.obs1",
                            "ai.paywall.fake.obs2",
                        ]
                    )
                }
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0.0),
                            .init(color: .black, location: 0.42),
                            .init(color: .clear, location: 0.72),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

                // Lock overlay at the bottom
                VStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("ai.paywall.preview.unlock")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .padding(.bottom, 12)
            }
        }
    }

    private func fakeInsightSection(title: LocalizedStringKey, icon: String, color: Color, items: [LocalizedStringKey]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.8)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(items.indices, id: \.self) { i in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(color.opacity(0.6))
                            .frame(width: 6, height: 6)
                            .padding(.top, 7)
                        Text(items[i])
                            .font(.body)
                            .foregroundStyle(AppTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(color.opacity(0.25), lineWidth: 1)
                }
        }
    }

    // MARK: CTA

    @ViewBuilder
    private var ctaSection: some View {
        if isSupporter && !deviceSupported {
            VStack(spacing: 12) {
                Image(systemName: "iphone.slash")
                    .font(.title2)
                    .foregroundStyle(AppTheme.textTertiary)
                Text("ai.paywall.incompatible")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 8)
        } else {
            VStack(spacing: 10) {
                Button { showTipView = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.callout)
                        Text("ai.paywall.cta")
                            .font(.body.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundStyle(.white)
                    .glassEffect(
                        .regular.tint(AppTheme.adorationPurple.opacity(0.75)),
                        in: RoundedRectangle(cornerRadius: 30, style: .continuous)
                    )
                    .shadow(color: AppTheme.adorationPurple.opacity(0.45), radius: 14, x: 0, y: 0)
                }
                .buttonStyle(.plain)

                Text("ai.paywall.cta.subtitle")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    AIPremiumView()
        .preferredColorScheme(.dark)
}
