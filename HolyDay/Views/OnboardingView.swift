//
//  OnboardingView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 15/05/2026.
//

import SwiftUI

struct OnboardingView: View {
  var onComplete: () -> Void

  @State private var currentPage = 0
  @State private var goingForward = true
  @AppStorage("holyday.userName") private var storedName = ""
  @State private var nameInput = ""

  var body: some View {
    ZStack {
      AnimatedMeshBackground()
        .ignoresSafeArea()

      if currentPage == 0 {
        WelcomePage { advance(to: 1) }
          .transition(slideTransition)
      } else if currentPage == 1 {
        NamePage(nameInput: $nameInput) {
          storedName = nameInput.trimmingCharacters(in: .whitespaces)
          advance(to: 2)
        }
        .transition(slideTransition)
      } else {
        NotificationsPage(onComplete: onComplete)
          .transition(slideTransition)
      }
    }
    .overlay(alignment: .topLeading) {
      if currentPage > 0 {
        Button(action: goBack) {
          Image(systemName: "chevron.left")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(AppTheme.textSecondary)
            .frame(width: 40, height: 40)
            .glassEffect(.regular, in: Circle())
        }
        .padding(.leading, 20)
        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
      }
    }
    .animation(.easeInOut(duration: 0.2), value: currentPage > 0)
    .safeAreaInset(edge: .bottom, spacing: 0) {
      pageIndicator.padding(.vertical, 12)
    }
  }

  private var slideTransition: AnyTransition {
    goingForward
      ? .asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
      )
      : .asymmetric(
        insertion: .move(edge: .leading).combined(with: .opacity),
        removal: .move(edge: .trailing).combined(with: .opacity)
      )
  }

  private func advance(to page: Int) {
    goingForward = true
    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
      currentPage = page
    }
  }

  private func goBack() {
    goingForward = false
    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
      currentPage -= 1
    }
  }

  private var pageIndicator: some View {
    HStack(spacing: 6) {
      ForEach(0..<3, id: \.self) { i in
        Capsule()
          .fill(i == currentPage ? AppTheme.textPrimary : AppTheme.textTertiary.opacity(0.4))
          .frame(width: i == currentPage ? 20 : 6, height: 6)
          .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
      }
    }
  }
}

// MARK: - Feature model

private struct Feature: Identifiable {
  let id = UUID()
  let icon: String
  let label: String
  let description: String
  let color: Color
}

private let onboardingFeatures: [Feature] = [
  Feature(
    icon: "book.pages", label: String(localized: "onboarding.feature.verse.label"),
    description: String(localized: "onboarding.feature.verse.desc"),
    color: AppTheme.thanksgivingGold),
  Feature(
    icon: "hands.sparkles", label: String(localized: "onboarding.feature.prayer.label"),
    description: String(localized: "onboarding.feature.prayer.desc"),
    color: AppTheme.adorationPurple),
  Feature(
    icon: "calendar", label: String(localized: "onboarding.feature.journal.label"),
    description: String(localized: "onboarding.feature.journal.desc"),
    color: AppTheme.confessionBlue),
  Feature(
    icon: "bell", label: String(localized: "onboarding.feature.reminders.label"),
    description: String(localized: "onboarding.feature.reminders.desc"),
    color: AppTheme.supplicationGreen),
]

// MARK: - Welcome page

private struct WelcomePage: View {
  var onNext: () -> Void
  @State private var breathe = false
  @State private var tileAppeared = Array(repeating: false, count: onboardingFeatures.count)

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      VStack(spacing: 32) {
        ZStack {
          Circle()
            .fill(AppTheme.thanksgivingGold.opacity(0.15))
            .frame(width: 120, height: 120)
            .blur(radius: 14)
            .scaleEffect(breathe ? 1.25 : 0.8)

          Image(systemName: "sun.horizon.fill")
            .font(.system(size: 64))
            .foregroundStyle(AppTheme.thanksgivingGold)
            .scaleEffect(breathe ? 1.06 : 0.94)
        }
        .onAppear {
          withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            breathe = true
          }
        }

        VStack(spacing: 6) {
          HStack(spacing: 0) {
            Text("Holy")
              .font(.system(.largeTitle, design: .serif).weight(.bold).italic())
              .foregroundStyle(AppTheme.textPrimary)
            Text("Day")
              .font(.system(.largeTitle, design: .serif).weight(.thin))
              .foregroundStyle(AppTheme.textSecondary)
          }

          Text("onboarding.welcome.subtitle")
            .font(.subheadline)
            .foregroundStyle(AppTheme.textTertiary)
            .multilineTextAlignment(.center)
        }

