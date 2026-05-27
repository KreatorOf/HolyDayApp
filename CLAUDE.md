# HolyDay — CLAUDE.md

## Localisation (obligatoire)

Toute chaîne visible par l'utilisateur doit être disponible **en français ET en anglais** dans `HolyDay/Localizable.xcstrings`.

- La langue source est le **français** (`"sourceLanguage": "fr"`).
- Chaque clé doit avoir une entrée `fr` et une entrée `en` avec `"state": "translated"`.
- Ne jamais écrire de texte littéral en dur dans les vues SwiftUI. Toujours passer par `String(localized: "clé")` ou le `.init` `LocalizedStringKey`.
- Format du fichier : `.xcstrings` (String Catalog Xcode) — ne pas créer de fichiers `.strings` séparés.

## Linting & formatage

Deux outils sont utilisés ensemble. Les respecter systématiquement avant tout commit.

### SwiftLint (`swiftlint`)

Config : `.swiftlint.yml` à la racine.  
SwiftLint est intégré en build phase Xcode — les violations bloquent le build en erreur.

```bash
# Vérifier
swiftlint lint --strict

# Corriger automatiquement ce qui peut l'être
swiftlint --fix
```

Règles notables activées : `force_unwrapping`, `empty_count`.  
Règles désactivées : `trailing_whitespace`, `line_length`, `trailing_comma`, `todo`.

### swift-format (Apple)

Config : `.swift-format` à la racine.  
Indentation : 2 espaces. Longueur de ligne : 100.

```bash
# Formater tous les fichiers Swift du projet
swift-format format --recursive --in-place HolyDay/ HolyDayTests/ HolyDayWidget/

# Vérifier sans modifier (CI)
swift-format lint --recursive HolyDay/ HolyDayTests/ HolyDayWidget/
```

## Documentation & références (obligatoire)

Avant d'implémenter toute fonctionnalité SwiftUI, SwiftData, UIKit, ou tout autre framework Apple :

1. **Toujours interroger Context7** via `mcp__context7__resolve-library-id` + `mcp__context7__query-docs` pour obtenir la documentation à jour. Ne jamais se fier uniquement aux données d'entraînement — les APIs Apple évoluent rapidement (ex. Liquid Glass iOS 26, `@Observable`, nouveaux modificateurs SwiftUI).
2. **Respecter les Human Interface Guidelines (HIG) d'Apple** dans chaque décision UI/UX :
   - Espacement, typographie et tailles de touch target conformes aux HIG
   - Utiliser les composants natifs (SF Symbols, Dynamic Type, Safe Area) plutôt que des équivalents custom
   - Respecter les patterns de navigation natifs iOS (NavigationStack, sheets, confirmationAction)
   - Accessibilité : labels VoiceOver, tailles Dynamic Type, contraste suffisant
   - Ne pas reproduire des patterns d'autres plateformes (Android, web)

## Architecture

- Pattern : **MVVM** avec `@Observable` (pas de `ObservableObject`/`@Published`)
- Persistence : **SwiftData** (`@Model`, `@Query`, `ModelContext`)
- UI : **SwiftUI** uniquement
- iOS cible : voir `Config/` xcconfig

## Conventions Swift

- Pas de `force unwrap` (`!`) sauf cas documenté et justifié
- `private` par défaut sur toutes les propriétés et méthodes non exposées
- Sections MARK pour organiser les vues (`// MARK: - Body`, `// MARK: - Helpers`, etc.)
- Pas de commentaires qui décrivent ce que fait le code — uniquement pourquoi (invariants non évidents, contournements)
