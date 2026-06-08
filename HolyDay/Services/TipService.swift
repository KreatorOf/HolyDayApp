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

  // Derived from RevenueCat CustomerInfo; falls back to cached UserDefaults value
  private(set) var hasTipped: Bool = UserDefaults.standard.bool(forKey: "holyday.hasTipped") {
    didSet { UserDefaults.standard.set(hasTipped, forKey: "holyday.hasTipped") }
  }

  // Stored as index+1 so 0 means "never purchased" (UserDefaults returns 0 for missing keys)
  private var tipTierIndexStored: Int = UserDefaults.standard.integer(
    forKey: "holyday.highestTipIndex")
  {
    didSet { UserDefaults.standard.set(tipTierIndexStored, forKey: "holyday.highestTipIndex") }
  }

  private(set) var tipsOffering: Offering?

  // Palier dérivé du rang de prix dans l'offering (le moins cher = palier le plus bas).
  // Robuste aux changements d'identifiants ou de prix des produits sur l'App Store, contrairement
  // à une correspondance basée sur le nom du produit (« tip_small/medium/large »).
  private var tierByProductId: [String: SupporterTier] = [:]

  var supporterTier: SupporterTier? {
    guard hasTipped else { return nil }
    return SupporterTier(rawValue: tipTierIndexStored - 1)
  }

  private init() {
    Task { await refreshCustomerInfo() }
  }

  func refreshCustomerInfo() async {
    async let customerInfoTask: CustomerInfo? = try? Purchases.shared.customerInfo()
    async let offeringsTask: Offerings? = try? Purchases.shared.offerings()

    // L'offering doit être appliqué AVANT les transactions : la correspondance produit → palier
    // est dérivée du rang de prix de l'offering, donc la carte doit déjà être construite.
    let offs = await offeringsTask
    tipsOffering = offs?.offering(identifier: RevenueCatConfig.offeringId)
    rebuildTierMap()

    if let info = await customerInfoTask {
      applyCustomerInfo(info)
    }
  }

  // Carte produit → palier construite par rang de prix croissant de l'offering.
  private func rebuildTierMap() {
    let ranked =
      (tipsOffering?.availablePackages ?? [])
      .sorted { $0.storeProduct.price < $1.storeProduct.price }
    var map: [String: SupporterTier] = [:]
    for (index, package) in ranked.enumerated() {
      guard let tier = SupporterTier(rawValue: index) else { break }
      map[package.storeProduct.productIdentifier] = tier
    }
    tierByProductId = map
  }

  // Repli sur la correspondance par nom tant que l'offering n'est pas chargé.
  func tier(for productIdentifier: String) -> SupporterTier? {
    tierByProductId[productIdentifier] ?? SupporterTier.tier(for: productIdentifier)
  }

  func applyCustomerInfo(_ info: CustomerInfo) {
    let wasAlreadyTipped = hasTipped
    let entitlementActive = info.entitlements[RevenueCatConfig.entitlementId]?.isActive == true
    let hasTransactions = !info.nonSubscriptions.isEmpty

    guard entitlementActive || hasTransactions else {
      // Plus aucun achat actif (remboursement, historique effacé) : on efface le badge en cache
      // pour rester aligné sur le store plutôt que de figer l'ancien palier.
      if wasAlreadyTipped {
        hasTipped = false
        tipTierIndexStored = 0
      }
      return
    }
    hasTipped = true
    updateTier(from: info.nonSubscriptions)
  }

  // Le badge reflète le don le PLUS RÉCENT (et non le palier le plus élevé jamais atteint) : on
  // réaffecte sans `max` pour qu'il puisse aussi redescendre si le dernier don est d'un palier
  // inférieur. Sinon, un don élevé ponctuel figerait le badge sur ce palier indéfiniment.
  private func updateTier(from transactions: [NonSubscriptionTransaction]) {
    let latestTier =
      transactions
      .max { $0.purchaseDate < $1.purchaseDate }
      .flatMap { tier(for: $0.productIdentifier) }
    // Repli : un achat est actif mais le palier reste introuvable → palier minimal.
    tipTierIndexStored = (latestTier?.rawValue ?? 0) + 1
  }
}
