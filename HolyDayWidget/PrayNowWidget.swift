//
//  PrayNowWidget.swift
//  HolyDayWidget
//

import SwiftUI
import WidgetKit

// MARK: - Timeline

/// Porte d'entrée vers la prière. Philosophie de l'app : inviter sans jamais culpabiliser —
/// pas prié = une invitation ouverte, prié = une confirmation paisible. Aucun état « en retard »,
/// aucun compteur menacé.
struct PrayNowEntry: TimelineEntry, Sendable {
  let date: Date
  let hasPrayed: Bool
  let verse: SharedVerse?

  var accessibilityText: String {
    var label = String(
      localized: hasPrayed ? "widget.pray.a11y.done" : "widget.pray.a11y.invite")
    if let verse {
      label += ". \(verse.reference)"
    }
    return label
  }
}

struct PrayNowTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> PrayNowEntry {
    PrayNowEntry(date: .now, hasPrayed: false, verse: WidgetPreviewData.sampleVerse())
  }

  func getSnapshot(in context: Context, completion: @escaping @Sendable (PrayNowEntry) -> Void) {
    // Galerie de widgets : montrer le volet verset rempli plutôt que l'état vide.
    let verse =
      SharedStore.lastVerse ?? (context.isPreview ? WidgetPreviewData.sampleVerse() : nil)
    completion(PrayNowEntry(date: .now, hasPrayed: SharedStore.hasPrayed(), verse: verse))
  }

  func getTimeline(
    in context: Context, completion: @escaping @Sendable (Timeline<PrayNowEntry>) -> Void
  ) {
    // L'app recharge les timelines dès qu'une prière est enregistrée (WidgetSyncService) ;
    // l'échéance à minuit ne sert qu'à revenir à l'état « invitation » au changement de jour.
    let entry = PrayNowEntry(
      date: .now, hasPrayed: SharedStore.hasPrayed(), verse: SharedStore.lastVerse)
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .distantFuture
    let nextMidnight = Calendar.current.startOfDay(for: tomorrow)
    completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
  }
}

// MARK: - Pieces

private struct PrayNowHeader: View {
  @Environment(\.widgetRenderingMode) private var renderingMode

  var body: some View {
    let palette = WidgetTheme.Palette(renderingMode)
    HStack(spacing: 4) {
      Image(systemName: "hands.sparkles.fill")
        .font(.caption2)
        .foregroundStyle(WidgetTheme.violet)
        .widgetAccentable()
      Text(verbatim: "HolyDay")
        .font(.caption2.weight(.semibold))
        .fontDesign(.serif)
        .foregroundStyle(palette.tertiary)
    }
  }
}

private struct PrayNowInviteBlock: View {
  @Environment(\.widgetRenderingMode) private var renderingMode

  var body: some View {
    let palette = WidgetTheme.Palette(renderingMode)
    VStack(alignment: .leading, spacing: 10) {
      Text("widget.pray.invite.title")
        .font(.subheadline.weight(.medium))
        .fontDesign(.serif)
        .foregroundStyle(palette.primary)
        .lineSpacing(3)

      Text("widget.pray.invite.button")
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.vertical, 6)
        .padding(.horizontal, 14)
        .background(Capsule().fill(WidgetTheme.violet.opacity(0.85)))
        .widgetAccentable()
    }
  }
}

private struct PrayNowDoneBlock: View {
  @Environment(\.widgetRenderingMode) private var renderingMode
  /// Référence du dernier verset reçu : après l'Amen, une invitation à la méditation — pas un
  /// score.
  var verseReference: String?
  var emotionTag: String = ""

  var body: some View {
    let palette = WidgetTheme.Palette(renderingMode)
    VStack(alignment: .leading, spacing: 6) {
      Image(systemName: "checkmark.seal.fill")
        .font(.title3)
        .foregroundStyle(WidgetTheme.gold)
        .widgetAccentable()

      Text("widget.pray.done.title")
        .font(.headline)
        .fontDesign(.serif)
        .foregroundStyle(palette.primary)

      if let verseReference {
        Text(verseReference)
          .font(.caption.weight(.bold))
          .fontDesign(.serif)
          .foregroundStyle(WidgetTheme.accent(forEmotionTag: emotionTag))
          .widgetAccentable()
      } else {
        Text("widget.pray.done.subtitle")
          .font(.caption2)
          .foregroundStyle(palette.tertiary)
          .lineSpacing(2)
      }
    }
  }
}

// MARK: - Small view

private struct PrayNowWidgetSmallView: View {
  let entry: PrayNowEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      PrayNowHeader()
      Spacer()
      if entry.hasPrayed {
        PrayNowDoneBlock(
          verseReference: entry.verse?.reference,
          emotionTag: entry.verse?.emotionTag ?? "")
      } else {
        PrayNowInviteBlock()
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(entry.accessibilityText)
    .containerBackground(for: .widget) {
      WidgetTheme.nightBackground(accent: entry.hasPrayed ? WidgetTheme.gold : WidgetTheme.violet)
    }
  }
}

