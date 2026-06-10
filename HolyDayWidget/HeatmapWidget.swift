//
//  HeatmapWidget.swift
//  HolyDayWidget
//

import SwiftUI
import WidgetKit

// MARK: - Timeline

struct HeatmapEntry: TimelineEntry, Sendable {
  let date: Date
  let counts: [String: Int]
}

struct HeatmapTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> HeatmapEntry {
    HeatmapEntry(date: .now, counts: WidgetPreviewData.sampleCounts())
  }

  func getSnapshot(in context: Context, completion: @escaping @Sendable (HeatmapEntry) -> Void) {
    // Galerie de widgets : une grille remplie montre la promesse, pas une grille vide.
    var counts = SharedStore.dailyCounts()
    if counts.isEmpty && context.isPreview {
      counts = WidgetPreviewData.sampleCounts()
    }
    completion(HeatmapEntry(date: .now, counts: counts))
  }

  func getTimeline(
    in context: Context, completion: @escaping @Sendable (Timeline<HeatmapEntry>) -> Void
  ) {
    // Les données fraîches arrivent par rechargement déclenché côté app (WidgetSyncService) ;
    // minuit ne sert qu'à décaler la grille au changement de jour.
    let entry = HeatmapEntry(date: .now, counts: SharedStore.dailyCounts())
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .distantFuture
    let nextMidnight = Calendar.current.startOfDay(for: tomorrow)
    completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
  }
}

// MARK: - Échelle de teinte

/// Teinte or proportionnelle au nombre de prières du jour — mêmes paliers que la heatmap du
/// journal. Le niveau 0 reste une case neutre, jamais un reproche ; les jours à venir sont
/// quasi invisibles (pas encore arrivés, rien à reprocher non plus).
private func levelColor(_ count: Int) -> Color {
  switch min(count, 4) {
  case 0: return Color.white.opacity(0.10)
  case 1: return WidgetTheme.gold.opacity(0.35)
  case 2: return WidgetTheme.gold.opacity(0.60)
  case 3: return WidgetTheme.gold.opacity(0.82)
  default: return WidgetTheme.gold
  }
}

private let futureColor = Color.white.opacity(0.04)

/// Numéro de jour lisible quelle que soit la teinte : encre nuit sur les ors soutenus,
/// hiérarchie blanche ailleurs, estompé pour les jours à venir.
private func dayNumberColor(count: Int, isFuture: Bool, isToday: Bool) -> Color {
  if isFuture { return Color.white.opacity(0.25) }
  if count >= 2 { return WidgetTheme.night }
  if isToday { return .white }
  return WidgetTheme.textTertiary
}

/// Initiales localisées des jours, lundi en premier (clé : "L,M,M,J,V,S,D").
private func weekdayInitials() -> [String] {
  String(localized: "widget.weekday.labels").split(separator: ",").map(String.init)
}

// MARK: - View

/// Moments de prière, pensés pour la lecture d'un coup d'œil : le medium montre les deux
/// dernières semaines en grosses pastilles ancrées sur les jours de la semaine ; le large, le
/// mois en cours en mini-calendrier avec les numéros de jours. (L'ancienne grille façon GitHub
/// sur 13-17 semaines était trop dense pour un widget.)
struct HeatmapWidgetEntryView: View {
  @Environment(\.widgetFamily) private var family
  @Environment(\.widgetRenderingMode) private var renderingMode
  let entry: HeatmapEntry

  private var calendar: Calendar { Calendar.current }
  private var isLarge: Bool { family == .systemLarge }

  var body: some View {
    let palette = WidgetTheme.Palette(renderingMode)
    VStack(alignment: .leading, spacing: 8) {
      header(palette)
      if isLarge {
        MonthCalendarView(entry: entry, palette: palette)
      } else {
        CurrentWeekView(entry: entry, palette: palette)
      }
      bottomRow(palette)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityText)
    .containerBackground(for: .widget) {
      WidgetTheme.nightBackground(accent: WidgetTheme.gold, intensity: 0.1)
    }
    .widgetURL(URL(string: "holyday://journal"))
  }

