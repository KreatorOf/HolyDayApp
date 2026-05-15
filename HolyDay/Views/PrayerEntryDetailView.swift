//
//  PrayerEntryDetailView.swift
//  Kairos
//
//  Created by Matthias Cadet on 14/05/2026.
//

import SwiftUI
import SwiftData

struct PrayerEntryDetailView: View {
    let entry: PrayerEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                entryHeader
                Divider()
                prayerContent
            }
            .padding(20)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var entryHeader: some View {
        HStack(spacing: 14) {
            Image(systemName: entry.stepIcon)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.color(for: entry.stepColorName))
                .frame(width: 50, height: 50)
                .background(AppTheme.color(for: entry.stepColorName).opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.stepTitle)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(entry.date.formatted(date: .long, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var prayerContent: some View {
        Group {
            if entry.text.isEmpty {
                Text("Aucun texte enregistré pour cette prière.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                Text(entry.text)
                    .font(.body)
                    .lineSpacing(8)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PrayerEntryDetailView(entry: PrayerEntry(
            stepTitle: "Adoration",
            stepIcon: "hands.sparkles",
            stepColorName: "adorationPurple",
            text: "Seigneur, je te loue pour ta grandeur et ta bonté infinie. Tu es digne de toute gloire et de tout honneur.",
            date: .now
        ))
    }
    .preferredColorScheme(.dark)
}
