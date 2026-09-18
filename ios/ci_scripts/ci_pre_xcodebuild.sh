#!/bin/sh

# Xcode Cloud — porte de qualité, exécutée avant chaque commande xcodebuild.
# Reprend à l'identique les deux linters du pre-commit et de l'ancien job `lint` :
# SwiftLint --strict et swift-format --strict. Un écart bloque le build.

set -e

REPO_IOS="${CI_PRIMARY_REPOSITORY_PATH}/ios"
cd "${REPO_IOS}"

# Une action `archive` rejoue ce script après `build-for-testing` dans le même build :
# linter deux fois le même arbre ne dit rien de plus et coûte une minute de compute.
case "${CI_XCODEBUILD_ACTION}" in
  archive|analyze)
    echo "Lint déjà passé sur ce commit (action ${CI_XCODEBUILD_ACTION}) — ignoré."
    exit 0
    ;;
esac

echo "SwiftLint…"
swiftlint lint --strict --config "${REPO_IOS}/.swiftlint.yml"

# HolyDayUITests/SnapshotHelper.swift est fourni tel quel par fastlane : listé fichier par
# fichier plutôt qu'en --recursive, car swift-format n'a pas d'option d'exclusion.
echo "swift-format…"
xcrun swift-format lint --strict --recursive \
  HolyDay/ HolyDayShared/ HolyDayTests/ HolyDayWidget/ \
  HolyDayUITests/HolyDayUITests.swift

echo "Lint OK."
