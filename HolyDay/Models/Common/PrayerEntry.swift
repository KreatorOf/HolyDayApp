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

  // Titre d'affichage distinct de `stepTitle` (qui reste la catégorie structurelle : « Prière libre »
  // ou l'étape ACTS). Pour les prières libres : repli sur la 1re ligne à l'enregistrement, puis titre
  // suggéré par le modèle on-device, puis éventuellement titre saisi par l'utilisateur. `nil` pour les
  // entrées existantes / guidées → `displayTitle` retombe sur `stepTitle` (aucune migration lourde).
  var customTitle: String?

  // Origine du `customTitle`, persistée en rawValue (migration SwiftData légère). Voir `titleSource`.
  var titleSourceRaw: String = TitleSource.fallback.rawValue

  enum TitleSource: String {
    case fallback  // repli automatique (1re ligne) — aucun appel modèle abouti
    case ai  // suggéré par le modèle on-device
    case user  // saisi/modifié par l'utilisateur — ne jamais réécraser
  }

  var titleSource: TitleSource {
    get { TitleSource(rawValue: titleSourceRaw) ?? .fallback }
    set { titleSourceRaw = newValue.rawValue }
  }

  /// Titre montré dans le journal : `customTitle` quand présent, sinon la catégorie `stepTitle`.
  var displayTitle: String { customTitle ?? stepTitle }

  /// Distingue une prière libre d'une étape de prière guidée (ACTS). Les prières libres sont seules à
  /// utiliser cette icône — voir `saveFreePrayer`. Sert à regrouper le journal par type.
  var isFreePrayer: Bool { stepIcon == "square.and.pencil" }

  /// Repli de titre quand le modèle est indisponible : première ligne non vide, tronquée.
  static func fallbackTitle(from text: String) -> String {
    let firstLine =
      text
      .split(whereSeparator: \.isNewline)
      .first
      .map { $0.trimmingCharacters(in: .whitespaces) } ?? ""
    let limit = 40
    guard firstLine.count > limit else { return firstLine }
    let cut = firstLine.prefix(limit).trimmingCharacters(in: .whitespaces)
    return "\(cut)…"
  }

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
