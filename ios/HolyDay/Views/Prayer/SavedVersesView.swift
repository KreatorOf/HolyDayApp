import SwiftData
import SwiftUI

struct SavedVersesView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \SavedVerse.savedAt, order: .reverse) private var verses: [SavedVerse]

  var body: some View {
    NavigationStack {
      Group {
        if verses.isEmpty {
          ContentUnavailableView(
            "savedVerses.empty.title",
            systemImage: "bookmark",
            description: Text("savedVerses.empty.message")
          )
        } else {
          List {
            ForEach(verses) { verse in
              SavedVerseRow(verse: verse)
                .swipeActions {
                  Button("common.delete", systemImage: "trash", role: .destructive) {
                    modelContext.delete(verse)
                  }
                }
            }
          }
          .scrollContentBackground(.hidden)
        }
      }
      .background { AppBackground() }
      .navigationTitle("savedVerses.title")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) { AppCloseButton { dismiss() } }
      }
    }
  }
}

private struct SavedVerseRow: View {
  @Bindable var verse: SavedVerse

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("“\(verse.text)”")
        .font(.system(.body, design: .serif).italic())
        .foregroundStyle(AppTheme.textPrimary)
      Text(verse.reference)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(AppTheme.adorationPurple)
      TextField("savedVerses.note.placeholder", text: $verse.note, axis: .vertical)
        .lineLimit(1...4)
        .font(.subheadline)
    }
    .padding(.vertical, 8)
  }
}
