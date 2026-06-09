//
//  PrayerStatsService.swift
//  HolyDay
//
//  Created by Matthias Cadet on 01/06/2026.
//

import Foundation

/// Période d'observation des statistiques. Le « bucket » fixe la granularité des courbes :
/// quotidien sur 1 semaine, hebdomadaire jusqu'à 6 mois, mensuel au-delà — pour rester lisible
/// quelle que soit l'ampleur.
enum StatsPeriod: String, CaseIterable, Identifiable {
  case week
  case month
  case sixMonths
  case year
  case all

  var id: String { rawValue }

  var cutoff: Date? {
    let calendar = Calendar.current
    switch self {
    case .week: return calendar.date(byAdding: .day, value: -7, to: Date())
    case .month: return calendar.date(byAdding: .day, value: -30, to: Date())
    case .sixMonths: return calendar.date(byAdding: .day, value: -180, to: Date())
    case .year: return calendar.date(byAdding: .day, value: -365, to: Date())
    case .all: return nil
    }
  }

  var bucket: Calendar.Component {
    switch self {
    case .week: return .day
    case .month, .sixMonths: return .weekOfYear
    case .year, .all: return .month
    }
  }
}

/// Un point d'une courbe : la date de début de bucket et la valeur agrégée.
struct StatPoint: Identifiable {
  let id = UUID()
  let date: Date
  let value: Double
}

/// Un point de la courbe d'émotions : combien de prières d'une émotion donnée dans un bucket.
struct EmotionStatPoint: Identifiable {
  let id = UUID()
  let date: Date
  let emotion: Emotion
  let count: Int
}

/// Agrégateur pur (sans UI) : transforme une liste de `PrayerEntry` en séries prêtes à tracer.
enum PrayerStats {
  /// Nombre de prières par bucket.
  static func activity(_ entries: [PrayerEntry], period: StatsPeriod) -> [StatPoint] {
    let calendar = Calendar.current
    let groups = Dictionary(grouping: filtered(entries, period, calendar)) {
      bucketStart($0.date, period.bucket, calendar)
    }
    return
      groups
      .map { StatPoint(date: $0.key, value: Double($0.value.count)) }
      .sorted { $0.date < $1.date }
  }

  /// Répartition des émotions par bucket (uniquement les prières où une émotion est renseignée).
  static func emotions(_ entries: [PrayerEntry], period: StatsPeriod) -> [EmotionStatPoint] {
    let calendar = Calendar.current
    let pairs = filtered(entries, period, calendar).compactMap { entry -> Key? in
      guard let emotion = entry.emotion else { return nil }
      return Key(date: bucketStart(entry.date, period.bucket, calendar), emotion: emotion)
    }
    return
      Dictionary(grouping: pairs) { $0 }
      .map { EmotionStatPoint(date: $0.key.date, emotion: $0.key.emotion, count: $0.value.count) }
      .sorted { $0.date < $1.date }
  }

  /// Nombre de prières par jour (clé = début de journée). Sert à la heatmap des jours priés.
  static func dailyCounts(_ entries: [PrayerEntry]) -> [Date: Int] {
    let calendar = Calendar.current
    return Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
      .mapValues(\.count)
  }

  // MARK: - Helpers

  private struct Key: Hashable {
    let date: Date
    let emotion: Emotion
  }

  private static func filtered(
    _ entries: [PrayerEntry], _ period: StatsPeriod, _ calendar: Calendar
  ) -> [PrayerEntry] {
    guard let cutoff = period.cutoff else { return entries }
    return entries.filter { $0.date >= cutoff }
  }

  private static func bucketStart(
    _ date: Date, _ component: Calendar.Component, _ calendar: Calendar
  ) -> Date {
    calendar.dateInterval(of: component, for: date)?.start ?? calendar.startOfDay(for: date)
  }
}
