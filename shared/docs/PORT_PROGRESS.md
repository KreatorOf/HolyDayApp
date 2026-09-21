# Portage Android HolyDay — Suivi d'avancement

But : reproduire à l'identique (fonctionnalités, contenu, localisation FR/EN) l'app iOS native HolyDay en natif Android (Kotlin + Jetpack Compose), publier sur Play Store.

Ce fichier est la source de vérité de l'avancement. À relire en priorité en cas de reprise de session (compactage de contexte).

## Toolchain figée (validée par un build réussi le 2026-08-27)

**Ne pas monter en version sans raison** : AGP 9.x (>=9.0) casse la compatibilité classique KSP/kotlin-android plugin (bug de cast `BaseExtension` / rejet explicite de KSP en mode "built-in Kotlin"). Rester sur la ligne 8.x tant que l'écosystème KSP/Room n'a pas rattrapé AGP 9.

- Gradle wrapper : **8.14.5** (`gradle/wrapper/gradle-wrapper.properties`)
- AGP (`com.android.application`) : **8.13.2**
- Kotlin (`org.jetbrains.kotlin.android` + `org.jetbrains.kotlin.plugin.compose`) : **2.1.20**
- KSP (`com.google.devtools.ksp`) : **2.1.20-2.0.1**
- compileSdk / targetSdk : **36**, minSdk : **26**
- Compose BOM : **2025.06.01**
- androidx core-ktx **1.15.0**, core-splashscreen **1.0.1**, lifecycle-runtime-ktx/viewmodel-compose **2.9.4**, activity-compose **1.10.1**, navigation-compose **2.9.4**, datastore-preferences **1.1.7**, work-runtime-ktx **2.10.5**, glance-appwidget/glance-material3 **1.1.1** — versions volontairement légèrement en retrait des toutes dernières (qui exigent compileSdk 37 + AGP 9.1+, cf. `androidx.core:core:1.19.0` et `lifecycle 2.11.0`).
- Room **2.8.4**, RevenueCat Android **10.19.0**, review-ktx (Play In-App Review) **2.0.2**.
- Commande de build : `cd android && export JAVA_HOME=/Users/matt/.local/share/mise/installs/java/zulu-17 ANDROID_HOME=~/Library/Android/sdk ANDROID_SDK_ROOT=~/Library/Android/sdk && ./gradlew :app:assembleDebug`
- Icônes de lancement générées directement depuis `ios/HolyDay/Assets.xcassets/AppIcon.appiconset/HolyDay-iOS-Default-1024x1024@1x.png` (mêmes visuels que iOS) dans `mipmap-{m,h,xh,xxh,xxxh}dpi`, + export 512×512 dans `android/store/play/ic_launcher_512.png` pour la fiche Play Store.

## Décisions d'architecture (figées)

- Langage/UI : Kotlin + Jetpack Compose (Material3), package `com.matthiascadet.holyday`.
- Pas de framework DI (Hilt/Koin) : singletons `object` Kotlin, miroir exact du pattern iOS `X.shared`.
- Persistance structurée : Room (KSP) pour `PrayerEntry` et `PrayerIntention` (équivalent SwiftData `@Model`).
- Préférences/état léger : la dépendance Jetpack DataStore est présente, mais les services et les
  receivers historiques utilisent encore `SharedPreferences` pour leur accès synchrone. Une
  migration atomique avec reprise des données existantes reste nécessaire pour satisfaire
  complètement l'exigence DataStore.
