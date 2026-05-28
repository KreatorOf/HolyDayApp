//
//  StreakHeroView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 22/05/2026.
//

import SwiftUI

struct StreakHeroView: View {
  let streak: StreakService
  let prayedDays: Set<Date>
  var onTap: () -> Void

  @State private var flameScale: CGFloat = 1.0
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private var active: Bool { streak.currentStreak > 0 }
  private let calendar = Calendar.current
  private var today: Date { calendar.startOfDay(for: Date()) }

  @State private var tapToken = false

  var body: some View {
    Button(action: {
      tapToken.toggle()
      onTap()
    }) {
      HStack(spacing: 0) {
        HStack(spacing: 5) {
          Image(systemName: "flame.fill")
            .font(.footnote)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(active ? AppTheme.adaptiveOrange : AppTheme.textTertiary)
            .scaleEffect(flameScale)

          Text("\(streak.currentStreak)")
            .font(.system(.callout, design: .rounded, weight: .medium))
            .foregroundStyle(active ? AppTheme.textPrimary : AppTheme.textTertiary)
            .monospacedDigit()
            .contentTransition(.numericText(value: Double(streak.currentStreak)))
            .animation(.spring(response: 0.35), value: streak.currentStreak)

          Text(
            streak.currentStreak > 1
              ? String(localized: "streak.days")
              : String(localized: "streak.day")
          )
          .font(.caption2)
          .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.trailing, 12)

        Rectangle()
          .fill(AppTheme.cardStroke)
          .frame(width: 1, height: 14)
          .padding(.trailing, 12)

        HStack(spacing: 6) {
          ForEach(daysOfCurrentWeek, id: \.self) { date in
            let isToday = calendar.startOfDay(for: date) == today
            let hasPrayer = prayedDays.contains(calendar.startOfDay(for: date))
            MiniDayDot(isToday: isToday, hasPrayer: hasPrayer)
          }
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.caption2)
          .foregroundStyle(AppTheme.textTertiary)
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
      .glassEffect(
        .regular.tint(Color.white.opacity(active ? 0.04 : 0.02)),
        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
      )
    }
    .buttonStyle(.plain)
    .sensoryFeedback(.selection, trigger: tapToken)
    .animation(.easeInOut(duration: 0.35), value: active)
    .onChange(of: streak.currentStreak) { old, new in
      guard !reduceMotion, old == 0, new > 0 else { return }
      withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { flameScale = 1.3 }
      withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15)) { flameScale = 1.0 }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityLabel)
    .accessibilityValue(accessibilityValue)
    .accessibilityHint(String(localized: "streak.tap.hint"))
  }

  // MARK: - Days

  private var daysOfCurrentWeek: [Date] {
    let weekday = calendar.component(.weekday, from: today)
    let daysFromMonday = (weekday + 5) % 7
    let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
    return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
  }

  // MARK: - Accessibility

  private var accessibilityLabel: String {
    let dayLabel =
      streak.currentStreak == 1
      ? String(localized: "streak.day.vo")
      : String(localized: "streak.days.vo")
    return String(
      format: String(localized: "streak.accessibility.label"), streak.currentStreak, dayLabel)
  }

  private var accessibilityValue: String {
    let prayedThisWeek = daysOfCurrentWeek.filter {
      prayedDays.contains(calendar.startOfDay(for: $0))
    }.count
    let todayDone = prayedDays.contains(today)
    let todayStatus =
      todayDone
      ? String(localized: "streak.accessibility.today.done")
      : String(localized: "streak.accessibility.today.pending")

    var value = ""
    if streak.bestStreak > 0 {
      value += String(format: String(localized: "streak.accessibility.record"), streak.bestStreak)
    }
    value += String(format: String(localized: "streak.accessibility.week.count"), prayedThisWeek)
    value += todayStatus
    return value
  }
}

// MARK: - Mini Day Dot

private struct MiniDayDot: View {
  let isToday: Bool
  let hasPrayer: Bool

  var body: some View {
    Circle()
      .fill(
        hasPrayer
          ? AppTheme.adaptiveOrange.opacity(0.65)
          : AppTheme.textTertiary.opacity(isToday ? 0.40 : 0.18)
      )
      .frame(width: 8, height: 8)
      .overlay(
        Circle()
          .stroke(AppTheme.cardStroke, lineWidth: 0.5)
      )
  }
}

#Preview("Streak vide") {
  StreakHeroView(streak: StreakService.shared, prayedDays: [], onTap: {})
    .padding()
    .preferredColorScheme(.dark)
}
