//
//  InsightCards.swift
//  HolyDay
//
//  Created by Matthias Cadet on 31/05/2026.
//

import SwiftData
import SwiftUI

// MARK: - Reusable container

struct InsightCard<Content: View>: View {
  let icon: String
  let tint: Color
  let title: LocalizedStringKey
  @ViewBuilder var content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 6) {
        Image(systemName: icon)
          .font(.caption.weight(.semibold))
          .foregroundStyle(tint)
        Text(title)
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(AppTheme.textTertiary)
          .textCase(.uppercase)
          .tracking(1.0)
      }
      content
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(AppTheme.cardFill)
        .overlay {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(tint.opacity(0.2), lineWidth: 1)
        }
    }
  }
}

// MARK: - ① Answered prayers

struct AnsweredPrayersInsight: View {
  @Query(filter: #Predicate<PrayerEntry> { $0.isAnswered }) private var answeredEntries:
    [PrayerEntry]
  @Query(filter: #Predicate<PrayerIntention> { $0.isAnswered }) private var answeredIntentions:
    [PrayerIntention]

  private var total: Int { answeredEntries.count + answeredIntentions.count }

  var body: some View {
    if total > 0 {
      InsightCard(
        icon: "checkmark.seal.fill", tint: AppTheme.supplicationGreen,
        title: "insight.answered.title"
      ) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text("\(total)")
            .font(.system(.largeTitle, design: .serif).weight(.bold))
            .foregroundStyle(AppTheme.supplicationGreen)
          Text("insight.answered.label")
            .font(.subheadline)
            .foregroundStyle(AppTheme.textSecondary)
        }
        .accessibilityElement(children: .combine)
      }
    }
  }
}

// MARK: - ② Prayer rhythm

struct PrayerRhythmInsight: View {
  @Query private var entries: [PrayerEntry]

  var body: some View {
    if entries.count >= 5 {
      InsightCard(
        icon: "clock.fill", tint: AppTheme.adorationPurple, title: "insight.rhythm.title"
      ) {
        VStack(alignment: .leading, spacing: 4) {
          Text(periodPhrase)
            .font(.subheadline)
            .foregroundStyle(AppTheme.textPrimary)
          if let weekday = dominantWeekdayName {
            Text(String(format: String(localized: "insight.rhythm.weekday"), weekday))
              .font(.caption)
              .foregroundStyle(AppTheme.textSecondary)
          }
        }
      }
    }
  }

  private var periodPhrase: LocalizedStringKey {
    var morning = 0
    var afternoon = 0
    var evening = 0
    for entry in entries {
      let hour = Calendar.current.component(.hour, from: entry.date)
      switch hour {
      case 5..<12: morning += 1
      case 12..<18: afternoon += 1
      default: evening += 1
      }
    }
    let maxCount = max(morning, afternoon, evening)
    if maxCount == morning { return "insight.rhythm.morning" }
    if maxCount == afternoon { return "insight.rhythm.afternoon" }
    return "insight.rhythm.evening"
  }

  private var dominantWeekdayName: String? {
    var counts: [Int: Int] = [:]
    for entry in entries {
      let weekday = Calendar.current.component(.weekday, from: entry.date)
      counts[weekday, default: 0] += 1
    }
    guard let dominant = counts.max(by: { $0.value < $1.value })?.key else { return nil }
    // weekday is 1-based starting Sunday; standaloneWeekdaySymbols is 0-based starting Sunday.
    let symbols = Calendar.current.standaloneWeekdaySymbols
    guard dominant - 1 < symbols.count else { return nil }
    return symbols[dominant - 1]
  }
}

// MARK: - ③ ACTS balance

struct ACTSBalanceInsight: View {
  @Query private var entries: [PrayerEntry]

  private struct Bucket: Identifiable {
    let id: String
    let name: LocalizedStringKey
    let color: Color
    let value: Int
  }

  private var buckets: [Bucket] {
    let acts = entries.filter { $0.stepIcon != "square.and.pencil" }
    func tally(_ colorName: String) -> Int {
      acts.filter { $0.stepColorName == colorName }.count
    }
    return [
      Bucket(
        id: "adoration", name: "step.adoration.title", color: AppTheme.adorationPurple,
        value: tally("adorationPurple")),
      Bucket(
        id: "confession", name: "step.confession.title", color: AppTheme.confessionBlue,
        value: tally("confessionBlue")),
      Bucket(
        id: "thanksgiving", name: "step.thanksgiving.title", color: AppTheme.thanksgivingGold,
        value: tally("thanksgivingGold")),
      Bucket(
        id: "supplication", name: "step.supplication.title", color: AppTheme.supplicationGreen,
        value: tally("supplicationGreen")),
    ]
  }

  private var total: Int { buckets.reduce(0) { $0 + $1.value } }

  var body: some View {
    if total >= 4 {
      InsightCard(
        icon: "chart.pie.fill", tint: AppTheme.confessionBlue, title: "insight.balance.title"
      ) {
        VStack(alignment: .leading, spacing: 12) {
          stackedBar
          legend
        }
      }
    }
  }

  private var stackedBar: some View {
    GeometryReader { geo in
      HStack(spacing: 2) {
        ForEach(buckets) { bucket in
          if bucket.value > 0 {
            Rectangle()
              .fill(bucket.color)
              .frame(width: geo.size.width * CGFloat(bucket.value) / CGFloat(total))
          }
        }
      }
    }
    .frame(height: 10)
    .clipShape(Capsule())
    .accessibilityHidden(true)
  }

  private var legend: some View {
    VStack(alignment: .leading, spacing: 6) {
      ForEach(buckets) { bucket in
        HStack(spacing: 8) {
          Circle().fill(bucket.color).frame(width: 7, height: 7)
          Text(bucket.name)
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)
          Spacer(minLength: 8)
          Text("\(bucket.value)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.textPrimary)
        }
      }
    }
  }
}

// MARK: - AI upsell

struct AIInsightUpsellCard: View {
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 14) {
        ZStack {
          Circle()
            .fill(AppTheme.adorationPurple.opacity(0.12))
            .frame(width: 38, height: 38)
          Image(systemName: "sparkles")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(AppTheme.adorationPurple)
        }
        VStack(alignment: .leading, spacing: 3) {
          Text("insight.upsell.title")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.textPrimary)
          Text("insight.upsell.subtitle")
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)
        }
        Spacer()
        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(AppTheme.textTertiary)
      }
      .padding(14)
      .background {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(AppTheme.cardFill)
          .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .strokeBorder(AppTheme.adorationPurple.opacity(0.25), lineWidth: 1)
          }
      }
    }
    .buttonStyle(.plain)
  }
}
