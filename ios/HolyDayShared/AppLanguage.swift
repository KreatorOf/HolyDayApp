//
//  AppLanguage.swift
//  HolyDay
//

import Foundation

/// Langue dans laquelle l'app s'adresse à l'utilisateur.
///
/// L'app n'est localisée qu'en français et en anglais, le français étant la langue source : tout
/// appareil qui n'est pas en anglais voit donc l'interface en français. Cette règle était dupliquée
/// dans `VerseService` et absente d'`AIAssistantService` — d'où des versets en anglais accompagnés
/// de questions de réflexion en français. Elle vit ici, à un seul endroit.
///
/// `Bundle.main.preferredLocalizations` plutôt que `Locale.current` : c'est la localisation que le
/// système a réellement retenue pour ce bundle après repli, donc exactement ce que l'utilisateur
/// lit à l'écran. `Locale.current` décrit l'appareil, pas l'app — sur un appareil en espagnol,
/// l'app affiche du français, et seule la première réponse est la bonne.
enum AppLanguage {
  static var isFrench: Bool {
    !current.hasPrefix("en")
  }

  /// Code de langue effectif du bundle (« fr » ou « en »), replié sur le français.
  static var current: String {
    Bundle.main.preferredLocalizations.first ?? "fr"
  }
}
