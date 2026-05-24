//
//  TipService.swift
//  HolyDay
//
//  Created by Matthias Cadet on 14/05/2026.
//

import Observation
import StoreKit

@Observable
final class TipService {
  static let shared = TipService()

  private(set) var products: [Product] = []
  private(set) var isLoading = false
  var purchaseState: PurchaseState = .idle

  var hasTipped: Bool = UserDefaults.standard.bool(forKey: "holyday.hasTipped") {
    didSet { UserDefaults.standard.set(hasTipped, forKey: "holyday.hasTipped") }
  }

  // Stored as index+1 so 0 means "never tipped" (UserDefaults returns 0 for missing keys)
  private var highestTipIndexStored: Int = UserDefaults.standard.integer(
    forKey: "holyday.highestTipIndex")
  {
    didSet { UserDefaults.standard.set(highestTipIndexStored, forKey: "holyday.highestTipIndex") }
  }

  var supporterTier: SupporterTier? {
    SupporterTier(rawValue: highestTipIndexStored - 1)
  }

  enum PurchaseState: Equatable {
    case idle, purchasing, success, failed
  }

  private init() {}

  func loadProducts() async {
    guard products.isEmpty else { return }
    isLoading = true
    defer { isLoading = false }
    do {
      let fetched = try await Product.products(for: TipProducts.all)
      products = fetched.sorted { $0.price < $1.price }
    } catch {
      // StoreKit fetch failed — products stay empty, UI shows unavailable state
    }
  }

  func purchase(_ product: Product) async {
    purchaseState = .purchasing
    do {
      let result = try await product.purchase()
      switch result {
      case .success(let verification):
        let transaction = try verification.payloadValue
        await transaction.finish()
        hasTipped = true
        if let purchasedIndex = products.firstIndex(where: { $0.id == product.id }) {
          // +1 offset: stored 1 = tier index 0 (ami), 2 = 1 (bienfaiteur), 3 = 2 (pèlerin)
          let stored = purchasedIndex + 1
          if stored > highestTipIndexStored {
            highestTipIndexStored = stored
          }
        }
        purchaseState = .success
      case .userCancelled:
        purchaseState = .idle
      case .pending:
        purchaseState = .idle
      @unknown default:
        purchaseState = .idle
      }
    } catch {
      purchaseState = .failed
    }
  }

  func resetState() {
    purchaseState = .idle
  }

  #if DEBUG
    func debugUnlock(tier: SupporterTier = .pelerin) {
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
