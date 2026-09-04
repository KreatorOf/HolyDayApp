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

/// Part d'une émotion dans la répartition globale : combien de prières l'ont déclarée sur la période.
/// Non temporel — le donut montre une distribution (« la palette de ce qui t'amène à prier »), pas
/// une évolution dans le temps qui suggérerait une trajectoire émotionnelle « souhaitable ».
struct EmotionTotal: Identifiable {
  let id = UUID()
  let emotion: Emotion
  let count: Int
}

/// Bilan des intentions exaucées : cumulatif et non filtré par période (contrairement à
/// `activity`/`emotionTotals`), car c'est un compteur d'encouragement dans la durée — restreindre à
/// « cette semaine » viderait l'essentiel de son sens (une intention peut être exaucée des mois après).
struct AnsweredIntentionsStats {
  let answeredCount: Int
  let totalCount: Int
  /// Délai médian, en jours, entre la création de l'intention et sa réponse. `nil` si aucune
  /// intention exaucée n'a de date de réponse exploitable.
  let medianDelayDays: Int?
}

/// Agrégateur pur (sans UI) : transforme une liste de `PrayerEntry` en séries prêtes à tracer.
enum PrayerStats {
  /// Compte les intentions exaucées et le délai médian de réponse.
  static func answeredIntentions(_ intentions: [PrayerIntention]) -> AnsweredIntentionsStats {
    let calendar = Calendar.current
    let delays = intentions.filter(\.isAnswered).compactMap { intention -> Int? in
      guard let answeredAt = intention.answeredAt else { return nil }
      return calendar.dateComponents(
        [.day],
        from: calendar.startOfDay(for: intention.createdAt),
        to: calendar.startOfDay(for: answeredAt)
      ).day
    }
    .sorted()
    let median: Int? =
      switch delays.count {
      case 0: nil
      default: delays[delays.count / 2]
      }
    return AnsweredIntentionsStats(
      answeredCount: intentions.filter(\.isAnswered).count,
      totalCount: intentions.count,
      medianDelayDays: median
    )
  }

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

  /// Répartition des émotions sur la période (uniquement les prières où une émotion est renseignée).
  /// Triée dans l'ordre stable de `Emotion.allCases` → couleurs des secteurs cohérentes d'un rendu
  /// à l'autre.
  static func emotionTotals(_ entries: [PrayerEntry], period: StatsPeriod) -> [EmotionTotal] {
    let calendar = Calendar.current
    let counts = filtered(entries, period, calendar)
      .compactMap(\.emotion)
      .reduce(into: [Emotion: Int]()) { $0[$1, default: 0] += 1 }
    return Emotion.allCases.compactMap { emotion in
      counts[emotion].map { EmotionTotal(emotion: emotion, count: $0) }
    }
  }

  // MARK: - Helpers

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
