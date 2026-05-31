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
    .sensoryFeedback(.selection, trigger: selectedTab)
    .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    .preferredColorScheme(preferredScheme)
    .onChange(of: scenePhase) { _, phase in
      if phase == .active { StreakService.shared.refresh() }
    }
  }
}

#Preview {
  MainTabView()
    .modelContainer(for: [PrayerEntry.self, PrayerIntention.self], inMemory: true)
}
