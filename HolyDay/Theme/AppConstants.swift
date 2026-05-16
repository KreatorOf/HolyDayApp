//
//  AppConstants.swift
//  Holyday
//
//  Created by Matthias Cadet on 13/05/2026.
//

import Foundation

// TODO: Replace these URLs with your actual policy pages before App Store submission
enum AppLinks {
    static let privacyPolicy = URL(string: "https://holyday-landing.vercel.app/privacy.html")!
    static let termsOfService = URL(string: "https://holyday-landing.vercel.app/terms.html")!
    // Remplace l'ID par celui attribué dans App Store Connect après soumission
    static let appStore = URL(string: "https://apps.apple.com/app/id000000000")!
}

// IAP product IDs — create these in App Store Connect as Consumable products
enum TipProducts {
    static let small  = "com.holyday.app.tip.small"
    static let medium = "com.holyday.app.tip.medium"
    static let large  = "com.holyday.app.tip.large"

    static let all: Set<String> = [small, medium, large]
}
