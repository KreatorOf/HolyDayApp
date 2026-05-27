//
//  TipService.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import Foundation
import Observation
import RevenueCat

@Observable
final class TipService {
  static let shared = TipService()

  private(set) var packages: [Package] = []
  private(set) var isLoading = false
  var purchaseState: PurchaseState = .idle

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

  var supporterTier: SupporterTier? {
    guard hasTipped else { return nil }
    return SupporterTier(rawValue: highestTipIndexStored - 1)
  }

  enum PurchaseState: Equatable {
    case idle, purchasing, success, failed
  }

  private init() {
    Task { await refreshCustomerInfo() }
  }

  func loadProducts() async {
    guard packages.isEmpty else { return }
    isLoading = true
    defer { isLoading = false }
    do {
      let offerings = try await Purchases.shared.offerings()
      packages =
        offerings.current?.availablePackages
        .sorted { $0.storeProduct.price < $1.storeProduct.price } ?? []
    } catch {
      // Offerings fetch failed — packages stay empty, UI shows unavailable state
    }
  }

  func purchase(_ package: Package) async {
    purchaseState = .purchasing
    do {
      let (_, customerInfo, userCancelled) = try await Purchases.shared.purchase(package: package)
      if userCancelled {
        purchaseState = .idle
        return
      }
      applyCustomerInfo(customerInfo, purchasedPackage: package)
    } catch {
      purchaseState = .failed
    }
  }

  func restorePurchases() async {
    purchaseState = .purchasing
    do {
      let customerInfo = try await Purchases.shared.restorePurchases()
      if customerInfo.entitlements[RevenueCatConfig.entitlementId]?.isActive == true {
        hasTipped = true
        purchaseState = .success
      } else {
        purchaseState = .idle
      }
    } catch {
      purchaseState = .failed
    }
  }

  func resetState() {
    purchaseState = .idle
  }

  private func applyCustomerInfo(_ info: CustomerInfo, purchasedPackage: Package? = nil) {
    guard info.entitlements[RevenueCatConfig.entitlementId]?.isActive == true else {
      purchaseState = .idle
      return
    }
    hasTipped = true
    if let pkg = purchasedPackage,
      let purchasedIndex = packages.firstIndex(where: { $0.identifier == pkg.identifier })
    {
      let stored = purchasedIndex + 1
      if stored > highestTipIndexStored {
        highestTipIndexStored = stored
      }
    }
    purchaseState = .success
  }

  private func refreshCustomerInfo() async {
    guard let info = try? await Purchases.shared.customerInfo() else { return }
    if info.entitlements[RevenueCatConfig.entitlementId]?.isActive == true {
      hasTipped = true
    }
  }

  #if DEBUG
    func debugUnlock(tier: SupporterTier = .bienfaiteur) {
      highestTipIndexStored = tier.rawValue + 1
      hasTipped = true
    }

    func debugPurchase(tier: SupporterTier) {
      debugUnlock(tier: tier)
      purchaseState = .success
    }

    func debugReset() {
      highestTipIndexStored = 0
      hasTipped = false
    }
  #endif
}
