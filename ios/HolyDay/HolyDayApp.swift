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
  // d'arrière-plan, le process et donc cet état étant conservés. Ignoré en mode capture d'écran.
  @State private var showSplash = !ScreenshotMode.isActive
  @State private var splashOpacity = 1.0
  // Vrai si l'ouverture du store sur disque a échoué et qu'on tourne en mémoire cette session
  // → affiche une bannière. Les données de cette session ne sont pas persistées.
  @State private var showStoreBanner = false

  init() {
    #if DEBUG
      Purchases.logLevel = .debug
    #endif
    Purchases.configure(withAPIKey: RevenueCatConfig.apiKey)

    let resolvedContainer: ModelContainer
    var storeFailed = false
    do {
      let storeURL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("HolyDay.sqlite")
      let config = ModelConfiguration(url: storeURL)
      resolvedContainer = try ModelContainer(
        for: PrayerEntry.self, PrayerIntention.self, configurations: config)
      Self.protectStoreFiles(at: storeURL)
    } catch {
      // Store sur disque illisible (corruption, migration ratée) : on NE supprime PAS le fichier —
      // les prières de l'utilisateur restent récupérables au prochain lancement / après mise à jour.
      // On démarre en mémoire pour ne pas crasher, en avertissant que rien n'est enregistré.
      Self.logger.error(
        "Ouverture du store SwiftData échouée, repli en mémoire : \(error.localizedDescription, privacy: .public)"
      )
      do {
        let memoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
        resolvedContainer = try ModelContainer(
          for: PrayerEntry.self, PrayerIntention.self, configurations: memoryConfig)
      } catch {
        // Un échec du conteneur en mémoire ne peut venir que d'un schéma invalide (erreur de
        // développement), pas d'un incident d'exécution récupérable.
        fatalError("SwiftData in-memory fallback failed: \(error)")
      }
      storeFailed = true
    }
    container = resolvedContainer
    _showStoreBanner = State(initialValue: storeFailed)
    #if DEBUG
      SeedService.seedIfNeeded(in: container.mainContext)
      // Le menu Debug demande une réinitialisation des tips : doit se faire AVANT configure().
      if UserDefaults.standard.bool(forKey: "holyday.debug.resetTips") {
        try? Tips.resetDatastore()
        UserDefaults.standard.set(false, forKey: "holyday.debug.resetTips")
      }
    #endif

    SharedStore.repairLegacyTranslationSigil()

    // En mode capture d'écran, on ne configure pas TipKit : les popovers du parcours de
    // découverte ne doivent pas venir masquer les écrans capturés.
    if !ScreenshotMode.isActive {
      try? Tips.configure([
        .displayFrequency(.immediate),
        .datastoreLocation(.applicationDefault),
      ])
    }
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

  private var storeBanner: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.orange)
        .accessibilityHidden(true)
      Text("app.storeError.message")
        .font(.footnote)
        .foregroundStyle(.primary)
        .fixedSize(horizontal: false, vertical: true)
      Spacer(minLength: 0)
      Button {
        showStoreBanner = false
      } label: {
        Image(systemName: "xmark")
          .font(.footnote.weight(.semibold))
          .foregroundStyle(.secondary)
          .frame(width: 44, height: 44)
      }
      .accessibilityLabel(Text("accessibility.storeError.dismiss"))
    }
    .padding(.leading, 16)
    .padding(.vertical, 12)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    .padding(.horizontal, 12)
    .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
  }

  var body: some Scene {
    WindowGroup {
      ZStack {
        Group {
          if hasCompletedOnboarding || ScreenshotMode.isActive {
            MainTabView()
              .transition(.opacity)
          } else {
            OnboardingView {
              // Une installation neuve ne doit pas se voir annoncer des « nouveautés » : on note la
              // version courante comme déjà vue avant même d'entrer dans l'app.
              WhatsNewService.shared.markSeen()
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
      .overlay(alignment: .top) {
        if showStoreBanner && !showSplash {
          storeBanner
            .transition(.move(edge: .top).combined(with: .opacity))
            .zIndex(2)
        }
      }
      .animation(.easeInOut(duration: 0.3), value: showStoreBanner)
      .task {
        // Splash affiché au lancement, puis fondu d'opacité vers le contenu.
        try? await Task.sleep(for: .seconds(2.5))
        splashOpacity = 0
        // Retire le splash de la hiérarchie une fois le fondu terminé.
        try? await Task.sleep(for: .seconds(0.5))
        showSplash = false
        // Après le splash seulement : une feuille présentée plus tôt s'ouvrirait derrière lui.
        // `MainTabView` observe `pending` et se charge de l'affichage.
        if hasCompletedOnboarding {
          WhatsNewService.shared.evaluate()
        }
      }
    }
  }
}
