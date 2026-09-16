//
//  WidgetVerseResolver.swift
//  HolyDay
//
//  Created by Matthias Cadet on 16/09/2026.
//

import Foundation

nonisolated struct WidgetVerse: Equatable, Sendable {
  enum Source: Equatable, Sendable {
    /// Verset reçu aujourd'hui via le ruban d'émotions (ou un voisin du même thème).
    case emotion
    /// Repli quand aucun ressenti n'a été partagé aujourd'hui.
    case daily
  }

  let text: String
  let reference: String
  /// `rawValue` d'émotion portant la teinte ; vide pour le verset du jour (teinte de marque).
  let emotionTag: String
  let source: Source
}

/// Choisit le verset des widgets. Le widget ne doit jamais rester vide ni figé : le verset d'émotion
/// ne vaut que pour le jour où il a été reçu, ensuite on retombe sur un verset du jour tiré du
/// corpus. `skips` avance dans le même thème (bouton « Un autre verset »).
nonisolated enum WidgetVerseResolver {
  static func resolve(
    on date: Date,
    lastVerse: SharedVerse?,
    lastVerseDate: Date?,
    skips: Int,
    french: Bool,
    calendar: Calendar = .current
  ) -> WidgetVerse {
    let corpus = VerseCorpus.all
    let dayIndex = calendar.ordinality(of: .day, in: .year, for: date) ?? 1

    if let lastVerse, let lastVerseDate, calendar.isDate(lastVerseDate, inSameDayAs: date) {
      guard skips > 0 else {
        return WidgetVerse(
          text: lastVerse.text, reference: lastVerse.reference,
          emotionTag: lastVerse.emotionTag, source: .emotion)
      }
      // Le verset reçu est exclu de la rotation : le premier tap doit toujours changer le texte.
      let pool = corpus.indices.filter {
        corpus[$0].emotionTags.contains(lastVerse.emotionTag)
          && corpus[$0].text(french: french) != lastVerse.text
      }
      if !pool.isEmpty {
        let index = pool[(dayIndex + skips - 1) % pool.count]
        return make(corpus[index], tag: lastVerse.emotionTag, source: .emotion, french: french)
      }
    }

    let index = (dayIndex + skips) % corpus.count
    return make(corpus[index], tag: "", source: .daily, french: french)
  }

  // Même sigle que `VerseService` : il doit suivre les traductions réellement embarquées.
  private static func make(
    _ entry: CorpusVerse, tag: String, source: WidgetVerse.Source, french: Bool
  )
    -> WidgetVerse
  {
    let reference = "\(entry.reference(french: french)) (\(french ? "LSG" : "BSB"))"
    return WidgetVerse(
      text: entry.text(french: french), reference: reference, emotionTag: tag, source: source)
  }
}
