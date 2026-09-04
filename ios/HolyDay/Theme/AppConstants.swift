//
//  AppConstants.swift
//  Holyday
//
//  Created by Matthias Cadet on 13/05/2026.
//

import Foundation

// TODO: Replace these URLs with your actual policy pages before App Store submission
enum AppLinks {
  static let privacyPolicy = makeURL("https://holyday-landing.vercel.app/privacy.html")
  static let termsOfService = makeURL("https://holyday-landing.vercel.app/terms.html")
  static let appStore = makeURL("https://apps.apple.com/us/app/holyday/id6774578624")
  /// Ouvre directement le composeur d'avis de l'App Store. À préférer à `requestReview` dès que
  /// c'est l'utilisateur qui demande à noter : la fenêtre système est bridée par Apple (3 fois par
  /// an au plus, et pas du tout si l'utilisateur a désactivé les avis in-app), donc un bouton qui
  /// s'appuie dessus peut ne produire aucune réaction visible.
  static let writeReview = makeURL(
    "https://apps.apple.com/app/id6774578624?action=write-review")

  private static func makeURL(_ string: String) -> URL {
    guard let url = URL(string: string) else {
      preconditionFailure("URL statique invalide : \(string)")
    }
    return url
  }
}

enum RevenueCatConfig {
  // Clé SDK *publique* RevenueCat (préfixe `appl_`) : conçue pour être embarquée dans le binaire
  // et extractible de toute app publiée — ce n'est pas un secret. La garder en clair ici est
  // conforme aux recommandations RevenueCat.
  static let apiKey = "appl_UlQUPWYbfJUrWXoDkEkNxuQHZkY"
  static let entitlementId = "ia_lifetime"
  static let aiEntitlementId = "ia_feature"
  static let offeringId = "tips"
  static let aiOfferingId = "default"
}
