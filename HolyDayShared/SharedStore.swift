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
}
