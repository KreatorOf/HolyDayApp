//
//  PrayerHistoryView.swift
//  Kairos
//
//  Created by Matthias Cadet on 14/05/2026.
//

import SwiftUI
import SwiftData

struct PrayerHistoryView: View {
    @Query(sort: \PrayerEntry.date, order: .reverse) private var entries: [PrayerEntry]
    @Environment(\.modelContext) private var modelContext
    @State private var showInsight = false

    private var groupedByDay: [(Date, [PrayerEntry])] {
        let groups = Dictionary(grouping: entries) { entry in
            Calendar.current.startOfDay(for: entry.date)
        }
        return groups.sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    journalList
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                if entries.filter({ !$0.text.isEmpty }).count >= 3,
                   AIAssistantService.shared.isAvailable {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showInsight = true
                        } label: {
                            Image(systemName: "sparkles")
                                .foregroundStyle(AppTheme.adorationPurple)
                        }
                    }
                }
            }
            .sheet(isPresented: $showInsight) {
                JournalInsightView()
            }
        }
    }

    // MARK: List

    private var journalList: some View {
        List {
            ForEach(groupedByDay, id: \.0) { date, dayEntries in
                Section(dayLabel(date)) {
                    ForEach(dayEntries) { entry in
                        NavigationLink {
                            PrayerEntryDetailView(entry: entry)
                        } label: {
                            PrayerEntryRow(entry: entry)
                        }
                    }
                    .onDelete { indexSet in
                        delete(from: dayEntries, at: indexSet)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("Journal vide")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Vos prières apparaîtront ici après chaque session complétée.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Helpers

    private func dayLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return NSLocalizedString("date.today", comment: "") }
        if calendar.isDateInYesterday(date) { return NSLocalizedString("date.yesterday", comment: "") }
        return date.formatted(.dateTime.day().month(.wide).year())
    }

    private func delete(from dayEntries: [PrayerEntry], at indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(dayEntries[index])
        }
    }
}

// MARK: Row

private struct PrayerEntryRow: View {
    let entry: PrayerEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.stepIcon)
                .font(.callout)
                .foregroundStyle(AppTheme.color(for: entry.stepColorName))
                .frame(width: 36, height: 36)
                .background(AppTheme.color(for: entry.stepColorName).opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(entry.stepTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(entry.date, format: .dateTime.hour().minute())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if entry.text.isEmpty {
                    Text("Prière sans texte")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .italic()
                } else {
                    Text(entry.text)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PrayerHistoryView()
        .modelContainer(for: PrayerEntry.self, inMemory: true)
        .preferredColorScheme(.dark)
}
