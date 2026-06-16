//
//  OnboardingView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 15/05/2026.
//

import SwiftData
import SwiftUI

// MARK: - View model

@MainActor @Observable
final class OnboardingViewModel {
  enum Step: Int, CaseIterable {
    case hero, value, name, intention, privacy, notifications
  }

  private(set) var step: Step = .hero
  private(set) var goingForward = true
  var name = ""

  var canGoBack: Bool { step != .hero }
  var progress: (current: Int, total: Int) { (step.rawValue + 1, Step.allCases.count) }

  func advance() {
    guard let next = Step(rawValue: step.rawValue + 1) else { return }
    goingForward = true
    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { step = next }
  }

  func back() {
    guard let previous = Step(rawValue: step.rawValue - 1) else { return }
    goingForward = false
    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { step = previous }
  }
}

// MARK: - Root

struct OnboardingView: View {
  var onComplete: () -> Void

  @State private var model = OnboardingViewModel()
  @AppStorage("holyday.userName") private var storedName = ""

  var body: some View {
    ZStack {
      AppBackground()

      currentPage
        .transition(slideTransition)
    }
    .overlay(alignment: .topLeading) {
      if model.canGoBack {
        Button(action: model.back) {
          Image(systemName: "chevron.left")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(AppTheme.textSecondary)
            .frame(width: 44, height: 44)
            .glassEffect(.regular, in: Circle())
        }
        .accessibilityLabel(Text("onboarding.back"))
        .padding(.leading, 16)
        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
      }
    }
    .animation(.easeInOut(duration: 0.2), value: model.canGoBack)
    .safeAreaInset(edge: .bottom, spacing: 0) {
      pageIndicator.padding(.vertical, 12)
    }
  }

  @ViewBuilder private var currentPage: some View {
    switch model.step {
    case .hero:
      HeroPage(onNext: model.advance)
    case .value:
      ValuePage(onNext: model.advance)
    case .name:
      NamePage(name: $model.name) {
        storedName = model.name.trimmingCharacters(in: .whitespaces)
        model.advance()
      }
    case .intention:
      FirstIntentionPage(onNext: model.advance)
    case .privacy:
      PrivacyPage(onNext: model.advance)
    case .notifications:
      NotificationsPage(onComplete: onComplete)
    }
  }

  private var slideTransition: AnyTransition {
    model.goingForward
      ? .asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
      )
      : .asymmetric(
        insertion: .move(edge: .leading).combined(with: .opacity),
        removal: .move(edge: .trailing).combined(with: .opacity)
      )
  }

  private var pageIndicator: some View {
    HStack(spacing: 6) {
      ForEach(0..<model.progress.total, id: \.self) { index in
        Capsule()
          .fill(
            index == model.step.rawValue
              ? AppTheme.textPrimary : AppTheme.textTertiary.opacity(0.4)
          )
          .frame(width: index == model.step.rawValue ? 20 : 6, height: 6)
          .animation(.spring(response: 0.3, dampingFraction: 0.7), value: model.step)
      }
    }
    .accessibilityElement()
    .accessibilityLabel(Text("onboarding.progress.label"))
    .accessibilityValue(
      Text(
        String(
          format: String(localized: "onboarding.progress.value"),
          model.progress.current, model.progress.total
        )
      )
    )
  }
}

// MARK: - Shared layout

/// Gabarit commun : symbole + contenu centrés verticalement, CTA ancré en bas (grille 8pt).
private struct OnboardingScaffold<Content: View, Footer: View>: View {
  @ViewBuilder var content: Content
  @ViewBuilder var footer: Footer

  var body: some View {
    VStack(spacing: 0) {
      Spacer(minLength: 0)
      content
      Spacer(minLength: 0)
      footer
        .padding(.horizontal, 32)
        .padding(.bottom, 60)
    }
  }
}

/// Symbole « hero » avec halo respirant. L'animation continue est désactivée si
/// l'utilisateur a activé « Réduire les animations » (HIG accessibilité).
private struct HeroSymbol: View {
  // Soit un SF Symbol, soit une image de marque (asset template, ex. logo de l'app).
  private enum Glyph {
    case symbol(String)
    case brand(String)
  }

  private let glyph: Glyph
  private let color: Color
  private let size: CGFloat

  init(systemName: String, color: Color, size: CGFloat = 64) {
    self.glyph = .symbol(systemName)
    self.color = color
    self.size = size
  }

  init(brand: String, color: Color, size: CGFloat = 56) {
    self.glyph = .brand(brand)
    self.color = color
    self.size = size
  }

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var breathe = false

  private var haloScale: CGFloat { reduceMotion ? 1.0 : (breathe ? 1.25 : 0.8) }
  private var iconScale: CGFloat { reduceMotion ? 1.0 : (breathe ? 1.06 : 0.94) }

