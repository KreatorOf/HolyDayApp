//
//  ReminderPlanner.swift
//  HolyDay
//
//  Created by Matthias Cadet on 16/09/2026.
//

import Foundation

/// Ce que l'app sait de la vie de prière au moment où elle planifie les rappels. Les notifications
/// locales étant figées à la planification (et le store SwiftData illisible appareil verrouillé),
/// ce contexte est relu à chaque replanification, jamais au déclenchement.
struct ReminderContext: Equatable {
  var lastPrayerDate: Date?
  var lastEmotion: Emotion?
  var lastEmotionDate: Date?
  var oldestOpenIntentionDate: Date?

  static let empty = ReminderContext()
}

enum ReminderKind: Equatable {
  /// Question de réflexion tournante (comportement historique).
  case question
  /// Verset du thème de la dernière émotion déclarée ; index dans `VerseCorpus.all`.
  case verse(corpusIndex: Int)
  /// Invitation à revenir sur ses intentions — sans jamais en citer le texte (écran verrouillé).
  case intentions
}

/// Règles de contenu des rappels, pures et déterministes : miroir exact de `ReminderPlanner.kt`.
/// Toute modification doit être portée des deux côtés.
enum ReminderPlanner {
  /// Nombre de jours, après une prière portant une émotion, où le rappel propose un verset de ce
  /// thème. Court à dessein : on accompagne, on ne ressasse pas.
  static let emotionFollowUpDays = 2
  /// Âge minimal d'une intention ouverte avant qu'on invite à y revenir.
  static let intentionMinimumAgeDays = 7
  /// Dimanche (`Calendar.component(.weekday)`), jour fixe pour que l'invitation reste hebdomadaire
  /// même si l'app replanifie tous les jours.
  static let intentionWeekday = 1

  /// `nil` : pas de rappel ce jour-là (l'utilisateur a déjà prié — on ne relance pas).
  /// Priorité : silence > verset d'émotion > intentions du dimanche > question.
  static func kind(
    for fireDate: Date, context: ReminderContext, calendar: Calendar = .current
  ) -> ReminderKind? {
    if let lastPrayer = context.lastPrayerDate, calendar.isDate(lastPrayer, inSameDayAs: fireDate) {
      return nil
    }

    if let emotion = context.lastEmotion, let emotionDate = context.lastEmotionDate {
      let elapsed = days(from: emotionDate, to: fireDate, calendar: calendar)
      if (1...emotionFollowUpDays).contains(elapsed),
        let index = verseIndex(for: emotion, on: fireDate, calendar: calendar)
      {
        return .verse(corpusIndex: index)
      }
    }

    if calendar.component(.weekday, from: fireDate) == intentionWeekday,
      let oldest = context.oldestOpenIntentionDate,
      days(from: oldest, to: fireDate, calendar: calendar) >= intentionMinimumAgeDays
    {
      return .intentions
    }

    return .question
  }

  // Choix par jour de l'année et non via les decks mélangés de `VerseService` : planifier ne doit
  // pas consommer la pioche que l'utilisateur voit dans l'app.
  static func verseIndex(for emotion: Emotion, on date: Date, calendar: Calendar = .current)
    -> Int?
  {
    let corpus = VerseCorpus.all
    let pool = corpus.indices.filter { corpus[$0].emotionTags.contains(emotion.rawValue) }
    guard !pool.isEmpty else { return nil }
    let dayIndex = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
    return pool[dayIndex % pool.count]
  }

  private static func days(from start: Date, to end: Date, calendar: Calendar) -> Int {
    let from = calendar.startOfDay(for: start)
    let to = calendar.startOfDay(for: end)
    return calendar.dateComponents([.day], from: from, to: to).day ?? 0
  }
}
