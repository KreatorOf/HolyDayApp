//
//  PrayerGuideViewModel.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class PrayerGuideViewModel {
  var prayerSteps: [PrayerStep]
  var expandedStepId: UUID?
  var completedSteps: Set<UUID> = []
  var prayerTexts: [UUID: String] = [:]
  var reflectionQuestions: [UUID: [String]] = [:]

  private var stepOpenedAt: [UUID: Date] = [:]

  init() {
    self.prayerSteps = PrayerStep.defaultSteps
  }

  func toggleStep(_ step: PrayerStep) {
    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
      if expandedStepId != step.id {
        stepOpenedAt[step.id] = Date()
      }
      expandedStepId = expandedStepId == step.id ? nil : step.id
    }
  }

  func isExpanded(_ step: PrayerStep) -> Bool {
    expandedStepId == step.id
  }

  func save(step: PrayerStep, in context: ModelContext) {
    let text = prayerTexts[step.id, default: ""]
    let duration = stepOpenedAt[step.id].map { Date().timeIntervalSince($0) } ?? 0
    let entry = PrayerEntry(
      stepTitle: step.title,
      stepIcon: step.icon,
      stepColorName: step.colorName,
      text: text,
      duration: duration
    )
    context.insert(entry)
    markCompleted(step)
    if isAllCompleted {
      PrayerRecordService.shared.recordPrayer()
    }
    WidgetSyncService.sync()
  }

  func markCompleted(_ step: PrayerStep) {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
      completedSteps.insert(step.id)
      expandedStepId = nil
    }
  }

  func isCompleted(_ step: PrayerStep) -> Bool {
    completedSteps.contains(step.id)
  }

  func resetProgress() {
    withAnimation {
      completedSteps.removeAll()
      expandedStepId = nil
      prayerTexts.removeAll()
    }
  }

  var progressPercentage: Double {
    guard !prayerSteps.isEmpty else { return 0 }
    return Double(completedSteps.count) / Double(prayerSteps.count)
  }

  var isAllCompleted: Bool {
    !prayerSteps.isEmpty && completedSteps.count == prayerSteps.count
  }
}