  // MARK: - Pieces

  private func header(_ palette: WidgetTheme.Palette) -> some View {
    HStack {
      HStack(spacing: 5) {
        Image(systemName: "sparkles")
          .font(.caption2)
          .foregroundStyle(WidgetTheme.gold)
          .widgetAccentable()
        Text("widget.heatmap.title")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(palette.tertiary)
          .textCase(.uppercase)
          .tracking(1)
      }
      Spacer()
      Text(entry.date.formatted(.dateTime.month(.wide)))
        .font(.caption2)
        .foregroundStyle(palette.tertiary)
    }
  }

  private func bottomRow(_ palette: WidgetTheme.Palette) -> some View {
    HStack(spacing: 6) {
      if isLarge {
        Text("widget.heatmap.legend.less")
          .font(.caption2)
          .foregroundStyle(palette.tertiary)
        ForEach(0..<5, id: \.self) { level in
          RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(levelColor(level))
            .frame(width: 8, height: 8)
        }
        Text("widget.heatmap.legend.more")
          .font(.caption2)
          .foregroundStyle(palette.tertiary)
      }
      Spacer()
      if monthPrayedDays > 0 {
        Text(monthCountText)
          .font(.caption2.weight(.medium))
          .foregroundStyle(WidgetTheme.gold)
          .widgetAccentable()
      } else {
        Text("widget.heatmap.empty")
          .font(.caption2.weight(.medium))
          .foregroundStyle(palette.tertiary)
      }
    }
  }

  // MARK: - Helpers

  /// Jours distincts priés dans le mois en cours.
  private var monthPrayedDays: Int {
    let parts = calendar.dateComponents([.year, .month], from: entry.date)
    let prefix = String(format: "%04d-%02d-", parts.year ?? 0, parts.month ?? 0)
    return entry.counts.filter { $0.key.hasPrefix(prefix) && $0.value > 0 }.count
  }

  private var monthCountText: String {
    String.localizedStringWithFormat(
      String(localized: "widget.heatmap.monthCount"), monthPrayedDays)
  }

  private var accessibilityText: String {
    let title = String(localized: "widget.heatmap.title")
    let detail =
      monthPrayedDays > 0 ? monthCountText : String(localized: "widget.heatmap.empty")
    return "\(title). \(detail)"
  }
}

// MARK: - Semaine en cours (medium)

private struct CurrentWeekView: View {
  let entry: HeatmapEntry
  let palette: WidgetTheme.Palette

  private var calendar: Calendar { Calendar.current }
  private let dotSize: CGFloat = 28

  var body: some View {
    let today = calendar.startOfDay(for: entry.date)
    let mondayOffset = (calendar.component(.weekday, from: today) + 5) % 7
    let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: today) ?? today
    let initials = weekdayInitials()

    HStack(spacing: 6) {
      ForEach(0..<7, id: \.self) { column in
        VStack(spacing: 6) {
          Text(initials.indices.contains(column) ? initials[column] : "")
            .font(.caption2.weight(.medium))
            .foregroundStyle(palette.tertiary)
          dayDot(calendar.date(byAdding: .day, value: column, to: monday) ?? monday, today: today)
        }
        .frame(maxWidth: .infinity)
      }
    }
  }

  private func dayDot(_ day: Date, today: Date) -> some View {
    let isFuture = day > today
    let isToday = calendar.isDate(day, inSameDayAs: today)
    let count = isFuture ? 0 : (entry.counts[SharedStore.dayKey(for: day)] ?? 0)
    return ZStack {
      Circle()
        .fill(isFuture ? futureColor : levelColor(count))
      Text("\(calendar.component(.day, from: day))")
        .font(.system(size: 11, weight: isToday ? .bold : .medium))
        .foregroundStyle(dayNumberColor(count: count, isFuture: isFuture, isToday: isToday))
    }
    .frame(width: dotSize, height: dotSize)
    .overlay {
      if isToday {
        Circle().stroke(Color.white.opacity(0.85), lineWidth: 1.5)
      }
    }
  }
}

