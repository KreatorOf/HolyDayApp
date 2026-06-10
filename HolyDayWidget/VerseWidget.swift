//
//  VerseWidget.swift
//  HolyDayWidget
//

import SwiftUI
import WidgetKit

// MARK: - Timeline

/// « Mon verset » : le dernier verset reçu via le ruban d'émotions (cf. `SharedStore.lastVerse`).
/// Le `kind` reste "VerseWidget" (ex-verset du jour) pour que les widgets déjà posés migrent en
/// place au lieu de disparaître de l'écran d'accueil.
struct VerseEntry: TimelineEntry, Sendable {
  let date: Date
  let verse: SharedVerse?

  var accentColor: Color {
    WidgetTheme.accent(forEmotionTag: verse?.emotionTag ?? "")
  }

  var emotionIcon: String {
    WidgetTheme.icon(forEmotionTag: verse?.emotionTag ?? "")
  }

  var accessibilityText: String {
    guard let verse else { return String(localized: "widget.verse.empty") }
    return "\(verse.text) — \(verse.reference)"
  }
}

struct VerseTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> VerseEntry {
    VerseEntry(date: .now, verse: WidgetPreviewData.sampleVerse())
  }

  func getSnapshot(in context: Context, completion: @escaping @Sendable (VerseEntry) -> Void) {
    // Galerie de widgets : montrer un verset d'exemple plutôt que l'état vide.
    let verse =
      SharedStore.lastVerse ?? (context.isPreview ? WidgetPreviewData.sampleVerse() : nil)
    completion(VerseEntry(date: .now, verse: verse))
  }

  func getTimeline(
    in context: Context, completion: @escaping @Sendable (Timeline<VerseEntry>) -> Void
  ) {
    // Pas d'échéance calendaire : le contenu ne change que lorsque l'app publie un nouveau
    // verset, et elle recharge alors les timelines (WidgetSyncService.updateLastVerse).
    let entry = VerseEntry(date: .now, verse: SharedStore.lastVerse)
    completion(Timeline(entries: [entry], policy: .never))
  }
}

// MARK: - Shared pieces

private struct VerseHeader: View {
  @Environment(\.widgetRenderingMode) private var renderingMode
  let entry: VerseEntry
  var kicker: LocalizedStringKey?

  var body: some View {
    let palette = WidgetTheme.Palette(renderingMode)
    HStack(spacing: 5) {
      Image(systemName: entry.emotionIcon)
        .font(.caption2)
        .foregroundStyle(entry.accentColor)
        .widgetAccentable()
      if let kicker {
        Text(kicker)
          .font(.caption2.weight(.semibold))
          .foregroundStyle(palette.tertiary)
          .textCase(.uppercase)
          .tracking(1)
      } else {
        Text(verbatim: "HolyDay")
          .font(.caption2.weight(.semibold))
          .fontDesign(.serif)
          .foregroundStyle(palette.tertiary)
      }
      Spacer(minLength: 0)
    }
  }
}

private struct VerseReferenceRow: View {
  let reference: String
  let accent: Color
  var prominent = false

  var body: some View {
    HStack(spacing: 4) {
      Circle()
        .fill(accent)
        .frame(width: prominent ? 5 : 4, height: prominent ? 5 : 4)
      Text(reference)
        .font((prominent ? Font.callout : .caption).weight(.bold))
        .fontDesign(.serif)
        .foregroundStyle(accent)
    }
    .widgetAccentable()
  }
}

/// Invitation douce, jamais une injonction : cohérent avec la philosophie de l'app.
private struct VerseEmptyView: View {
  @Environment(\.widgetRenderingMode) private var renderingMode
  var compact = false

