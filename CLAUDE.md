# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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

### Livraison iOS (Xcode Cloud + fastlane, depuis `ios/`)

**Xcode Cloud est le seul producteur de binaires.** Un push sur `main` lint, teste, archive et dépose sur TestFlight ; aucune lane fastlane ne compile plus quoi que ce soit. fastlane ne couvre que ce qu'Xcode Cloud ne sait pas faire : la fiche App Store, la review, les captures.

`bundle exec fastlane <lane>` depuis `ios/`. Quatre lanes, aucune ne recompile :

| Lane | Effet |
|---|---|
| `beta_external` | Distribue le build TestFlight courant aux testeurs externes + Beta App Review |
| `release` | Promeut vers l'App Store le dernier build TestFlight de la version courante |
| `update_testflight_notes` | Met à jour le « ce qu'il faut tester » du dernier build TestFlight |
| `screenshots` | `capture_screenshots` (config `fastlane/Snapfile`) |

Le principe commun : `distribute_only` (pilot) et `skip_binary_upload` (deliver) désignent un build **déjà en ligne** au lieu d'en téléverser un nouveau. C'est ce qui garantit qu'on soumet exactement le binaire testé et non un jumeau recompilé après la recette. Erreur facile à faire : ces deux actions ont des jeux d'options distincts pour la même idée. Toutes échouent explicitement si aucun build TestFlight n'existe pour la version courante (helper `current_testflight_build`).

`release` : `submit_for_review` est à `false` par défaut — `fastlane release submit:true` pour envoyer en review, et la mise en vente reste manuelle (`automatic_release: false`). Les captures ne sont pas versionnées (`fastlane/screenshots/` est vide) : `release` laisse par défaut intactes celles en ligne. Pour les remplacer : `fastlane screenshots` puis `fastlane release screenshots:true`.

Le « ce qu'il faut tester » vit dans `ios/TestFlight/WhatToTest.<locale>.txt` (`fr-FR` et `en-US`), à côté du `.xcodeproj` : c'est l'emplacement qu'Xcode Cloud lit tout seul pour joindre les notes au build qu'il distribue. Les lanes lisent le même fichier `fr-FR` — une seule source de vérité. Distinct des notes App Store (`fastlane/metadata/<langue>/release_notes.txt`), qui s'adressent au public.

App Store Connect refuse certains caractères dans le champ « what to test » (les filets `━` par exemple) : garder ces fichiers en ASCII est le plus sûr. `fastlane update_testflight_notes` corrige le texte seul, sans renuméroter. Convention de nommage dans le Fastfile : les lanes portent un verbe, les helpers portent la valeur qu'ils renvoient — une lane et un helper homonymes se confondent silencieusement à l'appel.

Plus de `match` : la signature est entièrement automatique (cloud managed signing). Les cibles `HolyDay` et `HolyDayWidgetExtension` sont en `CODE_SIGN_STYLE = Automatic` **en Debug comme en Release**, sans `PROVISIONING_PROFILE_SPECIFIER` — un profil `match AppStore …` codé en dur fait échouer l'archive Xcode Cloud, qui ne dispose d'aucun profil importé. Ne pas réintroduire `update_code_signing_settings` dans le Fastfile.

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

# Vérifier sans modifier (identique à ci_scripts/ci_pre_xcodebuild.sh)
cd ios && swift-format lint --strict --recursive \
  HolyDay/ HolyDayShared/ HolyDayTests/ HolyDayWidget/ HolyDayUITests/HolyDayUITests.swift
