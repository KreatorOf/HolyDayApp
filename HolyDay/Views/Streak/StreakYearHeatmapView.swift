//
//  StreakYearHeatmapView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 22/05/2026.
//

import SwiftData
import SwiftUI

// MARK: - HeatDayData

private struct HeatDayData {
  let prayerCount: Int
  let dominantColorName: String?
  let hasAnswered: Bool
}

// MARK: - RegularityStats

private struct RegularityStats {
  let rate7d: Double
  let rate30d: Double
  let bestWeekday: String?
  let worstWeekday: String?

  static let empty = RegularityStats(
    rate7d: 0, rate30d: 0,
    bestWeekday: nil, worstWeekday: nil
  )
}

// MARK: - WeekStats

private struct WeekStats {
  struct Day: Identifiable {
    let id: Date
    let hasPrayer: Bool
    let isFuture: Bool
  }

  let currentWeekPrayed: Int
  let lastWeekPrayed: Int
  let isBestWeekOfMonth: Bool
  let days: [Day]

  static let empty = WeekStats(
    currentWeekPrayed: 0, lastWeekPrayed: 0, isBestWeekOfMonth: false, days: []
  )
}

// MARK: - StreakYearHeatmapView

struct StreakYearHeatmapView: View {
  let streak: StreakService
  @Query(sort: \PrayerEntry.date) private var allEntries: [PrayerEntry]
  @Environment(\.dismiss) private var dismiss
  @State private var cachedHeatData: [Date: HeatDayData] = [:]
  @State private var cachedRegularityStats: RegularityStats = .empty
  @State private var cachedWeekStats: WeekStats = .empty

  private let calendar = Calendar.current
  private var today: Date { calendar.startOfDay(for: Date()) }

  private let cellSize: CGFloat = 12
  private let cellGap: CGFloat = 2
  private var gridHeight: CGFloat { 7 * cellSize + 6 * cellGap }

