//
//  VerseService.swift
//  HolyDay
//
//  Created by Matthias Cadet on 13/05/2026.
//

import Foundation

@Observable
final class VerseService {
  static let shared = VerseService()

  private init() {}

  // Decks mélangés par émotion : on épuise toute la pioche avant de re-mélanger → l'utilisateur
  // voit l'ensemble des versets d'un thème avant qu'un seul ne se répète.
  @ObservationIgnored private var decks: [Emotion: [Int]] = [:]
  @ObservationIgnored private var lastServed: [Emotion: Int] = [:]

  private var isFrench: Bool {
    let lang = Locale.current.language.languageCode?.identifier ?? "fr"
    return !lang.hasPrefix("en")
  }

  // Le corpus vit dans `VerseCorpus` (dossier HolyDayShared), partagé avec l'extension widget.
  // Le sigle de version (LSG/KJV) est ajouté à la référence ici, côté app uniquement.
  private func makeVerse(_ entry: CorpusVerse) -> Verse {
    let translation = isFrench ? "LSG" : "KJV"
    let reference = "\(entry.reference(french: isFrench)) (\(translation))"
    return Verse(
      text: entry.text(french: isFrench),
      reference: reference,
      book: entry.book(french: isFrench),
      chapter: entry.chapter, verse: entry.verse)
  }

  /// Verset accompagnant une émotion. Chaque appel (re-tap inclus) avance la pioche du thème :
  /// le verset change tant qu'il en reste, sans répétition immédiate, pour que l'utilisateur
  /// finisse par trouver celui qui lui parle. Repli défensif sur le premier verset du corpus si
  /// le thème est vide (ne devrait pas arriver : le corpus couvre les huit émotions).
  func verse(for emotion: Emotion) -> Verse {
    let corpus = VerseCorpus.all
    let pool = corpus.indices.filter { corpus[$0].emotionTags.contains(emotion.rawValue) }
    guard !pool.isEmpty else { return makeVerse(corpus[0]) }
    guard pool.count > 1 else { return makeVerse(corpus[pool[0]]) }

    var deck = decks[emotion] ?? []
    if deck.isEmpty {
      deck = pool.shuffled()
      // Évite d'enchaîner deux fois de suite le même verset au moment du re-mélange.
      if let last = lastServed[emotion], deck.first == last {
        deck.swapAt(0, 1)
      }
    }

    let index = deck.removeFirst()
    decks[emotion] = deck
    lastServed[emotion] = index
    return makeVerse(corpus[index])
  }
}
