//
//  HolyDayApp.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import OSLog
import RevenueCat
import SwiftData
import SwiftUI

@main
struct HolyDayApp: App {
  let container: ModelContainer
  @AppStorage("holyday.hasCompletedOnboarding") private var hasCompletedOnboarding = false
  // Vrai au lancement à froid (état du process) → affiche le splash. Non rejoué au retour
  // d'arrière-plan, le process et donc cet état étant conservés.
  @State private var showSplash = true

  init() {
    #if DEBUG
      Purchases.logLevel = .debug
    #endif
    Purchases.configure(withAPIKey: RevenueCatConfig.apiKey)

    do {
      let storeURL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("HolyDay.sqlite")
      let config = ModelConfiguration(url: storeURL)
      container = try ModelContainer(
        for: PrayerEntry.self, PrayerIntention.self, configurations: config)
      Self.protectStoreFiles(at: storeURL)
    } catch {
      fatalError("SwiftData failed to initialize: \(error)")
    }
    #if DEBUG
      SeedService.seedIfNeeded(in: container.mainContext)
    #endif
  }

  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "HolyDay", category: "storage")

  // Chiffrement au repos du store SwiftData (prières = données sensibles). Couvre aussi les
  // fichiers annexes -wal/-shm du journal WAL, sinon laissés à la protection par défaut
  // (« Until First User Authentication ») et donc lisibles appareil verrouillé.
  private static func protectStoreFiles(at storeURL: URL) {
    let paths = [storeURL.path, storeURL.path + "-wal", storeURL.path + "-shm"]
    for path in paths where FileManager.default.fileExists(atPath: path) {
      do {
        try FileManager.default.setAttributes(
          [.protectionKey: FileProtectionType.complete], ofItemAtPath: path)
      } catch {
        // Tracé en production (Console) plutôt qu'un `assertionFailure` muet en Release : un échec
        // signifie que des données sensibles restent en protection par défaut.
        logger.error("Échec de la protection fichier pour \(path, privacy: .public) : \(error)")
      }
    }
  }

  var body: some Scene {
    WindowGroup {
      ZStack {
        Group {
          if hasCompletedOnboarding {
            MainTabView()
              .transition(.opacity)
          } else {
            OnboardingView {
              withAnimation(.easeInOut(duration: 0.5)) {
                hasCompletedOnboarding = true
              }
            }
            .transition(.opacity)
          }
        }
        .modelContainer(container)
        .background { AppBackground() }

        if showSplash {
          SplashView()
            .transition(.opacity)
            .zIndex(1)
        }
      }
      // Fondu fiable du splash vers le contenu (plutôt qu'un withAnimation au niveau scène,
      // qui peut couper net) : l'animation est pilotée par le changement de `showSplash`.
      .animation(.easeInOut(duration: 0.6), value: showSplash)
      .task {
        // Splash affiché au lancement, puis fondu vers le contenu.
        try? await Task.sleep(for: .seconds(2.5))
        showSplash = false
      }
    }
  }
}