  private static let shortMonthFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "MMMMM"
    return f
  }()

  private var weekdayLabels: [String] {
    let symbols = calendar.veryShortWeekdaySymbols
    return Array(symbols[1...]) + [symbols[0]]
  }

  // MARK: - Data: heatmap

  private func computeHeatData() -> [Date: HeatDayData] {
    let cutoff = calendar.date(byAdding: .day, value: -365, to: today) ?? today
    var countMap: [Date: Int] = [:]
    var colorMap: [Date: [String: Int]] = [:]
    var answeredSet = Set<Date>()

    for entry in allEntries where entry.date >= cutoff {
      let day = calendar.startOfDay(for: entry.date)
      countMap[day, default: 0] += 1
      colorMap[day, default: [:]][entry.stepColorName, default: 0] += 1
      if entry.isAnswered { answeredSet.insert(day) }
    }

    return countMap.reduce(into: [:]) { result, pair in
      let day = pair.key
      let dominant = colorMap[day]?.max(by: { $0.value < $1.value })?.key
      result[day] = HeatDayData(
        prayerCount: pair.value,
        dominantColorName: dominant,
        hasAnswered: answeredSet.contains(day)
      )
    }
  }

  private var daysToDisplay: [Date] {
    let startApprox = calendar.date(byAdding: .weekOfYear, value: -52, to: today) ?? today
    let weekday = calendar.component(.weekday, from: startApprox)
    let daysFromMonday = (weekday + 5) % 7
    let startMonday =
      calendar.date(byAdding: .day, value: -daysFromMonday, to: startApprox) ?? startApprox

    let currentWeekday = calendar.component(.weekday, from: today)
    let daysToSunday = (8 - currentWeekday) % 7
    let endSunday = calendar.date(byAdding: .day, value: daysToSunday, to: today) ?? today

    var days: [Date] = []
    var current = startMonday
    while current <= endSunday {
      days.append(current)
      current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
    }
    return days
  }

  private var weeks: [[Date]] {
    let days = daysToDisplay
    return stride(from: 0, to: days.count, by: 7).map {
      Array(days[$0..<min($0 + 7, days.count)])
    }
  }

  private func monthLabel(forWeekIndex i: Int) -> String? {
    guard let first = weeks[i].first else { return nil }
    if i == 0 { return Self.shortMonthFormatter.string(from: first) }
    guard let prevFirst = weeks[i - 1].first else { return nil }
    return calendar.isDate(first, equalTo: prevFirst, toGranularity: .month)
      ? nil
      : Self.shortMonthFormatter.string(from: first)
  }

  private func computeRegularityStats() -> RegularityStats {
    guard !allEntries.isEmpty else { return .empty }

    let prayedDays = Set(allEntries.map { calendar.startOfDay(for: $0.date) })

    func rate(days: Int) -> Double {
      let cutoff = calendar.date(byAdding: .day, value: -days, to: today) ?? today
      return min(Double(prayedDays.filter { $0 >= cutoff }.count) / Double(days), 1.0)
    }

    var weekdayCounts = Array(repeating: 0, count: 7)
    for day in prayedDays {
      weekdayCounts[(calendar.component(.weekday, from: day) + 5) % 7] += 1
    }
    let standaloneSymbols = calendar.standaloneWeekdaySymbols

    let maxCount = weekdayCounts.max() ?? 0
    let bestWeekday: String? =
      maxCount > 0
      ? weekdayCounts.firstIndex(of: maxCount).map { standaloneSymbols[($0 + 1) % 7].capitalized }
      : nil

    let worstWeekday: String?
    if prayedDays.count >= 7, let minIdx = weekdayCounts.firstIndex(of: weekdayCounts.min() ?? 0) {
      worstWeekday = standaloneSymbols[(minIdx + 1) % 7].capitalized
    } else {
      worstWeekday = nil
    }

    return RegularityStats(
      rate7d: rate(days: 7),
      rate30d: rate(days: 30),
      bestWeekday: bestWeekday,
      worstWeekday: worstWeekday
    )
  }

  private func computeWeekStats() -> WeekStats {
    let weekdayOffset = (calendar.component(.weekday, from: today) + 5) % 7
    guard let currentMonday = calendar.date(byAdding: .day, value: -weekdayOffset, to: today)
    else { return .empty }

    let weekDays: [WeekStats.Day] = (0..<7).compactMap { i in
      guard let day = calendar.date(byAdding: .day, value: i, to: currentMonday) else { return nil }
      let isFuture = day > today
      let hasPrayer = !isFuture && (cachedHeatData[day]?.prayerCount ?? 0) > 0
      return WeekStats.Day(id: day, hasPrayer: hasPrayer, isFuture: isFuture)
    }
    let currentWeekPrayed = weekDays.filter(\.hasPrayer).count

    let lastWeekPrayed: Int = {
      guard let lastMonday = calendar.date(byAdding: .day, value: -7, to: currentMonday)
      else { return 0 }
      return (0..<7).filter { i in
        guard let day = calendar.date(byAdding: .day, value: i, to: lastMonday) else {
          return false
        }
        return (cachedHeatData[day]?.prayerCount ?? 0) > 0
      }.count
    }()

    let isBestWeekOfMonth: Bool = {
      guard currentWeekPrayed > 0 else { return false }
      let comps = calendar.dateComponents([.year, .month], from: today)
      guard let firstOfMonth = calendar.date(from: comps) else { return false }
      let firstOffset = (calendar.component(.weekday, from: firstOfMonth) + 5) % 7
      guard let firstMonday = calendar.date(byAdding: .day, value: -firstOffset, to: firstOfMonth)
      else { return false }
      var weekStart = firstMonday
      var maxOther = 0
      while weekStart < currentMonday {
        let count = (0..<7).filter { i in
          guard let day = calendar.date(byAdding: .day, value: i, to: weekStart) else {
            return false
          }
          return (cachedHeatData[day]?.prayerCount ?? 0) > 0
        }.count
        maxOther = max(maxOther, count)
        guard let next = calendar.date(byAdding: .day, value: 7, to: weekStart) else { break }
        weekStart = next
      }
      return currentWeekPrayed >= maxOther
    }()

    return WeekStats(
      currentWeekPrayed: currentWeekPrayed,
      lastWeekPrayed: lastWeekPrayed,
      isBestWeekOfMonth: isBestWeekOfMonth,
      days: weekDays
    )
  }

  // MARK: - Motivation & consistency

  private var streakContext: StreakContext {
    let current = streak.currentStreak
    let best = streak.bestStreak
    guard best > 0 else { return .neverPrayed }
    guard current > 0 else { return .streakBroken(best: best) }
    if streak.isStreakAtRisk { return .atRisk(current: current) }
    guard current < best else { return .atRecord(days: current) }
    let daysLeft = best - current
    let isNear = daysLeft <= 5 || Double(current) / Double(best) >= 0.8
    return isNear
      ? .nearRecord(current: current, daysLeft: daysLeft)
      : .building(current: current, best: best)
  }

  private var consistencyLast30: Double {
    let cutoff = calendar.date(byAdding: .day, value: -30, to: today) ?? today
    let count = cachedHeatData.keys.filter { $0 >= cutoff }.count
    return min(Double(count) / 30.0, 1.0)
  }

  private var consistencyColor: Color {
    if consistencyLast30 >= 0.7 { return AppTheme.supplicationGreen }
    if consistencyLast30 >= 0.4 { return AppTheme.thanksgivingGold }
    return AppTheme.textTertiary
  }

  // MARK: - Body

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 16) {
          motivationCard
            .padding(.horizontal, 20)
            .padding(.top, 4)
          weekStripSection
            .padding(.horizontal, 20)
          statsHeader
            .padding(.horizontal, 20)
          regularitySection
            .padding(.horizontal, 20)
          heatmapSection
            .padding(.horizontal, 20)
          milestonesSection
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
      }
      .background { AnimatedMeshBackground() }
      .task {
        cachedHeatData = computeHeatData()
        cachedRegularityStats = computeRegularityStats()
        cachedWeekStats = computeWeekStats()
      }
      .onChange(of: allEntries) { _, _ in
        cachedHeatData = computeHeatData()
        cachedRegularityStats = computeRegularityStats()
        cachedWeekStats = computeWeekStats()
      }
      .navigationTitle(String(localized: "streak.heatmap.title"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(String(localized: "common.close")) { dismiss() }
        }
      }
    }
  }

  // MARK: - Motivation card

  private var motivationCard: some View {
    StreakMotivationCard(
      context: streakContext,
      isPrayedToday: streak.isPrayedToday,
      onPrayNow: { dismiss() }
    )
  }

  // MARK: - Week strip

  private var weekStripSection: some View {
    let stats = cachedWeekStats
    let delta = stats.currentWeekPrayed - stats.lastWeekPrayed

    return VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(String(localized: "streak.week.title", defaultValue: "CETTE SEMAINE"))
          .font(.caption)
          .foregroundStyle(AppTheme.textTertiary)
          .textCase(.uppercase)
          .tracking(0.8)
        Spacer()
        if stats.currentWeekPrayed > 0 {
          Text("\(stats.currentWeekPrayed)/7 ✓")
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.thanksgivingGold)
        }
      }

      HStack(spacing: 0) {
        ForEach(stats.days) { day in
          Spacer(minLength: 0)
          VStack(spacing: 6) {
            ZStack {
              Circle()
                .fill(weekDayFill(hasPrayer: day.hasPrayer, isFuture: day.isFuture))
                .frame(width: 32, height: 32)
              if day.hasPrayer {
                Image(systemName: "checkmark")
                  .font(.system(size: 12, weight: .bold))
                  .foregroundStyle(.white)
              }
            }
            .overlay {
              if calendar.isDateInToday(day.id) {
                Circle()
                  .strokeBorder(AppTheme.thanksgivingGold.opacity(0.7), lineWidth: 1.5)
                  .frame(width: 32, height: 32)
              }
            }
            Text(dayInitial(for: day.id))
              .font(.system(size: 9, weight: .medium))
              .foregroundStyle(
                calendar.isDateInToday(day.id) ? AppTheme.thanksgivingGold : AppTheme.textTertiary
              )
          }
          Spacer(minLength: 0)
        }
      }

      if stats.isBestWeekOfMonth {
        HStack(spacing: 4) {
          Text("🎉")
          Text(
            String(localized: "streak.week.best.month", defaultValue: "Meilleure semaine du mois !")
          )
          .font(.caption)
          .foregroundStyle(AppTheme.thanksgivingGold)
        }
      } else if delta > 0 {
        Text(
          String(
            format: String(
              localized: "streak.week.delta.positive",
              defaultValue: "+%d jour(s) vs semaine dernière"),
            delta
          )
        )
        .font(.caption2)
        .foregroundStyle(AppTheme.supplicationGreen)
      } else if delta == 0 && stats.lastWeekPrayed > 0 {
        Text(
          String(
            localized: "streak.week.delta.equal",
            defaultValue: "Même rythme que la semaine dernière")
        )
        .font(.caption2)
        .foregroundStyle(AppTheme.textTertiary)
      }
    }
    .padding(16)
    .glassEffect(
      .regular.tint(Color.white.opacity(0.04)),
      in: RoundedRectangle(cornerRadius: 20, style: .continuous)
    )
  }

  private func weekDayFill(hasPrayer: Bool, isFuture: Bool) -> Color {
    if isFuture { return Color.white.opacity(0.04) }
    return hasPrayer ? AppTheme.thanksgivingGold : Color.white.opacity(0.10)
  }

  private func dayInitial(for date: Date) -> String {
    let weekday = calendar.component(.weekday, from: date)
    return calendar.veryShortWeekdaySymbols[weekday - 1]
  }

  // MARK: - Milestones

  private var milestonesSection: some View {
    StreakMilestonesView(bestStreak: streak.bestStreak)
  }

  // MARK: - Stats header

  private var statsHeader: some View {
    VStack(spacing: 0) {
      HStack(spacing: 0) {
        StatBlock(
          label: String(localized: "streak.current"),
          value: streak.currentStreak,
          color: streak.currentStreak > 0 ? AppTheme.thanksgivingGold : AppTheme.textTertiary
        )
        Divider().frame(height: 32).opacity(0.2)
        StatBlock(
          label: String(localized: "streak.best.label"),
          value: streak.bestStreak,
          color: AppTheme.thanksgivingGold
        )
        Divider().frame(height: 32).opacity(0.2)
        StatBlock(
          label: String(localized: "streak.total"),
          value: cachedHeatData.count,
          color: AppTheme.textPrimary
        )
      }
      .padding(.vertical, 14)

      Divider().opacity(0.1)

      consistencyRow
        .padding(.horizontal, 16)
        .padding(.vertical, 10)

      if streak.freezesAvailable > 0 {
        Divider().opacity(0.1)
        HStack(spacing: 6) {
          Image(systemName: "shield.fill")
            .font(.caption2)
            .foregroundStyle(AppTheme.confessionBlue)
          Text(
            String(
              format: String(localized: "streak.freeze.available"),
              streak.freezesAvailable)
          )
          .font(.caption2)
          .foregroundStyle(AppTheme.textSecondary)
          Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
      }
    }
    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
  }

  private var consistencyRow: some View {
    HStack(spacing: 8) {
      Text(String(localized: "streak.consistency.label", defaultValue: "Régularité 30j"))
        .font(.caption2)
        .foregroundStyle(AppTheme.textTertiary)
      GeometryReader { geo in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(Color.white.opacity(0.08))
          RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(consistencyColor)
            .frame(width: geo.size.width * consistencyLast30)
        }
      }
      .frame(height: 5)
      Text("\(Int(consistencyLast30 * 100))%")
        .font(.caption2.weight(.semibold))
        .foregroundStyle(consistencyColor)
        .monospacedDigit()
        .frame(width: 32, alignment: .trailing)
    }
  }

  // MARK: - Heatmap

  private var heatmapSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(String(localized: "streak.heatmap.year", defaultValue: "CETTE ANNÉE"))
        .font(.caption)
        .foregroundStyle(AppTheme.textTertiary)
        .textCase(.uppercase)
        .tracking(0.8)

      HStack(alignment: .top, spacing: 4) {
        dayLabels
          .padding(.top, 12 + 4)

        ScrollView(.horizontal, showsIndicators: false) {
          ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 4) {
              monthLabelsRow
              HStack(spacing: 0) {
                LazyHGrid(
                  rows: Array(repeating: GridItem(.fixed(cellSize), spacing: cellGap), count: 7),
                  spacing: cellGap
                ) {
                  ForEach(daysToDisplay, id: \.self) { date in
                    HeatCell(
                      date: date,
                      data: cachedHeatData[date],
                      isFuture: date > today
                    )
                  }
                }
                Color.clear.frame(width: 1).id("scroll_end")
              }
            }
            .onAppear {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                  proxy.scrollTo("scroll_end", anchor: .trailing)
                }
              }
            }
          }
        }
        .frame(height: gridHeight + 12 + 4)
      }

      legend
    }
    .padding(16)
    .glassEffect(
      .regular.tint(Color.white.opacity(0.04)),
      in: RoundedRectangle(cornerRadius: 20, style: .continuous)
    )
  }

  private var dayLabels: some View {
    VStack(spacing: cellGap) {
      ForEach(weekdayLabels.indices, id: \.self) { i in
        Text(weekdayLabels[i])
          .font(.system(size: 9, weight: .medium))
          .foregroundStyle(AppTheme.textTertiary)
          .frame(height: cellSize)
      }
    }
  }

  private var monthLabelsRow: some View {
    HStack(spacing: 0) {
      ForEach(weeks.indices, id: \.self) { i in
        Text(monthLabel(forWeekIndex: i) ?? "")
          .font(.system(size: 9, weight: .medium))
          .foregroundStyle(AppTheme.textTertiary)
          .frame(width: cellSize + cellGap, alignment: .leading)
          .lineLimit(1)
      }
    }
  }

  private var legend: some View {
    HStack(spacing: 6) {
      Text(String(localized: "streak.heatmap.legend.less", defaultValue: "Moins"))
        .font(.system(size: 9))
        .foregroundStyle(AppTheme.textTertiary)
      ForEach(0..<5, id: \.self) { level in
        RoundedRectangle(cornerRadius: 2, style: .continuous)
          .fill(legendColor(for: level))
          .frame(width: 10, height: 10)
      }
      Text(String(localized: "streak.heatmap.legend.more", defaultValue: "Plus"))
        .font(.system(size: 9))
        .foregroundStyle(AppTheme.textTertiary)
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
  }

  private func legendColor(for level: Int) -> Color {
    switch level {
    case 0: return Color.white.opacity(0.10)
    case 1: return AppTheme.thanksgivingGold.opacity(0.30)
    case 2: return AppTheme.thanksgivingGold.opacity(0.55)
    case 3: return AppTheme.thanksgivingGold.opacity(0.80)
    default: return AppTheme.thanksgivingGold
    }
  }

  // MARK: - Regularity stats

  private var regularitySection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(String(localized: "streak.stats.regularity"))
        .font(.caption)
        .foregroundStyle(AppTheme.textTertiary)
        .textCase(.uppercase)
        .tracking(0.8)

      HStack(spacing: 0) {
        RegularityRateBlock(
          label: String(localized: "streak.stats.regularity.7d"),
          rate: cachedRegularityStats.rate7d
        )
        Divider().frame(height: 40).opacity(0.2)
        RegularityRateBlock(
          label: String(localized: "streak.stats.regularity.30d"),
          rate: cachedRegularityStats.rate30d
        )
      }

      if cachedRegularityStats.bestWeekday != nil || cachedRegularityStats.worstWeekday != nil {
        Divider().opacity(0.1)
        VStack(alignment: .leading, spacing: 8) {
          if let best = cachedRegularityStats.bestWeekday {
            Label(
              String(format: String(localized: "streak.stats.regularity.best"), best),
              systemImage: "trophy.fill"
            )
            .font(.caption)
            .foregroundStyle(AppTheme.thanksgivingGold)
          }
          if let worst = cachedRegularityStats.worstWeekday {
            Label(
              String(format: String(localized: "streak.stats.regularity.challenge"), worst),
              systemImage: "bolt.fill"
            )
            .font(.caption)
            .foregroundStyle(AppTheme.confessionBlue)
          }
        }
      }
    }
    .padding(16)
    .glassEffect(
      .regular.tint(Color.white.opacity(0.04)),
      in: RoundedRectangle(cornerRadius: 20, style: .continuous)
    )
  }
}

