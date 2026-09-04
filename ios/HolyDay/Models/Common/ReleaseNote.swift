//
//  ReleaseNote.swift
//  HolyDay
//

import SwiftUI

/// Nouveautés d'une version, telles que présentées à l'utilisateur après une mise à jour.
///
/// Le catalogue est statique et compilé : pas d'appel réseau, donc l'écran s'affiche hors ligne et
/// reste figé pour une version donnée — ce qui est le comportement attendu (les notes décrivent le
/// binaire installé, pas le dernier disponible sur l'App Store).
struct ReleaseNote: Identifiable {
  /// Doit correspondre exactement à `CFBundleShortVersionString` de la version concernée.
  /// C'est cette chaîne qui est comparée à la version installée — une faute de frappe ici et les
  /// nouveautés ne sortiront jamais.
  let version: String
  let items: [Item]

  var id: String { version }

  struct Item: Identifiable {
    let icon: String
    let titleKey: LocalizedStringKey
    let bodyKey: LocalizedStringKey
    /// Nom de couleur résolu par `AppTheme.color(for:)` — aligné sur la palette ACTS.
    let colorName: String
    /// Libellé lu par VoiceOver : `LocalizedStringKey` n'est pas inspectable, il faut donc une
    /// chaîne résolue à part pour composer l'étiquette d'accessibilité de la ligne.
    let accessibilityTitle: String

    var id: String { accessibilityTitle }

    var color: Color { AppTheme.color(for: colorName) }
  }
}

enum ReleaseNotesCatalog {
  /// Ordre indifférent : `WhatsNewService` trie par version décroissante avant présentation.
  ///
  /// Pour ajouter une version : une entrée ici + les clés `whatsnew.<version>.*` dans le
  /// String Catalog (fr ET en). Une version absente de ce catalogue ne déclenche aucun écran —
  /// c'est le comportement voulu pour un correctif purement interne.
  static let all: [ReleaseNote] = [
    ReleaseNote(
      version: "1.1",
      items: [
        ReleaseNote.Item(
          icon: "text.book.closed",
          titleKey: "whatsnew.11.attribution.title",
          bodyKey: "whatsnew.11.attribution.body",
          colorName: "adorationPurple",
          accessibilityTitle: String(localized: "whatsnew.11.attribution.title")
        ),
        ReleaseNote.Item(
          icon: "doc.text",
          titleKey: "whatsnew.11.legal.title",
          bodyKey: "whatsnew.11.legal.body",
          colorName: "confessionBlue",
          accessibilityTitle: String(localized: "whatsnew.11.legal.title")
        ),
        ReleaseNote.Item(
          icon: "bubble.left.and.text.bubble.right",
          titleKey: "whatsnew.11.language.title",
          bodyKey: "whatsnew.11.language.body",
          colorName: "thanksgivingGold",
          accessibilityTitle: String(localized: "whatsnew.11.language.title")
        ),
        ReleaseNote.Item(
          icon: "square.grid.2x2",
          titleKey: "whatsnew.11.widget.title",
          bodyKey: "whatsnew.11.widget.body",
          colorName: "supplicationGreen",
          accessibilityTitle: String(localized: "whatsnew.11.widget.title")
        ),
      ]
    )
  ]
}
