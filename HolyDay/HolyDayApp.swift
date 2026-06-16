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
import TipKit

@main
struct HolyDayApp: App {
  let container: ModelContainer
  @AppStorage("holyday.hasCompletedOnboarding") private var hasCompletedOnboarding = false
  // Vrai au lancement à froid (état du process) → affiche le splash. Non rejoué au retour
  // d'arrière-plan, le process et donc cet état étant conservés.
  @State private var showSplash = true
  @State private var splashOpacity = 1.0

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
      // Le menu Debug demande une réinitialisation des tips : doit se faire AVANT configure().
      if UserDefaults.standard.bool(forKey: "holyday.debug.resetTips") {
        try? Tips.resetDatastore()
        UserDefaults.standard.set(false, forKey: "holyday.debug.resetTips")
      }
    #endif

    try? Tips.configure([
      .displayFrequency(.immediate),
      .datastoreLocation(.applicationDefault),
    ])
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
            .opacity(splashOpacity)
            // Animation implicite : anime tout changement de `splashOpacity`, quelle que soit
            // sa source. Indispensable ici car le changement vient d'une tâche async — un
            // `withAnimation` appelé depuis une continuation async n'établit pas de transaction
            // fiable et laissait le splash « couper net ».
            .animation(.easeInOut(duration: 0.5), value: splashOpacity)
            .zIndex(1)
            .allowsHitTesting(false)
        }
      }
      .task {
        // Splash affiché au lancement, puis fondu d'opacité vers le contenu.
        try? await Task.sleep(for: .seconds(2.5))
        splashOpacity = 0
        // Retire le splash de la hiérarchie une fois le fondu terminé.
        try? await Task.sleep(for: .seconds(0.5))
        showSplash = false
      }
    }
  }
}
