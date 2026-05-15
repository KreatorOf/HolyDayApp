//
//  AppConstants.swift
//  Kairos
//
//  Created by Matthias Cadet on 13/05/2026.
//

import Foundation

// TODO: Replace these URLs with your actual policy pages before App Store submission
enum AppLinks {
    static let privacyPolicy = URL(string: "https://example.com/holyday/privacy")!
    static let termsOfService = URL(string: "https://example.com/holyday/terms")!
}

// IAP product IDs — create these in App Store Connect as Consumable products
enum TipProducts {
    static let small  = "com.holyday.app.tip.small"
    static let medium = "com.holyday.app.tip.medium"
    static let large  = "com.holyday.app.tip.large"

    static let all: Set<String> = [small, medium, large]
}