  var body: some View {
    ZStack {
      Circle()
        .fill(color.opacity(0.15))
        .frame(width: 120, height: 120)
        .blur(radius: 14)
        .scaleEffect(haloScale)

      glyphView
        .foregroundStyle(color)
        .scaleEffect(iconScale)
    }
    .accessibilityHidden(true)
    .onAppear {
      guard !reduceMotion else { return }
      withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
        breathe = true
      }
    }
  }

  @ViewBuilder private var glyphView: some View {
    switch glyph {
    case .symbol(let name):
      Image(systemName: name)
        .font(.system(size: size))
    case .brand(let name):
      Image(name)
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: size, height: size)
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
    icon: "checklist", label: String(localized: "onboarding.pillar.way.label"),
    description: String(localized: "onboarding.pillar.way.desc"),
    color: AppTheme.adorationPurple),
  Feature(
    icon: "hands.and.sparkles", label: String(localized: "onboarding.pillar.intentions.label"),
    description: String(localized: "onboarding.pillar.intentions.desc"),
    color: AppTheme.thanksgivingGold),
  Feature(
    icon: "book.pages", label: String(localized: "onboarding.pillar.thread.label"),
    description: String(localized: "onboarding.pillar.thread.desc"),
    color: AppTheme.confessionBlue),
]

private struct FeatureRow: View {
  let feature: Feature

  var body: some View {
    HStack(spacing: 16) {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(feature.color.opacity(0.15))
        .frame(width: 44, height: 44)
        .overlay {
          Image(systemName: feature.icon)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(feature.color)
        }

      VStack(alignment: .leading, spacing: 2) {
        Text(feature.label)
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundStyle(AppTheme.textPrimary)

        Text(feature.description)
          .font(.caption)
          .foregroundStyle(AppTheme.textTertiary)
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer(minLength: 0)
    }
    .accessibilityElement(children: .combine)
  }
}

// MARK: - ① Hero page

private struct HeroPage: View {
  var onNext: () -> Void

  var body: some View {
    OnboardingScaffold {
      VStack(spacing: 32) {
        HeroSymbol(systemName: "sun.horizon.fill", color: AppTheme.thanksgivingGold)

        VStack(spacing: 12) {
          HStack(spacing: 0) {
            Text("Holy")
              .font(.system(.largeTitle, design: .serif).weight(.bold).italic())
              .foregroundStyle(AppTheme.textPrimary)
            Text("Day")
              .font(.system(.largeTitle, design: .serif).weight(.thin))
              .foregroundStyle(AppTheme.textSecondary)
          }
          .accessibilityElement()
          .accessibilityLabel("HolyDay")

          Text("onboarding.welcome.subtitle")
            .font(.subheadline)
            .foregroundStyle(AppTheme.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
        }
      }
    } footer: {
      OnboardingPrimaryButton(title: String(localized: "onboarding.welcome.cta"), action: onNext)
    }
  }
}

// MARK: - ② Value page

private struct ValuePage: View {
  var onNext: () -> Void

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var appeared = Array(repeating: false, count: onboardingFeatures.count)

  var body: some View {
    OnboardingScaffold {
      VStack(spacing: 56) {
        VStack(spacing: 24) {
          HeroSymbol(brand: "prayingHands", color: AppTheme.adorationPurple)

          Text("onboarding.value.title")
            .font(.system(.largeTitle, design: .serif).weight(.bold))
            .foregroundStyle(AppTheme.textPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
        }

        VStack(spacing: 36) {
          ForEach(Array(onboardingFeatures.enumerated()), id: \.offset) { index, feature in
            FeatureRow(feature: feature)
              .opacity(appeared[index] ? 1 : 0)
              .offset(y: appeared[index] ? 0 : 24)
          }
        }
        .padding(.horizontal, 32)
      }
    } footer: {
      OnboardingPrimaryButton(title: String(localized: "onboarding.name.cta"), action: onNext)
    }
    .onAppear(perform: animateIn)
  }

  private func animateIn() {
    guard !reduceMotion else {
      for index in appeared.indices { appeared[index] = true }
      return
    }
    // Cascade nettement séquentielle : chaque feature entre l'une après l'autre (~0,5 s d'écart).
    for index in onboardingFeatures.indices {
      withAnimation(
        .spring(response: 0.5, dampingFraction: 0.8).delay(0.35 + Double(index) * 0.5)
      ) {
        appeared[index] = true
      }
    }
  }
}

// MARK: - ③ Name page

private struct NamePage: View {
  @Binding var name: String
  var onNext: () -> Void

  @FocusState private var focused: Bool

  private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }

