//
//  StreakMilestonesView.swift
//  HolyDay
//

import SwiftUI

struct PrayerMilestone: Identifiable {
  let id: Int
  let days: Int
  let icon: String
  let title: String
}

private let allMilestones: [PrayerMilestone] = [
  PrayerMilestone(id: 1, days: 3, icon: "leaf.fill", title: "Premier pas"),
  PrayerMilestone(id: 2, days: 7, icon: "flame.fill", title: "1 semaine"),
  PrayerMilestone(id: 3, days: 14, icon: "heart.fill", title: "2 semaines"),
  PrayerMilestone(id: 4, days: 21, icon: "star.fill", title: "Habitude"),
  PrayerMilestone(id: 5, days: 30, icon: "moon.fill", title: "1 mois"),
  PrayerMilestone(id: 6, days: 60, icon: "sparkles", title: "2 mois"),
  PrayerMilestone(id: 7, days: 100, icon: "rosette", title: "100 jours"),
  PrayerMilestone(id: 8, days: 180, icon: "trophy.fill", title: "6 mois"),
  PrayerMilestone(id: 9, days: 365, icon: "crown.fill", title: "1 an"),
]

struct StreakMilestonesView: View {
  let bestStreak: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(String(localized: "streak.milestones.title", defaultValue: "JALONS"))
        .font(.caption)
        .foregroundStyle(AppTheme.textTertiary)
        .textCase(.uppercase)
        .tracking(0.8)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(allMilestones) { milestone in
            MilestoneCell(milestone: milestone, bestStreak: bestStreak)
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
  let bestStreak: Int

  private var isUnlocked: Bool { bestStreak >= milestone.days }
  private var progress: Double {
    isUnlocked ? 1.0 : min(Double(bestStreak) / Double(milestone.days), 1.0)
  }

  var body: some View {
    VStack(spacing: 6) {
      ringView
      titleStack
    }
  }

  private var ringView: some View {
    ZStack {
      Circle()
        .stroke(Color.white.opacity(0.1), lineWidth: 2.5)
        .frame(width: 48, height: 48)
      Circle()
        .trim(from: 0, to: progress)
        .stroke(
          isUnlocked ? AppTheme.thanksgivingGold : AppTheme.thanksgivingGold.opacity(0.4),
          style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
        )
        .frame(width: 48, height: 48)
        .rotationEffect(.degrees(-90))
      Image(systemName: milestone.icon)
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(isUnlocked ? AppTheme.thanksgivingGold : AppTheme.textTertiary)
    }
  }

  private var titleStack: some View {
    VStack(spacing: 2) {
      Text(milestone.title)
        .font(.system(size: 9, weight: .medium))
        .foregroundStyle(isUnlocked ? AppTheme.textPrimary : AppTheme.textTertiary)
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .frame(width: 52)
      Text(
        String(
          format: String(localized: "streak.milestone.days", defaultValue: "%dj"), milestone.days)
      )
      .font(.system(size: 8))
      .foregroundStyle(AppTheme.textTertiary)
    }
  }
}
