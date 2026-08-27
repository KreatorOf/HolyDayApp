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
- Préférences/état léger : Jetpack DataStore (Preferences) — équivalent `UserDefaults` (PrayerRecordService, SupportPromptService, onboarding, tips vus, avatar path, réglages notifications).
- Widgets : Glance App Widgets (même process que l'app sur Android → pas besoin d'équivalent "App Group", simplification par rapport à iOS).
- Notifications : `AlarmManager` (alarme exacte quotidienne) + `BroadcastReceiver` qui poste la notif et reprogramme le lendemain, contenu rotatif déterministe par jour de l'année (miroir logique de `NotificationService`).
- Graphiques stats : Canvas Compose custom (pas de lib tierce, pour limiter le risque de build) — pas d'équivalent Swift Charts direct.
- Avis app : Play Core In-App Review API (équivalent `SKStoreReviewController`/`requestReview`).
- Sélection photo avatar : Android Photo Picker (`ActivityResultContracts.PickVisualMedia`).
- Paiements/dons : RevenueCat Android SDK (mêmes entitlements/offerings logiques que iOS ; nécessite config manuelle côté dashboard RevenueCat + Play Console, voir rapport final).
- Assistant IA (titres, questions de réflexion, recherche sémantique) : **gap de parité assumé**. Pas d'équivalent fiable et universel à FoundationModels sur Android (Gemini Nano/AICore limité à certains Pixel). Implémenté avec la même interface que `AIAssistantService` mais dégradation systématique vers les fallbacks (1re ligne comme titre, pas de questions IA, recherche texte simple) — comportement identique à un iPhone non compatible Apple Intelligence. Documenté comme limitation de plateforme dans le rapport final, pas un oubli.
- TipKit → système de coach-marks séquentiels custom Compose + DataStore (flags "tip vu").
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
- ⬜ DataStore preferences wrapper (à faire avec les services qui en dépendent)
- Note qualité : 27 clés de localisation iOS orphelines (feature "milestones"/streak + widget heatmap jamais câblés dans le code Swift actuel) ont été délibérément exclues du port — non fonctionnelles sur iOS non plus, cf. grep de vérification. Ne pas les réintroduire sans vérifier qu'elles sont utilisées.
- Piège d'outillage noté : Kotlin imbrique les commentaires `/* */` — tout `/*` littéral dans un KDoc (ex: chemin de fichier avec un glob) casse la compilation ("Unclosed comment"). Éviter.

