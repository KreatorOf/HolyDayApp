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
    @AppStorage("holyday.userName") private var storedName = ""
    @State private var nameInput = ""

    var body: some View {
        ZStack {
            AnimatedMeshBackground()

            TabView(selection: $currentPage) {
                WelcomePage { withAnimation(.spring(response: 0.5)) { currentPage = 1 } }
                    .tag(0)

                NamePage(nameInput: $nameInput) {
                    storedName = nameInput.trimmingCharacters(in: .whitespaces)
                    withAnimation(.spring(response: 0.5)) { currentPage = 2 }
                }
                .tag(1)

                NotificationsPage(onComplete: onComplete)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            pageIndicator.padding(.vertical, 12)
        }
        .preferredColorScheme(.dark)
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

// MARK: - Welcome page

private struct WelcomePage: View {
    var onNext: () -> Void
    @State private var breathe = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "sun.horizon.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(AppTheme.thanksgivingGold)
                    .scaleEffect(breathe ? 1.06 : 0.94)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                            breathe = true
                        }
                    }

                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        Text("Holy")
                            .font(.system(size: 52, weight: .bold, design: .serif).italic())
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Day")
                            .font(.system(size: 52, weight: .thin, design: .serif))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Text("Guidez chaque journée\npar la prière")
                        .font(.body)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                }
            }

            Spacer()

            OnboardingPrimaryButton(title: "Commencer", action: onNext)
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
        }
    }
}

// MARK: - Name page

private struct NamePage: View {
    @Binding var nameInput: String
    var onNext: () -> Void
    @FocusState private var focused: Bool

    private var greetingPreview: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let base: String
        switch hour {
        case 5..<12: base = NSLocalizedString("greeting.morning", comment: "")
        case 12..<18: base = NSLocalizedString("greeting.afternoon", comment: "")
        default: base = NSLocalizedString("greeting.evening", comment: "")
        }
        return "\(base), \(nameInput.trimmingCharacters(in: .whitespaces))"
    }

    private var trimmedName: String { nameInput.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 36) {
                VStack(spacing: 10) {
                    Text("Comment vous\nappeler-vous ?")
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Votre prénom apparaîtra sur l'écran d'accueil")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }

                TextField("", text: $nameInput, prompt: Text("Votre prénom").foregroundStyle(AppTheme.textTertiary))
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
                    .onSubmit { if !trimmedName.isEmpty { onNext() } }

                if !trimmedName.isEmpty {
                    Text(greetingPreview)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }

            Spacer()

            OnboardingPrimaryButton(
                title: "Continuer",
                isEnabled: !trimmedName.isEmpty,
                action: onNext
            )
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
        .onAppear { focused = true }
    }
}

// MARK: - Notifications page

private struct NotificationsPage: View {
    var onComplete: () -> Void
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                VStack(spacing: 14) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(AppTheme.thanksgivingGold)

                    Text("Rappel quotidien")
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Recevez une notification chaque matin\npour commencer votre journée en prière.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                }
            }

            Spacer()

            VStack(spacing: 14) {
                OnboardingPrimaryButton(title: "Activer les rappels", isLoading: isRequesting) {
                    isRequesting = true
                    Task { @MainActor in
                        await NotificationService.shared.setReminder(enabled: true)
                        onComplete()
                    }
                }

                Button("Peut-être plus tard") { onComplete() }
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
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
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(!isEnabled || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
