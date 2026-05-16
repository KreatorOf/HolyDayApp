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
            Tab("Prière", systemImage: "hands.sparkles") {
                ContentView()
            }
            Tab("Journal", systemImage: "book.pages") {
                PrayerHistoryView()
            }
            Tab("Paramètres", systemImage: "gear") {
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
