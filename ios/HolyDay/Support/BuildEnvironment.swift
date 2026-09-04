//
//  BuildEnvironment.swift
//  HolyDay
//

import Observation
import StoreKit

/// Distingue une installation de test d'une installation App Store.
///
/// La section Développeur des réglages est compilée sous `#if DEBUG` : elle est donc absente de
/// tout binaire Release, TestFlight compris. Les bêta-testeurs n'avaient par conséquent aucun moyen
/// de rejouer un écran qui ne s'affiche qu'une fois par version — ce qui rendait cet écran
/// intestable au-delà du tout premier lancement.
///
/// Sert à exposer le strict nécessaire aux testeurs sans livrer d'outils de développement aux
/// utilisateurs finaux.
@MainActor
@Observable
final class BuildEnvironment {
  static let shared = BuildEnvironment()

  /// Faux tant que la résolution n'a pas abouti : en cas de doute on n'affiche rien plutôt que
  /// d'exposer par erreur un outil de test à un utilisateur App Store.
  private(set) var isTestFlight = false

  private init() {}

  /// À appeler une fois au démarrage.
  ///
  /// `AppTransaction.shared` remplace `Bundle.main.appStoreReceiptURL`, déprécié depuis iOS 18.
  /// Il est asynchrone (la transaction est signée par l'App Store), d'où la résolution en amont
  /// plutôt qu'une lecture synchrone au moment de composer la vue.
  ///
  /// En développement, l'appel échoue faute de transaction signée — sans conséquence : ces builds
  /// disposent déjà du menu Développeur complet.
  func resolve() async {
    guard let result = try? await AppTransaction.shared else { return }
    guard case .verified(let transaction) = result else { return }
    isTestFlight = transaction.environment == .sandbox
  }
}
