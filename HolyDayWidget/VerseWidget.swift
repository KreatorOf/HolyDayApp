//
//  VerseWidget.swift
//  HolyDayWidget
//

import WidgetKit
import SwiftUI

// MARK: - Local verse model

struct WidgetVerse: Sendable {
    let text: String
    let reference: String
    let book: String

    var accentColor: Color {
        switch book {
        case "Jean", "Matthieu", "Marc", "Luc",
             "John", "Matthew", "Mark", "Luke":
            return Color(red: 0.3, green: 0.6, blue: 0.95)
        case "Psaumes", "Proverbes",
             "Psalms", "Proverbs":
            return Color(red: 0.95, green: 0.7, blue: 0.3)
        case "Philippiens", "Jacques", "1 Pierre",
             "Philippians", "James", "1 Peter":
            return Color(red: 0.3, green: 0.8, blue: 0.6)
        default:
            return Color(red: 0.55, green: 0.35, blue: 0.85)
        }
    }
}

// MARK: - Verse data (mirrors VerseService)

private let frenchVerses: [WidgetVerse] = [
    WidgetVerse(text: "Car Dieu a tant aimé le monde qu'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu'il ait la vie éternelle.", reference: "Jean 3:16", book: "Jean"),
    WidgetVerse(text: "Je puis tout par celui qui me fortifie.", reference: "Philippiens 4:13", book: "Philippiens"),
    WidgetVerse(text: "L'Éternel est mon berger : je ne manquerai de rien.", reference: "Psaume 23:1", book: "Psaumes"),
    WidgetVerse(text: "Confie-toi en l'Éternel de tout ton cœur, et ne t'appuie pas sur ta sagesse.", reference: "Proverbes 3:5", book: "Proverbes"),
    WidgetVerse(text: "Ne crains rien, car je suis avec toi ; ne promène pas des regards inquiets, car je suis ton Dieu.", reference: "Ésaïe 41:10", book: "Ésaïe"),
    WidgetVerse(text: "Cherchez premièrement le royaume et la justice de Dieu ; et toutes ces choses vous seront données par-dessus.", reference: "Matthieu 6:33", book: "Matthieu"),
    WidgetVerse(text: "Voici, je suis avec vous tous les jours, jusqu'à la fin du monde.", reference: "Matthieu 28:20", book: "Matthieu"),
    WidgetVerse(text: "Car mes pensées ne sont pas vos pensées, et vos voies ne sont pas mes voies, dit l'Éternel.", reference: "Ésaïe 55:8", book: "Ésaïe"),
    WidgetVerse(text: "Que ton cœur ne se trouble point. Croyez en Dieu, et croyez en moi.", reference: "Jean 14:1", book: "Jean"),
    WidgetVerse(text: "Approchez-vous de Dieu, et il s'approchera de vous.", reference: "Jacques 4:8", book: "Jacques"),
    WidgetVerse(text: "L'Éternel combattra pour vous ; et vous, gardez le silence.", reference: "Exode 14:14", book: "Exode"),
    WidgetVerse(text: "Demandez, et l'on vous donnera ; cherchez, et vous trouverez ; frappez, et l'on vous ouvrira.", reference: "Matthieu 7:7", book: "Matthieu"),
    WidgetVerse(text: "Mais ceux qui se confient en l'Éternel renouvellent leur force.", reference: "Ésaïe 40:31", book: "Ésaïe"),
    WidgetVerse(text: "Rejetez sur lui tous vos soucis, car lui-même prend soin de vous.", reference: "1 Pierre 5:7", book: "1 Pierre"),
    WidgetVerse(text: "La paix de Dieu, qui surpasse toute intelligence, gardera vos cœurs et vos pensées en Jésus Christ.", reference: "Philippiens 4:7", book: "Philippiens"),
]

private let englishVerses: [WidgetVerse] = [
    WidgetVerse(text: "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.", reference: "John 3:16", book: "John"),
    WidgetVerse(text: "I can do all this through him who gives me strength.", reference: "Philippians 4:13", book: "Philippians"),
    WidgetVerse(text: "The Lord is my shepherd, I lack nothing.", reference: "Psalm 23:1", book: "Psalms"),
    WidgetVerse(text: "Trust in the Lord with all your heart and lean not on your own understanding.", reference: "Proverbs 3:5", book: "Proverbs"),
    WidgetVerse(text: "So do not fear, for I am with you; do not be dismayed, for I am your God.", reference: "Isaiah 41:10", book: "Isaiah"),
    WidgetVerse(text: "But seek first his kingdom and his righteousness, and all these things will be given to you as well.", reference: "Matthew 6:33", book: "Matthew"),
    WidgetVerse(text: "And surely I am with you always, to the very end of the age.", reference: "Matthew 28:20", book: "Matthew"),
    WidgetVerse(text: "For my thoughts are not your thoughts, neither are your ways my ways, declares the Lord.", reference: "Isaiah 55:8", book: "Isaiah"),
    WidgetVerse(text: "Do not let your hearts be troubled. You believe in God; believe also in me.", reference: "John 14:1", book: "John"),
    WidgetVerse(text: "Come near to God and he will come near to you.", reference: "James 4:8", book: "James"),
    WidgetVerse(text: "The Lord will fight for you; you need only to be still.", reference: "Exodus 14:14", book: "Exodus"),
    WidgetVerse(text: "Ask and it will be given to you; seek and you will find; knock and the door will be opened to you.", reference: "Matthew 7:7", book: "Matthew"),
    WidgetVerse(text: "But those who hope in the Lord will renew their strength.", reference: "Isaiah 40:31", book: "Isaiah"),
    WidgetVerse(text: "Cast all your anxiety on him because he cares for you.", reference: "1 Peter 5:7", book: "1 Peter"),
    WidgetVerse(text: "And the peace of God, which transcends all understanding, will guard your hearts and your minds in Christ Jesus.", reference: "Philippians 4:7", book: "Philippians"),
]

