//
//  StreakYearHeatmapView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 22/05/2026.
//

import Charts
import SwiftData
import SwiftUI

struct StreakYearHeatmapView: View {
  let streak: StreakService
  @Query(sort: \PrayerEntry.date) private var allEntries: [PrayerEntry]
  @Environment(\.dismiss) private var dismiss

  private let calendar = Calendar.current
  private var today: Date { calendar.startOfDay(for: Date()) }

  private let cellSize: CGFloat = 12
  private let cellGap: CGFloat = 2
  private var gridHeight: CGFloat { 7 * cellSize + 6 * cellGap }  // 96

  private static let shortMonthFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "MMMMM"  // single initial letter, e.g. J, F, M
    return f
  }()

  private var weekdayLabels: [String] {
    let symbols = calendar.veryShortWeekdaySymbols  // index 0 = Sunday
    return Array(symbols[1...]) + [symbols[0]]  // reorder to Monday–Sunday
  }

  // MARK: - Data: heatmap

  private var prayedDaysIndexed: [Date: Int] {
    let cutoff = calendar.date(byAdding: .day, value: -365, to: today) ?? today
    return
      allEntries
      .filter { $0.date >= cutoff }
      .reduce(into: [Date: Int]()) { result, entry in
        let day = calendar.startOfDay(for: entry.date)
        result[day, default: 0] += 1
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

  // MARK: - Data: stats

  private var weekdayDistribution: [Int] {
    var counts = Array(repeating: 0, count: 7)
    for date in prayedDaysIndexed.keys {
      let weekday = calendar.component(.weekday, from: date)
      let mondayFirst = (weekday + 5) % 7
      counts[mondayFirst] += 1
    }
    return counts
  }

  private var monthlyActivity: [(label: String, ratio: Double)] {
    let index = prayedDaysIndexed
    return ((-11)...0).compactMap { offset -> (label: String, ratio: Double)? in
      guard
        let monthDate = calendar.date(byAdding: .month, value: offset, to: today),
        let firstOfMonth = calendar.date(
          from: calendar.dateComponents([.year, .month], from: monthDate)),
        let range = calendar.range(of: .day, in: .month, for: firstOfMonth)
      else { return nil }

      let daysInMonth = range.count
      let prayedDays = (0..<daysInMonth).filter { day in
        guard let dayDate = calendar.date(byAdding: .day, value: day, to: firstOfMonth) else {
          return false
        }
        return (index[calendar.startOfDay(for: dayDate)] ?? 0) > 0
      }.count

      return (
        label: Self.shortMonthFormatter.string(from: firstOfMonth),
        ratio: Double(prayedDays) / Double(daysInMonth)
      )
    }
  }

  private var detailedStats:
    (
      acts: [(colorName: String, icon: String, count: Int)],
      answered: (count: Int, total: Int)
    )
  {
    let cutoff = calendar.date(byAdding: .day, value: -365, to: today) ?? today
    let recent = allEntries.filter { $0.date >= cutoff }

    var stepCounts: [String: Int] = [:]
    var answeredCount = 0
    for entry in recent {
      stepCounts[entry.stepColorName, default: 0] += 1
      if entry.isAnswered { answeredCount += 1 }
    }

    let acts = PrayerStep.defaultSteps.sorted { $0.order < $1.order }.map { step in
      (colorName: step.colorName, icon: step.icon, count: stepCounts[step.colorName] ?? 0)
    }
    return (acts: acts, answered: (count: answeredCount, total: recent.count))
  }

  // MARK: - Radar helpers

  private func radarAngle(_ index: Int, count: Int) -> Double {
    Double(index) * (2 * .pi / Double(count)) - .pi / 2
  }

  private func radarPath(values: [Double], center: CGPoint, radius: CGFloat) -> Path {
    var path = Path()
    for (i, value) in values.enumerated() {
      let angle = radarAngle(i, count: values.count)
      let r = radius * CGFloat(value)
      let point = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
      if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
    }
    path.closeSubpath()
    return path
  }

  // MARK: - Body

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 16) {
          statsHeader
            .padding(.horizontal, 20)
            .padding(.top, 4)
          heatmapSection
            .padding(.horizontal, 20)
          weekdaySection
            .padding(.horizontal, 20)
          monthlySection
            .padding(.horizontal, 20)
          recordSection
            .padding(.horizontal, 20)
          actsSection
            .padding(.horizontal, 20)
          answeredSection
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
      }
      .background { AnimatedMeshBackground() }
      .navigationTitle(String(localized: "streak.heatmap.title"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(String(localized: "common.close")) { dismiss() }
        }
      }
    }
  }

  // MARK: - Stats header

  private var statsHeader: some View {
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
        value: prayedDaysIndexed.count,
        color: AppTheme.textPrimary
      )
    }
    .padding(.vertical, 14)
    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
          .padding(.top, 12 + 4)  // aligns with grid, below month labels

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
                      count: prayedDaysIndexed[date, default: 0],
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
        .frame(height: gridHeight + 12 + 4)  // grid + month labels + spacing
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
    let scales: [CGFloat] = [0.38, 0.6, 0.75, 0.88, 1.0]
    return HStack(spacing: 6) {
      Text(String(localized: "streak.heatmap.legend.less", defaultValue: "Moins"))
        .font(.system(size: 9))
        .foregroundStyle(AppTheme.textTertiary)
      ForEach(0..<5, id: \.self) { level in
        Circle()
          .fill(legendColor(for: level))
          .frame(width: 10, height: 10)
          .scaleEffect(scales[level])
      }
      Text(String(localized: "streak.heatmap.legend.more", defaultValue: "Plus"))
        .font(.system(size: 9))
        .foregroundStyle(AppTheme.textTertiary)
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
  }

  private func legendColor(for level: Int) -> Color {
    switch level {
    case 0: return Color.white.opacity(0.08)
    case 1: return AppTheme.thanksgivingGold.opacity(0.30)
    case 2: return AppTheme.thanksgivingGold.opacity(0.55)
    case 3: return AppTheme.thanksgivingGold.opacity(0.80)
    default: return AppTheme.thanksgivingGold
    }
  }

  // MARK: - Weekday distribution

  private var weekdaySection: some View {
    let distribution = weekdayDistribution
    let maxCount = max(distribution.max() ?? 1, 1)
    let normalized = distribution.map { Double($0) / Double(maxCount) }
    let labels = weekdayLabels

    return VStack(alignment: .leading, spacing: 12) {
      Text(
        String(
          localized: "streak.stats.weekday",
          defaultValue: "PAR JOUR DE LA SEMAINE")
      )
      .font(.caption)
      .foregroundStyle(AppTheme.textTertiary)
      .textCase(.uppercase)
      .tracking(0.8)

      Canvas { context, size in
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2 - 26

        for scale in stride(from: 0.25, through: 1.0, by: 0.25) {
          let ring = radarPath(
            values: Array(repeating: scale, count: 7), center: center, radius: radius)
          context.stroke(ring, with: .color(Color.white.opacity(0.07)), lineWidth: 0.5)
        }

        for i in 0..<7 {
          let angle = radarAngle(i, count: 7)
          var line = Path()
          line.move(to: center)
          line.addLine(
            to: CGPoint(
              x: center.x + cos(angle) * radius,
              y: center.y + sin(angle) * radius))
          context.stroke(line, with: .color(Color.white.opacity(0.06)), lineWidth: 0.5)
        }

        let dataPath = radarPath(values: normalized, center: center, radius: radius)
        context.fill(dataPath, with: .color(AppTheme.thanksgivingGold.opacity(0.22)))
        context.stroke(
          dataPath,
          with: .color(AppTheme.thanksgivingGold),
          style: StrokeStyle(lineWidth: 1.8, lineJoin: .round))

        for (i, value) in normalized.enumerated() {
          let angle = radarAngle(i, count: 7)
          let r = radius * CGFloat(value)
          let pt = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
          var dot = Path()
          dot.addEllipse(in: CGRect(x: pt.x - 3, y: pt.y - 3, width: 6, height: 6))
          context.fill(dot, with: .color(AppTheme.thanksgivingGold))
        }

        for i in 0..<7 {
          let angle = radarAngle(i, count: 7)
          let labelRadius = radius + 18
          let pt = CGPoint(
            x: center.x + cos(angle) * labelRadius,
            y: center.y + sin(angle) * labelRadius)
          context.draw(
            Text(labels[i])
              .font(.system(size: 10, weight: .semibold))
              .foregroundColor(AppTheme.textTertiary),
            at: pt)
        }
      }
      .frame(height: 200)
    }
    .padding(16)
    .glassEffect(
      .regular.tint(Color.white.opacity(0.04)),
      in: RoundedRectangle(cornerRadius: 20, style: .continuous)
    )
  }

  // MARK: - Monthly activity

  private var monthlySection: some View {
    let activities = monthlyActivity

    return VStack(alignment: .leading, spacing: 12) {
      Text(
        String(
          localized: "streak.stats.monthly",
          defaultValue: "ACTIVITÉ MENSUELLE")
      )
      .font(.caption)
      .foregroundStyle(AppTheme.textTertiary)
      .textCase(.uppercase)
      .tracking(0.8)

      Chart(Array(activities.enumerated()), id: \.offset) { i, item in
        AreaMark(
          x: .value("Month", i),
          y: .value("Ratio", item.ratio)
        )
        .interpolationMethod(.catmullRom)
        .foregroundStyle(
          LinearGradient(
            colors: [
              AppTheme.thanksgivingGold.opacity(0.45),
              AppTheme.thanksgivingGold.opacity(0.02),
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )

        LineMark(
          x: .value("Month", i),
          y: .value("Ratio", item.ratio)
        )
        .interpolationMethod(.catmullRom)
        .foregroundStyle(AppTheme.thanksgivingGold)
        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))

        PointMark(
          x: .value("Month", i),
          y: .value("Ratio", item.ratio)
        )
        .symbolSize(item.ratio > 0 ? 20 : 0)
        .foregroundStyle(AppTheme.thanksgivingGold)
      }
      .chartXAxis {
        AxisMarks(values: Array(0..<activities.count)) { value in
          if let i = value.as(Int.self), i < activities.count {
            AxisValueLabel {
              Text(activities[i].label)
                .font(.system(size: 9))
                .foregroundStyle(AppTheme.textTertiary)
            }
          }
        }
      }
      .chartYAxis(.hidden)
      .chartYScale(domain: 0...1)
      .chartPlotStyle { plot in
        plot.background(Color.clear)
      }
      .frame(height: 100)
    }
    .padding(16)
    .glassEffect(
      .regular.tint(Color.white.opacity(0.04)),
      in: RoundedRectangle(cornerRadius: 20, style: .continuous)
    )
  }

  // MARK: - Record distance

  private var recordSection: some View {
    let isRecord = streak.bestStreak > 0 && streak.currentStreak >= streak.bestStreak
    let hasNoRecord = streak.bestStreak < 1
    let progress = CGFloat(
      streak.bestStreak > 0
        ? min(Double(streak.currentStreak) / Double(streak.bestStreak), 1.0)
        : 0
    )
    return VStack(alignment: .leading, spacing: 12) {
      Text(
        String(
          localized: "streak.stats.record",
          defaultValue: "OBJECTIF RECORD")
      )
      .font(.caption)
      .foregroundStyle(AppTheme.textTertiary)
      .textCase(.uppercase)
      .tracking(0.8)

      if isRecord {
        HStack(spacing: 8) {
          Image(systemName: "trophy.fill")
            .foregroundStyle(AppTheme.thanksgivingGold)
          Text(
            String(
              localized: "streak.stats.record.achieved",
              defaultValue: "Nouveau record établi !")
          )
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(AppTheme.thanksgivingGold)
        }
      } else if hasNoRecord {
        Text(
          String(
            localized: "streak.stats.record.none",
            defaultValue: "Commence ta première série de prière !")
        )
        .font(.subheadline)
        .foregroundStyle(AppTheme.textSecondary)
      } else {
        VStack(spacing: 8) {
          HStack {
            Text(
              String(
                format: String(
                  localized: "streak.stats.record.days",
                  defaultValue: "%d jour(s)"),
                streak.currentStreak)
            )
            .font(.system(.caption, design: .serif, weight: .bold))
            .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            Text(
              String(
                format: String(
                  localized: "streak.stats.record.best",
                  defaultValue: "Record : %d"),
                streak.bestStreak)
            )
            .font(.caption)
            .foregroundStyle(AppTheme.textTertiary)
          }
          GeometryReader { geo in
            ZStack(alignment: .leading) {
              RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.white.opacity(0.08))
              RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(AppTheme.thanksgivingGold)
                .frame(width: geo.size.width * progress)
            }
          }
          .frame(height: 6)
        }
      }
    }
    .padding(16)
    .glassEffect(
      .regular.tint(Color.white.opacity(0.04)),
      in: RoundedRectangle(cornerRadius: 20, style: .continuous)
    )
  }

  // MARK: - ACTS breakdown

  private var actsSection: some View {
    let breakdown = detailedStats.acts
    let total = max(breakdown.reduce(0) { $0 + $1.count }, 1)
    return VStack(alignment: .leading, spacing: 12) {
      Text(
        String(
          localized: "streak.stats.acts",
          defaultValue: "TYPES DE PRIÈRE")
      )
      .font(.caption)
      .foregroundStyle(AppTheme.textTertiary)
      .textCase(.uppercase)
      .tracking(0.8)

      VStack(spacing: 10) {
        ForEach(breakdown.indices, id: \.self) { i in
          let item = breakdown[i]
          let ratio = CGFloat(item.count) / CGFloat(total)
          HStack(spacing: 8) {
            Image(systemName: item.icon)
              .font(.system(size: 11))
              .foregroundStyle(AppTheme.color(for: item.colorName))
              .frame(width: 16)
            GeometryReader { geo in
              ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                  .fill(Color.white.opacity(0.06))
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                  .fill(AppTheme.color(for: item.colorName).opacity(0.75))
                  .frame(width: geo.size.width * ratio)
              }
            }
            .frame(height: 8)
            Text("\(item.count)")
              .font(.system(size: 11, weight: .semibold, design: .serif))
              .foregroundStyle(AppTheme.textSecondary)
              .frame(width: 28, alignment: .trailing)
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

  // MARK: - Answered prayers

  private var answeredSection: some View {
    let stats = detailedStats.answered
    let ratio = stats.total > 0 ? Double(stats.count) / Double(stats.total) : 0
    let percentage = Int(ratio * 100)
    return VStack(alignment: .leading, spacing: 12) {
      Text(
        String(
          localized: "streak.stats.answered",
          defaultValue: "PRIÈRES EXAUCÉES")
      )
      .font(.caption)
      .foregroundStyle(AppTheme.textTertiary)
      .textCase(.uppercase)
      .tracking(0.8)

      HStack(spacing: 16) {
        Gauge(value: ratio) {
          EmptyView()
        } currentValueLabel: {
          Text("\(percentage)%")
            .font(.system(.caption, design: .serif, weight: .bold))
            .foregroundStyle(AppTheme.textPrimary)
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(AppTheme.supplicationGreen)
        .frame(width: 60, height: 60)

        VStack(alignment: .leading, spacing: 4) {
          Text(
            String(
              format: String(
                localized: "streak.stats.answered.count",
                defaultValue: "%d exaucée(s)"),
              stats.count)
          )
          .font(.system(.subheadline, design: .serif, weight: .semibold))
          .foregroundStyle(AppTheme.supplicationGreen)
          Text(
            String(
              format: String(
                localized: "streak.stats.answered.total",
                defaultValue: "sur %d prières au total"),
              stats.total)
          )
          .font(.caption)
          .foregroundStyle(AppTheme.textTertiary)
        }
        Spacer()
      }
    }
    .padding(16)
    .glassEffect(
      .regular.tint(Color.white.opacity(0.04)),
      in: RoundedRectangle(cornerRadius: 20, style: .continuous)
    )
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
  let count: Int
  let isFuture: Bool

  @State private var showPopover = false
  private var isEmpty: Bool { count < 1 }

  private static let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .none
    return f
  }()

  private var scaleFactor: CGFloat {
    if isFuture { return 0.3 }
    switch count {
    case 0: return 0.38
    case 1: return 0.60
    case 2, 3: return 0.75
    case 4, 5, 6: return 0.88
    default: return 1.0
    }
  }

  private var cellColor: Color {
    if isFuture { return Color.white.opacity(0.04) }
    switch count {
    case 0: return Color.white.opacity(0.08)
    case 1: return AppTheme.thanksgivingGold.opacity(0.30)
    case 2, 3: return AppTheme.thanksgivingGold.opacity(0.55)
    case 4, 5, 6: return AppTheme.thanksgivingGold.opacity(0.80)
    default: return AppTheme.thanksgivingGold
    }
  }

  var body: some View {
    Circle()
      .fill(cellColor)
      .scaleEffect(scaleFactor)
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
    VStack(alignment: .leading, spacing: 4) {
      Text(Self.dateFormatter.string(from: date))
        .font(.caption.weight(.semibold))
      Text(
        isEmpty
          ? String(localized: "streak.heatmap.popup.empty", defaultValue: "Aucune prière")
          : String(
            format: String(
              localized: "streak.heatmap.popup.count",
              defaultValue: "%d prière(s)"),
            count)
      )
      .font(.caption2)
      .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .presentationCompactAdaptation(.popover)
  }

  private var accessibilityLabel: String {
    let dateStr = Self.dateFormatter.string(from: date)
    if isFuture { return dateStr }
    return !isEmpty
      ? String(format: String(localized: "streak.heatmap.cell.prayed"), dateStr, count)
      : String(format: String(localized: "streak.heatmap.cell.empty"), dateStr)
  }
}

#Preview {
  StreakYearHeatmapView(streak: StreakService.shared)
    .modelContainer(for: PrayerEntry.self, inMemory: true)
    .preferredColorScheme(.dark)
}