  var body: some View {
    let palette = WidgetTheme.Palette(renderingMode)
    VStack(alignment: .leading, spacing: 8) {
      Image(systemName: "hands.sparkles.fill")
        .font(compact ? .footnote : .body)
        .foregroundStyle(WidgetTheme.violet)
        .widgetAccentable()
      Text("widget.verse.empty")
        .font((compact ? Font.caption : .footnote).weight(.medium))
        .fontDesign(.serif)
        .foregroundStyle(palette.secondary)
        .lineSpacing(3)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }
}

// MARK: - Small view

private struct VerseWidgetSmallView: View {
  @Environment(\.widgetRenderingMode) private var renderingMode
  let entry: VerseEntry

  var body: some View {
    let palette = WidgetTheme.Palette(renderingMode)
    VStack(alignment: .leading, spacing: 0) {
      VerseHeader(entry: entry)

      if let verse = entry.verse {
        Spacer(minLength: 6)

        // Deux compositions plutôt qu'un minimumScaleFactor : les versets courts gardent une
        // taille confortable, les longs passent en caption au lieu d'être tronqués.
        ViewThatFits(in: .vertical) {
          verseText(verse.text, font: .footnote, palette: palette)
          verseText(verse.text, font: .caption, palette: palette)
        }
        .contentTransition(.opacity)

        Spacer(minLength: 6)

        VerseReferenceRow(reference: verse.reference, accent: entry.accentColor)
      } else {
        VerseEmptyView(compact: true)
          .padding(.top, 8)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(entry.accessibilityText)
    .containerBackground(for: .widget) {
      WidgetTheme.nightBackground(accent: entry.accentColor)
    }
  }

  private func verseText(_ text: String, font: Font, palette: WidgetTheme.Palette) -> some View {
    Text(text)
      .font(font.weight(.medium))
      .fontDesign(.serif)
      .foregroundStyle(palette.primary)
      .lineSpacing(3)
  }
}

// MARK: - Medium view

private struct VerseWidgetMediumView: View {
  @Environment(\.widgetRenderingMode) private var renderingMode
  let entry: VerseEntry

  var body: some View {
    let palette = WidgetTheme.Palette(renderingMode)
    HStack(spacing: 0) {
      RoundedRectangle(cornerRadius: 2)
        .fill(entry.accentColor)
        .frame(width: 3)
        .padding(.vertical, 2)
        .widgetAccentable()

      VStack(alignment: .leading, spacing: 10) {
        VerseHeader(entry: entry, kicker: "widget.verse.kicker")

        if let verse = entry.verse {
          Text(verse.text)
            .font(.footnote.weight(.medium))
            .fontDesign(.serif)
            .foregroundStyle(palette.primary)
            .lineSpacing(4)
            .lineLimit(3)
            .contentTransition(.opacity)

          VerseReferenceRow(reference: verse.reference, accent: entry.accentColor)
        } else {
          VerseEmptyView(compact: true)
        }
      }
      .padding(.leading, 12)

      Spacer(minLength: 0)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(entry.accessibilityText)
    .containerBackground(for: .widget) {
      WidgetTheme.nightBackground(accent: entry.accentColor, intensity: 0.12)
    }
  }
}

// MARK: - Large view

private struct VerseWidgetLargeView: View {
  @Environment(\.widgetRenderingMode) private var renderingMode
  let entry: VerseEntry

  var body: some View {
    let palette = WidgetTheme.Palette(renderingMode)
    VStack(alignment: .leading, spacing: 0) {
      VerseHeader(entry: entry, kicker: "widget.verse.kicker.large")

      if let verse = entry.verse {
        Spacer()

        Text(String(format: String(localized: "widget.verse.quote"), verse.text))
          .font(.title3.weight(.medium).italic())
          .fontDesign(.serif)
          .foregroundStyle(palette.primary)
          .lineSpacing(8)
          .multilineTextAlignment(.leading)
          .contentTransition(.opacity)

        Spacer()

        HStack {
          Spacer()
          VerseReferenceRow(
            reference: verse.reference, accent: entry.accentColor, prominent: true)
        }
      } else {
        Spacer()

        // L'état vide du large montre la promesse : l'invitation + un verset d'exemple grisé.
        VStack(alignment: .leading, spacing: 16) {
          VerseEmptyView()
            .frame(maxHeight: 80)
          Text(String(format: String(localized: "widget.verse.quote"), sampleText))
            .font(.footnote.weight(.medium).italic())
            .fontDesign(.serif)
            .foregroundStyle(palette.tertiary)
            .lineSpacing(5)
        }

        Spacer()
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(entry.accessibilityText)
    .containerBackground(for: .widget) {
      ZStack {
        WidgetTheme.night
        LinearGradient(
          colors: [
            entry.accentColor.opacity(0.18),
            Color.clear,
            Color(red: 0.4, green: 0.3, blue: 0.8).opacity(0.1),
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      }
    }
  }

  private var sampleText: String {
    WidgetPreviewData.sampleVerse().text
  }
}

// MARK: - Lock screen views

private struct VerseWidgetRectangularView: View {
  let entry: VerseEntry

  var body: some View {
    Group {
      if let verse = entry.verse {
        VStack(alignment: .leading, spacing: 2) {
          Text(verse.reference)
            .font(.headline)
            .widgetAccentable()
          Text(verse.text)
            .font(.caption2)
            .lineLimit(2)
        }
      } else {
        Text("widget.verse.empty")
          .font(.caption2)
          .lineLimit(3)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(entry.accessibilityText)
    .containerBackground(for: .widget) { Color.clear }
  }
}

private struct VerseWidgetInlineView: View {
  let entry: VerseEntry

  var body: some View {
    Group {
      if let verse = entry.verse {
        Label(verse.reference, systemImage: entry.emotionIcon)
      } else {
        Label {
          Text(verbatim: "HolyDay")
        } icon: {
          Image(systemName: "book.closed.fill")
        }
      }
    }
    .containerBackground(for: .widget) { Color.clear }
  }
}

// MARK: - Entry view dispatcher

struct VerseWidgetEntryView: View {
  @Environment(\.widgetFamily) private var family
  let entry: VerseEntry

  var body: some View {
    Group {
      switch family {
      case .systemSmall: VerseWidgetSmallView(entry: entry)
      case .systemLarge: VerseWidgetLargeView(entry: entry)
      case .accessoryRectangular: VerseWidgetRectangularView(entry: entry)
      case .accessoryInline: VerseWidgetInlineView(entry: entry)
      default: VerseWidgetMediumView(entry: entry)
      }
    }
    .widgetURL(URL(string: "holyday://verse"))
  }
}

// MARK: - Widget definition

struct VerseWidget: Widget {
  let kind = "VerseWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: VerseTimelineProvider()) { entry in
      VerseWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("widget.verse.name")
    .description("widget.verse.description")
    .supportedFamilies([
      .systemSmall, .systemMedium, .systemLarge,
      .accessoryRectangular, .accessoryInline,
    ])
  }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
  VerseWidget()
} timeline: {
  VerseEntry(date: .now, verse: WidgetPreviewData.sampleVerse())
}

#Preview("Small — vide", as: .systemSmall) {
  VerseWidget()
} timeline: {
  VerseEntry(date: .now, verse: nil)
}

#Preview("Medium", as: .systemMedium) {
  VerseWidget()
} timeline: {
  VerseEntry(date: .now, verse: WidgetPreviewData.sampleVerse())
}

#Preview("Large", as: .systemLarge) {
  VerseWidget()
} timeline: {
  VerseEntry(date: .now, verse: WidgetPreviewData.sampleVerse())
}

#Preview("Large — vide", as: .systemLarge) {
  VerseWidget()
} timeline: {
  VerseEntry(date: .now, verse: nil)
}

#Preview("Rectangular", as: .accessoryRectangular) {
  VerseWidget()
} timeline: {
  VerseEntry(date: .now, verse: WidgetPreviewData.sampleVerse())
}