// MARK: - Medium view

private struct PrayNowWidgetMediumView: View {
  @Environment(\.widgetRenderingMode) private var renderingMode
  let entry: PrayNowEntry

  var body: some View {
    let palette = WidgetTheme.Palette(renderingMode)
    HStack(spacing: 14) {
      VStack(alignment: .leading, spacing: 0) {
        PrayNowHeader()
        Spacer()
        if entry.hasPrayed {
          PrayNowDoneBlock(
            verseReference: entry.verse?.reference,
            emotionTag: entry.verse?.emotionTag ?? "")
        } else {
          PrayNowInviteBlock()
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      RoundedRectangle(cornerRadius: 1)
        .fill(WidgetTheme.separator)
        .frame(width: 1)
        .padding(.vertical, 6)

      VStack(alignment: .leading, spacing: 8) {
        Text("widget.verse.kicker")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(palette.tertiary)
          .textCase(.uppercase)
          .tracking(1)
        if let verse = entry.verse {
          Text(verse.text)
            .font(.caption.weight(.medium))
            .fontDesign(.serif)
            .foregroundStyle(palette.secondary)
            .lineLimit(4)
            .lineSpacing(3)
            .contentTransition(.opacity)
          Text(verse.reference)
            .font(.caption2.weight(.bold))
            .fontDesign(.serif)
            .foregroundStyle(WidgetTheme.accent(forEmotionTag: verse.emotionTag))
            .widgetAccentable()
        } else {
          Text("widget.verse.empty")
            .font(.caption.weight(.medium))
            .fontDesign(.serif)
            .foregroundStyle(palette.tertiary)
            .lineSpacing(3)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(entry.accessibilityText)
    .containerBackground(for: .widget) {
      WidgetTheme.nightBackground(accent: entry.hasPrayed ? WidgetTheme.gold : WidgetTheme.violet)
    }
  }
}

// MARK: - Lock screen views

private struct PrayNowWidgetCircularView: View {
  let entry: PrayNowEntry

  var body: some View {
    ZStack {
      AccessoryWidgetBackground()
      Image(systemName: entry.hasPrayed ? "checkmark.seal.fill" : "hands.sparkles.fill")
        .font(.title3)
        .widgetAccentable()
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(entry.accessibilityText)
    .containerBackground(for: .widget) { Color.clear }
  }
}

private struct PrayNowWidgetRectangularView: View {
  let entry: PrayNowEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(verbatim: "HolyDay")
        .font(.caption2.weight(.semibold))
        .widgetAccentable()
      Text(entry.hasPrayed ? "widget.pray.done.title" : "widget.pray.invite.title")
        .font(.headline)
        .lineLimit(2)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(entry.accessibilityText)
    .containerBackground(for: .widget) { Color.clear }
  }
}

// MARK: - Entry view dispatcher

struct PrayNowWidgetEntryView: View {
  @Environment(\.widgetFamily) private var family
  let entry: PrayNowEntry

  var body: some View {
    Group {
      switch family {
      case .accessoryCircular: PrayNowWidgetCircularView(entry: entry)
      case .accessoryRectangular: PrayNowWidgetRectangularView(entry: entry)
      case .systemMedium: PrayNowWidgetMediumView(entry: entry)
      default: PrayNowWidgetSmallView(entry: entry)
      }
    }
    .widgetURL(URL(string: "holyday://pray"))
  }
}

// MARK: - Widget definition

struct PrayNowWidget: Widget {
  let kind = "PrayNowWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PrayNowTimelineProvider()) { entry in
      PrayNowWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("widget.pray.name")
    .description("widget.pray.description")
    .supportedFamilies([
      .systemSmall, .systemMedium,
      .accessoryCircular, .accessoryRectangular,
    ])
  }
}

// MARK: - Previews

#Preview("Small — invitation", as: .systemSmall) {
  PrayNowWidget()
} timeline: {
  PrayNowEntry(date: .now, hasPrayed: false, verse: nil)
}

#Preview("Small — prié", as: .systemSmall) {
  PrayNowWidget()
} timeline: {
  PrayNowEntry(date: .now, hasPrayed: true, verse: WidgetPreviewData.sampleVerse())
}

#Preview("Medium", as: .systemMedium) {
  PrayNowWidget()
} timeline: {
  PrayNowEntry(date: .now, hasPrayed: false, verse: WidgetPreviewData.sampleVerse())
}

#Preview("Circular", as: .accessoryCircular) {
  PrayNowWidget()
} timeline: {
  PrayNowEntry(date: .now, hasPrayed: false, verse: nil)
}
