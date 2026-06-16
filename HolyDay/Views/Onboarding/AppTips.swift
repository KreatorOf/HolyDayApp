//
//  AppTips.swift
//  HolyDay
//
//  Parcours de découverte (TipKit) qui remplace l'ancien tour guidé : présenté une seule fois,
//  étape par étape. Chaque tip rend le suivant éligible quand il est fermé (chaînage par
//  événements), pour un guidage linéaire et non bloquant. Ton sans culpabilisation : des invitations.
//

import SwiftUI
import TipKit

/// Événements de progression : chaque étape fermée déclenche l'éligibilité de la suivante.
enum TourEvents {
  nonisolated static let emotionsDone = Tips.Event(id: "tour.emotionsDone")
  nonisolated static let prayDone = Tips.Event(id: "tour.prayDone")
  nonisolated static let intentionsDone = Tips.Event(id: "tour.intentionsDone")
}

/// Étape 1 — le ressenti. Première de la séquence : aucune règle.
struct EmotionsTip: Tip {
  var title: Text { Text("tour.emotions.title") }
  var message: Text? { Text("tour.emotions.message") }
  var image: Image? { Image(systemName: "heart.fill") }
  var options: [Option] { [Tips.MaxDisplayCount(1)] }
}

/// Étape 2 — prier. Éligible une fois l'étape Émotions fermée.
struct PrayTip: Tip {
  var title: Text { Text("tour.pray.title") }
  var message: Text? { Text("tour.pray.message") }
  var image: Image? { Image(systemName: "hands.sparkles.fill") }
  var rules: [Rule] {
    #Rule(TourEvents.emotionsDone) { $0.donations.count >= 1 }
  }
  var options: [Option] { [Tips.MaxDisplayCount(1)] }
}

/// Étape 3 — les sujets de prière. Éligible une fois l'étape Prier fermée.
struct IntentionsTip: Tip {
  var title: Text { Text("tour.intentions.title") }
  var message: Text? { Text("tour.intentions.message") }
  var image: Image? { Image(systemName: "list.bullet") }
  var rules: [Rule] {
    #Rule(TourEvents.prayDone) { $0.donations.count >= 1 }
  }
  var options: [Option] { [Tips.MaxDisplayCount(1)] }
}

/// Étape 4 — le journal. Éligible une fois l'étape Intentions fermée ; s'affiche à l'ouverture
/// de l'onglet Journal.
struct JournalTip: Tip {
  var title: Text { Text("tour.journal.title") }
  var message: Text? { Text("tour.journal.message") }
  var image: Image? { Image(systemName: "book.pages.fill") }
  var rules: [Rule] {
    #Rule(TourEvents.intentionsDone) { $0.donations.count >= 1 }
  }
  var options: [Option] { [Tips.MaxDisplayCount(1)] }
}
