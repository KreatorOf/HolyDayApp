//
//  NextVerseIntent.swift
//  HolyDayWidget
//

import AppIntents
import SwiftUI
import WidgetKit

/// « Un autre verset » : avance dans le thème du jour sans ouvrir l'app. S'exécute dans
/// l'extension ; WidgetKit recharge les timelines une fois `perform` terminé.
struct NextVerseIntent: AppIntent {
  static let title: LocalizedStringResource = "widget.verse.next"
  static let isDiscoverable = false

  func perform() async throws -> some IntentResult {
    SharedStore.incrementVerseSkip()
    return .result()
  }
}

struct NextVerseButton: View {
  @Environment(\.widgetRenderingMode) private var renderingMode

  var body: some View {
    let palette = WidgetTheme.Palette(renderingMode)
    Button(intent: NextVerseIntent()) {
      Image(systemName: "arrow.clockwise")
        .font(.caption2.weight(.semibold))
        .foregroundStyle(palette.secondary)
        .frame(width: 26, height: 26)
        .background(Circle().fill(WidgetTheme.separator))
        // Zone de tap plus large que la pastille, sans alourdir le visuel.
        .padding(6)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .padding(-6)
    .accessibilityLabel(Text("widget.verse.next"))
  }
}