private func verseOfTheDay() -> WidgetVerse {
    let lang = Locale.current.language.languageCode?.identifier ?? "fr"
    let verses = lang.hasPrefix("en") ? englishVerses : frenchVerses
    let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    return verses[(dayOfYear - 1) % verses.count]
}

// MARK: - Timeline

struct VerseEntry: TimelineEntry, Sendable {
    let date: Date
    let verse: WidgetVerse
}

struct VerseTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> VerseEntry {
        VerseEntry(date: .now, verse: frenchVerses[0])
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (VerseEntry) -> Void) {
        completion(VerseEntry(date: .now, verse: verseOfTheDay()))
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<VerseEntry>) -> Void) {
        let entry = VerseEntry(date: .now, verse: verseOfTheDay())
        let nextMidnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!
        )
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

// MARK: - Small view

private struct VerseWidgetSmallView: View {
    let entry: VerseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(entry.verse.accentColor)
                Text("HolyDay")
                    .font(.system(size: 9, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.white.opacity(0.55))
            }

            Spacer()

            Text(entry.verse.text)
                .font(.system(size: 12, weight: .medium, design: .serif))
                .foregroundStyle(.white)
                .lineLimit(5)
                .lineSpacing(3)

            Spacer()

            HStack(spacing: 3) {
                Circle()
                    .fill(entry.verse.accentColor)
                    .frame(width: 3, height: 3)
                Text(entry.verse.reference)
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundStyle(entry.verse.accentColor)
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.12)
                LinearGradient(
                    colors: [entry.verse.accentColor.opacity(0.15), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .widgetURL(URL(string: "holyday://verse"))
    }
}

// MARK: - Medium view

private struct VerseWidgetMediumView: View {
    let entry: VerseEntry

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(entry.verse.accentColor)
                .frame(width: 3)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(entry.verse.accentColor)
                        Text("Verset du jour")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.5))
                            .textCase(.uppercase)
                            .tracking(1)
                    }
                    Spacer()
                    Text(Date.now.formatted(.dateTime.day().month(.abbreviated)))
                        .font(.system(size: 9))
                        .foregroundStyle(Color.white.opacity(0.35))
                }

                Text(entry.verse.text)
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundStyle(.white)
                    .lineSpacing(4)
                    .lineLimit(3)

                HStack(spacing: 4) {
                    Circle()
                        .fill(entry.verse.accentColor)
                        .frame(width: 4, height: 4)
                    Text(entry.verse.reference)
                        .font(.system(size: 11, weight: .bold, design: .serif))
                        .foregroundStyle(entry.verse.accentColor)
                }
            }
            .padding(.leading, 12)
        }
        .padding(.vertical, 14)
        .padding(.trailing, 14)
        .padding(.leading, 12)
        .containerBackground(for: .widget) {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.12)
                LinearGradient(
                    colors: [entry.verse.accentColor.opacity(0.12), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .widgetURL(URL(string: "holyday://verse"))
    }
}

// MARK: - Large view

private struct VerseWidgetLargeView: View {
    let entry: VerseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "book.closed.fill")
                        .font(.caption2)
                        .foregroundStyle(entry.verse.accentColor)
                    Text("HolyDay · Verset du jour")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(1)
                }
                Spacer()
                Text(Date.now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.35))
            }

            Spacer()

            Text("« \(entry.verse.text) »")
                .font(.system(size: 18, weight: .medium, design: .serif).italic())
                .foregroundStyle(.white)
                .lineSpacing(9)
                .multilineTextAlignment(.leading)

            Spacer()

            HStack {
                Spacer()
                HStack(spacing: 5) {
                    Circle()
                        .fill(entry.verse.accentColor)
                        .frame(width: 5, height: 5)
                    Text(entry.verse.reference)
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundStyle(entry.verse.accentColor)
                }
            }
        }
        .padding(20)
        .containerBackground(for: .widget) {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.12)
                LinearGradient(
                    colors: [
                        entry.verse.accentColor.opacity(0.18),
                        Color.clear,
                        Color(red: 0.4, green: 0.3, blue: 0.8).opacity(0.1),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .widgetURL(URL(string: "holyday://verse"))
    }
}

// MARK: - Entry view dispatcher

struct VerseWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: VerseEntry

    var body: some View {
        switch family {
        case .systemSmall:  VerseWidgetSmallView(entry: entry)
        case .systemLarge:  VerseWidgetLargeView(entry: entry)
        default:            VerseWidgetMediumView(entry: entry)
        }
    }
}

// MARK: - Widget definition

struct VerseWidget: Widget {
    let kind = "VerseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VerseTimelineProvider()) { entry in
            VerseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Verset du jour")
        .description("Affichez le verset du jour directement sur votre écran d'accueil.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    VerseWidget()
} timeline: {
    VerseEntry(date: .now, verse: frenchVerses[0])
}

#Preview("Medium", as: .systemMedium) {
    VerseWidget()
} timeline: {
    VerseEntry(date: .now, verse: frenchVerses[1])
}

#Preview("Large", as: .systemLarge) {
    VerseWidget()
} timeline: {
    VerseEntry(date: .now, verse: frenchVerses[2])
}
