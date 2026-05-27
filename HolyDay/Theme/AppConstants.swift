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
  // Remplace l'ID par celui attribué dans App Store Connect après soumission
  static let appStore = makeURL("https://apps.apple.com/app/id000000000")

  private static func makeURL(_ string: String) -> URL {
    guard let url = URL(string: string) else {
      preconditionFailure("URL statique invalide : \(string)")
    }
    return url
  }
}

// IAP product IDs — create these in App Store Connect as Non-Consumable products
// Then map them to RevenueCat packages in the RevenueCat dashboard
enum TipProducts {
  static let small = "com.holyday.app.tip.small"  // Ami — 4,99 €
  static let medium = "com.holyday.app.tip.medium"  // Généreux — 9,99 €
  static let large = "com.holyday.app.tip.large"  // Bienfaiteur — 19,99 €

  static let all: Set<String> = [small, medium, large]
}

// RevenueCat configuration
// 1. Create an account at https://app.revenuecat.com
// 2. Create a new project and add your iOS app
// 3. Copy your public API key (starts with "appl_") and replace the placeholder below
// 4. In the RevenueCat dashboard: create an Entitlement "supporter", an Offering "default",
//    and 3 Packages linked to your App Store Connect product IDs above
enum RevenueCatConfig {
  static let apiKey = "REVENUECAT_PUBLIC_API_KEY_PLACEHOLDER"
  static let entitlementId = "supporter"
}