- Widgets : Glance App Widgets (même process que l'app sur Android → pas besoin d'équivalent "App Group", simplification par rapport à iOS).
- Notifications : `AlarmManager` (alarme exacte quotidienne) + `BroadcastReceiver` qui poste la notif et reprogramme le lendemain, contenu rotatif déterministe par jour de l'année (miroir logique de `NotificationService`).
- Graphiques stats : Canvas Compose custom (pas de lib tierce, pour limiter le risque de build) — pas d'équivalent Swift Charts direct.
- Avis app : Play Core In-App Review API (équivalent `SKStoreReviewController`/`requestReview`).
- Sélection photo avatar : Android Photo Picker (`ActivityResultContracts.PickVisualMedia`).
- Paiements/dons : RevenueCat Android SDK (mêmes entitlements/offerings logiques que iOS ; nécessite config manuelle côté dashboard RevenueCat + Play Console, voir rapport final).
- Assistant IA (titres, questions de réflexion, recherche sémantique) : **gap de parité assumé**. Pas d'équivalent fiable et universel à FoundationModels sur Android (Gemini Nano/AICore limité à certains Pixel). Implémenté avec la même interface que `AIAssistantService` mais dégradation systématique vers les fallbacks (1re ligne comme titre, pas de questions IA, recherche texte simple) — comportement identique à un iPhone non compatible Apple Intelligence. Documenté comme limitation de plateforme dans le rapport final, pas un oubli.
- TipKit → système de coach-marks séquentiels custom Compose, persisté dans les préférences.
- Locale par défaut `values/` (fallback) = français (source language iOS = fr), `values-en/` = anglais explicite. Reproduit le comportement de repli de `Localizable.xcstrings` (sourceLanguage fr).

## Inventaire iOS de référence

