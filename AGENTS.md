# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Structure du dépôt

Monorepo à trois dossiers racine :

- `ios/` — app native Swift/SwiftUI/SwiftData (le projet Xcode `HolyDay.xcodeproj`, ses cibles, `Config/`, `fastlane/`). Toutes les règles ci-dessous qui mentionnent des chemins (`HolyDay/`, `.swiftlint.yml`, etc.) sont relatives à `ios/`.
- `android/` — app native Kotlin/Jetpack Compose (portage fonctionnellement fidèle à l'iOS, voir `shared/docs/PORT_PROGRESS.md`). Pas de KMM/code partagé compilé : Swift et Kotlin sont deux implémentations indépendantes qui doivent rester équivalentes en comportement.
- `shared/` — contenu source-de-vérité commun aux deux plateformes (pas de code compilé) :
  - `shared/data/verses.json` — corpus de versets FR/EN (LSG/BSB), extrait de `ios/HolyDayShared/VerseCorpus.swift`. Les deux apps embarquent aujourd'hui encore leur propre copie (`ios/HolyDayShared/VerseCorpus.swift`, `android/.../data/model/VerseCorpus.kt`) ; ce fichier sert de référence pour vérifier qu'elles restent identiques après toute modification du corpus.
  - `shared/docs/KEYMAP.md` — correspondance clés de localisation iOS (`.xcstrings`) ↔ ressources Android (`strings.xml`).
  - `shared/docs/PORT_PROGRESS.md` — suivi d'avancement du portage Android, source de vérité pour la parité fonctionnelle entre les deux apps. **À relire en priorité** avant toute modification côté Android : il fige la toolchain et les décisions d'architecture.

Toute évolution fonctionnelle doit être portée des deux côtés, ou l'écart doit être consigné dans `PORT_PROGRESS.md` (voir « gap de parité assumé » pour l'assistant IA).

## Commandes

### iOS (depuis `ios/`)

Trois schemes partagés (`HolyDay Dev`, `HolyDay Staging`, `HolyDay`) ; le scheme de développement et de CI est `HolyDay Dev`.

```bash
# Build
xcodebuild build -project HolyDay.xcodeproj -scheme "HolyDay Dev" \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO

# Tous les tests (XCTest)
xcodebuild test -project HolyDay.xcodeproj -scheme "HolyDay Dev" \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO

# Une seule classe / un seul test
xcodebuild test -project HolyDay.xcodeproj -scheme "HolyDay Dev" \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:HolyDayTests/VerseServiceTests \
  -only-testing:HolyDayTests/PrayerGuideViewModelTests/test_resetProgress_clearsCompletedSteps
```

Cibles : `HolyDay`, `HolyDayWidgetExtension`, `HolyDayTests` (unitaires), `HolyDayUITests` (captures fastlane).

### Android (depuis `android/`)

`local.properties` (non versionné) doit pointer sur le SDK, ou exporter `ANDROID_HOME`. JDK 17 obligatoire (`jvmTarget`/`compileOptions`).

```bash
./gradlew lintDebug            # Android Lint
./gradlew testDebugUnitTest    # tests unitaires JVM
./gradlew assembleDebug
./gradlew assembleRelease      # valide R8 : minify + shrinkResources + proguard-rules.pro

# Une seule classe / un seul test — les noms de test sont des identifiants entre
# backticks (avec espaces), à reprendre tels quels dans le filtre.
./gradlew testDebugUnitTest --tests "com.matthiascadet.holyday.service.VerseServiceTest"
./gradlew testDebugUnitTest --tests "*PrayerGuideViewModelTest.resetProgress clears completed steps"
```

Pas de `app/src/androidTest/` : aucun test instrumenté à ce jour.

### Livraison iOS (fastlane, depuis `ios/`)

`bundle exec fastlane <lane>` depuis `ios/`. Quatre lanes, un verbe par destination :

| Lane | Recompile ? | Effet |
|---|---|---|
| `beta` | oui | Build signé → TestFlight (testeurs internes) |
| `beta_external` | oui | Build signé → TestFlight externe + Beta App Review |
| `release` | **non** | Promeut vers l'App Store le dernier build TestFlight de la version courante |
| `update_testflight_notes` | **non** | Met à jour le « ce qu'il faut tester » du dernier build TestFlight |
| `screenshots` | — | `capture_screenshots` (config `fastlane/Snapfile`) |

**`release` ne construit rien** : il désigne, via `skip_binary_upload`, le build déjà passé par TestFlight, et pousse les métadonnées de `fastlane/metadata/`. C'est ce qui garantit qu'on soumet exactement le binaire testé et non un jumeau recompilé après la recette. Il échoue explicitement si aucun build TestFlight n'existe pour la version courante. `submit_for_review` est à `false` par défaut — `fastlane release submit:true` pour envoyer en review, et la mise en vente reste manuelle (`automatic_release: false`).

