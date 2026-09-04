"""Garde-fous appliqués aux brouillons, après génération.

Demander à un modèle de ne pas inventer réduit le risque ; ça ne l'élimine
pas. Ces vérifications sont mécaniques et tournent sur la sortie, sans modèle :
un brouillon qui les échoue est rejeté, jamais « corrigé silencieusement ».

Trois familles :
  1. chiffres — tout nombre écrit doit exister dans le `FeatureFact` ;
  2. affirmations interdites — métriques d'audience, témoignages, revenus ;
  3. secrets — rien qui ressemble à une clé ne doit sortir, ni dans un post,
     ni dans un log.
"""

from __future__ import annotations

import re
from dataclasses import dataclass

from .facts import Drafts, FeatureFact


@dataclass(frozen=True)
class Violation:
    kind: str
    detail: str


# Nombres qu'on s'autorise sans qu'ils figurent dans les faits : ils relèvent
# du langage courant (« deux ou trois choses », « en 2 minutes ») et non d'une
# métrique. Volontairement très court — en cas de doute, on rejette.
_NEUTRAL_NUMBERS = {"1", "2", "3", "24", "100"}

# Formulations qui prétendent à une audience, un revenu ou un témoignage.
# Le motif vise l'affirmation chiffrée ou attestée, pas le mot isolé.
_BANNED_CLAIM_PATTERNS = [
    (r"\b\d[\d\s.,]*\s*(utilisateurs?|users?|téléchargements?|downloads?|abonnés?|followers?)\b",
     "métrique d'audience"),
    (r"\b\d[\d\s.,]*\s*(€|\$|euros?|dollars?)\b", "montant de revenu"),
    (r"\b(des\s+)?(milliers|millions|centaines)\s+d[e']", "volumétrie vague"),
    (r"\b\d+\s*%", "pourcentage"),
    (r"\b(un|une|des)\s+(utilisateur|utilisatrice|client)s?\s+m'?a\s+(dit|écrit|demandé)",
     "témoignage"),
    (r"\b(top|n[°o]\s*1|meilleure?\s+app)\b", "classement"),
]

# Motifs de secrets. Génériques volontairement : mieux vaut un faux positif
# qu'une clé publiée.
_SECRET_PATTERNS = [
    (r"sk-ant-[A-Za-z0-9_\-]{8,}", "clé API Anthropic"),
    (r"\bappl_[A-Za-z0-9]{16,}", "clé SDK RevenueCat"),
    (r"\bghp_[A-Za-z0-9]{20,}", "token GitHub"),
    (r"-----BEGIN [A-Z ]*PRIVATE KEY-----", "clé privée"),
    (r"\b[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}\b", "adresse e-mail"),
    (r"\bAuthKey_[A-Za-z0-9]+\.p8\b", "clé App Store Connect"),
]


def scan_secrets(text: str) -> list[Violation]:
    """Cherche des secrets dans un texte. Utilisé sur les brouillons ET les logs."""
    return [
        Violation("secret", f"{label} détecté")
        for pattern, label in _SECRET_PATTERNS
        if re.search(pattern, text)
    ]


def check_no_invented_numbers(drafts: Drafts, fact: FeatureFact) -> list[Violation]:
    allowed = fact.numbers | _NEUTRAL_NUMBERS
    text = drafts.all_text()

    # Un sha est un fait, mais il contient des chiffres qui n'en sont pas : « c7106ed »
    # se lirait comme le nombre 7106. On le retire du texte plutôt que d'autoriser
    # ses chiffres, ce qui ouvrirait une brèche de la taille d'un sha.
    for sha in (fact.sha, fact.short_sha):
        if sha:
            text = text.replace(sha, " ")

    violations: list[Violation] = []
    for number in set(re.findall(r"\d+", text)):
        # Une année récente est une date, pas une métrique.
        if len(number) == 4 and number.startswith("20"):
            continue
        if number not in allowed:
            violations.append(
                Violation("nombre inventé", f"« {number} » n'apparaît nulle part dans les faits")
            )
    return violations


def check_no_banned_claims(drafts: Drafts) -> list[Violation]:
    text = drafts.all_text()
    return [
        Violation("affirmation interdite", f"{label} : « {match.group(0).strip()} »")
        for pattern, label in _BANNED_CLAIM_PATTERNS
        for match in re.finditer(pattern, text, flags=re.IGNORECASE)
    ]


def check_platform_limits(drafts: Drafts) -> list[Violation]:
    violations: list[Violation] = []
    if len(drafts.x) > 280:
        violations.append(Violation("longueur", f"X : {len(drafts.x)} caractères (max 280)"))
    if len(drafts.threads) > 500:
        violations.append(
            Violation("longueur", f"Threads : {len(drafts.threads)} caractères (max 500)")
        )
    for name, value in (("X", drafts.x), ("Threads", drafts.threads)):
        if not value.strip():
            violations.append(Violation("vide", f"{name} : aucun contenu"))
    return violations


def verify(drafts: Drafts, fact: FeatureFact) -> list[Violation]:
    """Toutes les vérifications. Une liste vide vaut approbation technique."""
    if drafts.is_skip:
        return []
    return [
        *check_no_invented_numbers(drafts, fact),
        *check_no_banned_claims(drafts),
        *check_platform_limits(drafts),
        *scan_secrets(drafts.all_text()),
    ]


def redact(text: str) -> str:
    """Masque les secrets avant journalisation.

    Le journal est écrit sur disque et potentiellement partagé ; il ne doit
    jamais devenir le maillon par lequel une clé fuit.
    """
    redacted = text
    for pattern, _ in _SECRET_PATTERNS:
        redacted = re.sub(pattern, "[masqué]", redacted)
    return redacted
