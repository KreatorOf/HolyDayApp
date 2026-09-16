//
//  PrayControl.swift
//  HolyDayWidget
//

import AppIntents
import SwiftUI
import WidgetKit

/// Commande « Prier » : Centre de contrôle, écran verrouillé, bouton Action. Ouvre directement la
/// prière libre — un geste, sans passer par l'accueil.
struct PrayControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: "com.matthiascadet.HolyDay.PrayControl") {
      ControlWidgetButton(action: OpenFreePrayerIntent()) {
        Label("control.pray.label", systemImage: "hands.sparkles")
      }
    }
    .displayName("control.pray.label")
    .description("control.pray.description")
  }
}
