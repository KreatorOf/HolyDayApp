//
//  SettingsView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import PhotosUI
import StoreKit
import SwiftData
import SwiftUI

struct SettingsView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.requestReview) private var requestReview
  @State private var notifications = NotificationService.shared
  @State private var tipService = TipService.shared
  @State private var showTipView = false
  @State private var topInset: CGFloat = 100
  @State private var showNavTitle = false
  @State private var showResetConfirmation = false
  @State private var isEditingName = false
  @State private var pendingName = ""
  @State private var avatarImage: UIImage? = AvatarService.shared.load()
  @State private var showPhotoPicker = false
  @State private var photoPickerItem: PhotosPickerItem?
  @AppStorage("holyday.colorScheme") private var colorSchemePreference = "system"
  @AppStorage("holyday.userName") private var userName = ""
  @State private var rateFeedbackToken = false

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
          profileCard
          supportCard
          communitySection
          notificationsCard
          appearanceCard
          aboutCard
          legalCard
          dangerZoneSection
          copyrightFooter
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
      }
      .scrollIndicators(.hidden)
      .ignoresSafeArea(.all, edges: .top)
      .onScrollGeometryChange(for: CGFloat.self) {
        $0.contentOffset.y
      } action: { _, y in
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
      .sheet(isPresented: $showTipView) { TipView() }
      .alert("settings.danger.reset.confirm.title", isPresented: $showResetConfirmation) {
        Button("settings.danger.reset.confirm.action", role: .destructive) { resetAllData() }
        Button("common.cancel", role: .cancel) {}
      } message: {
        Text("settings.danger.reset.confirm.message")
      }
    }
    .background(
      GeometryReader { geo in
        Color.clear.onAppear { topInset = geo.safeAreaInsets.top }
      }
      .ignoresSafeArea()
    )
  }

  // MARK: Header

  private var pageHeader: some View {
    Text("tab.settings")
      .font(.system(size: 34, weight: .bold, design: .serif).italic())
      .foregroundStyle(AppTheme.textPrimary)
      .padding(.top, topInset + 44 + 50)
  }

  // MARK: Profile card

  private var profileCard: some View {
    settingsCard {
      HStack(spacing: 16) {
        avatarCircle

        VStack(alignment: .leading, spacing: 5) {
          if isEditingName {
            TextField("settings.profile.name.placeholder", text: $pendingName)
              .font(.headline)
              .foregroundStyle(AppTheme.textPrimary)
              .onSubmit { commitName() }
              .submitLabel(.done)
          } else {
            Text(
              userName.isEmpty ? String(localized: "settings.profile.name.placeholder") : userName
            )
            .font(.headline)
            .foregroundStyle(userName.isEmpty ? AppTheme.textTertiary : AppTheme.textPrimary)
          }

          if let tier = tipService.supporterTier {
            SupporterBadge(tier: tier)
          } else {
            Text("settings.profile.edit.hint")
              .font(.caption)
              .foregroundStyle(AppTheme.textTertiary)
          }
        }

        Spacer()

        Button {
          if isEditingName {
            commitName()
          } else {
            pendingName = userName
            withAnimation(.spring(response: 0.3)) { isEditingName = true }
          }
        } label: {
          Image(systemName: isEditingName ? "checkmark" : "pencil")
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.textTertiary)
            .frame(width: 32, height: 32)
            .background(AppTheme.buttonFillSubtle)
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isEditingName)
        .animation(.spring(response: 0.3), value: isEditingName)
      }
      .padding(16)
    }
  }

  private var avatarCircle: some View {
    let initials: String = {
      let words = userName.split(separator: " ").prefix(2)
      let letters = words.compactMap { $0.first }.map { String($0).uppercased() }.joined()
      return letters.isEmpty ? "?" : letters
    }()

    return Button {
      showPhotoPicker = true
    } label: {
      ZStack(alignment: .bottomTrailing) {
        if let img = avatarImage {
          Image(uiImage: img)
            .resizable()
            .scaledToFill()
            .frame(width: 56, height: 56)
            .clipShape(Circle())
            .overlay { Circle().strokeBorder(AppTheme.cardStroke, lineWidth: 1) }
        } else {
          ZStack {
            Circle()
              .fill(.ultraThinMaterial)
              .overlay { Circle().strokeBorder(AppTheme.cardStroke, lineWidth: 1) }
            Text(initials)
              .font(.system(size: 20, weight: .bold, design: .rounded))
              .foregroundStyle(AppTheme.adorationPurple)
          }
        }

        Image(systemName: "camera.fill")
          .font(.system(size: 8, weight: .bold))
          .foregroundStyle(.white)
          .frame(width: 18, height: 18)
          .background(AppTheme.adorationPurple)
          .clipShape(Circle())
      }
      .frame(width: 56, height: 56)
    }
    .buttonStyle(.plain)
    .contextMenu {
      if avatarImage != nil {
        Button(role: .destructive) {
          AvatarService.shared.delete()
          avatarImage = nil
        } label: {
          Label("settings.avatar.remove", systemImage: "trash")
        }
      }
    }
    .photosPicker(isPresented: $showPhotoPicker, selection: $photoPickerItem, matching: .images)
    .onChange(of: photoPickerItem) { _, item in
      Task {
        if let data = try? await item?.loadTransferable(type: Data.self),
          let img = UIImage(data: data)
        {
          AvatarService.shared.save(img)
          avatarImage = AvatarService.shared.load()
        }
        photoPickerItem = nil
      }
    }
  }

  private func commitName() {
    userName = pendingName.trimmingCharacters(in: .whitespaces)
    withAnimation(.spring(response: 0.3)) { isEditingName = false }
  }

  // MARK: Support

  private var supportCard: some View {
    settingsCard {
      Button {
        showTipView = true
      } label: {
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
          Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.textTertiary)
        }
        .padding(16)
      }
      .buttonStyle(.plain)
      .sensoryFeedback(.selection, trigger: showTipView)
    }
  }

  // MARK: Community

  private var communitySection: some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionLabel(String(localized: "settings.community.section"))
      settingsCard {
        VStack(spacing: 0) {
          NavigationLink {
            RoadmapView()
          } label: {
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

          cardDivider

          ShareLink(item: AppLinks.appStore) {
            externalLinkRow(
              icon: "square.and.arrow.up",
              label: String(localized: "settings.community.share"),
              color: AppTheme.supplicationGreen
            )
          }
          .buttonStyle(.plain)

          cardDivider

          Button {
            rateFeedbackToken.toggle()
            requestReview()
          } label: {
            externalLinkRow(
              icon: "star.fill",
              label: String(localized: "settings.community.rate"),
              color: AppTheme.thanksgivingGold,
              isExternal: false
            )
          }
          .buttonStyle(.plain)
          .sensoryFeedback(.selection, trigger: rateFeedbackToken)
        }
      }
    }
  }

  // MARK: Danger zone

  private var dangerZoneSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionLabel(String(localized: "settings.danger.section"))
      settingsCard {
        Button {
          showResetConfirmation = true
        } label: {
          HStack(spacing: 14) {
            iconBadge(systemName: "trash.fill", color: .red)
            VStack(alignment: .leading, spacing: 2) {
              Text("settings.danger.reset.title")
                .font(.body)
                .foregroundStyle(.red)
              Text("settings.danger.reset.subtitle")
                .font(.caption)
                .foregroundStyle(.red.opacity(0.65))
            }
            Spacer()
            Image(systemName: "chevron.right")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.red.opacity(0.4))
          }
          .padding(16)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.warning, trigger: showResetConfirmation)

        #if DEBUG
          cardDivider

          Button {
            tipService.debugUnlock()
          } label: {
            HStack(spacing: 14) {
              iconBadge(systemName: "wrench.and.screwdriver.fill", color: .orange)
              VStack(alignment: .leading, spacing: 2) {
                Text("DEBUG — Unlock Mécène")
                  .font(.body)
                  .foregroundStyle(.orange)
                Text("Simule un achat sans StoreKit")
                  .font(.caption)
                  .foregroundStyle(.orange.opacity(0.65))
              }
              Spacer()
            }
            .padding(16)
          }
          .buttonStyle(.plain)

          cardDivider

          Button {
            tipService.debugReset()
          } label: {
            HStack(spacing: 14) {
              iconBadge(systemName: "arrow.counterclockwise", color: .orange)
              Text("DEBUG — Reset supporter")
                .font(.body)
                .foregroundStyle(.orange)
              Spacer()
            }
            .padding(16)
          }
          .buttonStyle(.plain)
        #endif
      }
    }
  }

  private func resetAllData() {
    try? modelContext.delete(model: PrayerEntry.self)
    UINotificationFeedbackGenerator().notificationOccurred(.warning)
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
            Toggle(
              "",
              isOn: Binding(
                get: { notifications.isDailyReminderEnabled },
                set: { enabled in Task { await notifications.setReminder(enabled: enabled) } }
              )
            )
            .labelsHidden()
            .tint(AppTheme.thanksgivingGold)
          }
          .padding(16)
          .sensoryFeedback(.success, trigger: notifications.isDailyReminderEnabled)

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
        .animation(
          .spring(response: 0.35, dampingFraction: 0.8), value: notifications.isDailyReminderEnabled
        )
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
        .sensoryFeedback(.selection, trigger: colorSchemePreference)
      }
    }
  }

  // MARK: About

  private var aboutCard: some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionLabel(String(localized: "settings.about.section"))
      settingsCard {
        VStack(spacing: 0) {
          infoRow(
            label: String(localized: "settings.about.version"),
            value: "\(appVersion) (\(buildNumber))")
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
            externalLinkRow(
              icon: "lock.shield.fill", label: String(localized: "settings.legal.privacy"),
              color: AppTheme.supplicationGreen)
          }
          .buttonStyle(.plain)
          cardDivider
          Link(destination: AppLinks.termsOfService) {
            externalLinkRow(
              icon: "doc.text.fill", label: String(localized: "settings.legal.terms"),
              color: AppTheme.confessionBlue)
          }
          .buttonStyle(.plain)
          cardDivider
          NavigationLink {
            LegalNoticeView()
          } label: {
            externalLinkRow(
              icon: "info.circle.fill", label: String(localized: "settings.legal.notice"),
              color: AppTheme.adorationPurple, isExternal: false)
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
    VStack(spacing: 0) { content() }
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
    AppTheme.divider.frame(height: 1).padding(.horizontal, 16)
  }

  private func infoRow(label: String, value: String) -> some View {
    HStack {
      Text(label).font(.body).foregroundStyle(AppTheme.textPrimary)
      Spacer()
      Text(value).font(.body).foregroundStyle(AppTheme.textSecondary)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
  }

  private func externalLinkRow(icon: String, label: String, color: Color, isExternal: Bool = true)
    -> some View
  {
    HStack(spacing: 14) {
      iconBadge(systemName: icon, color: color)
      Text(label).font(.body).foregroundStyle(AppTheme.textPrimary)
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
    .modelContainer(for: PrayerEntry.self, inMemory: true)
    .preferredColorScheme(.dark)
}