        VStack(spacing: 12) {
          ForEach(Array(onboardingFeatures.enumerated()), id: \.offset) { index, feature in
            FeatureTile(feature: feature)
              .opacity(tileAppeared[index] ? 1 : 0)
              .offset(y: tileAppeared[index] ? 0 : 14)
          }
        }
        .padding(.horizontal, 32)
      }

      Spacer()

      OnboardingPrimaryButton(title: String(localized: "onboarding.welcome.cta"), action: onNext)
        .padding(.horizontal, 32)
        .padding(.bottom, 60)
    }
    .onAppear {
      for i in 0..<onboardingFeatures.count {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35 + Double(i) * 0.25) {
          withAnimation(.easeOut(duration: 0.4)) {
            tileAppeared[i] = true
          }
        }
      }
    }
  }
}

private struct FeatureTile: View {
  let feature: Feature
  @State private var bouncing = false

  var body: some View {
    HStack(spacing: 16) {
      Image(systemName: feature.icon)
        .font(.system(size: 20, weight: .medium))
        .foregroundStyle(feature.color)
        .frame(width: 26, alignment: .center)

      VStack(alignment: .leading, spacing: 2) {
        Text(feature.label)
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundStyle(AppTheme.textPrimary)

        Text(feature.description)
          .font(.caption)
          .foregroundStyle(AppTheme.textTertiary)
          .lineLimit(1)
          .minimumScaleFactor(0.85)
      }

      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 16)
    .glassEffect(
      .regular.tint(feature.color.opacity(0.06)),
      in: RoundedRectangle(cornerRadius: 14, style: .continuous)
    )
    .scaleEffect(bouncing ? 0.94 : 1.0)
    .animation(.spring(response: 0.3, dampingFraction: 0.4), value: bouncing)
    .onTapGesture {
      bouncing = true
      Task {
        try? await Task.sleep(for: .milliseconds(120))
        bouncing = false
      }
    }
  }
}

// MARK: - Name page

private struct NamePage: View {
  @Binding var nameInput: String
  var onNext: () -> Void
  @FocusState private var focused: Bool
  @State private var breathe = false

  private var trimmedName: String { nameInput.trimmingCharacters(in: .whitespaces) }

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      VStack(spacing: 36) {
        ZStack {
          Circle()
            .fill(AppTheme.confessionBlue.opacity(0.15))
            .frame(width: 120, height: 120)
            .blur(radius: 14)
            .scaleEffect(breathe ? 1.25 : 0.8)

          Image(systemName: "person.fill")
            .font(.system(size: 64))
            .foregroundStyle(AppTheme.confessionBlue)
            .scaleEffect(breathe ? 1.06 : 0.94)
        }
        .onAppear {
          withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
            breathe = true
          }
        }

        VStack(spacing: 10) {
          Text("onboarding.name.title")
            .font(.system(.largeTitle, design: .serif).weight(.bold))
            .foregroundStyle(AppTheme.textPrimary)
            .multilineTextAlignment(.center)

          Text("onboarding.name.subtitle")
            .font(.subheadline)
            .foregroundStyle(AppTheme.textTertiary)
            .multilineTextAlignment(.center)
        }

        TextField(
          "", text: $nameInput,
          prompt: Text("onboarding.name.placeholder").foregroundStyle(AppTheme.textTertiary)
        )
        .font(.title2)
        .foregroundStyle(AppTheme.textPrimary)
        .multilineTextAlignment(.center)
        .focused($focused)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(
              focused ? AppTheme.confessionBlue.opacity(0.7) : Color.clear,
              lineWidth: 1
            )
        }
        .padding(.horizontal, 32)
        .animation(.easeInOut(duration: 0.2), value: focused)
        .submitLabel(.done)
        .onSubmit { if !trimmedName.isEmpty { dismissAndAdvance() } }

      }

      Spacer()

      OnboardingPrimaryButton(
        title: String(localized: "onboarding.name.cta"),
        isEnabled: !trimmedName.isEmpty,
        action: dismissAndAdvance
      )
      .padding(.horizontal, 32)
      .padding(.bottom, 60)
    }
    .onAppear { focused = true }
  }

  private func dismissAndAdvance() {
    focused = false
    Task {
      try? await Task.sleep(for: .milliseconds(280))
      onNext()
    }
  }
}

// MARK: - Notifications page

private struct NotificationsPage: View {
  var onComplete: () -> Void
  @State private var isRequesting = false
  @State private var breathe = false
  @State private var rang = false
  @State private var cardAppeared = false

