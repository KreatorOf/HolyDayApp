//
//  VerseWidget.swift
//  HolyDayWidget
//

import SwiftUI
import WidgetKit

// MARK: - Timeline

/// « Mon verset » : le verset reçu aujourd'hui via le ruban d'émotions, sinon un verset du jour
/// (cf. `WidgetVerseResolver`) — jamais vide, jamais figé. Le `kind` reste "VerseWidget" pour que
/// les widgets déjà posés migrent en place au lieu de disparaître de l'écran d'accueil.
struct VerseEntry: TimelineEntry, Sendable {
  let date: Date
  let verse: WidgetVerse

  var accentColor: Color {
    WidgetTheme.accent(forEmotionTag: verse.emotionTag)
  }

  var emotionIcon: String {
    WidgetTheme.icon(forEmotionTag: verse.emotionTag)
  }

  var kicker: LocalizedStringKey {
    verse.source == .emotion ? "widget.verse.kicker" : "widget.verse.kicker.daily"
  }

  var largeKicker: LocalizedStringKey {
    verse.source == .emotion ? "widget.verse.kicker.large" : "widget.verse.kicker.large.daily"
  }

  var accessibilityText: String {
    "\(verse.text) — \(verse.reference)"
  }
}

struct VerseTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> VerseEntry {
    VerseEntry(date: .now, verse: WidgetPreviewData.sampleVerse())
  }

  func getSnapshot(in context: Context, completion: @escaping @Sendable (VerseEntry) -> Void) {
    completion(VerseEntry(date: .now, verse: SharedStore.widgetVerse()))
  }

  func getTimeline(
    in context: Context, completion: @escaping @Sendable (Timeline<VerseEntry>) -> Void
  ) {
    // Échéance à minuit : le verset d'émotion ne vaut que pour son jour, puis le verset du jour
    // prend le relais. Dans la journée, l'app (nouveau ressenti) et `NextVerseIntent` rechargent.
    let entry = VerseEntry(date: .now, verse: SharedStore.widgetVerse())
    completion(Timeline(entries: [entry], policy: .after(WidgetTheme.nextMidnight())))
  }
}

// MARK: - Shared pieces

private struct VerseHeader: View {
  @Environment(\.widgetRenderingMode) private var renderingMode
  let entry: VerseEntry
  let kicker: LocalizedStringKey

  var body: some View {
    let palette = WidgetTheme.Palette(renderingMode)
    HStack(spacing: 5) {
      Image(systemName: entry.emotionIcon)
        .font(.caption2)
        .foregroundStyle(entry.accentColor)
        .widgetAccentable()
      Text(kicker)
        .font(.caption2.weight(.semibold))
        .foregroundStyle(palette.tertiary)
        .textCase(.uppercase)
        .tracking(1)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
      Spacer(minLength: 0)
    }
    // Place réservée au bouton « Un autre verset », posé en overlay hors de l'élément
    // d'accessibilité du verset (sinon VoiceOver ne l'atteint pas).
    .padding(.trailing, 30)
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

// MARK: - Small view

private struct VerseWidgetSmallView: View {
  @Environment(\.widgetRenderingMode) private var renderingMode
  let entry: VerseEntry

  var body: some View {
    let palette = WidgetTheme.Palette(renderingMode)
    VStack(alignment: .leading, spacing: 0) {
      VerseHeader(entry: entry, kicker: entry.kicker)

      Spacer(minLength: 6)

      // Deux compositions plutôt qu'un minimumScaleFactor : les versets courts gardent une
      // taille confortable, les longs passent en caption au lieu d'être tronqués.
      ViewThatFits(in: .vertical) {
        verseText(entry.verse.text, font: .footnote, palette: palette)
        verseText(entry.verse.text, font: .caption, palette: palette)
      }
      .contentTransition(.opacity)
      .invalidatableContent()

      Spacer(minLength: 6)

      VerseReferenceRow(reference: entry.verse.reference, accent: entry.accentColor)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(entry.accessibilityText)
    .overlay(alignment: .topTrailing) { NextVerseButton() }
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
        VerseHeader(entry: entry, kicker: entry.kicker)

        Text(entry.verse.text)
          .font(.footnote.weight(.medium))
          .fontDesign(.serif)
          .foregroundStyle(palette.primary)
          .lineSpacing(4)
          .lineLimit(3)
          .contentTransition(.opacity)
          .invalidatableContent()

        VerseReferenceRow(reference: entry.verse.reference, accent: entry.accentColor)
      }
      .padding(.leading, 12)

      Spacer(minLength: 0)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(entry.accessibilityText)
    .overlay(alignment: .topTrailing) { NextVerseButton() }
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
      VerseHeader(entry: entry, kicker: entry.largeKicker)

      Spacer()

      Text(String(format: String(localized: "widget.verse.quote"), entry.verse.text))
        .font(.title3.weight(.medium).italic())
        .fontDesign(.serif)
        .foregroundStyle(palette.primary)
        .lineSpacing(8)
        .multilineTextAlignment(.leading)
        .contentTransition(.opacity)
        .invalidatableContent()

      Spacer()

      HStack {
        Spacer()
        VerseReferenceRow(
          reference: entry.verse.reference, accent: entry.accentColor, prominent: true)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(entry.accessibilityText)
    .overlay(alignment: .topTrailing) { NextVerseButton() }
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
}

// MARK: - Lock screen views

private struct VerseWidgetRectangularView: View {
  let entry: VerseEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(entry.verse.reference)
        .font(.headline)
        .widgetAccentable()
      Text(entry.verse.text)
        .font(.caption2)
        .lineLimit(2)
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
    Label(entry.verse.reference, systemImage: entry.emotionIcon)
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
    .widgetURL(AppRoute.pray.url)
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

#Preview("Small — émotion", as: .systemSmall) {
  VerseWidget()
} timeline: {
  VerseEntry(date: .now, verse: WidgetPreviewData.sampleVerse())
}

#Preview("Small — du jour", as: .systemSmall) {
  VerseWidget()
} timeline: {
  VerseEntry(date: .now, verse: WidgetPreviewData.dailyVerse())
}

#Preview("Medium", as: .systemMedium) {
  VerseWidget()
} timeline: {
  VerseEntry(date: .now, verse: WidgetPreviewData.sampleVerse())
}

#Preview("Large — du jour", as: .systemLarge) {
  VerseWidget()
} timeline: {
  VerseEntry(date: .now, verse: WidgetPreviewData.dailyVerse())
}

#Preview("Rectangular", as: .accessoryRectangular) {
  VerseWidget()
} timeline: {
  VerseEntry(date: .now, verse: WidgetPreviewData.sampleVerse())
}
