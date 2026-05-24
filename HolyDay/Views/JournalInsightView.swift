//
//  JournalInsightView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import SwiftUI
import SwiftData

struct JournalInsightView: View {
    @Query(sort: \PrayerEntry.date, order: .reverse) private var entries: [PrayerEntry]
    @Environment(\.dismiss) private var dismiss

    @State private var insight: JournalInsight?
    @State private var isGenerating = false
    @State private var failed = false

    var body: some View {
        NavigationStack {
            Group {
                if isGenerating {
                    loadingView
                } else if let insight {
                    insightContent(insight)
                } else if failed {
                    errorView
                } else {
                    emptyView
                }
            }
            .navigationTitle(Text("insight.nav.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.close") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
                if insight != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task { await generate() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task { await generate() }
    }

    // MARK: Loading

    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
                .tint(AppTheme.adorationPurple)
            Text("insight.loading")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
        }
    }

    // MARK: Insight content

    private func insightContent(_ insight: JournalInsight) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 36))
                        .foregroundStyle(AppTheme.adorationPurple)
                        .padding(.top, 8)
                    Text("insight.header.title")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(entries.count == 1
                         ? String(format: String(localized: "insight.count.one"), entries.count)
                         : String(format: String(localized: "insight.count.other"), entries.count))
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .frame(maxWidth: .infinity)

                // Themes
                if !insight.themes.isEmpty {
                    insightSection(
                        title: String(localized: "insight.themes.title"),
                        icon: "tag.fill",
                        color: AppTheme.confessionBlue,
                        items: insight.themes
                    )
                }

                // Observations
                if !insight.observations.isEmpty {
                    insightSection(
                        title: String(localized: "insight.observations.title"),
                        icon: "eye.fill",
                        color: AppTheme.adorationPurple,
                        items: insight.observations
                    )
                }

                // Answered prayers
                if !insight.answeredPrayers.isEmpty {
                    insightSection(
                        title: String(localized: "insight.answered.title"),
                        icon: "checkmark.seal.fill",
                        color: AppTheme.thanksgivingGold,
                        items: insight.answeredPrayers
                    )
                }

                Text("insight.ai.footer")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }
            .padding(20)
        }
    }

    private func insightSection(title: String, icon: String, color: Color, items: [String]) -> some View {
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
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(color.opacity(0.6))
                            .frame(width: 6, height: 6)
                            .padding(.top, 7)
                        Text(item)
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

    // MARK: Error / empty states

    private var errorView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.textTertiary)
            Text("insight.error.title")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text("insight.error.subtitle")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "book.closed")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.textTertiary)
            Text("insight.empty.title")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text("insight.empty.subtitle")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: Generation

    private func generate() async {
        guard AIAssistantService.shared.isAvailable else {
            failed = true
            return
        }
        let withText = entries.filter { !$0.text.isEmpty }
        guard withText.count >= 3 else { return }

        isGenerating = true
        insight = nil
        failed = false
        defer { isGenerating = false }

        do {
            insight = try await AIAssistantService.shared.analyzeJournal(entries: withText)
        } catch {
            failed = true
        }
    }
}

#Preview {
    JournalInsightView()
        .modelContainer(for: PrayerEntry.self, inMemory: true)
        .preferredColorScheme(.dark)
}
