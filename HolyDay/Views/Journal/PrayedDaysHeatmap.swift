//
//  PrayedDaysHeatmap.swift
//  HolyDay
//
//  Created by Matthias Cadet on 01/06/2026.
//

import SwiftUI

/// Heatmap « jours priés » façon GitHub : une colonne par semaine, une ligne par jour de la
/// semaine (lundi en haut), avec les initiales des jours à gauche et les mois (3 lettres) en haut.
/// Teinte proportionnelle au nombre de prières du jour. Pilotée par la période ; défile jusqu'à
/// aujourd'hui.
struct PrayedDaysHeatmap: View {
  let entries: [PrayerEntry]
  let period: StatsPeriod

  private let cellSize: CGFloat = 13
  private let cellGap: CGFloat = 3
  private let monthRowHeight: CGFloat = 13
  private let calendar = Calendar.current

  private var today: Date { calendar.startOfDay(for: Date()) }

  // Initiales des jours, lundi en premier (ex. « L,M,M,J,V,S,D »).
  private var weekdayLabels: [String] {
    String(localized: "calendar.weekday.labels").split(separator: ",").map(String.init)
  }

  private struct WeekColumn: Identifiable {
    let id: Int
    let monthLabel: String  // vide sauf à la 1ʳᵉ semaine d'un mois
    let days: [Date]  // 7 entrées (lundi→dimanche), semaine courante comprise (jours futurs inclus)
  }

  // Colonnes hebdomadaires complètes : du lundi de la 1ʳᵉ semaine de la période jusqu'au dimanche
  // de la semaine en cours. Les jours non encore priés (y compris à venir) restent dessinés en
  // case vide (niveau 0), pour que la grille forme un rectangle plein.
  private var weekColumns: [WeekColumn] {
    let periodBase = period.cutoff ?? entries.map(\.date).min() ?? Date()
    // Plancher : on remonte toujours d'au moins ~26 semaines pour que la grille remplisse la
    // largeur (et déborde → défilable), récent à droite. Les périodes plus longues l'étendent.
    let floorBase = calendar.date(byAdding: .day, value: -364, to: today) ?? periodBase
    let base = floorBase
    let baseDay = calendar.startOfDay(for: base)
    let startOffset = (calendar.component(.weekday, from: baseDay) + 5) % 7
    let endOffset = (calendar.component(.weekday, from: today) + 5) % 7
    guard let start = calendar.date(byAdding: .day, value: -startOffset, to: baseDay),
      let lastMonday = calendar.date(byAdding: .day, value: -endOffset, to: today)
    else { return [] }

    var columns: [WeekColumn] = []
    var weekStart = start
    var index = 0
    var previousMonth = -1
    while weekStart <= lastMonday {
      let days: [Date] = (0..<7).compactMap {
        calendar.date(byAdding: .day, value: $0, to: weekStart)
      }
      let month = calendar.component(.month, from: weekStart)
      let label = month != previousMonth ? monthAbbreviation(weekStart) : ""
      previousMonth = month
      columns.append(WeekColumn(id: index, monthLabel: label, days: days))
      index += 1
      guard let next = calendar.date(byAdding: .day, value: 7, to: weekStart) else { break }
      weekStart = next
    }
    return columns
  }

  var body: some View {
    // Calculés une seule fois par rendu : `dailyCounts` est O(n) sur toutes les prières et était
    // auparavant relu pour chacune des ~365 cellules ; `weekColumns` était évalué deux fois.
    let columns = weekColumns
    let counts = PrayerStats.dailyCounts(entries)
    return VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .top, spacing: 6) {
        weekdayColumn
        ScrollView(.horizontal, showsIndicators: false) {
          VStack(alignment: .leading, spacing: 4) {
            monthRow(columns)
            grid(columns, counts: counts)
          }
        }
        .defaultScrollAnchor(.trailing)
      }
      legend
    }
  }

  // MARK: - Pieces

  private var weekdayColumn: some View {
    VStack(spacing: cellGap) {
      ForEach(weekdayLabels.indices, id: \.self) { index in
        Text(weekdayLabels[index])
          .font(.system(size: 9, weight: .medium))
          .foregroundStyle(AppTheme.textTertiary)
          .frame(width: 12, height: cellSize)
      }
    }
    .padding(.top, monthRowHeight + 4)
  }

  // Labels positionnés en absolu (offset par index de colonne) pour qu'ils débordent librement
  // sans être tronqués à la largeur d'une cellule.
  private func monthRow(_ columns: [WeekColumn]) -> some View {
    ZStack(alignment: .topLeading) {
      ForEach(columns.filter { !$0.monthLabel.isEmpty }) { column in
        Text(column.monthLabel)
          .font(.system(size: 9, weight: .medium))
          .foregroundStyle(AppTheme.textTertiary)
          .fixedSize()
          .offset(
            x: CGFloat(column.id) * (cellSize + cellGap) + cellSize / 2
          )
      }
    }
    .frame(height: monthRowHeight, alignment: .leading)
  }

  private func grid(_ columns: [WeekColumn], counts: [Date: Int]) -> some View {
    HStack(spacing: cellGap) {
      ForEach(columns) { column in
        VStack(spacing: cellGap) {
          ForEach(column.days, id: \.self) { day in
            cell(day, counts: counts)
          }
        }
        .id(column.id)
      }
    }
  }

  private func cell(_ day: Date, counts: [Date: Int]) -> some View {
    RoundedRectangle(cornerRadius: 3, style: .continuous)
      .fill(color(forCount: counts[day] ?? 0))
      .frame(width: cellSize, height: cellSize)
  }

  private var legend: some View {
    HStack(spacing: 6) {
      Text("streak.heatmap.legend.less")
        .font(.system(size: 9))
        .foregroundStyle(AppTheme.textTertiary)
      ForEach(0..<5, id: \.self) { level in
        RoundedRectangle(cornerRadius: 2, style: .continuous)
          .fill(color(forCount: level))
          .frame(width: 10, height: 10)
      }
      Text("streak.heatmap.legend.more")
        .font(.system(size: 9))
        .foregroundStyle(AppTheme.textTertiary)
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
  }

  // MARK: - Helpers

  private func monthAbbreviation(_ date: Date) -> String {
    let month = calendar.component(.month, from: date)
    let symbols = calendar.shortStandaloneMonthSymbols
    guard month >= 1, month <= symbols.count else { return "" }
    return String(symbols[month - 1].prefix(3)).capitalized
  }

  private func color(forCount count: Int) -> Color {
    switch min(count, 4) {
    case 0: return AppTheme.buttonFillSubtle
    case 1: return AppTheme.thanksgivingGold.opacity(0.30)
    case 2: return AppTheme.thanksgivingGold.opacity(0.55)
    case 3: return AppTheme.thanksgivingGold.opacity(0.80)
    default: return AppTheme.thanksgivingGold
    }
  }
}
