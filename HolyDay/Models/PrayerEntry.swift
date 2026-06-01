//
//  PrayerEntry.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import Foundation
import SwiftData

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
