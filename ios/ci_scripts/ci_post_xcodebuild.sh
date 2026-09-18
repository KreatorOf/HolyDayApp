#!/bin/sh

# Xcode Cloud — exécuté après chaque commande xcodebuild.
# Sert au scan de code mort : Periphery a besoin d'un index-store, donc d'une compilation
# déjà faite. On se greffe sur celle de `build-for-testing` plutôt que d'en payer une seconde.

set -e

# Comme dans ci_pre_xcodebuild.sh : filtrer l'action avant de toucher aux chemins. Les phases
# de test tournent sur une autre machine, où CI_PRIMARY_REPOSITORY_PATH est vide.
[ "${CI_XCODEBUILD_ACTION}" = "build-for-testing" ] || exit 0
[ "${CI_XCODEBUILD_EXIT_CODE}" = "0" ] || exit 0

REPO_IOS="${CI_PRIMARY_REPOSITORY_PATH}/ios"
[ -d "${REPO_IOS}" ] || { echo "warning: ${REPO_IOS} introuvable — scan ignoré."; exit 0; }
cd "${REPO_IOS}"

INDEX_STORE="${CI_DERIVED_DATA_PATH}/Index.noindex/DataStore"

# L'emplacement de l'index-store est un détail d'implémentation de DerivedData, pas une API :
# s'il bouge, on veut un avertissement, pas une livraison bloquée.
if [ ! -d "${INDEX_STORE}" ]; then
  echo "warning: index-store introuvable (${INDEX_STORE}) — scan Periphery ignoré."
  exit 0
fi

if ! command -v periphery >/dev/null 2>&1; then
  echo "Installation de Periphery…"
  brew install peripheryapp/periphery/periphery
fi

echo "Periphery…"
periphery scan \
  --skip-build \
  --index-store-path "${INDEX_STORE}" \
  --strict \
  --disable-update-check \
  --relative-results
