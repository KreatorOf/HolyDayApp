//
//  StreakYearHeatmapView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 22/05/2026.
//

import SwiftData
import SwiftUI

struct StreakYearHeatmapView: View {
  let streak: StreakService
  @Query(sort: \PrayerEntry.date) private var allEntries: [PrayerEntry]
  @Environment(\.dismiss) private var dismiss

  private let calendar = Calendar.current
  private var today: Date { calendar.startOfDay(for: Date()) }

  private var weekdayLabels: [String] {
    let symbols = calendar.veryShortWeekdaySymbols  // index 0 = Sunday
    return Array(symbols[1...]) + [symbols[0]]  // reorder to Monday–Sunday
  }

  private var dayLabels: some View {
    VStack(spacing: 6) {
      ForEach(weekdayLabels.indices, id: \.self) { i in
        Text(weekdayLabels[i])
          .font(.system(size: 10, weight: .medium))
          .foregroundStyle(AppTheme.textTertiary)
          .frame(height: 16)
      }
    }
  }

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
    // Start from Monday of the week ~52 weeks ago
    let startApprox = calendar.date(byAdding: .weekOfYear, value: -52, to: today) ?? today
    let weekday = calendar.component(.weekday, from: startApprox)
    let daysFromMonday = (weekday + 5) % 7
    let startMonday =
      calendar.date(byAdding: .day, value: -daysFromMonday, to: startApprox) ?? startApprox

    // End at Sunday of the current week
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

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          statsHeader
            .padding(.horizontal, 20)
            .padding(.top, 4)

          heatmapSection

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

  // MARK: Stats

  private var statsHeader: some View {
    HStack(spacing: 0) {
      StatBlock(
        label: String(localized: "streak.current"),
        value: streak.currentStreak,
        color: streak.currentStreak > 0 ? AppTheme.thanksgivingGold : AppTheme.textTertiary
      )
      Divider()
        .frame(height: 32)
        .opacity(0.2)
      StatBlock(
        label: String(localized: "streak.best.label"),
        value: streak.bestStreak,
        color: AppTheme.thanksgivingGold
      )
      Divider()
        .frame(height: 32)
        .opacity(0.2)
      StatBlock(
        label: String(localized: "streak.total"),
        value: prayedDaysIndexed.count,
        color: AppTheme.textPrimary
      )
    }
    .padding(.vertical, 14)
    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
  }

  // MARK: Heatmap

  // 7 rows × 16pt + 6 gaps × 6pt spacing
  private let heatmapHeight: CGFloat = 148

  private var heatmapSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(String(localized: "streak.heatmap.year", defaultValue: "CETTE ANNÉE"))
        .font(.caption)
        .foregroundStyle(AppTheme.textTertiary)
        .textCase(.uppercase)
        .tracking(0.8)

      if prayedDaysIndexed.isEmpty {
        Text(String(localized: "streak.heatmap.empty", defaultValue: "Aucune activité"))
          .font(.callout)
          .foregroundStyle(AppTheme.textTertiary)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
      } else {
        HStack(spacing: 10) {
          dayLabels
            .frame(height: heatmapHeight)

          ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
              HStack(spacing: 0) {
                LazyHGrid(
                  rows: Array(repeating: GridItem(.fixed(16), spacing: 6), count: 7),
                  spacing: 6
                ) {
                  ForEach(daysToDisplay, id: \.self) { date in
                    HeatCell(
                      date: date,
                      count: prayedDaysIndexed[date, default: 0],
                      isFuture: date > today
                    )
                    .id(date)
                  }
                }

                Color.clear
                  .frame(width: 16)
                  .id("scroll_end")
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
          .frame(height: heatmapHeight)
          .mask {
            LinearGradient(
              stops: [
                .init(color: .black, location: 0.0),
                .init(color: .black, location: 0.88),
                .init(color: .clear, location: 1.0),
              ],
              startPoint: .leading,
              endPoint: .trailing
            )
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

// MARK: Subviews

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

private struct HeatCell: View {
  let date: Date
  let count: Int
  let isFuture: Bool

  @State private var isPressed = false
  private var isEmpty: Bool { count < 1 }
  private var intensity: Double { min(Double(count) / 3.0, 1.0) }

  private static let dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .none
    return f
  }()

  var body: some View {
    Circle()  // Forme plus organique que le carré de base
      .frame(width: 16, height: 16)
      .glassEffect(
        glassStyle,
        in: Circle()
      )
      // L'astuce "Liquid Glass" : un reflet spéculaire sur le bord supérieur
      .overlay(
        Circle()
          .stroke(
            LinearGradient(
              colors: [.white.opacity(0.4), .clear, .white.opacity(0.1)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            lineWidth: 0.5
          )
      )
      .scaleEffect(isPressed ? 0.8 : 1.0)
      .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
      // Retour haptique natif d'iOS 17+
      .sensoryFeedback(.selection, trigger: isPressed)
      .onLongPressGesture(
        minimumDuration: .infinity,
        pressing: { pressing in
          isPressed = pressing
        }, perform: {}
      )
      .accessibilityLabel(accessibilityLabel)
  }

  private var glassStyle: Glass {
    if isFuture {
      return .regular.tint(Color.white.opacity(0.01))
    } else if !isEmpty {
      return .regular.tint(AppTheme.thanksgivingGold.opacity(0.2 + 0.6 * intensity))
    } else {
      return .regular.tint(Color.white.opacity(0.05))
    }
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
