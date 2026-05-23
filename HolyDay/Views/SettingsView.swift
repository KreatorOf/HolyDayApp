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
    @State private var topInset: CGFloat = 100
    @State private var showNavTitle = false
    @AppStorage("holyday.colorScheme") private var colorSchemePreference = "system"

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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    pageHeader
                    supportCard
                    communityCard
                    notificationsCard
                    appearanceCard
                    aboutCard
                    legalCard
                    copyrightFooter
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(.all, edges: .top)
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { _, y in
                withAnimation(.easeInOut(duration: 0.2)) { showNavTitle = y > 80 }
            }
            .background { AnimatedMeshBackground() }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("tab.settings")
                        .font(.system(.callout, design: .serif, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .opacity(showNavTitle ? 1 : 0)
                }
            }
            .onAppear { notifications.checkStatus() }
            .sheet(isPresented: $showTipView) {
                TipView()
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { topInset = geo.safeAreaInsets.top }
            }
            .ignoresSafeArea()
        )
    }

    // MARK: Header

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("tab.settings")
                .font(.system(size: 34, weight: .bold, design: .serif).italic())
                .foregroundStyle(AppTheme.textPrimary)
            Text("settings.subtitle")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.top, topInset + 44 + 50)
    }

    // MARK: Support

    private var supportCard: some View {
        settingsCard {
            Button { showTipView = true } label: {
                HStack(spacing: 14) {
                    iconBadge(systemName: "heart.fill", color: AppTheme.adorationPurple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("settings.support.title")
                            .font(.body)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("settings.support.subtitle")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    if let tier = tipService.supporterTier {
                        SupporterBadge(tier: tier)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
                .padding(16)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Community

    private var communityCard: some View {
        settingsCard {
            NavigationLink { RoadmapView() } label: {
                HStack(spacing: 14) {
                    iconBadge(systemName: "chart.bar.xaxis.ascending", color: AppTheme.confessionBlue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("settings.roadmap.title")
                            .font(.body)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("settings.roadmap.subtitle")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .padding(16)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Notifications

    private var notificationsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(String(localized: "settings.notifications.section"))
            settingsCard {
                VStack(spacing: 0) {
                    HStack(spacing: 14) {
                        iconBadge(systemName: "bell.fill", color: AppTheme.thanksgivingGold)
                        Text("settings.notifications.reminder")
                            .font(.body)
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { notifications.isDailyReminderEnabled },
                            set: { enabled in Task { await notifications.setReminder(enabled: enabled) } }
                        ))
                        .labelsHidden()
                        .tint(AppTheme.thanksgivingGold)
                    }
                    .padding(16)

                    if notifications.isDailyReminderEnabled {
                        cardDivider
                        HStack(spacing: 14) {
                            iconBadge(systemName: "clock.fill", color: AppTheme.thanksgivingGold)
                            DatePicker(
                                String(localized: "settings.notifications.time"),
                                selection: Binding(
                                    get: { notifications.reminderTime },
                                    set: { newTime in
                                        notifications.reminderTime = newTime
                                        notifications.reschedule(at: newTime)
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .foregroundStyle(AppTheme.textPrimary)
                        }
                        .padding(16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if notifications.isPermissionDenied {
                        cardDivider
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text("settings.notifications.disabled")
                                .font(.caption)
                                .foregroundStyle(.orange.opacity(0.9))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .transition(.opacity)
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: notifications.isDailyReminderEnabled)
                .animation(.easeInOut(duration: 0.2), value: notifications.isPermissionDenied)
            }
        }
    }

    // MARK: Appearance

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(String(localized: "settings.appearance.section"))
            settingsCard {
                HStack(spacing: 14) {
                    iconBadge(systemName: "circle.lefthalf.filled", color: AppTheme.adorationPurple)
                    Text("settings.appearance.title")
                        .font(.body)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 10)

                cardDivider

                Picker("", selection: $colorSchemePreference) {
                    Text("settings.appearance.system").tag("system")
                    Text("settings.appearance.light").tag("light")
                    Text("settings.appearance.dark").tag("dark")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: About

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(String(localized: "settings.about.section"))
            settingsCard {
                VStack(spacing: 0) {
                    infoRow(label: String(localized: "settings.about.version"), value: "\(appVersion) (\(buildNumber))")
                    cardDivider
                    infoRow(label: String(localized: "settings.about.developer"), value: "Matthias Cadet")
                }
            }
        }
    }

    // MARK: Legal

    private var legalCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(String(localized: "settings.legal.section"))
            settingsCard {
                VStack(spacing: 0) {
                    Link(destination: AppLinks.privacyPolicy) {
                        externalLinkRow(icon: "lock.shield.fill", label: String(localized: "settings.legal.privacy"), color: AppTheme.supplicationGreen)
                    }
                    .buttonStyle(.plain)
                    cardDivider
                    Link(destination: AppLinks.termsOfService) {
                        externalLinkRow(icon: "doc.text.fill", label: String(localized: "settings.legal.terms"), color: AppTheme.confessionBlue)
                    }
                    .buttonStyle(.plain)
                    cardDivider
                    NavigationLink { LegalNoticeView() } label: {
                        externalLinkRow(icon: "info.circle.fill", label: String(localized: "settings.legal.notice"), color: AppTheme.adorationPurple, isExternal: false)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Copyright

    private var copyrightFooter: some View {
        Text(String(format: String(localized: "settings.copyright"), currentYear))
            .font(.caption2)
            .foregroundStyle(AppTheme.textTertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
    }

    // MARK: Reusable primitives

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func iconBadge(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 36, height: 36)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(AppTheme.textTertiary)
            .textCase(.uppercase)
            .tracking(1.0)
            .padding(.horizontal, 4)
    }

    private var cardDivider: some View {
        AppTheme.divider
            .frame(height: 1)
            .padding(.horizontal, 16)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func externalLinkRow(icon: String, label: String, color: Color, isExternal: Bool = true) -> some View {
        HStack(spacing: 14) {
            iconBadge(systemName: icon, color: color)
            Text(label)
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            Image(systemName: isExternal ? "arrow.up.right" : "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