// MARK: - Mini-calendrier du mois (large)

private struct MonthCalendarView: View {
  let entry: HeatmapEntry
  let palette: WidgetTheme.Palette

  private var calendar: Calendar { Calendar.current }
  private let gap: CGFloat = 4

  var body: some View {
    GeometryReader { geo in
      let weeks = monthWeeks
      let rows = CGFloat(max(weeks.count, 1))
      let weekdayBand: CGFloat = 16
      let cell = min(
        (geo.size.width - 6 * gap) / 7,
        (geo.size.height - weekdayBand - rows * gap) / rows)
      let gridWidth = cell * 7 + 6 * gap
      let initials = weekdayInitials()
      let today = calendar.startOfDay(for: entry.date)

      VStack(alignment: .leading, spacing: gap) {
        HStack(spacing: gap) {
          ForEach(0..<7, id: \.self) { column in
            Text(initials.indices.contains(column) ? initials[column] : "")
              .font(.caption2.weight(.medium))
              .foregroundStyle(palette.tertiary)
              .frame(width: cell, height: weekdayBand - gap)
          }
        }
        ForEach(weeks.indices, id: \.self) { weekIndex in
          HStack(spacing: gap) {
            ForEach(0..<7, id: \.self) { column in
              dayCell(weeks[weekIndex][column], size: cell, today: today)
            }
          }
        }
      }
      .frame(width: gridWidth)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  // MARK: - Cellule

  @ViewBuilder
  private func dayCell(_ day: Date?, size: CGFloat, today: Date) -> some View {
    if let day {
      let isFuture = day > today
      let isToday = calendar.isDate(day, inSameDayAs: today)
      let count = isFuture ? 0 : (entry.counts[SharedStore.dayKey(for: day)] ?? 0)
      ZStack {
        RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
          .fill(isFuture ? futureColor : levelColor(count))
        Text("\(calendar.component(.day, from: day))")
          .font(.system(size: min(11, size * 0.34), weight: isToday ? .bold : .medium))
          .foregroundStyle(dayNumberColor(count: count, isFuture: isFuture, isToday: isToday))
      }
      .overlay {
        if isToday {
          RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
            .stroke(Color.white.opacity(0.85), lineWidth: 1.5)
        }
      }
      .frame(width: size, height: size)
    } else {
      Color.clear
        .frame(width: size, height: size)
    }
  }

  /// Semaines du mois en cours (lundi→dimanche) ; `nil` hors du mois.
  private var monthWeeks: [[Date?]] {
    let monthParts = calendar.dateComponents([.year, .month], from: entry.date)
    guard let firstOfMonth = calendar.date(from: monthParts),
      let dayRange = calendar.range(of: .day, in: .month, for: firstOfMonth)
    else { return [] }

    let firstOffset = (calendar.component(.weekday, from: firstOfMonth) + 5) % 7
    let slots: [Date?] =
      Array(repeating: nil, count: firstOffset)
      + dayRange.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: firstOfMonth) }

    return stride(from: 0, to: slots.count, by: 7).map { start in
      (0..<7).map { offset in
        let index = start + offset
        return index < slots.count ? slots[index] : nil
      }
    }
  }
}

// MARK: - Widget definition

struct HeatmapWidget: Widget {
  let kind = "HeatmapWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: HeatmapTimelineProvider()) { entry in
      HeatmapWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("widget.heatmap.name")
    .description("widget.heatmap.description")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}

// MARK: - Previews

#Preview("Medium", as: .systemMedium) {
  HeatmapWidget()
} timeline: {
  HeatmapEntry(date: .now, counts: WidgetPreviewData.sampleCounts())
}

#Preview("Large", as: .systemLarge) {
  HeatmapWidget()
} timeline: {
  HeatmapEntry(date: .now, counts: WidgetPreviewData.sampleCounts())
}

#Preview("Medium — vide", as: .systemMedium) {
  HeatmapWidget()
} timeline: {
  HeatmapEntry(date: .now, counts: [:])
}
