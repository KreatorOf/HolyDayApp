#!/bin/sh

# Xcode Cloud — porte de qualité, exécutée avant chaque commande xcodebuild.
# Reprend à l'identique les deux linters du pre-commit : SwiftLint --strict et
# swift-format --strict. Un écart bloque le build.

set -e

# Le garde vient AVANT toute résolution de chemin, et pour cause : Xcode Cloud rejoue les
# scripts sur une seconde machine pour `test-without-building`, où CI_PRIMARY_REPOSITORY_PATH
# est vide. Un `cd` monté trop tôt y devient `cd /ios` et fait echouer l'action alors que le
# lint est déjà passé sur la machine de build. Ne linter que là où l'on compile.
case "${CI_XCODEBUILD_ACTION}" in
  build|build-for-testing) ;;
  *)
    echo "Action ${CI_XCODEBUILD_ACTION:-<aucune>} : pas de compilation, lint ignoré."
    exit 0
    ;;
esac

REPO_IOS="${CI_PRIMARY_REPOSITORY_PATH}/ios"
if [ ! -d "${REPO_IOS}" ]; then
  echo "warning: ${REPO_IOS} introuvable — lint ignoré."
  exit 0
fi
cd "${REPO_IOS}"

echo "SwiftLint…"
swiftlint lint --strict --config "${REPO_IOS}/.swiftlint.yml"

# HolyDayUITests/SnapshotHelper.swift est fourni tel quel par fastlane : listé fichier par
# fichier plutôt qu'en --recursive, car swift-format n'a pas d'option d'exclusion.
echo "swift-format…"
xcrun swift-format lint --strict --recursive \
  HolyDay/ HolyDayShared/ HolyDayTests/ HolyDayWidget/ \
  HolyDayUITests/HolyDayUITests.swift

echo "Lint OK."
