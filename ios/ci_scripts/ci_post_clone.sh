#!/bin/sh

# Xcode Cloud — exécuté après le clone, avant toute résolution de dépendances.
# Le dossier `ci_scripts` doit vivre à côté de HolyDay.xcodeproj : Xcode Cloud ne le
# cherche nulle part ailleurs (le dépôt est un monorepo, la racine clonée est au-dessus).
# Le cwd du script EST ci_scripts/ — d'où les chemins relatifs via REPO_IOS.

set -e

REPO_IOS="${CI_PRIMARY_REPOSITORY_PATH}/ios"

echo "Xcode Cloud : workflow ${CI_WORKFLOW}, action ${CI_XCODEBUILD_ACTION:-<aucune>}, commit ${CI_COMMIT}"

# Xcode ≥ 16 embarque swift-format (`xcrun swift-format`) ; seul SwiftLint manque à l'image.
# `brew install` est conditionné : une image future pourrait l'embarquer.
if ! command -v swiftlint >/dev/null 2>&1; then
  echo "Installation de SwiftLint…"
  brew install swiftlint
fi

# Le clone d'Xcode Cloud est superficiel (depth 1). `git log` sert aux notes de test et au
# diagnostic : on approfondit une fois ici plutôt que dans chaque script en aval.
git -C "${CI_PRIMARY_REPOSITORY_PATH}" fetch --deepen 10 || true

echo "Post-clone terminé (${REPO_IOS})."
