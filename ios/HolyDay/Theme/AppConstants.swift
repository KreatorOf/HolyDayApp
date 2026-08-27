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
