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
    private(set) var bestStreak: Int = 0
    private(set) var streakStartDate: Date?
    private(set) var lastIncrementToken: UUID?
    private(set) var lastIncrementValue: Int = 0

    var isPrayedToday: Bool {
        guard let last = UserDefaults.standard.object(forKey: lastPrayerDateKey) as? Date else { return false }
        return Calendar.current.isDateInToday(last)
    }

    private let streakKey = "holyday.streak"
    private let lastPrayerDateKey = "holyday.lastPrayerDate"
    private let bestStreakKey = "holyday.bestStreak"
    private let streakStartDateKey = "holyday.streakStartDate"

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

        if currentStreak == 0 {
            streakStartDate = today
            defaults.set(today, forKey: streakStartDateKey)
        }

        defaults.set(today, forKey: lastPrayerDateKey)
        currentStreak += 1
        defaults.set(currentStreak, forKey: streakKey)

        if currentStreak > bestStreak {
            bestStreak = currentStreak
            defaults.set(bestStreak, forKey: bestStreakKey)
        }

        lastIncrementValue = currentStreak
        lastIncrementToken = UUID()
    }

    private func recalculate() {
        let defaults = UserDefaults.standard
        bestStreak = defaults.integer(forKey: bestStreakKey)
        streakStartDate = defaults.object(forKey: streakStartDateKey) as? Date

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
            streakStartDate = nil
            defaults.set(0, forKey: streakKey)
            defaults.removeObject(forKey: streakStartDateKey)
        } else {
            currentStreak = defaults.integer(forKey: streakKey)
        }
    }
}
