//
//  DebugActions.swift
//  HolyDay
//
//  Menu développeur — compilé uniquement en DEBUG, exclu du binaire de production.
//  Libellés volontairement en dur (hors prod) : exception assumée à la règle de localisation.
//

#if DEBUG

  import SwiftData
  import SwiftUI

  @MainActor
  enum DebugActions {

    // MARK: - Resets

    static func resetPrayerRecord() {
      PrayerRecordService.shared.reset()
    }

    static func clearPrayers(in context: ModelContext) {
      try? context.delete(model: PrayerEntry.self)
    }

    static func clearIntentions(in context: ModelContext) {
      try? context.delete(model: PrayerIntention.self)
    }

    static func clearSavedVerses(in context: ModelContext) {
      try? context.delete(model: SavedVerse.self)
    }

    /// Rejoue l'écran de nouveautés au prochain lancement, sans avoir à réinstaller une version
    /// antérieure pour tester la détection de mise à jour.
    static func resetWhatsNew() {
      WhatsNewService.shared.reset()
    }

    // MARK: - Seed

    static func seedDemoPrayers(in context: ModelContext) {
      SeedService.seedDemoData(in: context)
    }
  }

#endif
