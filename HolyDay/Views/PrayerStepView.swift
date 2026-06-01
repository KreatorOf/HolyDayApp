//
//  PrayerStepView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import SwiftUI

struct PrayerStepView: View {
  let step: PrayerStep
  let isExpanded: Bool
  let isCompleted: Bool
  @Binding var prayerText: String
  var reflectionQuestions: [String] = []
  var intentions: [String] = []
  let onTap: () -> Void
  @State private var showReflection = false
  @State private var prayFeedbackToken = false
  let onPray: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      stepHeader
      if isExpanded {
        expandedContent
          .transition(
            .asymmetric(
              insertion: .opacity.combined(with: .move(edge: .top)),
              removal: .opacity.combined(with: .move(edge: .top))
            ))
      }
    }
    .background { cardBackground }
  }

  // MARK: Header

  private var stepHeader: some View {
    Button(action: onTap) {
      HStack(spacing: 16) {
        stepIcon
        stepTitle
        Spacer()
        Image(systemName: "chevron.down")
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(step.color)
          .rotationEffect(.degrees(isExpanded ? 180 : 0))
          .accessibilityHidden(true)
      }
      .padding(22)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .sensoryFeedback(.selection, trigger: isExpanded)
    .accessibilityLabel(stepAccessibilityLabel)
    .accessibilityHint(stepAccessibilityHint)
    .accessibilityAddTraits(isExpanded ? .isSelected : [])
  }

  private var stepAccessibilityLabel: String {
    let state: String
    if isCompleted {
      state = String(localized: "accessibility.step.completed")
    } else if isExpanded {
      state = String(localized: "accessibility.step.expanded")
    } else {
      state = String(localized: "accessibility.step.collapsed")
    }
    return "\(step.title) — \(state)"
  }

  private var stepAccessibilityHint: String {
    guard !isCompleted else { return "" }
    return isExpanded
      ? String(localized: "accessibility.step.hint.collapse")
      : String(localized: "accessibility.step.hint.expand")
  }

  private var stepIcon: some View {
    ZStack {
      Circle()
        .fill(step.color.opacity(isCompleted ? 0.2 : 0.12))
        .frame(width: 44, height: 44)
      Image(systemName: isCompleted ? "checkmark" : step.icon)
        .font(.system(size: 18, weight: isCompleted ? .bold : .semibold))
        .foregroundStyle(step.color)
        .transition(.scale.combined(with: .opacity))
    }
  }

  private var stepTitle: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(step.title)
        .font(.headline)
        .fontWeight(.semibold)
        .foregroundStyle(AppTheme.textPrimary)
        .strikethrough(isCompleted, color: AppTheme.textSecondary)
      if !isExpanded {
        Text(isCompleted ? "step.saved" : "step.tap.to.pray")
          .font(.caption2)
          .foregroundStyle(isCompleted ? step.color.opacity(0.8) : AppTheme.textTertiary)
      }
    }
  }

  // MARK: Expanded content

  private var expandedContent: some View {
    VStack(alignment: .leading, spacing: 18) {
      Rectangle()
        .fill(
          LinearGradient(
            colors: [step.color.opacity(0.5), step.color.opacity(0.1)],
            startPoint: .leading, endPoint: .trailing
          )
        )
        .frame(height: 1)
        .padding(.horizontal, 22)

      HStack(alignment: .bottom, spacing: 8) {
        Text(step.description)
          .font(.body)
          .foregroundStyle(AppTheme.textSecondary)
          .lineSpacing(8)

        if !reflectionQuestions.isEmpty {
          Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
              showReflection.toggle()
            }
          } label: {
            Image(systemName: showReflection ? "lightbulb.fill" : "lightbulb")
              .font(.callout)
              .foregroundStyle(step.color)
          }
          .buttonStyle(.plain)
          .sensoryFeedback(.selection, trigger: showReflection)
          .accessibilityLabel(String(localized: "accessibility.reflection.toggle"))
          .accessibilityHint(
            showReflection
              ? String(localized: "accessibility.reflection.hint.hide")
              : String(localized: "accessibility.reflection.hint.show")
          )
          .transition(.scale.combined(with: .opacity))
        }
      }
      .padding(.horizontal, 22)

      if showReflection {
        reflectionQuestionsView
      }

      if !intentions.isEmpty {
        intentionsView
      }

      prayerTextEditor

      if isCompleted {
        completedIndicator
      } else {
        prayerButton
      }
    }
    .onChange(of: isExpanded) { _, newValue in
      if !newValue { showReflection = false }
    }
  }

  // MARK: Reflection questions

  private var reflectionQuestionsView: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("step.reflection.title")
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(AppTheme.textTertiary)
        .textCase(.uppercase)
        .tracking(0.8)

      VStack(alignment: .leading, spacing: 8) {
        ForEach(reflectionQuestions, id: \.self) { question in
          HStack(alignment: .top, spacing: 8) {
            Circle()
              .fill(step.color.opacity(0.5))
              .frame(width: 5, height: 5)
              .padding(.top, 6)
            Text(question)
              .font(.subheadline)
              .foregroundStyle(AppTheme.textSecondary)
              .italic()
              .fixedSize(horizontal: false, vertical: true)
          }
        }
      }
    }
    .padding(.horizontal, 22)
    .padding(14)
    .background {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(step.color.opacity(0.06))
        .overlay {
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(step.color.opacity(0.2), lineWidth: 1)
        }
    }
    .padding(.horizontal, 22)
    .transition(.opacity.combined(with: .scale(scale: 0.97)))
  }

  // MARK: Intentions

  private var intentionsView: some View {
    VStack(spacing: 10) {
      Text("step.intentions.title")
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(AppTheme.textTertiary)
        .textCase(.uppercase)
        .tracking(0.8)

      VStack(spacing: 8) {
        ForEach(intentions, id: \.self) { intention in
          HStack(alignment: .top, spacing: 8) {
            Image(systemName: "hands.and.sparkles.fill")
              .font(.caption2)
              .foregroundStyle(step.color.opacity(0.7))
              .padding(.top, 2)
            Text(intention)
              .font(.subheadline)
              .foregroundStyle(AppTheme.textPrimary)
              .multilineTextAlignment(.center)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 22)
    .padding(14)
    .background {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(step.color.opacity(0.06))
        .overlay {
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(step.color.opacity(0.2), lineWidth: 1)
        }
    }
    .padding(.horizontal, 22)
  }

  // MARK: Text editor

  private var prayerTextEditor: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("step.prayer.title")
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(AppTheme.textTertiary)
        .textCase(.uppercase)
        .tracking(0.8)

      ZStack(alignment: .topLeading) {
        if prayerText.isEmpty {
          Text("step.prayer.placeholder")
            .font(.body)
            .foregroundStyle(AppTheme.textTertiary)
            .padding(.horizontal, 6)
            .padding(.vertical, 10)
            .allowsHitTesting(false)
        }
        TextEditor(text: $prayerText)
          .font(.body)
          .foregroundStyle(AppTheme.textPrimary)
          .scrollContentBackground(.hidden)
          .frame(minHeight: 90, maxHeight: 180)
          .disabled(isCompleted)
      }
      .padding(14)
      .background {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .fill(Color.white.opacity(0.04))
          .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .strokeBorder(
                step.color.opacity(isCompleted ? 0.15 : 0.3),
                lineWidth: 1
              )
          }
      }
    }
    .padding(.horizontal, 22)
  }

  // MARK: Buttons

  private var prayerButton: some View {
    let canPray = !prayerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    return Button {
      prayFeedbackToken.toggle()
      onPray()
    } label: {
      HStack(spacing: 10) {
        Image(systemName: "checkmark.circle")
          .font(.system(size: 18, weight: .semibold))
        Text("step.prayed")
          .font(.subheadline)
          .fontWeight(.bold)
          .tracking(0.3)
      }
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
      .background {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .fill(step.color)
          .shadow(color: step.color.opacity(canPray ? 0.4 : 0), radius: 8, x: 0, y: 4)
      }
    }
    .buttonStyle(.plain)
    .sensoryFeedback(.success, trigger: prayFeedbackToken)
    .disabled(!canPray)
    .opacity(canPray ? 1 : 0.35)
    .animation(.easeInOut(duration: 0.2), value: canPray)
    .padding(.horizontal, 22)
    .padding(.bottom, 22)
  }

  private var completedIndicator: some View {
    HStack(spacing: 10) {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 18, weight: .semibold))
      Text("step.prayed")
        .font(.subheadline)
        .fontWeight(.semibold)
    }
    .foregroundStyle(step.color)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 14)
    .background {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(step.color.opacity(0.12))
        .overlay {
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(step.color.opacity(0.35), lineWidth: 1.5)
        }
    }
    .padding(.horizontal, 22)
    .padding(.bottom, 22)
  }

  // MARK: Card background

  private var cardBackground: some View {
    ZStack {
      if isExpanded {
        LinearGradient(
          colors: [step.color.opacity(0.08), step.color.opacity(0.04)],
          startPoint: .topLeading, endPoint: .bottomTrailing
        )
      }
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .fill(.ultraThinMaterial)
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .strokeBorder(
          LinearGradient(
            colors: [
              step.color.opacity(isExpanded ? 0.5 : 0.2),
              step.color.opacity(isExpanded ? 0.2 : 0.1),
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
          ),
          lineWidth: isExpanded ? 2 : 1
        )
    }
    .shadow(color: AppTheme.premiumShadow, radius: 12, x: 0, y: 6)
    .shadow(color: step.color.opacity(isExpanded ? 0.25 : 0.08), radius: 20, x: 0, y: 10)
  }
}

#Preview {
  @Previewable @State var text0 = ""
  @Previewable @State var text1 = "Seigneur, je te loue pour ta grandeur infinie…"
  @Previewable @State var text2 = ""

  ZStack {
    AppBackground()
    VStack(spacing: 16) {
      PrayerStepView(
        step: PrayerStep.defaultSteps[0], isExpanded: false,
        isCompleted: false, prayerText: $text0, onTap: {}, onPray: {})
      PrayerStepView(
        step: PrayerStep.defaultSteps[1], isExpanded: true,
        isCompleted: false, prayerText: $text1,
        reflectionQuestions: [
          "Qu'est-ce qui vous a rappelé Sa présence cette semaine ?",
          "Y a-t-il une qualité de Dieu que vous voulez célébrer ?",
          "Quel moment de la journée vous a le plus touché ?",
        ],
        onTap: {}, onPray: {})
      PrayerStepView(
        step: PrayerStep.defaultSteps[2], isExpanded: false,
        isCompleted: true, prayerText: $text2, onTap: {}, onPray: {})
    }
    .padding()
  }
}
