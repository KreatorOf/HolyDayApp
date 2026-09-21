//
//  MainTabView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import SwiftData
import SwiftUI

struct MainTabView: View {
  @AppStorage("holyday.colorScheme") private var colorSchemePreference = "system"
  @State private var selectedTab = 0
  @State private var whatsNew = WhatsNewService.shared
  @State private var router = AppRouter.shared
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.modelContext) private var modelContext

  private var preferredScheme: ColorScheme? {
    switch colorSchemePreference {
    case "light": return .light
    case "dark": return .dark
    default: return nil
    }
  }

  var body: some View {
    TabView(selection: $selectedTab) {
      Tab("tab.prayer", systemImage: "hands.sparkles", value: 0) {
        ContentView()
      }
      Tab("tab.journal", systemImage: "book.pages", value: 1) {
        PrayerHistoryView()
      }
      Tab("tab.settings", systemImage: "gear", value: 2) {
        SettingsView()
      }
    }
    // Teinte épinglée sur le TabView : sans elle, la couleur de l'item sélectionné dérive de
    // l'environnement et les `.tint(...)` des NavigationStack enfants (IntentionDetailView…) la
    // font retomber « par moment » sur un gris secondaire lors des push/pop. `.label` suit le
    // mode clair/sombre (noir/blanc).
    .tint(AppTheme.textPrimary)
    .sensoryFeedback(.selection, trigger: selectedTab)
    .appTabBarBackground()
    .preferredColorScheme(preferredScheme)
    // `fullScreenCover(item:)` plutôt que `isPresented` : la variante `item` conserve son contenu
    // pendant l'animation de fermeture, alors que `markSeen()` vide `pending` dès le premier geste.
    .fullScreenCover(
      item: Binding(
        get: { whatsNew.pending },
        set: { if $0 == nil { whatsNew.markSeen() } }
      )
    ) { presentation in
      WhatsNewView(releases: presentation.releases) { whatsNew.markSeen() }
    }
    // Choisit l'onglet ; les feuilles de l'onglet Prière sont ouvertes par `ContentView`, qui
    // consomme la route. `initial: true` pour un lancement à froid depuis un widget ou une commande.
    .onChange(of: router.pending, initial: true) { _, route in
      switch route {
      case .journal:
        selectedTab = 1
        router.pending = nil
      case .pray:
        selectedTab = 0
        router.pending = nil
      case .freePrayer, .intentions:
        selectedTab = 0
      case nil:
        break
      }
    }
    .onChange(of: scenePhase) { _, phase in
      if phase == .active {
        PrayerRecordService.shared.refresh()
        NotificationService.shared.refreshScheduledReminders()
        // Rafraîchit les widgets (dernier verset, « a prié aujourd'hui ») au retour au premier plan.
        WidgetSyncService.sync()
      }
    }
    // Cibles des `widgetURL` de l'extension, cf. `AppRoute(url:)`.
    .onOpenURL { url in
      router.open(AppRoute(url: url))
    }
  }
}

#Preview {
  MainTabView()
    .modelContainer(
      for: [PrayerEntry.self, PrayerIntention.self, SavedVerse.self, IntentionUpdate.self],
      inMemory: true)
}
