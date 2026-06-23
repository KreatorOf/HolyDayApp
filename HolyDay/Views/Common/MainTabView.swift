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
    .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    .preferredColorScheme(preferredScheme)
    .onChange(of: scenePhase) { _, phase in
      if phase == .active {
        PrayerRecordService.shared.refresh()
        NotificationService.shared.refreshScheduledReminders()
        // Rafraîchit les widgets (dernier verset, « a prié aujourd'hui ») au retour au premier plan.
        WidgetSyncService.sync()
      }
    }
    // Cibles des `widgetURL` de l'extension : holyday://pray|verse → onglet prière,
    // holyday://journal → onglet journal.
    .onOpenURL { url in
      switch url.host() {
      case "journal":
        selectedTab = 1
      default:
        selectedTab = 0
      }
    }
  }
}

#Preview {
  MainTabView()
    .modelContainer(for: [PrayerEntry.self, PrayerIntention.self], inMemory: true)
}