Les captures ne sont pas versionnées (`fastlane/screenshots/` est vide) : `release` laisse par défaut intactes celles en ligne. Pour les remplacer : `fastlane screenshots` puis `fastlane release screenshots:true`.

Le « ce qu'il faut tester » envoyé aux testeurs vit dans `fastlane/testflight_whats_new.txt` (distinct des notes App Store, `fastlane/metadata/<langue>/release_notes.txt`).

App Store Connect refuse certains caractères dans le champ « what to test » (les filets `━` par exemple) : une faute y faisait échouer `beta` **après** l'upload du binaire, laissant un build correct sans notes. `fastlane update_testflight_notes` corrige le texte seul, sans reconstruire ni renuméroter. Convention de nommage dans le Fastfile : les lanes portent un verbe, les helpers portent la valeur qu'ils renvoient — une lane et un helper homonymes se confondent silencieusement à l'appel. Garder ce fichier en ASCII est le plus sûr.

`setup_ci` est appelé en `before_all` sous `ENV["CI"]` : sans lui, `match` ne peut pas poser la key partition list et `codesign` gèle sur un runner headless.

## Localisation (obligatoire)

Toute chaîne visible par l'utilisateur doit être disponible **en français ET en anglais** dans `ios/HolyDay/Localizable.xcstrings`.

- La langue source est le **français** (`"sourceLanguage": "fr"`).
- Chaque clé doit avoir une entrée `fr` et une entrée `en` avec `"state": "translated"`.
- Ne jamais écrire de texte littéral en dur dans les vues SwiftUI. Toujours passer par `String(localized: "clé")` ou le `.init` `LocalizedStringKey`.
- Format du fichier : `.xcstrings` (String Catalog Xcode) — ne pas créer de fichiers `.strings` séparés.
- Côté Android, `values/` (fallback) = français et `values-en/` = anglais, pour reproduire le repli de `.xcstrings`. Toute clé ajoutée doit être reportée dans `shared/docs/KEYMAP.md`.

## Linting & formatage

Deux outils sont utilisés ensemble. Les respecter systématiquement avant tout commit.

### SwiftLint (`swiftlint`)

Config : `ios/.swiftlint.yml`.  
SwiftLint est intégré en build phase Xcode — les violations bloquent le build en erreur.

```bash
# Vérifier (depuis ios/)
cd ios && swiftlint lint --strict

# Corriger automatiquement ce qui peut l'être
cd ios && swiftlint --fix
```

Règles notables activées : `force_unwrapping`, `empty_count`.  
Règles désactivées : `trailing_whitespace`, `line_length`, `trailing_comma`, `todo`.

### swift-format (Apple)

Config : `ios/.swift-format`.  
Indentation : 2 espaces. Longueur de ligne : 100.  
`HolyDayUITests/SnapshotHelper.swift` (fourni par fastlane) est exclu — swift-format n'ayant
pas d'option d'exclusion, le dossier est listé fichier par fichier.

```bash
# Formater tous les fichiers Swift du projet (depuis ios/)
cd ios && swift-format format --recursive --in-place \
  HolyDay/ HolyDayShared/ HolyDayTests/ HolyDayWidget/ HolyDayUITests/HolyDayUITests.swift

# Vérifier sans modifier (identique au job `lint` de la CI)
cd ios && swift-format lint --strict --recursive \
  HolyDay/ HolyDayShared/ HolyDayTests/ HolyDayWidget/ HolyDayUITests/HolyDayUITests.swift
```

Les deux outils tournent aussi en pre-commit (`.pre-commit-config.yaml`), depuis la racine du dépôt — d'où le `--config ios/.swiftlint.yml` explicite. Aucun hook Kotlin pour l'instant.

## Intégration continue

Trois workflows, tous filtrés par `paths:` — un commit qui ne touche qu'une plateforme ne déclenche que sa CI.

| Workflow | Déclencheur | Contenu |
|---|---|---|
| `.github/workflows/ios-ci.yml` | push/PR `main`, `feature/*` sur `ios/**`, `shared/**` | SwiftLint + swift-format (`--strict`), Periphery (dead code, `--strict`), build & test |
| `.github/workflows/android-ci.yml` | idem sur `android/**`, `shared/**` | wrapper validation, Android Lint, tests unitaires, `assembleDebug` + `assembleRelease` |
| `.github/workflows/beta.yml` | push `main` sur `ios/**`, `shared/**` | `fastlane beta` → TestFlight |

