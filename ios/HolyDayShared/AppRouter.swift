//
//  AppRouter.swift
//  HolyDay
//
//  Created by Matthias Cadet on 16/09/2026.
//

import AppIntents
import Foundation
import Observation

/// Destinations atteignables depuis l'extérieur de l'app : widgets (`widgetURL`), commande du
/// Centre de contrôle, notifications.
nonisolated enum AppRoute: Equatable, Sendable {
  case pray
  case freePrayer
  case intentions
  case journal

  static let scheme = "holyday"

  // `holyday://verse` (ancien lien des widgets déjà posés) retombe sur l'onglet Prière.
  init(url: URL) {
    switch (url.host(), url.path()) {
    case ("pray", "/free"): self = .freePrayer
    case ("intentions", _): self = .intentions
    case ("journal", _): self = .journal
    default: self = .pray
    }
  }

  var url: URL {
    let path =
      switch self {
      case .pray: "pray"
      case .freePrayer: "pray/free"
      case .intentions: "intentions"
      case .journal: "journal"
      }
    return URL(string: "\(Self.scheme)://\(path)") ?? URL(filePath: "/")
  }
}

/// Route en attente, consommée par la vue qui sait l'afficher (`MainTabView` choisit l'onglet,
/// `ContentView` ouvre la feuille). Compilé aussi dans l'extension widget pour que l'intent de la
/// commande « Prier » y soit référençable, mais il ne s'exécute que dans l'app.
@MainActor
@Observable
final class AppRouter {
  static let shared = AppRouter()

  var pending: AppRoute?

  private init() {}

  func open(_ route: AppRoute) {
    pending = route
  }
}

/// Commande « Prier » (Centre de contrôle, écran verrouillé, bouton Action). Doit être membre de
/// l'app ET de l'extension : `openAppWhenRun` fait exécuter `perform` dans le process de l'app.
nonisolated struct OpenFreePrayerIntent: AppIntent {
  static let title: LocalizedStringResource = "intent.freePrayer.title"
  static let description = IntentDescription("intent.freePrayer.description")
  static let openAppWhenRun = true

  @MainActor
  func perform() async throws -> some IntentResult {
    AppRouter.shared.open(.freePrayer)
    return .result()
  }
}
