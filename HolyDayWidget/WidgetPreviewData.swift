//
//  WidgetPreviewData.swift
//  HolyDayWidget
//

import Foundation

/// Données d'exemple pour la galerie de widgets (`context.isPreview`) et les previews Xcode :
/// un widget vide dans la galerie ne montre pas sa promesse.
enum WidgetPreviewData {
  /// Verset d'exemple dans la langue de l'appareil (Psaume 23:1, thème paix).
  static func sampleVerse() -> SharedVerse {
    let lang = Locale.current.language.languageCode?.identifier ?? "fr"
    let isFrench = !lang.hasPrefix("en")
    let entry = VerseCorpus.all[2]
    return SharedVerse(
      text: entry.text(french: isFrench),
      reference: entry.reference(french: isFrench),
      emotionTag: "peace")
  }

  /// Trois mois de pratique plausible : des trous réguliers, des jours à plusieurs prières.
  static func sampleCounts(relativeTo date: Date = .now) -> [String: Int] {
    var counts: [String: Int] = [:]
    for dayOffset in 0..<90 where dayOffset % 3 != 0 {
      guard let day = Calendar.current.date(byAdding: .day, value: -dayOffset, to: date) else {
        continue
      }
      counts[SharedStore.dayKey(for: day)] = dayOffset % 4 + 1
    }
    return counts
  }
}
