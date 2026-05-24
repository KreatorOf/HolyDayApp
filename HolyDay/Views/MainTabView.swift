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

  private var preferredScheme: ColorScheme? {
    switch colorSchemePreference {
    case "light": return .light
    case "dark": return .dark
    default: return nil
    }
  }

  var body: some View {
    TabView {
      Tab("tab.prayer", systemImage: "hands.sparkles") {
        ContentView()
      }
      Tab("tab.journal", systemImage: "book.pages") {
        PrayerHistoryView()
      }
      Tab("tab.settings", systemImage: "gear") {
        SettingsView()
      }
    }
    .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    .preferredColorScheme(preferredScheme)
  }
}

#Preview {
  MainTabView()
    .modelContainer(for: PrayerEntry.self, inMemory: true)
}
