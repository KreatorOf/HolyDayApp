//
//  SupportPromptService.swift
//  HolyDay
//
//  Created by Matthias Cadet on 03/06/2026.
//

import Foundation
import Observation

/// Décide quand proposer (avec retenue) de soutenir le développeur, à un moment calme de fin de
/// prière. Jamais pour un donateur, jamais après un opt-out, avec un plafond et un délai croissant
/// entre deux sollicitations — pour rester utile sans jamais devenir un « nag ».
///
/// Les entrées externes (jours priés, statut donateur, horloge) et le stockage sont injectables
/// pour rendre la décision testable en isolation.
@MainActor
@Observable
final class SupportPromptService {
  static let shared = SupportPromptService()

  // Jours distincts priés avant la toute première sollicitation.
  private let minPrayedDays = 5
  // Nombre maximal de sollicitations sur la durée de vie de l'app.
  private let maxPrompts = 3
  // Délai (en jours) requis avant la sollicitation suivante, selon le nombre déjà affiché.
  private let cooldownDays = [0, 30, 90]

  private let timesShownKey = "holyday.support.timesShown"
  private let lastShownKey = "holyday.support.lastShown"
  private let dismissedForeverKey = "holyday.support.dismissedForever"

  private let defaults: UserDefaults
  private let prayedDaysProvider: () -> Int
  private let hasTippedProvider: () -> Bool
  private let now: () -> Date

  init(
    defaults: UserDefaults = .standard,
    prayedDaysProvider: @escaping () -> Int = { PrayerRecordService.shared.totalPrayedDays },
    hasTippedProvider: @escaping () -> Bool = { TipService.shared.hasTipped },
    now: @escaping () -> Date = { Date() }
  ) {
    self.defaults = defaults
    self.prayedDaysProvider = prayedDaysProvider
    self.hasTippedProvider = hasTippedProvider
    self.now = now
  }

  // MARK: - State

  private var timesShown: Int {
    get { defaults.integer(forKey: timesShownKey) }
    set { defaults.set(newValue, forKey: timesShownKey) }
  }

  private var lastShown: Date? {
    get { defaults.object(forKey: lastShownKey) as? Date }
    set { defaults.set(newValue, forKey: lastShownKey) }
  }

  private var dismissedForever: Bool {
    get { defaults.bool(forKey: dismissedForeverKey) }
    set { defaults.set(newValue, forKey: dismissedForeverKey) }
  }

  // MARK: - Decision

  var shouldPrompt: Bool {
    guard !hasTippedProvider() else { return false }
    guard !dismissedForever else { return false }
    guard timesShown < maxPrompts else { return false }
    guard prayedDaysProvider() >= minPrayedDays else { return false }

    guard let last = lastShown else { return true }
    let required = cooldownDays[min(timesShown, cooldownDays.count - 1)]
    let daysSince = Calendar.current.dateComponents([.day], from: last, to: now()).day ?? 0
    return daysSince >= required
  }

  // MARK: - Mutations

  /// À appeler au moment où la page est effectivement présentée : démarre le délai de repos.
  func markShown() {
    timesShown += 1
    lastShown = now()
  }

  /// L'utilisateur choisit de ne plus jamais être sollicité.
  func dontAskAgain() {
    dismissedForever = true
  }

  /// Remet l'état à neuf (compteur, délai, opt-out). Appelé lors d'un effacement complet des
  /// données pour qu'un nouveau départ réautorise la sollicitation.
  func reset() {
    defaults.removeObject(forKey: timesShownKey)
    defaults.removeObject(forKey: lastShownKey)
    defaults.removeObject(forKey: dismissedForeverKey)
  }
}