Le parseur de workflows GitHub ne gère pas les ancres YAML : les listes `paths:` sont dupliquées volontairement entre `push` et `pull_request`.

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
- iOS cible : voir `ios/Config/` xcconfig

### L'état vit surtout dans des services, pas dans des ViewModels

Il n'existe qu'un seul vrai ViewModel (`ViewModels/PrayerGuideViewModel.swift`). Le reste de l'état applicatif est porté par des services singletons `@MainActor @Observable` exposés en `X.shared` (`VerseService`, `PrayerRecordService`, `NotificationService`, `SupportPromptService`, `TipService`, `AIAssistantService`, `AvatarService`), consommés directement par les vues. Android reproduit ce pattern à l'identique avec des `object` Kotlin — c'est pour ça qu'il n'y a **pas de framework DI** des deux côtés.

### Pont app → widgets (App Group)

À lire ensemble : `HolyDayShared/SharedStore.swift`, `Services/Common/WidgetSyncService.swift`, `HolyDayWidget/`.

Le store SwiftData est chiffré en `FileProtectionType.complete` (les prières sont des données sensibles), donc **illisible appareil verrouillé** — précisément le moment où WidgetKit rafraîchit une timeline. Les widgets ne lisent donc jamais SwiftData. L'app écrit un snapshot minimal (dernier verset **déjà localisé**, date de dernière prière) dans les `UserDefaults` de l'App Group `group.com.matthiascadet.HolyDay` via `SharedStore`, puis appelle `WidgetSyncService.sync()` / `.updateLastVerse(_:emotion:)`.

Tout nouvel état à afficher dans un widget doit passer par `SharedStore`. Le texte du verset est stocké déjà résolu parce que le deck par émotion est mélangé côté app : le widget ne peut pas le recalculer.

Sur Android ce pont n'existe pas — Glance tourne dans le même process que l'app.

### Back-deployment iOS 26 → iOS 18

La cible est iOS 18 (`Config/Config.shared.xcconfig`). **Ne jamais appeler directement** `glassEffect`, `GlassEffectContainer`, `.buttonStyle(.glass)` ou `Button(role: .close)` : tout passe par deux couches de compatibilité.

- `Theme/GlassCompat.swift` — `.appGlass(...)` / `AppGlassStyle` (`.regular`, `.clear`). Verre natif à partir d'iOS 26, matériau translucide équivalent en dessous. Le repli vise l'intention visuelle, pas le rendu.
- `Theme/BackDeployCompat.swift` — le reste des API iOS 26 (`AppCloseButton`, pilotage TipKit).

### Démarrage tolérant aux pannes

`HolyDayApp.swift` : si le store SwiftData ne s'ouvre pas (corruption, migration ratée), l'app **ne supprime jamais le fichier** — elle démarre en mémoire pour cette session et affiche une bannière d'avertissement, de sorte que les prières restent récupérables au lancement suivant.

### Mode capture d'écran

`Support/ScreenshotMode.swift` : les runs `fastlane snapshot` passent `--uiTestScreenshots` et `--screenshotEmotion <rawValue>` pour rendre le lancement déterministe (pas de splash, pas d'onboarding, pas de TipKit, émotion pré-sélectionnée). DEBUG uniquement — inerte en Release.

### Configurations de build

Le projet ne déclare que **deux configurations, `Debug` et `Release`** ; les trois schemes utilisent celles-ci. `Config.Staging.xcconfig` et les `*.xcconfig` à la racine de `ios/` ne sont référencés par rien — seul `Config/Config.shared.xcconfig` est la base configuration du projet. Les secrets vont dans `ios/Config/Secrets.{Debug,Release}.xcconfig` (non versionnés, inclus en `#include?`).

La clé SDK RevenueCat vit en clair dans `Theme/AppConstants.swift` : c'est une clé publique par conception, pas un secret.

### Android — toolchain figée

Ne pas monter AGP en 9.x : la compatibilité KSP/`kotlin-android` y est cassée (cf. `shared/docs/PORT_PROGRESS.md`, qui fait foi sur les versions). Room via KSP pour les données structurées, DataStore pour les préférences, Glance pour les widgets, `AlarmManager` + `BroadcastReceiver` pour les notifications.

## Conventions Swift

- Pas de `force unwrap` (`!`) sauf cas documenté et justifié
- `private` par défaut sur toutes les propriétés et méthodes non exposées
- Sections MARK pour organiser les vues (`// MARK: - Body`, `// MARK: - Helpers`, etc.)
- Pas de commentaires qui décrivent ce que fait le code — uniquement pourquoi (invariants non évidents, contournements)
