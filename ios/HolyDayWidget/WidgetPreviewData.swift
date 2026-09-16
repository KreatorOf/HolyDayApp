//
//  WidgetPreviewData.swift
//  HolyDayWidget
//

import Foundation

/// Données d'exemple pour les placeholders et les previews Xcode.
enum WidgetPreviewData {
  /// Verset d'émotion d'exemple dans la langue de l'interface (Psaume 23:1, thème paix).
  static func sampleVerse() -> WidgetVerse {
    let french = AppLanguage.isFrench
    let entry = VerseCorpus.all[2]
    return WidgetVerse(
      text: entry.text(french: french),
      reference: "\(entry.reference(french: french)) (\(french ? "LSG" : "BSB"))",
      emotionTag: "peace",
      source: .emotion)
  }

  static func dailyVerse() -> WidgetVerse {
    WidgetVerseResolver.resolve(
      on: .now, lastVerse: nil, lastVerseDate: nil, skips: 0, french: AppLanguage.isFrench)
  }
}
