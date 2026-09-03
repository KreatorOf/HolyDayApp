//
//  WhatsNewService.swift
//  HolyDay
//

import Foundation
import Observation

/// Décide si l'écran de nouveautés doit s'afficher après une mise à jour, et pour quelles versions.
///
/// Deux invariants tiennent tout le comportement :
///
/// 1. **Une installation neuve ne voit jamais de nouveautés.** L'onboarding appelle `markSeen()` à
///    sa dernière étape : la version courante est donc déjà enregistrée quand l'utilisateur entre
///    dans l'app. Sans ça, un nouvel utilisateur se verrait annoncer comme « nouveau » ce qu'il
///    découvre de toute façon pour la première fois.
/// 2. **Aucune version marquée signifie « mise à jour depuis un binaire antérieur à cette
///    fonctionnalité »**, et non « installation neuve » — d'où l'affichage dans ce cas. Le point 1
///    garantit que les deux situations ne se confondent pas.
///
/// Les versions sautées sont rattrapées : quelqu'un qui passe de 1.0.1 à 1.2 voit les notes de 1.1
/// et de 1.2 dans le même écran.
///
/// Entrées injectables (stockage, version courante, catalogue) pour rendre la décision testable
/// sans toucher au bundle ni aux préférences réelles.
@MainActor
@Observable
final class WhatsNewService {
  static let shared = WhatsNewService()

  /// Non-nil quand un écran de nouveautés est en attente d'affichage.
  private(set) var pending: Presentation?

  /// Regroupe les notes à présenter en une valeur `Identifiable`, pour `sheet(item:)` — qui, au
  /// contraire de `sheet(isPresented:)`, conserve son contenu pendant l'animation de fermeture.
  struct Presentation: Identifiable {
    let releases: [ReleaseNote]
    var id: String { releases.map(\.version).joined(separator: "+") }
  }

  private let defaults: UserDefaults
  private let currentVersion: String
  private let catalog: [ReleaseNote]

  private let lastSeenKey = "holyday.whatsNew.lastSeenVersion"

  init(
    defaults: UserDefaults = .standard,
    currentVersion: String = Bundle.main.appVersion,
    catalog: [ReleaseNote] = ReleaseNotesCatalog.all
  ) {
    self.defaults = defaults
    self.currentVersion = currentVersion
    self.catalog = catalog
  }

  // MARK: - Décision

  /// À appeler une fois le splash retiré, pour ne pas présenter une feuille sous l'écran de
  /// lancement. Sans effet en mode capture d'écran : les runs `fastlane snapshot` doivent rester
  /// déterministes.
  func evaluate() {
    guard !ScreenshotMode.isActive else { return }

    let lastSeen = defaults.string(forKey: lastSeenKey)
    let releases = releasesNewer(than: lastSeen)

    guard !releases.isEmpty else {
      // Rien à annoncer pour cette version : on avance quand même le repère, sinon la note d'une
      // version ultérieure ressortirait accompagnée de celles, périmées, des versions traversées.
      markSeen()
      return
    }

    pending = Presentation(releases: releases)
  }

  /// Notes strictement postérieures à `lastSeen`, plus récente en premier.
  /// `lastSeen == nil` (mise à jour depuis un binaire antérieur à cette fonctionnalité) ne renvoie
  /// que la note de la version installée : annoncer tout l'historique n'aurait aucun sens.
  private func releasesNewer(than lastSeen: String?) -> [ReleaseNote] {
    guard let lastSeen else {
      return catalog.filter { $0.version == currentVersion }
    }
    return
      catalog
      .filter { note in
        Self.isVersion(note.version, newerThan: lastSeen)
          && !Self.isVersion(note.version, newerThan: currentVersion)
      }
      .sorted { Self.isVersion($0.version, newerThan: $1.version) }
  }

  /// Comparaison numérique composant par composant : « 1.10 » est postérieure à « 1.9 », ce qu'une
  /// comparaison lexicographique donnerait à l'envers.
  static func isVersion(_ lhs: String, newerThan rhs: String) -> Bool {
    lhs.compare(rhs, options: .numeric) == .orderedDescending
  }

  // MARK: - Mutations

  /// Enregistre la version installée comme vue et referme l'écran.
  /// Appelé à la fermeture de la feuille **et** à la fin de l'onboarding (cf. invariant 1).
  func markSeen() {
    defaults.set(currentVersion, forKey: lastSeenKey)
    pending = nil
  }

  /// Efface le repère : au prochain `evaluate()`, les nouveautés de la version installée
  /// ressortent. Réservé au menu développeur — délibérément **pas** appelé par l'effacement
  /// complet des données, qui porte sur les données de l'utilisateur, pas sur le binaire installé :
  /// réafficher les nouveautés d'une version déjà utilisée depuis des semaines n'aurait aucun sens.
  func reset() {
    defaults.removeObject(forKey: lastSeenKey)
    pending = nil
  }
}

extension Bundle {
  /// `CFBundleShortVersionString` (« 1.0.1 »), repli sur « 0 » — une version illisible ne doit pas
  /// faire croire à une mise à jour à chaque lancement.
  var appVersion: String {
    object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
  }
}
