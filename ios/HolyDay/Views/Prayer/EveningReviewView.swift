import SwiftData
import SwiftUI

struct EveningReviewView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @State private var emotion: Emotion?
  @State private var gratitude = ""
  @State private var difficulty = ""
  @State private var tomorrow = ""

  private var canSave: Bool {
    !gratitude.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      || !difficulty.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      || !tomorrow.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("eveningReview.feeling") {
          ScrollView(.horizontal) {
            HStack(spacing: 10) {
              ForEach(Emotion.allCases) { item in
                Button {
                  emotion = item
                } label: {
                  Label(item.titleKey, systemImage: item.icon)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                      emotion == item ? item.pastel.opacity(0.3) : AppTheme.cardSurface,
                      in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(emotion == item ? .isSelected : [])
              }
            }
          }
          .scrollIndicators(.hidden)
        }
        reviewSection("eveningReview.gratitude", text: $gratitude)
        reviewSection("eveningReview.difficulty", text: $difficulty)
        reviewSection("eveningReview.tomorrow", text: $tomorrow)
      }
      .scrollContentBackground(.hidden)
      .background { AppBackground() }
      .navigationTitle("eveningReview.title")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { AppCloseButton { dismiss() } }
        ToolbarItem(placement: .confirmationAction) {
          Button("eveningReview.save") { save() }
            .fontWeight(.semibold)
            .disabled(!canSave)
        }
      }
    }
  }

  private func reviewSection(_ title: LocalizedStringKey, text: Binding<String>) -> some View {
    Section(title) {
      TextField("eveningReview.placeholder", text: text, axis: .vertical)
        .lineLimit(2...6)
    }
  }

  private func save() {
    let parts = [
      formattedPart(label: String(localized: "eveningReview.gratitude"), value: gratitude),
      formattedPart(label: String(localized: "eveningReview.difficulty"), value: difficulty),
      formattedPart(label: String(localized: "eveningReview.tomorrow"), value: tomorrow),
    ].compactMap { $0 }
    let entry = PrayerEntry(
      stepTitle: String(localized: "eveningReview.title"),
      stepIcon: "moon.stars.fill",
      stepColorName: "confessionBlue",
      text: parts.joined(separator: "\n\n"),
      emotion: emotion
    )
    modelContext.insert(entry)
    PrayerRecordService.shared.recordPrayer()
    NotificationService.shared.refreshScheduledReminders()
    WidgetSyncService.sync()
    dismiss()
  }

  private func formattedPart(label: String, value: String) -> String? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : "\(label)\n\(trimmed)"
  }
}
