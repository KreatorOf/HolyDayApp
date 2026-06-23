//
//  PrayerRecordService.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import Foundation
import Observation

/// Suivi minimal et sans pression des prières : retient le nombre de jours distincts où l'utilisateur
/// a prié et la date de la dernière prière (miroir App Group pour le widget « Prier maintenant »).
/// Aucune notion de série/streak — prier reste libre, sans compteur de jours consécutifs ni
/// culpabilisation. `totalPrayedDays` ne sert que de signal discret pour la sollicitation de don.
@MainActor
@Observable
final class PrayerRecordService {
  static let shared = PrayerRecordService()

  // Cumul de jours distincts où l'utilisateur a prié (ne retombe jamais à zéro).
  private(set) var totalPrayedDays: Int = 0
  // Change à chaque nouveau jour prié enregistré : permet à l'UI de détecter qu'une prière vient
  // d'avoir lieu pendant une session (déclencheur de la sollicitation de don).
  private(set) var lastRecordToken: UUID?

  var isPrayedToday: Bool {
    guard let last = UserDefaults.standard.object(forKey: lastPrayerDateKey) as? Date else {
      return false
    }
    return Calendar.current.isDateInToday(last)
  }

  private let lastPrayerDateKey = "holyday.lastPrayerDate"
  private let totalPrayedDaysKey = "holyday.totalPrayedDays"

  private init() {
    recalculate()
  }

  // Retourne `true` uniquement si un nouveau jour prié vient d'être enregistré (sinon l'appel est
  // sans effet car déjà prié aujourd'hui) — sert à ne déclencher la sollicitation de don qu'à un
  // vrai moment de fin de prière.
  @discardableResult
  func recordPrayer() -> Bool {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let defaults = UserDefaults.standard

    if let lastDate = defaults.object(forKey: lastPrayerDateKey) as? Date,
      calendar.startOfDay(for: lastDate) == today
    {
      return false
    }

    defaults.set(today, forKey: lastPrayerDateKey)
    SharedStore.setLastPrayerDate(today)

    totalPrayedDays += 1
    defaults.set(totalPrayedDays, forKey: totalPrayedDaysKey)

    lastRecordToken = UUID()
    return true
  }

  func refresh() {
    recalculate()
  }

  func reset() {
    let defaults = UserDefaults.standard
    defaults.removeObject(forKey: lastPrayerDateKey)
    defaults.removeObject(forKey: totalPrayedDaysKey)
    recalculate()
  }

  private func recalculate() {
    let defaults = UserDefaults.standard
    totalPrayedDays = defaults.integer(forKey: totalPrayedDaysKey)
    // Miroir vers l'App Group : le widget « Prier maintenant » lit cette date. Couvre aussi la
    // migration silencieuse des utilisateurs existants (la date vivait jusqu'ici uniquement dans
    // UserDefaults.standard).
    SharedStore.setLastPrayerDate(defaults.object(forKey: lastPrayerDateKey) as? Date)
  }
}
