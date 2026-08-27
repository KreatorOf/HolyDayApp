//
//  WidgetSyncService.swift
//  HolyDay
//
//  Created by Matthias Cadet on 10/06/2026.
//

import Foundation
import WidgetKit

/// Rafraîchit les timelines des widgets pour qu'ils reflètent les dernières données partagées
/// (cf. `SharedStore` : dernier verset, « a prié aujourd'hui »). À appeler après chaque prière
/// enregistrée et au retour de l'app au premier plan.
enum WidgetSyncService {
  @MainActor
  static func sync() {
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