Voir catalogue complet établi le 2026-08-27 (dans l'historique de conversation) : 25 vues, 1 ViewModel dédié + services `@Observable` faisant office de ViewModels, 6 models, 10 services, theme/glass compat, widget bundle (2 widgets), app shell, ~270+23 clés de localisation, 1 seule dépendance tierce (RevenueCat), 4 fichiers de tests unitaires + 1 UI test (screenshots fastlane).

## État d'avancement

Légende : ⬜ à faire · 🟨 en cours · ✅ fait · ⚠️ fait avec limitation documentée

### 0. Scaffold projet
- ✅ Structure Gradle (settings, build root, app module, wrapper) — build + assembleDebug OK

### 1. Data layer (Models + Room + DataStore)
- ✅ Emotion, Verse, PrayerStep, SupporterTier (data class/enum) — `data/model/`
- ✅ VerseCorpus (36 versets FR/EN, extraits programmatiquement de VerseCorpus.swift pour garantir la fidélité du texte biblique — script dans le scratchpad, voir aussi `KEYMAP.md` (ce dossier) pour la correspondance des clés de localisation)
- ✅ Room entities PrayerEntry, PrayerIntention + DAO + Database — `data/db/` (PrayerEntryEntity/PrayerIntentionEntity/*Dao/AppDatabase)
- ✅ Theme Compose (`ui/theme/Color.kt`, `AppTheme.kt`) — couleurs exactes extraites des colorset iOS (light+dark), pastels d'émotions exacts
- ⚠️ Migration DataStore des préférences historiques — à faire sans perdre les préférences déjà
  enregistrées ; les données structurées sont déjà sous Room.
- Note qualité : 27 clés de localisation iOS orphelines (feature "milestones"/streak + widget heatmap jamais câblés dans le code Swift actuel) ont été délibérément exclues du port — non fonctionnelles sur iOS non plus, cf. grep de vérification. Ne pas les réintroduire sans vérifier qu'elles sont utilisées.
- Piège d'outillage noté : Kotlin imbrique les commentaires `/* */` — tout `/*` littéral dans un KDoc (ex: chemin de fichier avec un glob) casse la compilation ("Unclosed comment"). Éviter.

### 2. Services — TOUS FAITS ET COMPILENT (`service/`)
- ✅ VerseService — port fidèle (pioche/deck par émotion, LSG/BSB comme iOS)
- ✅ PrayerRecordService — StateFlow au lieu de @Observable, SharedPreferences au lieu de UserDefaults
- ✅ PrayerStats (`data/model/PrayerStats.kt`) — bucket semaine=ISO lundi (iOS = 1er jour de semaine de la locale ; différence mineure assumée)
- ✅ NotificationService + PrayerReminderReceiver + BootRescheduleReceiver — **redesign volontaire** : au lieu de pré-planifier 60 notifications (contournement de la limite iOS de 64 notifs en attente), une seule AlarmManager exacte s'auto-replanifie à chaque déclenchement. Comportement perçu identique, mécanisme plus simple car Android n'a pas cette limite.
- ✅ Rappels contextuels (`ReminderPlanner`, miroir de `ReminderPlanner.swift`, mêmes tests) — silence le jour où l'on a déjà prié, verset du thème de la dernière émotion pendant 2 jours, invitation « intentions » le dimanche si une intention ouverte a ≥ 7 jours (tap → écran Intentions via `holyday://intentions`). **Écart de mécanisme assumé** : iOS fige le contenu à la planification et replanifie après chaque prière ; Android lit Room au déclenchement dans le récepteur (`goAsync`). Règles et résultat perçu identiques.
- ✅ SupportPromptService — classe injectable + `.shared`, mêmes seuils/cooldowns (5 jours, 3 max, 0/30/90j)
- ✅ TipService (RevenueCat Android SDK `com.revenuecat.purchases:purchases:10.19.0`) — a compilé du premier coup contre le vrai SDK (awaitOfferings/awaitCustomerInfo/entitlements/nonSubscriptionTransactions). **Nécessite avant publication** : créer l'app Android dans le dashboard RevenueCat + produits Play Console + remplacer `RevenueCatConfig.API_KEY` placeholder (`ui/theme/AppConstants.kt`) — voir rapport final.
- ✅ AvatarService — Bitmap crop carré 256px, JPEG q85, `context.filesDir` (équivalent Documents)
- ✅ AIAssistantService — stub dégradé assumé (voir décisions d'architecture)
- ✅ WidgetSyncService — écrit dans SharedPreferences + déclenche `GlanceAppWidget.updateAll()` (pas besoin d'App Group, même process)

### 3. Theme
- ✅ Couleurs et typographie (`AppTheme`) : palette issue des assets iOS, hiérarchie serif
  éditoriale + sans-serif système pour le fonctionnel, contrastes secondaires renforcés.
- ✅ AppConstants (liens, RevenueCat config)
- ✅ `GlassCompat` Android : adaptation Material 3 par surfaces tonales, liseré discret et
  élévation faible. Pas de faux flou Liquid Glass : Android conserve son propre langage natif.

### 4. Navigation & shell — FAIT, compile et s'assemble (`ui/navigation/HolyDayNavHost.kt`)
- ✅ NavHost unique (pas de nested nav) : routes ONBOARDING/MAIN/FREE_PRAYER/STRUCTURED_PRAYER/INTENTIONS/INTENTION_DETAIL/JOURNAL_ENTRY/JOURNAL_STATS/LEGAL/PAYWALL/DONATION_THANK_YOU/DEBUG_MENU. `selectedEmotion`/`emotionVerse` hoistés au niveau du NavHost (state Compose simple, pas de ViewModel partagé — équivalent des `@State` de `ContentView`).
- ✅ MainScreen : Scaffold + NavigationBar 3 items (switch de contenu direct, pas de sous-NavHost — miroir de `TabView` iOS)
- ⬜ SplashScreen dédié (actuellement géré par `core-splashscreen` système au démarrage froid uniquement, pas de splash custom animé 2.5s comme iOS — gap mineur)
- ✅ Deep links `holyday://pray|verse|journal` — `MainActivity` transmet l'intent au NavHost ; les
  deux premiers ouvrent l'onglet Prière et `journal` sélectionne le Journal, même si l'app était
  déjà ouverte.

### 5. Écrans
- ✅ Home (`ui/home/HomeScreen.kt`) — question ressenti, EmotionRibbon, verset révélé, menu Prier (libre/guidée), bouton intentions
- ✅ EmotionRibbon (marquee 2 rangées, vitesses différentes, tap pour sélectionner) + EmotionVerse (révélation mot par mot) + VerseRecall — `ui/prayer/`
- ✅ FreePrayerScreen
- ✅ StructuredPrayerScreen + PrayerStepCard + PrayerGuideViewModel (Room upsert, intentions actives à l'étape Supplication, questions de réflexion IA toujours vides — cf. AIAssistantService)
- ✅ IntentionsScreen + IntentionDetailScreen — CRUD complet, segments actif/exaucé. **Simplifié** : pas de l'animation en 2 phases (glissement + mains jointes qui persistent 1s) de l'iOS — bascule directe. Gap visuel assumé, pas fonctionnel.
- ✅ PrayerHistoryScreen / PrayerEntryDetailScreen / JournalStatsScreen (`ui/journal/`) — calendrier mensuel + points d'activité, decks pliables guidées/libres, recherche texte (pas de recherche sémantique IA, cf. gap AIAssistantService), stats activité + donut émotions via Canvas custom (`StatsCharts.kt`, pas de lib tierce)
- ✅ OnboardingScreen (`ui/onboarding/`) — 6 étapes (hero/valeur/prénom/1re intention/confidentialité/notifications), transitions slide, indicateur de progression, bouton retour. Simplifié : pas de halo "respirant" ni cascade d'apparition séquentielle des features (décoratif).
- ✅ Parcours post-onboarding (`service/TourService.kt`, `ui/common/TourTip.kt`) — les quatre
  invitations Material 3 sont persistantes et séquentielles (ressenti → prier → intentions →
  journal), miroir des règles/événements de TipKit. Leur rendu est une boîte de dialogue Android,
  plutôt qu'une bulle ancrée iOS : adaptation visuelle native sans écart métier.
- ✅ SettingsScreen / LegalNoticeScreen (`ui/settings/`) — profil (nom + avatar via Android Photo Picker), soutien (badge + lien paywall), apparence (system/light/dark, câblé jusqu'à `HolyDayTheme` dans `MainActivity`), notifications (toggle + permission POST_NOTIFICATIONS runtime + time picker Material3), communauté (partage via Intent.ACTION_SEND + notation Play Store directe), légal (liens externes + mentions légales), à propos, zone danger (reset complet avec confirmation), section debug (gate `BuildConfig.DEBUG`)
- ✅ PaywallScreen / DonationThankYouScreen / SupportPromptScreen / SupporterBadge (`ui/support/`) — achat réel via RevenueCat Android (`awaitPurchase`/`awaitRestore`), palier dérivé du rang de prix, badge, sollicitation douce câblée depuis la fermeture des feuilles de prière (`onPrayerSheetDismissed` dans `HolyDayNavHost`, miroir de `presentSupportPromptIfEligible`). L'écran de remerciement conserve une action Continuer et une invitation secondaire à noter l'app, comme l'iOS actuel. **Simplifié** : pas de `SparksView` (particules scintillantes).
- ✅ DebugMenuScreen (`ui/debug/`) — état, resets, seed 14 jours de démo, "tout réinitialiser". Accessible uniquement via `BuildConfig.DEBUG` (le fichier lui-même n'est pas exclu du binaire release comme le `#if DEBUG` iOS — gap mineur assumé : le code est présent mais inatteignable en release).

**Section 5 (Écrans) : TOUS FAITS.** Projet compile intégralement (`assembleDebug` OK) avec tous les écrans réels (aucun stub restant).

### 6. Widgets Glance
- ✅ PrayNowWidget — état invite/prié aujourd'hui, ouvre MainActivity au tap
- ✅ VerseWidget — dernier verset reçu, ouvre MainActivity au tap
- ⏳ **Gap de parité assumé (refonte widgets iOS, 2026-09-17)** — non porté volontairement tant que les modifs Glance en cours ne sont pas stabilisées :
  - verset du jour de repli (`WidgetVerseResolver` : le verset d'émotion ne vaut que pour son jour, puis rotation déterministe du corpus) — à porter à l'identique, mêmes tests ;
  - bouton « Un autre verset » (`NextVerseIntent`, compteur du jour dans l'App Group) → équivalent Glance `actionRunCallback` ;
  - routes ciblées (`AppRoute` : `holyday://pray`, `pray/free`, `intentions`, `journal`) → `HolyDayNavHost` ne gère aujourd'hui que `journal` et `intentions` ;
  - commande « Prier » (`ControlWidget`, iOS 18) → pas d'équivalent direct ; la tuile Quick Settings (`TileService`) serait la plus proche.
- Note : rendu volontairement simple (un seul layout, pas de tailles small/medium/large distinctes comme iOS) — à enrichir si besoin visuel après premier test sur device/émulateur.

### 6 bis. Écran de nouveautés
- ✅ iOS : `WhatsNewService` + `ReleaseNotesCatalog` + `WhatsNewView`, présenté après le splash depuis `MainTabView`, 12 tests unitaires.
- ✅ Android : `ReleaseNotesCatalog`, `WhatsNewService` et `WhatsNewScreen` sont portés. La
  version Android est désormais **1.2.0** (`versionCode` 4). Les invariants iOS sont couverts par
  six tests JVM : l'onboarding marque la version comme vue ; un repère absent est donc une mise à
  jour ancienne et n'affiche que la note de la version installée ; les versions sautées sont
  regroupées par ordre décroissant. L'écran est un `Dialog` Compose plein format, avec fermeture
  explicite et retour système. Le menu debug peut réinitialiser le repère pour les testeurs.

### 6 ter. Lien « noter l'application »
- ✅ iOS : `AppLinks.writeReview` (`?action=write-review`) remplace `requestReview` dans les Réglages, et une invitation discrète est posée sur l'écran de remerciement après un don.
- ✅ Android : `AppLinks.openReview` ouvre directement `market://details?id=…`, avec repli vers la
  fiche web Play Store si l'app Play Store est absente. Le lien est présent dans les Réglages et
  dans la célébration de don ; cette dernière ne se ferme plus automatiquement afin que la cible
  soit réellement utilisable, conformément au comportement iOS actuel.

### 6 quater. Carnet, relecture du soir et cheminement des intentions
- ✅ iOS et Android : un verset affiché depuis l'accueil peut être enregistré ou retiré en un geste.
  Le carnet permet de le relire, d'ajouter une note personnelle et de le supprimer. Les données
  restent locales (`SavedVerse` SwiftData / `SavedVerseEntity` Room).
- ✅ iOS et Android : la relecture du soir est accessible dans le menu « Prier ». Elle recueille
  une émotion facultative, la gratitude, la difficulté du jour et ce qui est confié pour demain,
  puis crée une entrée distincte dans le journal et met à jour le suivi de prière.
- ✅ iOS et Android : le détail d'une intention contient désormais une chronologie libre
  d'évolutions datées. La suppression de l'intention supprime ses évolutions en cascade.
- ✅ Android : migration Room 1 → 2 explicite et non destructive pour les deux nouvelles tables.
- ✅ Parité et qualité : toutes les nouvelles chaînes existent en français et en anglais et sont
  référencées dans `KEYMAP.md`. Build iOS, tests XCTest, SwiftLint/swift-format, tests JVM, lint et
  assemblage Android validés le 2026-09-22.

### 7. Localisation
- ⬜ Extraction complète des clés .xcstrings → strings.xml (fr default + en)
- **Divergences de valeur volontaires** (même clé, texte différent par plateforme — ne pas « corriger » en recopiant le texte iOS) :
  - `legal.section.notifications.content` → iOS dit « notifications locales d'iOS », Android « notifications locales d'Android ».
  - `paywall.legal.footer` → iOS dit « Paiements gérés par Apple », Android « Paiements gérés par Google Play ».
  - Les deux étaient des copies littérales du texte iOS, corrigées en 1.0.1.

### 8. Tests
- ✅ Unit tests — **41/41 passent** (`./gradlew :app:testDebugUnitTest`)
  - `VerseTest` (3) — round-trip Codable non porté (pas de sérialisation JSON de `Verse` sur Android), reste testé : stockage des champs, unicité d'ID, stabilité d'ID explicite
  - `VerseServiceTest` (5) — miroir exact
  - `SupportPromptServiceTest` (9) — miroir exact, via `FakeSharedPreferences` (in-memory) au lieu d'une suite `UserDefaults` isolée
  - `PrayerGuideViewModelTest` (18 au sens Gradle car chaque `@Test` méthode ; correspond aux mêmes cas que l'iOS) — a nécessité un refactor de `PrayerGuideViewModel` (retrait de `AndroidViewModel`/`Application` du constructeur, `Context` déplacé en paramètre de `save()`) pour rester testable en JVM pur sans Robolectric, à l'identique du ViewModel iOS qui ne détient pas non plus de `ModelContext`
  - `WhatsNewServiceTest` (6) — invariants d'installation neuve, mise à jour, versions sautées,
    absence de note, reset et comparaison numérique.
  - Bug réel trouvé et corrigé pendant l'écriture des tests : `SupportPromptService.shared` était initialisé **avec ses valeurs par défaut** dès le chargement de la classe (au lieu d'à la première utilisation), ce qui plantait dès qu'une instance de test isolée était construite. Corrigé en `by lazy` (comportement `static let` Swift, plus fidèle à l'iOS).
- ⬜ Tests instrumentés (androidTest) — non écrits, gap assumé faute de temps (les 4 fichiers iOS n'ont pas d'équivalent `HolyDayUITests` autre que les captures d'écran fastlane, non applicables)
- ✅ Smoke test réel sur émulateur (AVD "Pixel_10_Pro", Android 37 preview, déjà configuré sur la machine) : install + lancement + parcours complet onboarding (6 étapes, y compris la vraie boîte de dialogue système de permission notifications) → sélection d'émotion → révélation du verset mot par mot → menu Prier → Prière libre → sauvegarde → Journal (calendrier, jour marqué, entrée affichée) → Réglages (profil, apparence, notifications). Aucun crash (`logcat` vérifié).
  - **Bug réel trouvé et corrigé grâce à ce test** (invisible à la compilation) : le flux "Activer les rappels" de l'onboarding demandait bien la permission Android mais n'appelait jamais `NotificationService.setReminder(...)`, donc le rappel n'était jamais réellement programmé ni persisté — les Réglages affichaient le bouton bascule à l'état désactivé avec un avertissement de permission alors que la permission venait d'être accordée. Corrigé (`OnboardingScreen.kt`) + ajout d'un rafraîchissement d'état (`NotificationService.checkStatus`) à l'ouverture des Réglages (miroir de l'`.onAppear` iOS). Vérifié après correction : bascule active, heure 08:00 affichée, et `adb shell dumpsys alarm` confirme une alarme exacte réellement programmée (`RTC_WAKEUP` sur `PrayerReminderReceiver`).

### 9. Rapport final
- ✅ Rapport livré à l'utilisateur (artifact) — voir aussi ce fichier pour le détail technique complet.
- Lint Android (`./gradlew :app:lintDebug`) : 0 erreur, 104 avertissements (principalement `UnusedResources` sur des clés de traduction pas encore consommées par un écran, `UseKtx`, icônes de lancement non-adaptatives). Rien de bloquant.
- Suite complète validée le 2026-09-12 : `./gradlew :app:testDebugUnitTest :app:lintDebug
  :app:assembleDebug :app:assembleRelease` → tout vert (41 tests ; APK debug et release 1.1
  générés).

## Notes de reprise

(mis à jour à chaque étape significative — dernière étape en cours, prochaine action prévue)

- 2026-08-27 : Inventaire iOS terminé. Décisions d'architecture figées ci-dessus. Prochaine action : créer les fichiers Gradle du projet Android (`android/settings.gradle.kts`, `android/build.gradle.kts`, `android/gradle/wrapper/*`, `android/app/build.gradle.kts`, `AndroidManifest.xml`), package `com.matthiascadet.holyday`.
- 2026-08-28 : Réorganisation du dépôt en monorepo `ios/` + `android/` + `shared/` (voir `CLAUDE.md`). Le projet Xcode a été déplacé tel quel dans `ios/` (aucune référence de chemin dans `project.pbxproj` n'a dû être modifiée — build réel vérifié depuis le nouvel emplacement). Ce fichier et `KEYMAP.md` déménagent dans `shared/docs/`. Ajout de `shared/data/verses.json`, extrait mécaniquement (script Python, 36/36 entrées vérifiées) de `ios/HolyDayShared/VerseCorpus.swift` : c'est une référence de parité, pas encore la source consommée au runtime par les deux apps (qui embarquent chacune leur propre copie, cf. ci-dessus) — brancher les deux plateformes dessus reste à faire si on veut éliminer la duplication pour de bon.
- 2026-09-12 : rattrapage Android de la 1.1 iOS : nouveautés, notation Play Store, liens
  `holyday://…`, parcours de découverte et cycle de rafraîchissement au retour au premier plan.
  Les seules divergences restantes sont celles explicitement signalées ci-dessus, notamment la
  dégradation IA dépendante de la plateforme et la migration DataStore des préférences historiques.
- 2026-09-12 : audit visuel iOS/Android et passe de finition Android. La grosse barre d'onglets
  flottante a été remplacée par une `NavigationBar` Material 3 native avec indicateur tonal ; les
  CTA de l'accueil utilisent désormais des surfaces élevées neutres avec accent violet, les ombres
  globales sont plus courtes et les contours plus fins, le fond clair gagne une profondeur à peine
  perceptible et les textes tertiaires restent lisibles. Contrôle réel effectué sur les trois
  onglets avec l'AVD Pixel_10_Pro. Il s'agit d'une adaptation de présentation sans divergence
  fonctionnelle avec iOS.
- 2026-09-12 : lot de cohérence visuelle A. Ajout d'un `HolyDayScaffold` commun, adopté par les
  parcours de prière libre et guidée ; action principale de la prière libre fixée au-dessus du
  clavier, zone de rédaction agrandie, progression ACTS visible, hiérarchie des boutons alignée sur
  Material 3. Les émotions ont désormais un état sélectionné explicite. Les dialogues bloquants du
  parcours de découverte sont remplacés par des coach-marks non modaux placés près de la cible.
  Aucun changement de règle métier ni nouvelle divergence avec iOS.
- 2026-09-12 : lot visuel B. L'accueil guide maintenant l'utilisateur avant la première sélection
  et nuance discrètement son fond selon l'émotion. Les intentions utilisent le contrôle segmenté
  Material 3, un état vide illustré et un détail structuré en carte avec statut explicite. Le
  calendrier distingue sans ambiguïté aujourd'hui, la sélection et l'intensité de prière ; les
  cartes du journal ont un accent vertical et leurs états vides sont illustrés. Les statistiques
  adoptent une sélection de période Material 3, des cartes cohérentes et un total central dans le
  donut. Nouvelle clé Android `home_emotion_hint` documentée dans `KEYMAP.md` ; aucune divergence
  fonctionnelle introduite.
- 2026-09-13 : lot visuel C. L'onboarding gagne un halo respirant et des bénéfices présentés sur
  des surfaces tonales ; la fin de prière et le remerciement après don disposent d'une apparition
  ou respiration de célébration. Le paywall hiérarchise mieux son message, identifie sobrement le
  palier recommandé et précise l'achat unique ; la sollicitation de soutien et les nouveautés sont
  désormais des feuilles Material 3. Les nouveautés adoptent une lecture en timeline. Les deux
  widgets Glance utilisent `SizeMode.Responsive` et adaptent marges et typographie aux formats
  compact, horizontal et large. Nouvelles clés Android `paywall_recommended` et
  `paywall_one_time` documentées dans `KEYMAP.md`, sans divergence métier avec iOS.
- 2026-09-13 : lot visuel D de consolidation. Le détail d'une entrée et les mentions légales
  partagent désormais le scaffold secondaire Android, une largeur de lecture bornée et une
  typographie plus respirante. Journal et Réglages sont eux aussi bornés sur grands écrans ; la
  recherche du journal prend immédiatement le focus et adopte un champ Material 3 complet. Le
  sélecteur d'apparence est remplacé par `SingleChoiceSegmentedButtonRow`, les actions de profil
  et de calendrier disposent de libellés d'accessibilité et respectent les cibles tactiles. Le
  ruban d'émotions devient statique et défilable lorsque l'échelle d'animation système vaut zéro.
  Les nouvelles clés Android d'accessibilité et du menu debug sont documentées dans `KEYMAP.md` ;
  aucune règle métier ni divergence fonctionnelle n'est introduite. La recette sur émulateur a
  également révélé puis corrigé les icônes de barre d'état qui restaient sombres après le passage
  manuel au thème sombre ; leur apparence suit maintenant immédiatement le thème de l'app.
  Le Journal utilise enfin un fond uni derrière le `Scaffold` transparent : la rupture de teinte
  horizontale auparavant visible entre l'en-tête et le calendrier est supprimée, sans variation
  résiduelle du haut au bas de l'écran.
  Après validation visuelle, ce fond uni est généralisé à tous les écrans Android : les anciens
  dégradés globaux sont retirés et la profondeur reste assurée par les surfaces et accents locaux.
  Les titres principaux `HolyDay`, `Journal` et `Réglages` partagent désormais le même niveau
  typographique serif `headlineMedium` ; Journal et Réglages utilisent la même barre supérieure
  et le même positionnement, tandis que la marque reste centrée sur l'accueil.
  Les actions Statistiques et Recherche du Journal sont désormais présentées comme des boutons
  iconographiques Material 3 sur surface tonale, sans changement de parcours ni de fonctionnalité.
  L'icône Android est désormais une adaptive icon native : fond violet de marque, étincelle
  minimaliste et variante monochrome pour les lanceurs Android 13+, au lieu de la reprise
  volumétrique de l'icône iOS.
