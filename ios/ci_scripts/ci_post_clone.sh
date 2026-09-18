#!/bin/sh

# Xcode Cloud — exécuté après le clone, avant toute résolution de dépendances.
# Le dossier `ci_scripts` doit vivre à côté de HolyDay.xcodeproj : Xcode Cloud ne le
# cherche nulle part ailleurs (le dépôt est un monorepo, la racine clonée est au-dessus).

set -e

echo "Xcode Cloud : workflow ${CI_WORKFLOW}, action ${CI_XCODEBUILD_ACTION:-<aucune>}, commit ${CI_COMMIT}"

# Xcode ≥ 16 embarque swift-format (`xcrun swift-format`) ; seul SwiftLint manque à l'image.
# `brew install` est conditionné : une image future pourrait l'embarquer.
if ! command -v swiftlint >/dev/null 2>&1; then
  echo "Installation de SwiftLint…"
  brew install swiftlint
fi

# Le clone d'Xcode Cloud est superficiel (depth 1). `git log` sert au diagnostic : on
# approfondit une fois ici. La variable est vide sur les machines de test — d'où le garde.
if [ -n "${CI_PRIMARY_REPOSITORY_PATH}" ]; then
  git -C "${CI_PRIMARY_REPOSITORY_PATH}" fetch --deepen 10 || true
fi

echo "Post-clone terminé."
