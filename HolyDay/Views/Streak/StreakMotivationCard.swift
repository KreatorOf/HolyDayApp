//
//  StreakMotivationCard.swift
//  HolyDay
//

import SwiftUI

enum StreakContext {
  case neverPrayed
  case streakBroken(best: Int)
  case building(current: Int, best: Int)
  case nearRecord(current: Int, daysLeft: Int)
  case atRecord(days: Int)
}

struct StreakMotivationCard: View {
  let context: StreakContext
  let isPrayedToday: Bool
  let onPrayNow: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      headerRow
      Divider().opacity(0.15)
      verseLabel
      if !isPrayedToday {
        prayNowButton
      }
    }
    .padding(16)
    .glassEffect(
      .regular.tint(tintColor.opacity(0.06)),
      in: RoundedRectangle(cornerRadius: 20, style: .continuous)
    )
  }

  // MARK: - Sub-views

  private var headerRow: some View {
    HStack(alignment: .top, spacing: 12) {
      Text(contextIcon)
        .font(.title2)
      VStack(alignment: .leading, spacing: 4) {
        Text(contextTitle)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(AppTheme.textPrimary)
        Text(contextSubtitle)
          .font(.caption)
          .foregroundStyle(AppTheme.textSecondary)
          .lineSpacing(2)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private var verseLabel: some View {
    Text(contextVerse)
      .font(.system(.caption, design: .serif).italic())
      .foregroundStyle(AppTheme.textTertiary)
      .multilineTextAlignment(.leading)
      .lineSpacing(3)
      .fixedSize(horizontal: false, vertical: true)
  }

  private var prayNowButton: some View {
    Button(action: onPrayNow) {
      Label(
        String(
          localized: "streak.motivation.pray.now", defaultValue: "Prendre un moment maintenant"),
        systemImage: "hands.and.sparkles"
      )
      .font(.caption.weight(.semibold))
      .foregroundStyle(AppTheme.thanksgivingGold)
    }
    .buttonStyle(.plain)
    .padding(.top, 2)
  }

  // MARK: - Context-dependent values

  private var contextIcon: String {
    switch context {
    case .neverPrayed: "🕊️"
    case .streakBroken: "🌅"
    case .building: "🔥"
    case .nearRecord: "⚡️"
    case .atRecord: "🏆"
    }
  }

  private var contextTitle: String {
    switch context {
    case .neverPrayed:
      String(
        localized: "streak.motivation.never.title", defaultValue: "Commence ta première prière")
    case .streakBroken:
      String(
        localized: "streak.motivation.broken.title",
        defaultValue: "Chaque matin est un nouveau départ")
    case .building(let current, _):
      String(
        format: String(
          localized: "streak.motivation.building.title", defaultValue: "%d jours de fidélité"),
        current
      )
    case .nearRecord(_, let daysLeft):
      String(
        format: String(
          localized: "streak.motivation.near.title",
          defaultValue: "Plus que %d jour(s) pour ton record !"),
        daysLeft
      )
    case .atRecord(let days):
      String(
        format: String(
          localized: "streak.motivation.record.title", defaultValue: "%d jours — nouveau record !"),
        days
      )
    }
  }

  private var contextSubtitle: String {
    switch context {
    case .neverPrayed:
      String(
        localized: "streak.motivation.never.subtitle",
        defaultValue: "La prière, c'est simplement parler à Dieu.")
    case .streakBroken(let best):
      String(
        format: String(
          localized: "streak.motivation.broken.subtitle",
          defaultValue: "Tu avais atteint %d jours. Il n'y a pas de condamnation — reviens."
        ),
        best
      )
    case .building:
      String(
        localized: "streak.motivation.building.subtitle",
        defaultValue: "Continue, tu construis quelque chose de beau.")
    case .nearRecord:
      String(
        localized: "streak.motivation.near.subtitle",
        defaultValue: "Tu n'as jamais été aussi proche. Tiens bon.")
    case .atRecord:
      String(
        localized: "streak.motivation.record.subtitle",
        defaultValue: "Tu dépasses tes propres limites. Soli Deo gloria.")
    }
  }

  private var contextVerse: String {
    switch context {
    case .neverPrayed:
      "« Demandez et vous recevrez, afin que votre joie soit complète. » — Jean 16:24"
    case .streakBroken:
      "« Ses miséricordes se renouvellent chaque matin. Grande est ta fidélité. » — Lamentations 3:23"
    case .building:
      "« Priez sans cesse. » — 1 Thessaloniciens 5:17"
    case .nearRecord:
      "« Ne nous lassons pas de faire le bien, car nous moissonnerons au temps convenable. » — Galates 6:9"
    case .atRecord:
      "« La bénédiction, la gloire, la sagesse, la reconnaissance… soient à notre Dieu ! » — Apocalypse 7:12"
    }
  }

  private var tintColor: Color {
    switch context {
    case .neverPrayed: .blue
    case .streakBroken: .orange
    case .building, .nearRecord, .atRecord: AppTheme.thanksgivingGold
    }
  }
}
