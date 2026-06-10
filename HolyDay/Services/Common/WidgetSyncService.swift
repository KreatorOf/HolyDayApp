//
//  WidgetSyncService.swift
//  HolyDay
//
//  Created by Matthias Cadet on 10/06/2026.
//

import Foundation
import SwiftData
import WidgetKit

/// Recopie vers le conteneur App Group les données dont les widgets ont besoin (cf. `SharedStore`),
/// puis rafraîchit leurs timelines. À appeler après chaque prière enregistrée et au retour de
/// l'app au premier plan (rattrape les entrées modifiées dans le journal).
enum WidgetSyncService {
  @MainActor
  static func sync(context: ModelContext) {
    let entries = (try? context.fetch(FetchDescriptor<PrayerEntry>())) ?? []
    var counts: [String: Int] = [:]
    for entry in entries {
      counts[SharedStore.dayKey(for: entry.date), default: 0] += 1
    }
    SharedStore.setDailyCounts(counts)
    WidgetCenter.shared.reloadAllTimelines()
  }

  /// Publie le verset servi avec l'émotion déclarée — affiché par « Mon verset » et par le volet
  /// verset de « Prier maintenant ».
  @MainActor
  static func updateLastVerse(_ verse: Verse, emotion: Emotion) {
    SharedStore.setLastVerse(
      text: verse.text, reference: verse.reference, emotionTag: emotion.rawValue)
    WidgetCenter.shared.reloadAllTimelines()
  }
}
