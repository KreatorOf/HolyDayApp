//
//  ContentView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import SwiftData
import SwiftUI

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \PrayerEntry.date, order: .reverse) private var entries: [PrayerEntry]
  @State private var viewModel = PrayerGuideViewModel()
  @State private var streak = StreakService.shared
  @State private var showNavTitle = false
  @State private var showHeatmap = false
  @State private var showCelebration = false
  @State private var celebrationValue: Int = 0
  @AppStorage("holyday.userName") private var userName = ""
  @State private var stepsAppeared = false
  @State private var topInset: CGFloat = 100

  var body: some View {
    NavigationStack {
      ScrollViewReader { proxy in
        ScrollView {
          VStack(spacing: 20) {
            headerSection
              .padding(.horizontal, 16)
              .padding(.top, topInset + 44 + 50)

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
        .onScrollGeometryChange(for: CGFloat.self) {
          $0.contentOffset.y
        } action: { _, y in
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
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            showHeatmap = true
          } label: {
            HStack(spacing: 4) {
              Image(systemName: "flame.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(streak.currentStreak > 0 ? Color.orange : Color.white.opacity(0.3))
              Text("\(streak.currentStreak)")
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(streak.currentStreak)))
                .animation(.spring(response: 0.35), value: streak.currentStreak)
              if streak.freezesAvailable > 0 {
                Image(systemName: "shield.fill")
                  .font(.caption2)
                  .foregroundStyle(AppTheme.confessionBlue.opacity(0.85))
              }
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .glassEffect(
              .regular.tint(
                streak.isStreakAtRisk
                  ? Color.orange.opacity(0.30)
                  : Color.white.opacity(streak.currentStreak > 0 ? 0.05 : 0.02)
              ),
              in: Capsule()
            )
          }
          .buttonStyle(.plain)
          .sensoryFeedback(.selection, trigger: showHeatmap)
          .accessibilityLabel(streakAccessibilityLabel)
          .accessibilityHint(String(localized: "accessibility.streak.hint"))
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
    .sheet(isPresented: $showHeatmap) {
      StreakYearHeatmapView(streak: streak)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    .fullScreenCover(isPresented: $showCelebration) {
      StreakCelebrationView(streakValue: celebrationValue)
        .presentationBackground(.clear)
    }
    .onChange(of: streak.lastIncrementToken) { _, newToken in
      guard newToken != nil else { return }
      celebrationValue = streak.lastIncrementValue
      showCelebration = true
    }
  }

  // MARK: Accessibility

  private var streakAccessibilityLabel: String {
    if streak.currentStreak == 0 {
      return String(localized: "accessibility.streak.zero")
    }
    if streak.isStreakAtRisk {
      return String(
        format: String(localized: "accessibility.streak.atrisk"), streak.currentStreak)
    }
    return String(format: String(localized: "accessibility.streak.label"), streak.currentStreak)
  }

  // MARK: Header

  private var greeting: String {
    let hour = Calendar.current.component(.hour, from: Date())
    let base: String
    switch hour {
    case 5..<12: base = String(localized: "greeting.morning")
    case 12..<18: base = String(localized: "greeting.afternoon")
    default: base = String(localized: "greeting.evening")
    }
    return userName.isEmpty ? base : "\(base), \(userName)"
  }

  private var headerSection: some View {
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
      #if DEBUG
        .onTapGesture(count: 3) {
          streak.resetTodaysPrayer()
          viewModel.resetProgress()
          UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
      #endif
    }
  }

  // MARK: Sections

  private func prayerStepsSection(proxy: ScrollViewProxy) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("content.prayer.guide.title")
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
        .animation(
          .spring(response: 0.5, dampingFraction: 0.8), value: viewModel.progressPercentage)
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
      let questions = try await AIAssistantService.shared.generateReflectionQuestions(
        for: step,
        recentEntries: Array(entries.prefix(30))
      )
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
        Text("content.completion.title")
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundStyle(AppTheme.textPrimary)
        Text("content.completion.subtitle")
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