```

Les deux outils tournent aussi en pre-commit (`.pre-commit-config.yaml`), depuis la racine du dépôt — d'où le `--config ios/.swiftlint.yml` explicite. Aucun hook Kotlin pour l'instant.

## Intégration continue

La CI iOS est **Xcode Cloud** (workflows définis dans App Store Connect, pas dans le dépôt). GitHub Actions ne garde que l'Android.

| Chaîne | Déclencheur | Contenu |
|---|---|---|
| Xcode Cloud, workflow **CI** | PR (toutes branches) + push sur `feature/*`, filtre `ios/`, `shared/` | `ci_pre_xcodebuild` (SwiftLint + swift-format `--strict`), Test `HolyDay Dev`, `ci_post_xcodebuild` (Periphery `--strict`). N'archive rien |
| Xcode Cloud, workflow **TestFlight** | push `main`, filtre `ios/`, `shared/` | Archive `HolyDay`, *Deployment Preparation* = TestFlight and App Store → dépôt TestFlight |
| `.github/workflows/android-ci.yml` | push/PR `main`, `feature/*` sur `android/**`, `shared/**` | wrapper validation, Android Lint, tests unitaires, `assembleDebug` + `assembleRelease` |

Deux workflows et pas un seul : la distribution TestFlight est une propriété de l'action Archive, pas de la branche. Un workflow unique couvrant `main` et `feature/*` enverrait un build aux testeurs à chaque push de branche de feature.

Le filtre Files & Folders (`START_IF_ANY_FILE_MATCHES` sur les dossiers `ios` et `shared`) joue le rôle du `paths:` de GitHub Actions : un commit Android-only ne consomme pas de minutes Xcode Cloud.

L'action Test épingle un couple simulateur/runtime précis (`iPhone 17 Pro` / `iOS 27.0`) : l'API exige un `testDestinations` explicite, il n'y a pas de « dernier runtime disponible ». Quand Apple retire ce runtime des images, le workflow échoue au démarrage — c'est là qu'il faut aller le changer, pas dans le dépôt.

Le parseur de workflows GitHub ne gère pas les ancres YAML : les listes `paths:` d'`android-ci.yml` sont dupliquées volontairement entre `push` et `pull_request`.

### Xcode Cloud — ce qui vit dans le dépôt

Xcode Cloud ne cherche ses scripts **que** dans un dossier `ci_scripts/` situé au même niveau que le `.xcodeproj` : ici `ios/ci_scripts/`, pas la racine du monorepo. Le cwd des scripts est ce dossier — d'où `${CI_PRIMARY_REPOSITORY_PATH}/ios` partout plutôt que des chemins relatifs.

| Script | Rôle |
|---|---|
| `ci_post_clone.sh` | Installe SwiftLint (absent de l'image ; swift-format est fourni par Xcode via `xcrun`), approfondit le clone superficiel |
| `ci_pre_xcodebuild.sh` | Porte de qualité : SwiftLint + swift-format `--strict`. Ne s'exécute que sur `build` et `build-for-testing` |
| `ci_post_xcodebuild.sh` | Periphery `--strict` sur l'index-store de `build-for-testing` — pas de seconde compilation. Avertit sans bloquer si l'index-store a bougé |

Les trois scripts filtrent `CI_XCODEBUILD_ACTION` **avant** de toucher au moindre chemin. Xcode Cloud rejoue les scripts sur une seconde machine pour `test-without-building`, et `CI_PRIMARY_REPOSITORY_PATH` y est vide : un `cd "${CI_PRIMARY_REPOSITORY_PATH}/ios"` placé en tête devient `cd /ios` et fait échouer l'action alors que le lint est déjà passé sur la machine de build.

La build phase SwiftLint du projet sort immédiatement sous `CI_XCODE_CLOUD` : sinon chaque cible relinterait l'arbre déjà validé par `ci_pre_xcodebuild.sh`.

Xcode Cloud résout le projet par le `containerFilePath` du workflow, enregistré à sa création : il est resté sur `HolyDay.xcodeproj` après le passage en monorepo (`6d2530f`) et a fait échouer treize runs d'affilée sur `Project HolyDay.xcodeproj does not exist at the root of the repository`. Tout déplacement du `.xcodeproj` doit être reporté dans les deux workflows.

Le **numéro de build de départ** ne vit pas non plus dans le dépôt : App Store Connect → Xcode Cloud → Settings → Build Number. La numérotation Xcode Cloud est indépendante de `CURRENT_PROJECT_VERSION` et doit rester supérieure au dernier build déjà en ligne.

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
