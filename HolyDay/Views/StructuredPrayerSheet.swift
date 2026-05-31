//
//  StructuredPrayerSheet.swift
//  HolyDay
//
//  Created by Matthias Cadet on 31/05/2026.
//

import FoundationModels
import SwiftData
import SwiftUI

struct StructuredPrayerSheet: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @Query(sort: \PrayerEntry.date, order: .reverse) private var entries: [PrayerEntry]
  @Query(
    filter: #Predicate<PrayerIntention> { !$0.isAnswered }, sort: \PrayerIntention.createdAt,
    order: .reverse)
  private var activeIntentions: [PrayerIntention]
  @State private var viewModel = PrayerGuideViewModel()
  @State private var tipService = TipService.shared
  @State private var stepsAppeared = false

  var body: some View {
    NavigationStack {
      ScrollViewReader { proxy in
        ScrollView {
          VStack(spacing: 16) {
            stepsSection(proxy: proxy)
              .padding(.horizontal, 16)

            if viewModel.isAllCompleted {
              completionView
                .padding(.horizontal, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
          }
          .padding(.top, 24)
          .padding(.bottom, 48)
          .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isAllCompleted)
        }
        .scrollIndicators(.hidden)
      }
      .background { AnimatedMeshBackground().ignoresSafeArea() }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(role: .cancel) { dismiss() }
        }
        ToolbarItem(placement: .principal) {
          Text("prayer.structured.title")
            .font(.headline)
            .foregroundStyle(AppTheme.textPrimary)
        }
      }
      .toolbarBackground(.hidden, for: .navigationBar)
    }
  }

  // MARK: - Steps

  private func stepsSection(proxy: ScrollViewProxy) -> some View {
    VStack(spacing: 10) {
      ForEach(Array(viewModel.prayerSteps.enumerated()), id: \.element.id) { index, step in
        PrayerStepView(
          step: step,
          isExpanded: viewModel.isExpanded(step),
          isCompleted: viewModel.isCompleted(step),
          prayerText: prayerTextBinding(for: step),
          reflectionQuestions: viewModel.reflectionQuestions[step.id, default: []],
          intentions: intentions(for: step),
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

  // MARK: - Completion

  private var completionView: some View {
    VStack(spacing: 16) {
      Image(systemName: "hands.sparkles.fill")
        .font(.system(size: 36))
        .foregroundStyle(AppTheme.adorationPurple)

      Text("content.completion.title")
        .font(.system(.title3, design: .serif, weight: .semibold))
        .foregroundStyle(AppTheme.textPrimary)
        .multilineTextAlignment(.center)

      Text("content.completion.subtitle")
        .font(.subheadline)
        .foregroundStyle(AppTheme.textSecondary)
        .multilineTextAlignment(.center)

      Button {
        dismiss()
      } label: {
        Text("prayer.structured.finish")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(AppTheme.adorationPurple)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
          .background(
            AppTheme.adorationPurple.opacity(0.12),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
          )
      }
      .buttonStyle(.plain)
    }
    .padding(20)
    .background {
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .fill(.ultraThinMaterial)
        .overlay {
          RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(AppTheme.cardStroke, lineWidth: 1)
        }
    }
  }

  // MARK: - Helpers

  // Active intentions surface only in the Supplication step, where the user lifts them up.
  private func intentions(for step: PrayerStep) -> [String] {
    guard step.colorName == "supplicationGreen" else { return [] }
    return activeIntentions.map(\.text)
  }

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
      if viewModel.reflectionQuestions[step.id] == nil {
        Task { await generateQuestions(for: step) }
      }
    }
  }

  private func generateQuestions(for step: PrayerStep) async {
    guard tipService.hasAIFeature else { return }
    do {
      let questions = try await AIAssistantService.shared.generateReflectionQuestions(
        for: step,
        recentEntries: Array(entries.prefix(30))
      )
      withAnimation(.easeInOut(duration: 0.4)) {
        viewModel.reflectionQuestions[step.id] = questions
      }
    } catch {
      // silent — reflection questions are optional
    }
  }
}