### 2. Services — TOUS FAITS ET COMPILENT (`service/`)
- ✅ VerseService — port fidèle (pioche/deck par émotion, LSG/KJV comme iOS)
- ✅ PrayerRecordService — StateFlow au lieu de @Observable, SharedPreferences au lieu de UserDefaults
- ✅ PrayerStats (`data/model/PrayerStats.kt`) — bucket semaine=ISO lundi (iOS = 1er jour de semaine de la locale ; différence mineure assumée)
- ✅ NotificationService + PrayerReminderReceiver + BootRescheduleReceiver — **redesign volontaire** : au lieu de pré-planifier 60 notifications (contournement de la limite iOS de 64 notifs en attente), une seule AlarmManager exacte s'auto-replanifie à chaque déclenchement. Comportement perçu identique, mécanisme plus simple car Android n'a pas cette limite.
- ✅ SupportPromptService — classe injectable + `.shared`, mêmes seuils/cooldowns (5 jours, 3 max, 0/30/90j)
- ✅ TipService (RevenueCat Android SDK `com.revenuecat.purchases:purchases:10.19.0`) — a compilé du premier coup contre le vrai SDK (awaitOfferings/awaitCustomerInfo/entitlements/nonSubscriptionTransactions). **Nécessite avant publication** : créer l'app Android dans le dashboard RevenueCat + produits Play Console + remplacer `RevenueCatConfig.API_KEY` placeholder (`ui/theme/AppConstants.kt`) — voir rapport final.
- ✅ AvatarService — Bitmap crop carré 256px, JPEG q85, `context.filesDir` (équivalent Documents)
- ✅ AIAssistantService — stub dégradé assumé (voir décisions d'architecture)
- ✅ WidgetSyncService — écrit dans SharedPreferences + déclenche `GlanceAppWidget.updateAll()` (pas besoin d'App Group, même process)

### 3. Theme
- ⬜ Couleurs (AppTheme équivalent), typographie
- ⬜ AppConstants (liens, RevenueCat config)
- ⬜ GlassCompat Android (Surface/blur maison)

### 4. Navigation & shell — FAIT, compile et s'assemble (`ui/navigation/HolyDayNavHost.kt`)
- ✅ NavHost unique (pas de nested nav) : routes ONBOARDING/MAIN/FREE_PRAYER/STRUCTURED_PRAYER/INTENTIONS/INTENTION_DETAIL/JOURNAL_ENTRY/JOURNAL_STATS/LEGAL/PAYWALL/DONATION_THANK_YOU/DEBUG_MENU. `selectedEmotion`/`emotionVerse` hoistés au niveau du NavHost (state Compose simple, pas de ViewModel partagé — équivalent des `@State` de `ContentView`).
- ✅ MainScreen : Scaffold + NavigationBar 3 items (switch de contenu direct, pas de sous-NavHost — miroir de `TabView` iOS)
- ⬜ SplashScreen dédié (actuellement géré par `core-splashscreen` système au démarrage froid uniquement, pas de splash custom animé 2.5s comme iOS — gap mineur)
- ⬜ Deep links `holyday://` : intent-filter déclaré dans le manifest mais non branché à la navigation interne (onglet Journal etc.) — à faire

### 5. Écrans
- ✅ Home (`ui/home/HomeScreen.kt`) — question ressenti, EmotionRibbon, verset révélé, menu Prier (libre/guidée), bouton intentions
- ✅ EmotionRibbon (marquee 2 rangées, vitesses différentes, tap pour sélectionner) + EmotionVerse (révélation mot par mot) + VerseRecall — `ui/prayer/`
- ✅ FreePrayerScreen
- ✅ StructuredPrayerScreen + PrayerStepCard + PrayerGuideViewModel (Room upsert, intentions actives à l'étape Supplication, questions de réflexion IA toujours vides — cf. AIAssistantService)
- ✅ IntentionsScreen + IntentionDetailScreen — CRUD complet, segments actif/exaucé. **Simplifié** : pas de l'animation en 2 phases (glissement + mains jointes qui persistent 1s) de l'iOS — bascule directe. Gap visuel assumé, pas fonctionnel.
- ✅ PrayerHistoryScreen / PrayerEntryDetailScreen / JournalStatsScreen (`ui/journal/`) — calendrier mensuel + points d'activité, decks pliables guidées/libres, recherche texte (pas de recherche sémantique IA, cf. gap AIAssistantService), stats activité + donut émotions via Canvas custom (`StatsCharts.kt`, pas de lib tierce)
- ✅ OnboardingScreen (`ui/onboarding/`) — 6 étapes (hero/valeur/prénom/1re intention/confidentialité/notifications), transitions slide, indicateur de progression, bouton retour. Simplifié : pas de halo "respirant" ni cascade d'apparition séquentielle des features (décoratif). Pas de tour guidé TipKit post-onboarding (`AppTips.swift`) — non porté, gap fonctionnel mineur assumé faute de temps.
- ✅ SettingsScreen / LegalNoticeScreen (`ui/settings/`) — profil (nom + avatar via Android Photo Picker), soutien (badge + lien paywall), apparence (system/light/dark, câblé jusqu'à `HolyDayTheme` dans `MainActivity`), notifications (toggle + permission POST_NOTIFICATIONS runtime + time picker Material3), communauté (partage via Intent.ACTION_SEND + avis via Play Core `ReviewManagerFactory`), légal (liens externes + mentions légales), à propos, zone danger (reset complet avec confirmation), section debug (gate `BuildConfig.DEBUG`)
- ✅ PaywallScreen / DonationThankYouScreen / SupportPromptScreen / SupporterBadge (`ui/support/`) — achat réel via RevenueCat Android (`awaitPurchase`/`awaitRestore`), palier dérivé du rang de prix, badge, célébration auto-fermante 3s, sollicitation douce câblée depuis la fermeture des feuilles de prière (`onPrayerSheetDismissed` dans `HolyDayNavHost`, miroir de `presentSupportPromptIfEligible`). **Simplifié** : pas de `SparksView` (particules scintillantes) sur l'écran de remerciement.
- ✅ DebugMenuScreen (`ui/debug/`) — état, resets, seed 14 jours de démo, "tout réinitialiser". Accessible uniquement via `BuildConfig.DEBUG` (le fichier lui-même n'est pas exclu du binaire release comme le `#if DEBUG` iOS — gap mineur assumé : le code est présent mais inatteignable en release).

**Section 5 (Écrans) : TOUS FAITS.** Projet compile intégralement (`assembleDebug` OK) avec tous les écrans réels (aucun stub restant).

### 6. Widgets Glance
- ✅ PrayNowWidget — état invite/prié aujourd'hui, ouvre MainActivity au tap
- ✅ VerseWidget — dernier verset reçu, ouvre MainActivity au tap
- Note : rendu volontairement simple (un seul layout, pas de tailles small/medium/large distinctes comme iOS) — à enrichir si besoin visuel après premier test sur device/émulateur.

### 7. Localisation
- ⬜ Extraction complète des clés .xcstrings → strings.xml (fr default + en)

### 8. Tests
- ✅ Unit tests (miroir exact des 4 fichiers iOS) — **35/35 passent** (`./gradlew :app:testDebugUnitTest`)
  - `VerseTest` (3) — round-trip Codable non porté (pas de sérialisation JSON de `Verse` sur Android), reste testé : stockage des champs, unicité d'ID, stabilité d'ID explicite
  - `VerseServiceTest` (5) — miroir exact
  - `SupportPromptServiceTest` (9) — miroir exact, via `FakeSharedPreferences` (in-memory) au lieu d'une suite `UserDefaults` isolée
  - `PrayerGuideViewModelTest` (18 au sens Gradle car chaque `@Test` méthode ; correspond aux mêmes cas que l'iOS) — a nécessité un refactor de `PrayerGuideViewModel` (retrait de `AndroidViewModel`/`Application` du constructeur, `Context` déplacé en paramètre de `save()`) pour rester testable en JVM pur sans Robolectric, à l'identique du ViewModel iOS qui ne détient pas non plus de `ModelContext`
  - Bug réel trouvé et corrigé pendant l'écriture des tests : `SupportPromptService.shared` était initialisé **avec ses valeurs par défaut** dès le chargement de la classe (au lieu d'à la première utilisation), ce qui plantait dès qu'une instance de test isolée était construite. Corrigé en `by lazy` (comportement `static let` Swift, plus fidèle à l'iOS).
- ⬜ Tests instrumentés (androidTest) — non écrits, gap assumé faute de temps (les 4 fichiers iOS n'ont pas d'équivalent `HolyDayUITests` autre que les captures d'écran fastlane, non applicables)
- ✅ Smoke test réel sur émulateur (AVD "Pixel_10_Pro", Android 37 preview, déjà configuré sur la machine) : install + lancement + parcours complet onboarding (6 étapes, y compris la vraie boîte de dialogue système de permission notifications) → sélection d'émotion → révélation du verset mot par mot → menu Prier → Prière libre → sauvegarde → Journal (calendrier, jour marqué, entrée affichée) → Réglages (profil, apparence, notifications). Aucun crash (`logcat` vérifié).
  - **Bug réel trouvé et corrigé grâce à ce test** (invisible à la compilation) : le flux "Activer les rappels" de l'onboarding demandait bien la permission Android mais n'appelait jamais `NotificationService.setReminder(...)`, donc le rappel n'était jamais réellement programmé ni persisté — les Réglages affichaient le bouton bascule à l'état désactivé avec un avertissement de permission alors que la permission venait d'être accordée. Corrigé (`OnboardingScreen.kt`) + ajout d'un rafraîchissement d'état (`NotificationService.checkStatus`) à l'ouverture des Réglages (miroir de l'`.onAppear` iOS). Vérifié après correction : bascule active, heure 08:00 affichée, et `adb shell dumpsys alarm` confirme une alarme exacte réellement programmée (`RTC_WAKEUP` sur `PrayerReminderReceiver`).

### 9. Rapport final
- ✅ Rapport livré à l'utilisateur (artifact) — voir aussi ce fichier pour le détail technique complet.
- Lint Android (`./gradlew :app:lintDebug`) : 0 erreur, 104 avertissements (principalement `UnusedResources` sur des clés de traduction pas encore consommées par un écran, `UseKtx`, icônes de lancement non-adaptatives). Rien de bloquant.
- Suite complète validée avant livraison : `./gradlew :app:testDebugUnitTest :app:lintDebug` + `:app:assembleDebug` → tout vert.

## Notes de reprise

(mis à jour à chaque étape significative — dernière étape en cours, prochaine action prévue)

- 2026-08-27 : Inventaire iOS terminé. Décisions d'architecture figées ci-dessus. Prochaine action : créer les fichiers Gradle du projet Android (`android/settings.gradle.kts`, `android/build.gradle.kts`, `android/gradle/wrapper/*`, `android/app/build.gradle.kts`, `AndroidManifest.xml`), package `com.matthiascadet.holyday`.
- 2026-08-28 : Réorganisation du dépôt en monorepo `ios/` + `android/` + `shared/` (voir `CLAUDE.md`). Le projet Xcode a été déplacé tel quel dans `ios/` (aucune référence de chemin dans `project.pbxproj` n'a dû être modifiée — build réel vérifié depuis le nouvel emplacement). Ce fichier et `KEYMAP.md` déménagent dans `shared/docs/`. Ajout de `shared/data/verses.json`, extrait mécaniquement (script Python, 36/36 entrées vérifiées) de `ios/HolyDayShared/VerseCorpus.swift` : c'est une référence de parité, pas encore la source consommée au runtime par les deux apps (qui embarquent chacune leur propre copie, cf. ci-dessus) — brancher les deux plateformes dessus reste à faire si on veut éliminer la duplication pour de bon.
