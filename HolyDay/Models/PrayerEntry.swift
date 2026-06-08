//
//  PrayerEntry.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import SwiftData
import SwiftUI

@Model
final class PrayerEntry {
  var stepTitle: String
  var stepIcon: String
  var stepColorName: String
  var text: String
  var date: Date
  var isAnswered: Bool = false
  var answeredAt: Date?
  var duration: TimeInterval = 0

  // Émotion déclarée avant la prière. Optionnel : migration SwiftData légère pour les entrées
  // existantes. La rawValue de `Emotion` est persistée ; voir la computed `emotion` ci-dessous.
  var emotionRaw: String?

  var emotion: Emotion? {
    get { emotionRaw.flatMap(Emotion.init(rawValue:)) }
    set { emotionRaw = newValue?.rawValue }
  }

  // Référence du verset présenté pour l'émotion (ex. « Ésaïe 41:10 »). Optionnel.
  var verseReference: String?

  /// Couleur d'accent dans le journal : la pastel de l'émotion déclarée si présente (prière libre),
  /// sinon la couleur ACTS de l'étape (prière guidée). Dérivée à l'affichage — pas de migration : les
  /// entrées existantes reprennent automatiquement la teinte correspondant à leur émotion.
  /// `@MainActor` : s'appuie sur des couleurs isolées au main actor, et n'est lue que depuis les vues.
  @MainActor var accentColor: Color {
    emotion?.pastel ?? AppTheme.color(for: stepColorName)
  }

  init(
    stepTitle: String,
    stepIcon: String,
    stepColorName: String,
    text: String,
    date: Date = .now,
    duration: TimeInterval = 0,
    emotion: Emotion? = nil,
    verseReference: String? = nil
  ) {
    self.stepTitle = stepTitle
    self.stepIcon = stepIcon
    self.stepColorName = stepColorName
    self.text = text
    self.date = date
    self.duration = duration
    self.emotionRaw = emotion?.rawValue
    self.verseReference = verseReference
  }
}
