//
//  StreakMilestonesView.swift
//  HolyDay
//

import SwiftData
import SwiftUI

// MARK: - MilestoneTrigger

private enum MilestoneTrigger {
  case streak(days: Int)
  case longSessionDays(count: Int)
  case earlyMorningDays(count: Int)
}

// MARK: - PrayerMilestone

private struct PrayerMilestone: Identifiable {
  let id: Int
  let emoji: String
  let titleKey: LocalizedStringKey
  let triggerKey: LocalizedStringKey
  let trigger: MilestoneTrigger
}

private let allMilestones: [PrayerMilestone] = [
  PrayerMilestone(
    id: 1, emoji: "🌱",
    titleKey: "milestone.first.title", triggerKey: "milestone.first.trigger",
    trigger: .streak(days: 1)),
  PrayerMilestone(
    id: 2, emoji: "🔥",
    titleKey: "milestone.week.title", triggerKey: "milestone.week.trigger",
    trigger: .streak(days: 7)),
  PrayerMilestone(
    id: 3, emoji: "🌙",
    titleKey: "milestone.faithful.title", triggerKey: "milestone.faithful.trigger",
    trigger: .streak(days: 30)),
  PrayerMilestone(
    id: 4, emoji: "⭐️",
    titleKey: "milestone.perseverant.title", triggerKey: "milestone.perseverant.trigger",
    trigger: .streak(days: 100)),
  PrayerMilestone(
    id: 5, emoji: "🕊️",
    titleKey: "milestone.contemplative.title", triggerKey: "milestone.contemplative.trigger",
    trigger: .longSessionDays(count: 10)),
  PrayerMilestone(
    id: 6, emoji: "🌅",
    titleKey: "milestone.early.title", triggerKey: "milestone.early.trigger",
    trigger: .earlyMorningDays(count: 7)),
]

// MARK: - StreakMilestonesView

struct StreakMilestonesView: View {
  let bestStreak: Int
  @Query(sort: \PrayerEntry.date) private var allEntries: [PrayerEntry]

  private let calendar = Calendar.current

  private var longSessionDayCount: Int {
    var dailyDuration: [Date: TimeInterval] = [:]
    for entry in allEntries where entry.duration > 0 {
      dailyDuration[calendar.startOfDay(for: entry.date), default: 0] += entry.duration
    }
    return dailyDuration.values.filter { $0 >= 900 }.count
  }

  private var earlyMorningDayCount: Int {
    var earlyDays = Set<Date>()
    for entry in allEntries where calendar.component(.hour, from: entry.date) < 7 {
      earlyDays.insert(calendar.startOfDay(for: entry.date))
    }
    return earlyDays.count
  }

  private func progress(for milestone: PrayerMilestone) -> Double {
    switch milestone.trigger {
    case .streak(let days):
      return min(Double(bestStreak) / Double(days), 1.0)
    case .longSessionDays(let count):
      return min(Double(longSessionDayCount) / Double(count), 1.0)
    case .earlyMorningDays(let count):
      return min(Double(earlyMorningDayCount) / Double(count), 1.0)
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("streak.milestones.title")
        .font(.caption)
        .foregroundStyle(AppTheme.textTertiary)
        .textCase(.uppercase)
        .tracking(0.8)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
          ForEach(allMilestones) { milestone in
            let p = progress(for: milestone)
            MilestoneCell(milestone: milestone, progress: p)
              .scrollTransition(.animated) { content, phase in
                content
                  .opacity(phase.isIdentity ? 1 : 0.5)
                  .scaleEffect(phase.isIdentity ? 1 : 0.92)
              }
          }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
      }
    }
    .padding(16)
    .glassEffect(
      .regular.tint(Color.white.opacity(0.04)),
      in: RoundedRectangle(cornerRadius: 20, style: .continuous)
    )
  }
}

// MARK: - MilestoneCell

private struct MilestoneCell: View {
  let milestone: PrayerMilestone
  let progress: Double

  private var isUnlocked: Bool { progress >= 1.0 }

  var body: some View {
    VStack(spacing: 8) {
      ringView
      labelStack
    }
    .frame(width: 66)
  }

  private var ringView: some View {
    ZStack {
      Circle()
        .stroke(Color.white.opacity(0.10), lineWidth: 2.5)
        .frame(width: 52, height: 52)
      Circle()
        .trim(from: 0, to: progress)
        .stroke(
          isUnlocked ? AppTheme.thanksgivingGold : AppTheme.thanksgivingGold.opacity(0.4),
          style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
        )
        .frame(width: 52, height: 52)
        .rotationEffect(.degrees(-90))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
      Text(milestone.emoji)
        .font(.system(size: 22))
        .grayscale(isUnlocked ? 0 : 0.85)
        .opacity(isUnlocked ? 1 : 0.45)
    }
    .overlay(alignment: .topTrailing) {
      if isUnlocked {
        Circle()
          .fill(AppTheme.supplicationGreen)
          .frame(width: 16, height: 16)
          .overlay {
            Image(systemName: "checkmark")
              .font(.system(size: 8, weight: .bold))
              .foregroundStyle(.white)
          }
          .offset(x: 4, y: -4)
      }
    }
  }

  private var labelStack: some View {
    VStack(spacing: 3) {
      Text(milestone.titleKey)
        .font(.system(size: 9, weight: .semibold))
        .foregroundStyle(isUnlocked ? AppTheme.textPrimary : AppTheme.textTertiary)
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)
      Text(milestone.triggerKey)
        .font(.system(size: 8))
        .foregroundStyle(AppTheme.textTertiary)
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}
