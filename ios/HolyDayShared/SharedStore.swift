//
//  SharedStore.swift
//  HolyDay
//
//  Created by Matthias Cadet on 10/06/2026.
//

import Foundation

/// Pont de données app → widgets via le conteneur App Group.
/// Le store SwiftData est chiffré (`FileProtectionType.complete`) et donc illisible appareil
/// verrouillé — moment où WidgetKit peut justement rafraîchir une timeline : les widgets lisent
/// uniquement ce snapshot minimal, écrit côté app.
/// Dernier verset reçu via le ruban d'émotions, tel qu'affiché à l'utilisateur. Le texte est
/// stocké déjà localisé : le deck par émotion est mélangé, le widget ne peut pas le recalculer.
nonisolated struct SharedVerse: Sendable {
  let text: String
  let reference: String
  let emotionTag: String
}

nonisolated enum SharedStore {
  static let appGroupID = "group.com.matthiascadet.HolyDay"

  private static let lastPrayerDateKey = "holyday.shared.lastPrayerDate"
  private static let lastVerseTextKey = "holyday.shared.lastVerse.text"
  private static let lastVerseReferenceKey = "holyday.shared.lastVerse.reference"
  private static let lastVerseEmotionKey = "holyday.shared.lastVerse.emotion"
  private static let lastVerseDateKey = "holyday.shared.lastVerse.date"
  private static let verseSkipCountKey = "holyday.shared.verseSkip.count"
  private static let verseSkipDateKey = "holyday.shared.verseSkip.date"

  private static var defaults: UserDefaults? {
    UserDefaults(suiteName: appGroupID)
  }

  // MARK: - Écriture (app)

  static func setLastPrayerDate(_ date: Date?) {
    if let date {
      defaults?.set(date, forKey: lastPrayerDateKey)
    } else {
      defaults?.removeObject(forKey: lastPrayerDateKey)
    }
  }

  static func setLastVerse(text: String, reference: String, emotionTag: String) {
    defaults?.set(text, forKey: lastVerseTextKey)
    defaults?.set(reference, forKey: lastVerseReferenceKey)
    defaults?.set(emotionTag, forKey: lastVerseEmotionKey)
    defaults?.set(Date(), forKey: lastVerseDateKey)
    // Un nouveau ressenti remplace ce que le bouton « Un autre verset » avait fait défiler.
    resetVerseSkips()
  }

  // MARK: - Écriture (widget)

  /// Bouton « Un autre verset » : le compteur ne vaut que pour le jour où il a été incrémenté.
  static func incrementVerseSkip(now: Date = Date()) {
    let next = verseSkips(on: now) + 1
    defaults?.set(next, forKey: verseSkipCountKey)
    defaults?.set(now, forKey: verseSkipDateKey)
  }

  private static func resetVerseSkips() {
    defaults?.removeObject(forKey: verseSkipCountKey)
    defaults?.removeObject(forKey: verseSkipDateKey)
  }

  // MARK: - Reprise de données

  /// Répare les snapshots écrits avant la 1.0.1 : le corpus anglais est la Berean Standard Bible,
  /// mais la référence était rendue « (KJV) » et stockée ici telle qu'affichée. Sans cette reprise,
  /// le widget conserverait la mauvaise attribution jusqu'à la prochaine sélection d'émotion.
  static func repairLegacyTranslationSigil() {
    let legacy = "(KJV)"
    guard let reference = defaults?.string(forKey: lastVerseReferenceKey),
      reference.hasSuffix(legacy)
    else { return }
    let repaired = reference.dropLast(legacy.count) + "(BSB)"
    defaults?.set(String(repaired), forKey: lastVerseReferenceKey)
  }

  // MARK: - Lecture (widgets)

  static var lastPrayerDate: Date? {
    defaults?.object(forKey: lastPrayerDateKey) as? Date
  }

  static func hasPrayed(on date: Date = Date()) -> Bool {
    guard let last = lastPrayerDate else { return false }
    return Calendar.current.isDate(last, inSameDayAs: date)
  }

  static var lastVerse: SharedVerse? {
    guard let text = defaults?.string(forKey: lastVerseTextKey), !text.isEmpty,
      let reference = defaults?.string(forKey: lastVerseReferenceKey)
    else { return nil }
    return SharedVerse(
      text: text,
      reference: reference,
      emotionTag: defaults?.string(forKey: lastVerseEmotionKey) ?? "")
  }

  /// `nil` pour les snapshots écrits avant la date : traités comme d'un jour passé.
  static var lastVerseDate: Date? {
    defaults?.object(forKey: lastVerseDateKey) as? Date
  }

  static func verseSkips(on date: Date = Date()) -> Int {
    guard let skipDate = defaults?.object(forKey: verseSkipDateKey) as? Date,
      Calendar.current.isDate(skipDate, inSameDayAs: date)
    else { return 0 }
    return defaults?.integer(forKey: verseSkipCountKey) ?? 0
  }

  /// Verset à afficher dans les widgets aujourd'hui (cf. `WidgetVerseResolver`).
  static func widgetVerse(on date: Date = Date()) -> WidgetVerse {
    WidgetVerseResolver.resolve(
      on: date,
      lastVerse: lastVerse,
      lastVerseDate: lastVerseDate,
      skips: verseSkips(on: date),
      french: AppLanguage.isFrench)
  }
}