  private var reassurances: [(icon: String, text: String)] {
    [
      ("sun.horizon", String(localized: "onboarding.notifications.pill.frequency")),
      ("heart", String(localized: "onboarding.notifications.pill.timing")),
      ("bell.slash", String(localized: "onboarding.notifications.pill.control")),
    ]
  }

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      VStack(spacing: 28) {
        ZStack {
          Circle()
            .fill(AppTheme.supplicationGreen.opacity(0.15))
            .frame(width: 120, height: 120)
            .blur(radius: 14)
            .scaleEffect(breathe ? 1.25 : 0.8)

          Image(systemName: "bell.circle.fill")
            .font(.system(size: 64))
            .foregroundStyle(AppTheme.supplicationGreen)
            .rotationEffect(.degrees(rang ? 14 : 0))
            .animation(.easeInOut(duration: 0.08), value: rang)
        }
        .onAppear {
          withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            breathe = true
          }
          Task {
            try? await Task.sleep(for: .milliseconds(500))
            for _ in 0..<4 {
              withAnimation(.easeInOut(duration: 0.08)) { rang = true }
              try? await Task.sleep(for: .milliseconds(90))
              withAnimation(.easeInOut(duration: 0.08)) { rang = false }
              try? await Task.sleep(for: .milliseconds(90))
            }
          }
        }

        VStack(spacing: 10) {
          Text("onboarding.notifications.title")
            .font(.system(.title, design: .serif).weight(.bold))
            .foregroundStyle(AppTheme.textPrimary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)

          Text("onboarding.notifications.subtitle")
            .font(.subheadline)
            .foregroundStyle(AppTheme.textSecondary)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .frame(maxWidth: 280)
        }

        mockNotificationCard
          .opacity(cardAppeared ? 1 : 0)
          .offset(y: cardAppeared ? 0 : 10)
          .onAppear {
            withAnimation(.easeOut(duration: 0.45).delay(0.65)) {
              cardAppeared = true
            }
          }

        GlassEffectContainer {
          HStack(spacing: 8) {
            ForEach(reassurances, id: \.icon) { item in
              ReassurancePill(icon: item.icon, text: item.text)
            }
          }
        }
        .padding(.horizontal, 24)
      }

      Spacer()

      VStack(spacing: 14) {
        OnboardingPrimaryButton(
          title: String(localized: "onboarding.notifications.cta"), isLoading: isRequesting
        ) {
          isRequesting = true
          Task { @MainActor in
            await NotificationService.shared.setReminder(enabled: true)
            onComplete()
          }
        }

        Button("onboarding.notifications.skip") { onComplete() }
          .font(.subheadline)
          .foregroundStyle(AppTheme.textTertiary)
      }
      .padding(.horizontal, 32)
      .padding(.bottom, 60)
    }
  }

  private var mockNotificationCard: some View {
    HStack(spacing: 12) {
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(AppTheme.supplicationGreen.opacity(0.18))
        .frame(width: 40, height: 40)
        .overlay {
          Image(systemName: "sun.horizon.fill")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(AppTheme.supplicationGreen)
        }

      VStack(alignment: .leading, spacing: 2) {
        HStack {
          Text("HolyDay")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(AppTheme.textPrimary)
          Spacer()
          Text("08:00")
            .font(.caption2)
            .foregroundStyle(AppTheme.textTertiary)
        }
        Text("onboarding.notifications.mock.title")
          .font(.caption2)
          .fontWeight(.medium)
          .foregroundStyle(AppTheme.textSecondary)
        Text("onboarding.notifications.mock.verse")
          .font(.caption2)
          .foregroundStyle(AppTheme.textTertiary)
          .lineLimit(2)
      }
    }
    .padding(12)
    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    .padding(.horizontal, 24)
  }
}

private struct ReassurancePill: View {
  let icon: String
  let text: String

  var body: some View {
    VStack(spacing: 5) {
      Image(systemName: icon)
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(AppTheme.supplicationGreen)
      Text(text)
        .font(.caption2)
        .fontWeight(.medium)
        .foregroundStyle(AppTheme.textTertiary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .glassEffect(
      .regular.tint(AppTheme.supplicationGreen.opacity(0.08)),
      in: RoundedRectangle(cornerRadius: 12, style: .continuous))
  }
}

// MARK: - Shared button

private struct OnboardingPrimaryButton: View {
  var title: String
  var isEnabled: Bool = true
  var isLoading: Bool = false
  var action: () -> Void

  var body: some View {
    Button(action: action) {
      ZStack {
        if isLoading {
          ProgressView().tint(.black)
        } else {
          Text(title)
            .font(.body)
            .fontWeight(.semibold)
        }
      }
      .frame(maxWidth: .infinity)
      .frame(height: 52)
      .foregroundStyle(isEnabled ? Color.black : Color.black.opacity(0.4))
      .glassEffect(
        .regular.tint(AppTheme.thanksgivingGold.opacity(isEnabled ? 0.75 : 0.2)),
        in: RoundedRectangle(cornerRadius: 30, style: .continuous)
      )
      .shadow(
        color: AppTheme.thanksgivingGold.opacity(isEnabled ? 0.45 : 0), radius: 10, x: 0, y: 0)
    }
    .disabled(!isEnabled || isLoading)
    .animation(.easeInOut(duration: 0.2), value: isEnabled)
  }
}

#Preview {
  OnboardingView(onComplete: {})
}
