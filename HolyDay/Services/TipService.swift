//
//  TipService.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import Foundation
import Observation
import RevenueCat
import UserNotifications

@Observable
final class TipService {
  static let shared = TipService()

  // Derived from RevenueCat CustomerInfo; falls back to cached UserDefaults value
  private(set) var hasTipped: Bool = UserDefaults.standard.bool(forKey: "holyday.hasTipped") {
    didSet { UserDefaults.standard.set(hasTipped, forKey: "holyday.hasTipped") }
  }

  // Stored as index+1 so 0 means "never purchased" (UserDefaults returns 0 for missing keys)
  private var highestTipIndexStored: Int = UserDefaults.standard.integer(
    forKey: "holyday.highestTipIndex")
  {
    didSet { UserDefaults.standard.set(highestTipIndexStored, forKey: "holyday.highestTipIndex") }
  }

  private(set) var hasAIFeature: Bool = UserDefaults.standard.bool(
    forKey: "holyday.hasAIFeature")
  {
    didSet { UserDefaults.standard.set(hasAIFeature, forKey: "holyday.hasAIFeature") }
  }

  private(set) var tipsOffering: Offering?
  private(set) var aiOffering: Offering?

  var supporterTier: SupporterTier? {
    guard hasTipped else { return nil }
    return SupporterTier(rawValue: highestTipIndexStored - 1)
  }

  private init() {
    Task { await refreshCustomerInfo() }
  }

  func refreshCustomerInfo() async {
    async let customerInfoTask: CustomerInfo? = try? Purchases.shared.customerInfo()
    async let offeringsTask: Offerings? = try? Purchases.shared.offerings()

    if let info = await customerInfoTask {
      applyCustomerInfo(info)
    }
    let offs = await offeringsTask
    tipsOffering = offs?.offering(identifier: RevenueCatConfig.offeringId)
    // Use explicit identifier — offs?.current returns whatever is marked "current" in the
    // RevenueCat dashboard, which may be "tips" and not the AI offering.
    aiOffering = offs?.offering(identifier: RevenueCatConfig.aiOfferingId)
  }

  func grantAIFeatureAccess() {
    hasAIFeature = true
  }

  func applyCustomerInfo(_ info: CustomerInfo) {
    let aiEntitlementActive =
      info.entitlements[RevenueCatConfig.aiEntitlementId]?.isActive == true
    if aiEntitlementActive {
      // Entitlement confirmed by RevenueCat — always grant
      hasAIFeature = true
    } else if info.nonSubscriptions.isEmpty {
      // No purchases at all — safe to revoke (user never bought anything)
      hasAIFeature = false
    }
    // If there are purchases but no entitlement yet, preserve existing state:
    // RevenueCat can lag on sandbox receipt validation and we don't want to
    // revoke access that was just purchased.

    let wasAlreadyTipped = hasTipped
    let entitlementActive = info.entitlements[RevenueCatConfig.entitlementId]?.isActive == true
    let hasTransactions = !info.nonSubscriptions.isEmpty

    guard entitlementActive || hasTransactions else { return }
    hasTipped = true
    updateHighestTier(from: info.nonSubscriptions)
    if !wasAlreadyTipped { scheduleThankYouNotification() }
  }

  private func updateHighestTier(from transactions: [NonSubscriptionTransaction]) {
    for tx in transactions {
      if let tier = SupporterTier.tier(for: tx.productIdentifier) {
        let stored = tier.rawValue + 1
        if stored > highestTipIndexStored { highestTipIndexStored = stored }
      }
    }
    if highestTipIndexStored == 0 { highestTipIndexStored = 1 }
  }

  private func scheduleThankYouNotification() {
    let content = UNMutableNotificationContent()
    content.title = String(localized: "notification.purchase.title")
    content.body = String(localized: "notification.purchase.body")
    content.sound = .default

    let request = UNNotificationRequest(
      identifier: "holyday.purchase-thanks",
      content: content,
      trigger: nil
    )
    UNUserNotificationCenter.current().add(request)
  }
}