  var body: some View {
    OnboardingScaffold {
      VStack(spacing: 36) {
        HeroSymbol(systemName: "person.fill", color: AppTheme.confessionBlue)

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
          "", text: $name,
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
    } footer: {
      OnboardingPrimaryButton(
        title: String(localized: "onboarding.name.cta"),
        isEnabled: !trimmedName.isEmpty,
        action: dismissAndAdvance
      )
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

// MARK: - ④ First intention page

private struct FirstIntentionPage: View {
  var onNext: () -> Void

  @Environment(\.modelContext) private var modelContext
  @FocusState private var focused: Bool
  @State private var intentionInput = ""

  private var trimmed: String { intentionInput.trimmingCharacters(in: .whitespacesAndNewlines) }

  var body: some View {
    OnboardingScaffold {
      VStack(spacing: 36) {
        HeroSymbol(systemName: "hands.and.sparkles.fill", color: AppTheme.adorationPurple)

        VStack(spacing: 10) {
          Text("onboarding.intention.title")
            .font(.system(.largeTitle, design: .serif).weight(.bold))
            .foregroundStyle(AppTheme.textPrimary)
            .multilineTextAlignment(.center)

          Text("onboarding.intention.subtitle")
            .font(.subheadline)
            .foregroundStyle(AppTheme.textTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 300)
        }

        TextField(
          "", text: $intentionInput,
          prompt: Text("onboarding.intention.placeholder").foregroundStyle(AppTheme.textTertiary),
          axis: .vertical
        )
        .font(.title3)
        .foregroundStyle(AppTheme.textPrimary)
        .multilineTextAlignment(.center)
        .lineLimit(1...3)
        .focused($focused)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(
              focused ? AppTheme.adorationPurple.opacity(0.7) : Color.clear,
              lineWidth: 1
            )
        }
        .padding(.horizontal, 32)
        .animation(.easeInOut(duration: 0.2), value: focused)
        .submitLabel(.done)
        .onSubmit(commit)
      }
    } footer: {
      OnboardingPrimaryButton(title: String(localized: "onboarding.name.cta"), action: commit)
    }
  }

  private func commit() {
    if !trimmed.isEmpty {
      modelContext.insert(PrayerIntention(text: trimmed))
    }
    focused = false
    onNext()
  }
}

// MARK: - ⑤ Privacy page

private struct PrivacyPage: View {
  var onNext: () -> Void

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var appeared = Array(repeating: false, count: 3)

  private let points: [(icon: String, label: String, desc: String)] = [
    (
      "iphone", String(localized: "onboarding.privacy.local.label"),
      String(localized: "onboarding.privacy.local.desc")
    ),
    (
      "eye.slash", String(localized: "onboarding.privacy.private.label"),
      String(localized: "onboarding.privacy.private.desc")
    ),
    (
      "lock.fill", String(localized: "onboarding.privacy.you.label"),
      String(localized: "onboarding.privacy.you.desc")
    ),
  ]

  var body: some View {
    OnboardingScaffold {
      VStack(spacing: 56) {
        VStack(spacing: 24) {
          HeroSymbol(systemName: "lock.shield.fill", color: AppTheme.confessionBlue)

          VStack(spacing: 10) {
            Text("onboarding.privacy.title")
              .font(.system(.title, design: .serif).weight(.bold))
              .foregroundStyle(AppTheme.textPrimary)
              .multilineTextAlignment(.center)
              .frame(maxWidth: .infinity)

            Text("onboarding.privacy.subtitle")
              .font(.subheadline)
              .foregroundStyle(AppTheme.textTertiary)
              .multilineTextAlignment(.center)
              .frame(maxWidth: 300)
          }
        }

        VStack(spacing: 32) {
          ForEach(Array(points.enumerated()), id: \.offset) { index, point in
            PrivacyRow(icon: point.icon, label: point.label, desc: point.desc)
              .opacity(appeared[index] ? 1 : 0)
              .offset(y: appeared[index] ? 0 : 16)
          }
        }
        .padding(.horizontal, 32)
      }
    } footer: {
      OnboardingPrimaryButton(title: String(localized: "onboarding.name.cta"), action: onNext)
    }
    .onAppear(perform: animateIn)
  }

  private func animateIn() {
    guard !reduceMotion else {
      for index in appeared.indices { appeared[index] = true }
      return
    }
    for index in appeared.indices {
      withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2 + Double(index) * 0.18))
      {
        appeared[index] = true
      }
    }
  }
}

private struct PrivacyRow: View {
  let icon: String
  let label: String
  let desc: String

  var body: some View {
    HStack(spacing: 16) {
      Image(systemName: icon)
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(AppTheme.confessionBlue)
        .frame(width: 26, alignment: .center)

      VStack(alignment: .leading, spacing: 2) {
        Text(label)
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundStyle(AppTheme.textPrimary)

        Text(desc)
          .font(.caption)
          .foregroundStyle(AppTheme.textTertiary)
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer(minLength: 0)
    }
    .accessibilityElement(children: .combine)
  }
}

// MARK: - ⑥ Notifications page

private struct NotificationsPage: View {
  var onComplete: () -> Void

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var isRequesting = false
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
    OnboardingScaffold {
      VStack(spacing: 28) {
        ringingBell

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
            guard !reduceMotion else {
              cardAppeared = true
              return
            }
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
    } footer: {
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
    }
  }

  private var ringingBell: some View {
    ZStack {
      Circle()
        .fill(AppTheme.supplicationGreen.opacity(0.15))
        .frame(width: 120, height: 120)
        .blur(radius: 14)

      Image(systemName: "bell.circle.fill")
        .font(.system(size: 64))
        .foregroundStyle(AppTheme.supplicationGreen)
        .rotationEffect(.degrees(rang ? 14 : 0))
        .animation(.easeInOut(duration: 0.08), value: rang)
    }
    .accessibilityHidden(true)
    .onAppear {
      guard !reduceMotion else { return }
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
        Text("onboarding.notifications.mock.body")
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
