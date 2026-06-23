//
//  JournalStatsView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 01/06/2026.
//

import Charts
import SwiftUI

/// Statistiques du journal sous forme de belles courbes : activité, croissance cumulée et
/// évolution des émotions. Sélecteur de période en tête. Conçue pour vivre dans la feuille
/// « sparkles » du journal.
struct JournalStatsView: View {
  let entries: [PrayerEntry]

  @State private var period: StatsPeriod = .month

  var body: some View {
    // Agrégations O(n) calculées une seule fois par rendu.
    let activity = PrayerStats.activity(entries, period: period)
    let emotions = PrayerStats.emotionTotals(entries, period: period)
    return VStack(spacing: 20) {
      periodPicker

      if activity.isEmpty {
        emptyState
      } else {
        chartCard(activityTitleKey) { activityChart(activity) }
        if !emotions.isEmpty {
          chartCard("stats.emotions.title") { emotionsChart(emotions) }
        }
      }
    }
  }

  // MARK: - Period

  private var periodPicker: some View {
    Picker("stats.period.title", selection: $period) {
      Text("stats.period.week").tag(StatsPeriod.week)
      Text("stats.period.month").tag(StatsPeriod.month)
      Text("stats.period.sixmonths").tag(StatsPeriod.sixMonths)
      Text("stats.period.year").tag(StatsPeriod.year)
      Text("stats.period.all").tag(StatsPeriod.all)
    }
    .pickerStyle(.segmented)
    .labelsHidden()
  }

  // Titre explicite selon la granularité réelle de la courbe d'activité.
  private var activityTitleKey: LocalizedStringKey {
    switch period.bucket {
    case .day: return "stats.activity.daily"
    case .weekOfYear: return "stats.activity.weekly"
    default: return "stats.activity.monthly"
    }
  }

  // MARK: - Charts

  private func activityChart(_ activityPoints: [StatPoint]) -> some View {
    Chart(activityPoints) { point in
      AreaMark(x: .value("date", point.date), y: .value("value", point.value))
        .interpolationMethod(.catmullRom)
        .foregroundStyle(gradient(AppTheme.adorationPurple))
      LineMark(x: .value("date", point.date), y: .value("value", point.value))
        .interpolationMethod(.catmullRom)
        .foregroundStyle(AppTheme.adorationPurple)
      PointMark(x: .value("date", point.date), y: .value("value", point.value))
        .foregroundStyle(AppTheme.adorationPurple)
    }
    .chartYAxis { AxisMarks(position: .leading) }
    .frame(height: 180)
  }

  // Donut : répartition des émotions sur la période. Couleur = `pastel` de chaque émotion, identique
  // au ruban de l'onglet prière et à l'accent du journal (la palette ACTS `color` regroupait des
  // émotions sous une même teinte → secteurs indistinguables). Trou central pour l'aspect « palette »
  // plutôt que camembert plein, et `angularInset` pour séparer visuellement les secteurs.
  private func emotionsChart(_ totals: [EmotionTotal]) -> some View {
    Chart(totals) { total in
      SectorMark(
        angle: .value("count", total.count),
        innerRadius: .ratio(0.6),
        angularInset: 1.5
      )
      .cornerRadius(4)
      .foregroundStyle(by: .value("emotion", total.emotion.accessibilityLabel))
    }
    .chartForegroundStyleScale(
      domain: totals.map(\.emotion.accessibilityLabel),
      range: totals.map(\.emotion.pastel)
    )
    .chartLegend(position: .bottom, alignment: .leading, spacing: 12)
    .frame(height: 240)
  }

  // MARK: - Building blocks

  private func chartCard(
    _ titleKey: LocalizedStringKey, @ViewBuilder content: () -> some View
  ) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(titleKey)
        .font(.headline)
        .foregroundStyle(AppTheme.textPrimary)
      content()
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(AppTheme.cardSurface)
        .overlay {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
        }
    }
  }

  private func gradient(_ color: Color) -> LinearGradient {
    LinearGradient(
      colors: [color.opacity(0.35), color.opacity(0.02)],
      startPoint: .top,
      endPoint: .bottom
    )
  }

  private var emptyState: some View {
    ContentUnavailableView {
      Label("stats.empty.title", systemImage: "chart.xyaxis.line")
    } description: {
      Text("stats.empty.subtitle")
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 40)
  }
}

#Preview {
  ZStack {
    AppBackground()
    ScrollView { JournalStatsView(entries: []).padding(20) }
  }
  .preferredColorScheme(.dark)
}
