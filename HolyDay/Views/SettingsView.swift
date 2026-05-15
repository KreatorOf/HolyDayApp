//
//  SettingsView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import SwiftUI

struct SettingsView: View {
    @State private var notifications = NotificationService.shared
    @State private var tipService = TipService.shared
    @State private var showTipView = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var currentYear: String {
        String(Calendar.current.component(.year, from: Date()))
    }

    var body: some View {
        NavigationStack {
            Form {
                supportSection
                communitySection
                notificationsSection
                aboutSection
                legalSection
                copyrightSection
            }
            .navigationTitle("Paramètres")
            .onAppear { notifications.checkStatus() }
            .sheet(isPresented: $showTipView) {
                TipView()
            }
        }
    }

    // MARK: Support

    private var supportSection: some View {
        Section {
            Button {
                showTipView = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "heart.fill")
                        .font(.body)
                        .foregroundStyle(AppTheme.adorationPurple)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Soutenir le développement")
                            .font(.body)
                            .foregroundStyle(.primary)
                        Text("Pourboire libre, sans engagement")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if let tier = tipService.supporterTier {
                        SupporterBadge(tier: tier)
                    }
                }
            }
        } footer: {
            Text("HolyDay est gratuite et sans publicité. Votre soutien aide à la maintenir et à l'améliorer.")
        }
    }

    // MARK: Community

    private var communitySection: some View {
        Section {
            NavigationLink {
                RoadmapView()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "chart.bar.xaxis.ascending")
                        .font(.body)
                        .foregroundStyle(AppTheme.confessionBlue)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Voter pour la roadmap")
                            .font(.body)
                            .foregroundStyle(.primary)
                        Text("Influencez les prochaines fonctionnalités")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: Notifications

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { notifications.isDailyReminderEnabled },
                set: { enabled in Task { await notifications.setReminder(enabled: enabled) } }
            )) {
                Label("Rappel quotidien", systemImage: "bell")
            }

            if notifications.isDailyReminderEnabled {
                DatePicker(
                    "Heure du rappel",
                    selection: Binding(
                        get: { notifications.reminderTime },
                        set: { newTime in
                            notifications.reminderTime = newTime
                            notifications.reschedule(at: newTime)
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
        } header: {
            Text("Notifications")
        } footer: {
            if notifications.isPermissionDenied {
                Label(
                    "Les notifications sont désactivées. Activez-les dans Réglages > HolyDay.",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.caption)
                .foregroundStyle(.orange)
            }
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section("À propos") {
            LabeledContent("Version", value: "\(appVersion) (\(buildNumber))")
            LabeledContent("Développeur", value: "Matthias Cadet")
        }
    }

    // MARK: Legal

    private var legalSection: some View {
        Section("Légal") {
            Link(destination: AppLinks.privacyPolicy) {
                HStack {
                    Label("Politique de confidentialité", systemImage: "lock.shield")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
            }

            Link(destination: AppLinks.termsOfService) {
                HStack {
                    Label("Conditions d'utilisation", systemImage: "doc.text")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
            }

            NavigationLink {
                LegalNoticeView()
            } label: {
                Label("Mentions légales", systemImage: "info.circle")
            }
        }
    }

    // MARK: Copyright

    private var copyrightSection: some View {
        Section {
            Text("© \(currentYear) Matthias Cadet. Tous droits réservés.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .listRowBackground(Color.clear)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 4)
        }
    }
}

#Preview {
    SettingsView()
}
