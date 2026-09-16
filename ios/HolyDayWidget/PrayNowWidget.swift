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
  let verse: WidgetVerse

  var accessibilityText: String {
    let label = String(
      localized: hasPrayed ? "widget.pray.a11y.done" : "widget.pray.a11y.invite")
    return "\(label). \(verse.reference)"
  }
}

struct PrayNowTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> PrayNowEntry {
    PrayNowEntry(date: .now, hasPrayed: false, verse: WidgetPreviewData.sampleVerse())
  }

  func getSnapshot(in context: Context, completion: @escaping @Sendable (PrayNowEntry) -> Void) {
    completion(
      PrayNowEntry(
        date: .now, hasPrayed: SharedStore.hasPrayed(), verse: SharedStore.widgetVerse()))
  }

  func getTimeline(
    in context: Context, completion: @escaping @Sendable (Timeline<PrayNowEntry>) -> Void
  ) {
    // L'app recharge les timelines dès qu'une prière est enregistrée (WidgetSyncService) ;
    // l'échéance à minuit ramène l'état « invitation » et le verset du jour.
    let entry = PrayNowEntry(
      date: .now, hasPrayed: SharedStore.hasPrayed(), verse: SharedStore.widgetVerse())
    completion(Timeline(entries: [entry], policy: .after(WidgetTheme.nextMidnight())))
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
  /// Référence du verset du jour : après l'Amen, une invitation à la méditation — pas un score.
  let verse: WidgetVerse

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

      Text(verse.reference)
        .font(.caption.weight(.bold))
        .fontDesign(.serif)
        .foregroundStyle(WidgetTheme.accent(forEmotionTag: verse.emotionTag))
        .widgetAccentable()
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
        PrayNowDoneBlock(verse: entry.verse)
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
          PrayNowDoneBlock(verse: entry.verse)
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
        Text(entry.verse.source == .emotion ? "widget.verse.kicker" : "widget.verse.kicker.daily")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(palette.tertiary)
          .textCase(.uppercase)
          .tracking(1)
        Text(entry.verse.text)
          .font(.caption.weight(.medium))
          .fontDesign(.serif)
          .foregroundStyle(palette.secondary)
          .lineLimit(4)
          .lineSpacing(3)
          .contentTransition(.opacity)
        Text(entry.verse.reference)
          .font(.caption2.weight(.bold))
          .fontDesign(.serif)
          .foregroundStyle(WidgetTheme.accent(forEmotionTag: entry.verse.emotionTag))
          .widgetAccentable()
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
    .widgetURL(AppRoute.pray.url)
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
  PrayNowEntry(date: .now, hasPrayed: false, verse: WidgetPreviewData.dailyVerse())
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
  PrayNowEntry(date: .now, hasPrayed: false, verse: WidgetPreviewData.dailyVerse())
}
