//
//  ContentView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PrayerGuideViewModel()
    @State private var streak = StreakService.shared
    @State private var showNavTitle = false
    @AppStorage("holyday.userName") private var userName = ""

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                            .padding(.horizontal, 16)

                        VerseCardView(verse: viewModel.verseOfTheDay)
                            .padding(.horizontal, 16)

                        prayerStepsSection(proxy: proxy)
                            .padding(.horizontal, 16)

                        if viewModel.isAllCompleted {
                            CompletionBanner()
                                .padding(.horizontal, 16)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.bottom, 20)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isAllCompleted)
                }
                .scrollIndicators(.hidden)
                .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { _, y in
                    withAnimation(.easeInOut(duration: 0.2)) { showNavTitle = y > 80 }
                }
            }
            .background { AnimatedMeshBackground() }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 0) {
                        Text("Holy")
                            .font(.system(.callout, design: .serif, weight: .bold).italic())
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Day")
                            .font(.system(.callout, design: .serif, weight: .thin))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .opacity(showNavTitle ? 1 : 0)
                }
            }
        }
    }

    // MARK: Header

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let base: String
        switch hour {
        case 5..<12: base = "Bonjour"
        case 12..<18: base = "Bon après-midi"
        default: base = "Bonsoir"
        }
        return userName.isEmpty ? base : "\(base), \(userName)"
    }

    private var headerSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .tracking(0.3)
                HStack(spacing: 0) {
                    Text("Holy")
                        .font(.system(size: 38, weight: .bold, design: .serif).italic())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Day")
                        .font(.system(size: 38, weight: .thin, design: .serif))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            Spacer()
            if streak.currentStreak > 0 {
                streakBadge
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: streak.currentStreak)
    }

    private var streakBadge: some View {
        VStack(spacing: 2) {
            Text("🔥")
                .font(.title2)
            Text("\(streak.currentStreak)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.thanksgivingGold)
            Text(streak.currentStreak > 1 ? "jours" : "jour")
                .font(.caption2)
                .foregroundStyle(AppTheme.textTertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(AppTheme.thanksgivingGold.opacity(0.3), lineWidth: 1)
                }
        }
    }

    // MARK: Sections

    private func prayerStepsSection(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Guide de prière")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.textTertiary)
                    .textCase(.uppercase)
                    .tracking(1.0)
                Spacer()
                if !viewModel.completedSteps.isEmpty {
                    progressRing
                        .transition(.opacity.combined(with: .scale))
                }
            }

            VStack(spacing: 10) {
                ForEach(viewModel.prayerSteps) { step in
                    PrayerStepView(
                        step: step,
                        isExpanded: viewModel.isExpanded(step),
                        isCompleted: viewModel.isCompleted(step),
                        prayerText: prayerTextBinding(for: step),
                        reflectionQuestions: viewModel.reflectionQuestions[step.id, default: []],
                        onTap: { onStepTap(step, proxy: proxy) },
                        onPray: { viewModel.save(step: step, in: modelContext) }
                    )
                    .id(step.id)
                    .scrollTransition { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1 : 0.65)
                            .scaleEffect(phase.isIdentity ? 1 : 0.97)
                    }
                }
            }
        }
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.confessionBlue.opacity(0.2), lineWidth: 3)
                .frame(width: 28, height: 28)
            Circle()
                .trim(from: 0, to: viewModel.progressPercentage)
                .stroke(
                    viewModel.isAllCompleted ? Color.green : AppTheme.confessionBlue,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 28, height: 28)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.progressPercentage)
            Text("\(viewModel.completedSteps.count)")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(viewModel.isAllCompleted ? .green : AppTheme.confessionBlue)
        }
    }

    // MARK: Helpers

    private func prayerTextBinding(for step: PrayerStep) -> Binding<String> {
        Binding(
            get: { viewModel.prayerTexts[step.id, default: ""] },
            set: { viewModel.prayerTexts[step.id] = $0 }
        )
    }

    private func onStepTap(_ step: PrayerStep, proxy: ScrollViewProxy) {
        let wasExpanded = viewModel.isExpanded(step)
        viewModel.toggleStep(step)
        if !wasExpanded {
            Task {
                try? await Task.sleep(for: .milliseconds(150))
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    proxy.scrollTo(step.id, anchor: .top)
                }
            }
            if viewModel.reflectionQuestions[step.id] == nil, AIAssistantService.shared.isAvailable {
                Task { await generateQuestions(for: step) }
            }
        }
    }

    private func generateQuestions(for step: PrayerStep) async {
        do {
            let questions = try await AIAssistantService.shared.generateReflectionQuestions(for: step)
            withAnimation(.easeInOut(duration: 0.4)) {
                viewModel.reflectionQuestions[step.id] = questions
            }
        } catch {
            // silent — no questions shown, user still prays freely
        }
    }
}

// MARK: Completion banner

private struct CompletionBanner: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("Prière complétée")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Votre journal a été mis à jour.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.green.opacity(0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.green.opacity(0.25), lineWidth: 1)
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: PrayerEntry.self, inMemory: true)
        .preferredColorScheme(.dark)
}