// MARK: - RegularityRateBlock

private struct RegularityRateBlock: View {
  let label: String
  let rate: Double

  var body: some View {
    VStack(spacing: 6) {
      Text(label)
        .font(.system(size: 9, weight: .medium))
        .foregroundStyle(AppTheme.textTertiary)
      GeometryReader { geo in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(Color.white.opacity(0.08))
          RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(rateColor)
            .frame(width: geo.size.width * rate)
        }
      }
      .frame(height: 4)
      Text("\(Int(rate * 100))%")
        .font(.system(size: 11, weight: .semibold, design: .serif))
        .foregroundStyle(rateColor)
        .monospacedDigit()
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 4)
    .padding(.horizontal, 8)
  }

  private var rateColor: Color {
    if rate >= 0.8 { return AppTheme.supplicationGreen }
    if rate >= 0.5 { return AppTheme.thanksgivingGold }
    return AppTheme.textTertiary
  }
}

// MARK: - StatBlock

private struct StatBlock: View {
  let label: String
  let value: Int
  let color: Color

  var body: some View {
    VStack(spacing: 4) {
      Text("\(value)")
        .font(.system(.title2, design: .serif, weight: .bold))
        .foregroundStyle(color)
        .contentTransition(.numericText(value: Double(value)))
      Text(label)
        .font(.caption2)
        .foregroundStyle(AppTheme.textTertiary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 4)
  }
}

// MARK: - HeatCell

private struct HeatCell: View {
  let date: Date
  let data: HeatDayData?
  let isFuture: Bool

