//
//  StreakService.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class StreakService {
    static let shared = StreakService()

    private(set) var currentStreak: Int = 0

    private let streakKey = "holyday.streak"
    private let lastPrayerDateKey = "holyday.lastPrayerDate"

    private init() {
        recalculate()
    }

    func recordPrayer() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let defaults = UserDefaults.standard

        if let lastDate = defaults.object(forKey: lastPrayerDateKey) as? Date,
           calendar.startOfDay(for: lastDate) == today {
            return
        }

        defaults.set(today, forKey: lastPrayerDateKey)
        currentStreak += 1
        defaults.set(currentStreak, forKey: streakKey)
    }

    private func recalculate() {
        let defaults = UserDefaults.standard
        guard let lastDate = defaults.object(forKey: lastPrayerDateKey) as? Date else {
            currentStreak = 0
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: lastDate)
        let daysSince = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

        if daysSince > 1 {
            currentStreak = 0
            defaults.set(0, forKey: streakKey)
        } else {
            currentStreak = defaults.integer(forKey: streakKey)
        }
    }
}
