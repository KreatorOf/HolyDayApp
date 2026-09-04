#!/usr/bin/env bash
#
# Garde-fou sur la chaîne de livraison iOS.
#
# Le Fastfile et les notes de test ne sont ni compilés ni testés : une faute purement textuelle
# n'y est découverte qu'en production, après huit minutes de build sur un runner macOS. Ces trois
# vérifications reproduisent les deux pannes réellement vécues, et tournent en moins d'une seconde.
#
# Lancé par pre-commit (.pre-commit-config.yaml) depuis la racine du dépôt.

set -euo pipefail

FASTFILE="ios/fastlane/Fastfile"
NOTES="ios/fastlane/testflight_whats_new.txt"
status=0

fail() {
  printf '\033[31m✗ %s\033[0m\n' "$1" >&2
  status=1
}

ok() {
  printf '\033[32m✓ %s\033[0m\n' "$1"
}

# 1. Syntaxe Ruby — la vérification la plus élémentaire, et pourtant absente jusqu'ici.
if [ -f "$FASTFILE" ]; then
  if ruby -c "$FASTFILE" >/dev/null 2>&1; then
    ok "Fastfile : syntaxe Ruby valide"
  else
    fail "Fastfile : syntaxe Ruby invalide"
    ruby -c "$FASTFILE" || true
  fi
fi

# 2. Collision entre noms de lanes et de helpers.
#    Ruby ne signale rien : `changelog: testflight_notes` a silencieusement appelé la LANE au lieu
#    du helper, et une lane renvoie sa dernière valeur — ici `true`. Le build a échoué à l'upload
#    sur « 'changelog' value must be a String! Found TrueClass instead ».
if [ -f "$FASTFILE" ]; then
  clash=$(ruby -e '
    src = File.read(ARGV[0])
    lanes   = src.scan(/^\s*(?:private_)?lane :(\w+)/).flatten
    helpers = src.scan(/^\s*def (\w+)/).flatten
    puts (lanes & helpers).join(", ")
  ' "$FASTFILE")
  if [ -z "$clash" ]; then
    ok "Fastfile : aucune collision lane/helper"
  else
    fail "Fastfile : ces noms sont à la fois une lane et un helper -> $clash"
    echo "  Une lane appelée comme un helper renvoie sa dernière valeur, pas la vôtre." >&2
    echo "  Convention : les lanes portent un verbe, les helpers un nom de valeur." >&2
  fi
fi

# 3. Notes TestFlight en ASCII.
#    App Store Connect rejette certains caractères dans le champ « what to test » (les filets
#    « ━ » notamment). L'échec survient APRÈS l'upload du binaire : le build part, puis la lane
#    casse, laissant un build en ligne sans ses notes.
if [ -f "$NOTES" ]; then
  if LC_ALL=C grep -q '[^ -~]' "$NOTES"; then
    fail "$NOTES : caractères non-ASCII, refusés par App Store Connect"
    LC_ALL=C grep -n '[^ -~]' "$NOTES" | head -5 >&2
  else
    ok "Notes TestFlight : ASCII pur"
  fi
fi

exit "$status"
