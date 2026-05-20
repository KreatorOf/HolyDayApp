//
//  MainTabView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
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
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: PrayerEntry.self, inMemory: true)
}
