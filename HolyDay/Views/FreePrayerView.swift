//
//  FreePrayerView.swift
//  HolyDay
//
//  Created by Matthias Cadet on 31/05/2026.
//

import SwiftData
import SwiftUI

struct FreePrayerView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @State private var text = ""
  @FocusState private var isFocused: Bool

  private var canSave: Bool {
    !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    NavigationStack {
      ZStack {
        AnimatedMeshBackground().ignoresSafeArea()
        contentLayer
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(role: .cancel) { dismiss() }
        }
        ToolbarItem(placement: .principal) {
          Text("prayer.free.nav.title")
            .font(.system(.callout, design: .serif, weight: .bold))
            .foregroundStyle(AppTheme.textPrimary)
        }
      }
      .toolbarBackground(.hidden, for: .navigationBar)
    }
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
        isFocused = true
      }
    }
  }

  // MARK: - Content

  private var contentLayer: some View {
    VStack(spacing: 0) {
      ZStack(alignment: .topLeading) {
        if text.isEmpty {
          Text("prayer.free.placeholder")
            .font(.body)
            .foregroundStyle(AppTheme.textTertiary)
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .allowsHitTesting(false)
        }
        TextEditor(text: $text)
          .font(.body)
          .foregroundStyle(AppTheme.textPrimary)
          .scrollContentBackground(.hidden)
          .padding(.horizontal, 16)
          .focused($isFocused)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)

      Button {
        save()
      } label: {
        Text("prayer.free.amen")
          .font(.system(.body, design: .serif, weight: .bold))
          .tracking(1.5)
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .fill(canSave ? AppTheme.adorationPurple : AppTheme.textTertiary.opacity(0.4))
          }
      }
      .buttonStyle(.plain)
      .disabled(!canSave)
      .animation(.easeInOut(duration: 0.2), value: canSave)
      .padding(.horizontal, 20)
      .padding(.bottom, 32)
    }
    .padding(.top, 8)
  }

  // MARK: - Helpers

  private func save() {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    let entry = PrayerEntry(
      stepTitle: String(localized: "prayer.free.title"),
      stepIcon: "square.and.pencil",
      stepColorName: "adorationPurple",
      text: trimmed
    )
    modelContext.insert(entry)
    StreakService.shared.recordPrayer()
    dismiss()
  }
}
