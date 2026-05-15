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
    @Query(sort: \PrayerEntry.date) private var allEntries: [PrayerEntry]
    @State private var stepsAppeared = false
    @State private var topInset: CGFloat = 100

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                            .padding(.horizontal, 16)
                            .padding(.top, topInset + 44 + 12)

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
                .ignoresSafeArea(.all, edges: .top)
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
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { topInset = geo.safeAreaInsets.top }
            }
            .ignoresSafeArea()
        )
    }

    // MARK: Header

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let base: String
        switch hour {
        case 5..<12: base = NSLocalizedString("greeting.morning", comment: "")
        case 12..<18: base = NSLocalizedString("greeting.afternoon", comment: "")
        default: base = NSLocalizedString("greeting.evening", comment: "")
        }
        return userName.isEmpty ? base : "\(base), \(userName)"
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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

            weeklyCalendar
        }
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
                ForEach(Array(viewModel.prayerSteps.enumerated()), id: \.element.id) { index, step in
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
                    .offset(y: stepsAppeared ? 0 : 18)
                    .opacity(stepsAppeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.85).delay(Double(index) * 0.07),
                        value: stepsAppeared
                    )
                    .scrollTransition { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1 : 0.65)
                            .scaleEffect(phase.isIdentity ? 1 : 0.97)
                    }
                }
            }
            .onAppear { stepsAppeared = true }
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

// MARK: Date & weekly calendar

extension ContentView {
    private static let todayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "EEEE d MMMM"
        return f
    }()

    private static let dayLetterFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "EEEEE"
        return f
    }()

    var todayFormatted: String {
        let s = Self.todayFormatter.string(from: Date())
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    var prayedDays: Set<Date> {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: Date())) ?? Date()
        return Set(allEntries
            .filter { $0.date >= cutoff }
            .map { calendar.startOfDay(for: $0.date) })
    }

    var weeklyCalendar: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // weekday: 1=dim, 2=lun, ..., 7=sam → offset pour revenir au lundi
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
        return HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { i in
                let date = calendar.date(byAdding: .day, value: i, to: monday) ?? monday
                let isToday = calendar.startOfDay(for: date) == today
                let hasPrayer = prayedDays.contains(calendar.startOfDay(for: date))
                VStack(spacing: 5) {
                    Text(Self.dayLetterFormatter.string(from: date).uppercased())
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(isToday ? AppTheme.textSecondary : AppTheme.textTertiary)
                    ZStack {
                        Circle()
                            .fill(hasPrayer ? AppTheme.thanksgivingGold.opacity(0.9) : Color.white.opacity(0.07))
                        if isToday && !hasPrayer {
                            Circle()
                                .strokeBorder(AppTheme.thanksgivingGold.opacity(0.45), lineWidth: 1.5)
                        }
                        if hasPrayer {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.black)
                        }
                    }
                    .frame(width: 30, height: 30)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                }
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
