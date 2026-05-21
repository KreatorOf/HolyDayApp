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
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding(.leading, 20)
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: currentPage > 0)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            pageIndicator.padding(.vertical, 12)
        }
        .preferredColorScheme(.dark)
    }

    private var slideTransition: AnyTransition {
        goingForward
            ? .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal:   .move(edge: .leading).combined(with: .opacity)
              )
            : .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal:   .move(edge: .trailing).combined(with: .opacity)
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
    Feature(icon: "book.pages",     label: String(localized: "onboarding.feature.verse.label"),    description: String(localized: "onboarding.feature.verse.desc"),    color: AppTheme.thanksgivingGold),
    Feature(icon: "hands.sparkles", label: String(localized: "onboarding.feature.prayer.label"),   description: String(localized: "onboarding.feature.prayer.desc"),   color: AppTheme.adorationPurple),
    Feature(icon: "calendar",       label: String(localized: "onboarding.feature.journal.label"),  description: String(localized: "onboarding.feature.journal.desc"),  color: AppTheme.confessionBlue),
    Feature(icon: "bell",           label: String(localized: "onboarding.feature.reminders.label"),description: String(localized: "onboarding.feature.reminders.desc"),color: AppTheme.supplicationGreen),
]

// MARK: - Welcome page

private struct WelcomePage: View {
    var onNext: () -> Void
    @State private var breathe = false
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                Image(systemName: "sun.horizon.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AppTheme.thanksgivingGold)
                    .scaleEffect(breathe ? 1.06 : 0.94)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                            breathe = true
                        }
                    }

                VStack(spacing: 6) {
                    HStack(spacing: 0) {
                        Text("Holy")
                            .font(.system(size: 48, weight: .bold, design: .serif).italic())
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Day")
                            .font(.system(size: 48, weight: .thin, design: .serif))
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
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 14)
                            .animation(
                                .easeOut(duration: 0.4).delay(0.15 + Double(index) * 0.3),
                                value: appeared
                            )
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                appeared = true
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
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.09), lineWidth: 1)
                }
        }
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
                        .fill(
                            RadialGradient(
                                colors: [AppTheme.thanksgivingGold.opacity(0.25), .clear],
                                center: .center,
                                startRadius: 8,
                                endRadius: 64
                            )
                        )
                        .frame(width: 140, height: 140)
                        .blur(radius: 12)
                        .scaleEffect(breathe ? 1.15 : 0.9)

                    Image(systemName: "hands.sparkles.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.thanksgivingGold, AppTheme.thanksgivingGold.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(breathe ? 1.05 : 0.97)
                        .shadow(color: AppTheme.thanksgivingGold.opacity(0.4), radius: 16, x: 0, y: 4)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                        breathe = true
                    }
                }

                VStack(spacing: 10) {
                    Text("onboarding.name.title")
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("onboarding.name.subtitle")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }

                TextField("", text: $nameInput, prompt: Text("onboarding.name.placeholder").foregroundStyle(AppTheme.textTertiary))
                    .font(.title2)
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .focused($focused)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(
                                        focused ? AppTheme.thanksgivingGold.opacity(0.6) : Color.white.opacity(0.12),
                                        lineWidth: 1
                                    )
                            }
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

    private var reassurances: [(icon: String, text: String)] {[
        ("1.circle",    String(localized: "onboarding.notifications.pill.frequency")),
        ("clock",       String(localized: "onboarding.notifications.pill.timing")),
        ("hand.raised", String(localized: "onboarding.notifications.pill.control")),
    ]}

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                Image(systemName: "bell.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AppTheme.supplicationGreen)

                VStack(spacing: 10) {
                    Text("onboarding.notifications.title")
                        .font(.system(size: 30, weight: .bold, design: .serif))
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

                HStack(spacing: 8) {
                    ForEach(reassurances, id: \.icon) { item in
                        ReassurancePill(icon: item.icon, text: item.text)
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            VStack(spacing: 14) {
                OnboardingPrimaryButton(title: String(localized: "onboarding.notifications.cta"), isLoading: isRequesting) {
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
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(AppTheme.supplicationGreen.opacity(0.2), lineWidth: 1)
                }
        }
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
            .background(AppTheme.thanksgivingGold.opacity(isEnabled ? 1 : 0.4))
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
        .disabled(!isEnabled || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
