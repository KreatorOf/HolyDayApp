# shared/

Contenu source-de-vérité commun aux deux apps natives (`ios/`, `android/`). Il n'y a pas de code
compilé partagé entre Swift et Kotlin ici — seulement des données et de la documentation que les
deux plateformes doivent refléter à l'identique.

- `data/verses.json` — corpus de versets FR/EN (LSG/BSB), extrait de
  `ios/HolyDayShared/VerseCorpus.swift`. Sert de référence pour vérifier que la copie iOS et la
  copie Android (`android/app/src/main/java/com/matthiascadet/holyday/data/model/VerseCorpus.kt`)
  restent identiques ; les deux apps embarquent encore chacune leur propre copie du corpus au lieu
  de lire ce fichier au runtime/build.
- `docs/KEYMAP.md` — correspondance clés de localisation iOS (`.xcstrings`) ↔ ressources Android
  (`strings.xml`).
- `docs/PORT_PROGRESS.md` — journal d'avancement du portage Android et des décisions d'architecture
  qui gardent les deux apps équivalentes en comportement.
