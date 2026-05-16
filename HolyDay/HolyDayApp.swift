//
//  HolyDayApp.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import SwiftUI
import SwiftData

@main
struct HolyDayApp: App {
    let container: ModelContainer
    @AppStorage("holyday.hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        do {
            let storeURL = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("HolyDay.sqlite")
            let config = ModelConfiguration(url: storeURL)
            container = try ModelContainer(for: PrayerEntry.self, configurations: config)
            // Chiffrement du store SwiftData — protège les prières si l'appareil est compromis
            try? FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: storeURL.path
            )
        } catch {
            fatalError("SwiftData failed to initialize: \(error)")
        }
#if DEBUG
        SeedService.seedIfNeeded(in: container.mainContext)
#endif
    }

    var body: some Scene {
        WindowGroup {
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
            .background(Color(red: 0.05, green: 0.05, blue: 0.12))
        }
    }
}