  @State private var showPopover = false

  private var prayerCount: Int { data?.prayerCount ?? 0 }
  private var isEmpty: Bool { prayerCount == 0 }

  private static let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .none
    return f
  }()

  private var cellColor: Color {
    if isFuture { return Color.white.opacity(0.04) }
    switch prayerCount {
    case 0: return Color.white.opacity(0.10)
    case 1: return AppTheme.thanksgivingGold.opacity(0.30)
    case 2, 3: return AppTheme.thanksgivingGold.opacity(0.55)
    case 4, 5, 6: return AppTheme.thanksgivingGold.opacity(0.80)
    default: return AppTheme.thanksgivingGold
    }
  }

  var body: some View {
    RoundedRectangle(cornerRadius: 2, style: .continuous)
      .fill(cellColor)
      .frame(width: 12, height: 12)
      .contentShape(Rectangle())
      .sensoryFeedback(.selection, trigger: showPopover)
      .onTapGesture {
        guard !isFuture else { return }
        showPopover = true
      }
      .popover(isPresented: $showPopover) {
        popoverContent
      }
      .accessibilityLabel(accessibilityLabel)
  }

  private var popoverContent: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(Self.dateFormatter.string(from: date))
        .font(.caption.weight(.semibold))

      if isEmpty {
        Text(String(localized: "streak.heatmap.popup.empty", defaultValue: "Aucune prière"))
          .font(.caption2)
          .foregroundStyle(.secondary)
      } else {
        Text(
          String(
            format: String(
              localized: "streak.heatmap.popup.count",
              defaultValue: "%d prière(s)"),
            prayerCount)
        )
        .font(.caption2)
        .foregroundStyle(.secondary)

        if let colorName = data?.dominantColorName {
          HStack(spacing: 5) {
            Circle()
              .fill(AppTheme.color(for: colorName))
              .frame(width: 6, height: 6)
            Text(stepLabel(for: colorName))
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }

        if data?.hasAnswered == true {
          Label(
            String(localized: "streak.heatmap.popup.answered", defaultValue: "Prière exaucée"),
            systemImage: "checkmark.circle.fill"
          )
          .font(.caption2)
          .foregroundStyle(AppTheme.supplicationGreen)
        }
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .presentationCompactAdaptation(.popover)
  }

  private func stepLabel(for colorName: String) -> String {
    switch colorName {
    case "adorationPurple": String(localized: "step.adoration.title")
    case "confessionBlue": String(localized: "step.confession.title")
    case "thanksgivingGold": String(localized: "step.thanksgiving.title")
    case "supplicationGreen": String(localized: "step.supplication.title")
    default: ""
    }
  }

  private var accessibilityLabel: String {
    let dateStr = Self.dateFormatter.string(from: date)
    if isFuture { return dateStr }
    return !isEmpty
      ? String(format: String(localized: "streak.heatmap.cell.prayed"), dateStr, prayerCount)
      : String(format: String(localized: "streak.heatmap.cell.empty"), dateStr)
  }
}

// MARK: - Preview

#Preview {
  StreakYearHeatmapView(streak: StreakService.shared)
    .modelContainer(for: PrayerEntry.self, inMemory: true)
    .preferredColorScheme(.dark)
}
