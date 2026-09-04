"""Content Writer — transforme un `FeatureFact` en brouillons.

C'est la seule couche qui parle au modèle. Elle reçoit la fiche factuelle et
l'identité éditoriale, et rien d'autre : ni accès au dépôt, ni au réseau, ni
aux secrets. Ce périmètre est la moitié de la garantie « ne rien inventer » ;
l'autre moitié est la vérification dans `guards`, qui s'applique à sa sortie.

Un mode hors ligne produit des brouillons déterministes à partir des seuls
faits. Il sert aux tests — qui ne doivent ni coûter d'argent ni dépendre du
réseau — et permet d'utiliser l'outil sans clé API.
"""

from __future__ import annotations

import json

from .facts import Drafts, FeatureFact

MODEL = "claude-opus-5"


class WriterError(RuntimeError):
    """Échec côté modèle, traduit en message actionnable.

    L'appelant est un développeur devant son terminal, pas un service : une
    trace de pile ne lui dit pas quoi faire, un message si.
    """

SYSTEM = """Tu rédiges les publications d'un développeur solo qui documente son travail en public.

RÈGLE ABSOLUE : la fiche factuelle qu'on te donne est ta seule source. Tu ne peux
écrire que ce qui s'y trouve ou s'en déduit directement. Tu n'as accès ni au
dépôt, ni au web, ni à des données d'usage.

Il t'est formellement interdit d'inventer :
- un nombre d'utilisateurs, de téléchargements, d'abonnés ou de revenus ;
- un pourcentage, une durée ou une mesure absente de la fiche ;
- un témoignage, une réaction ou une citation d'utilisateur ;
- une fonctionnalité qui n'apparaît pas dans les fichiers modifiés ;
- une date de sortie ou une promesse.

Le développeur n'a aucune métrique publiable. Si un texte a besoin d'un chiffre
pour être intéressant, c'est que l'angle est mauvais : change d'angle.

Écris à la première personne, en français, au passé. Une seule idée par
publication. Si la fiche ne contient rien qui vaille d'être raconté, dis-le en
renseignant `skipped_reason` plutôt que de meubler.

Adapte réellement chaque plateforme : un même texte recoupé aux ciseaux est un
échec."""

SCHEMA = {
    "type": "object",
    "properties": {
        "angle": {
            "type": "string",
            "description": "L'angle éditorial retenu, en une phrase, pour l'historique.",
        },
        "x": {
            "type": "string",
            "description": "Post X. Maximum 280 caractères. Direct, conversationnel, sans hashtag.",
        },
        "threads": {
            "type": "string",
            "description": "Post Threads. Maximum 500 caractères. Plus personnel, peut finir sur une question ouverte.",
        },
        "substack_title": {"type": "string", "description": "Titre de l'article Substack."},
        "substack_outline": {
            "type": "string",
            "description": "Plan de l'article en 3 à 5 points, un par ligne.",
        },
        "substack_body": {
            "type": "string",
            "description": "Article complet en Markdown : contexte, ce qui a été tenté, ce qui a raté, ce qui a été appris.",
        },
        "skipped_reason": {
            "type": ["string", "null"],
            "description": "Renseigné uniquement si ce changement ne mérite aucune publication. Sinon null.",
        },
    },
    "required": [
        "angle",
        "x",
        "threads",
        "substack_title",
        "substack_outline",
        "substack_body",
        "skipped_reason",
    ],
    "additionalProperties": False,
}


def _prompt(fact: FeatureFact, brand: str, history: str) -> str:
    return f"""Voici l'identité éditoriale à respecter.

<identite>
{brand}
</identite>

Voici les angles déjà publiés. N'en reprends aucun ; si le seul angle possible a
déjà été traité, renseigne `skipped_reason`.

<historique>
{history}
</historique>

Voici la fiche factuelle du changement. C'est ta seule source d'information.

<faits>
{fact.to_json()}
</faits>

Rédige les trois formats."""


def write_offline(fact: FeatureFact) -> Drafts:
    """Brouillons déterministes, sans modèle, à partir des seuls faits.

    Utilisé par les tests et par `--offline`. Volontairement plat : ce mode
    prouve que la chaîne fonctionne, il ne prétend pas bien écrire.
    """
    langs = ", ".join(fact.languages) if fact.languages else "le projet"
    angle = f"Changement « {fact.subject} » sur {langs}"
    summary = (
        f"{fact.subject}\n\n"
        f"{fact.files_changed} fichiers touchés, "
        f"{fact.lines_added} lignes ajoutées et {fact.lines_removed} retirées."
    )
    return Drafts(
        x=f"{fact.subject}"[:280],
        threads=f"{fact.subject}\n\nCommit {fact.short_sha}."[:500],
        substack_title=fact.subject,
        substack_outline="- Contexte\n- Ce que j'ai changé\n- Ce que j'en retiens",
        substack_body=summary,
        angle=angle,
    )


def write(fact: FeatureFact, brand: str, history: str) -> Drafts:
    """Génère les brouillons via Claude."""
    import anthropic

    client = anthropic.Anthropic()

    # Streaming : l'article Substack peut être long, et une requête non
    # streamée avec un `max_tokens` élevé risque le délai d'expiration HTTP.
    try:
        with client.messages.stream(
            model=MODEL,
            max_tokens=16000,
            system=SYSTEM,
            thinking={"type": "adaptive"},
            output_config={"format": {"type": "json_schema", "schema": SCHEMA}},
            messages=[{"role": "user", "content": _prompt(fact, brand, history)}],
        ) as stream:
            response = stream.get_final_message()
    except anthropic.AuthenticationError:
        raise WriterError(
            "Authentification refusée. Vérifie `ant auth status` — le jeton a pu expirer "
            "(`ant auth login` le renouvelle)."
        ) from None
    except anthropic.BadRequestError as error:
        if "credit balance" in str(error).lower():
            raise WriterError(
                "Crédits API épuisés.\n"
                "  Ajoute des crédits sur platform.claude.com → Plans & Billing.\n"
                "  Un abonnement Claude Pro ou Max ne couvre PAS l'API : "
                "ce sont deux facturations distinctes.\n"
                "  En attendant, `--offline` fait tourner toute la chaîne sans rien dépenser."
            ) from None
        raise WriterError(f"Requête refusée par l'API : {error}") from None
    except anthropic.RateLimitError:
        raise WriterError("Limite de débit atteinte. Réessaie dans un moment.") from None
    except anthropic.APIConnectionError:
        raise WriterError(
            "Impossible de joindre l'API. Vérifie la connexion, ou utilise `--offline`."
        ) from None

    if response.stop_reason == "refusal":
        raise RuntimeError(
            "Le modèle a refusé la demande. "
            f"Catégorie : {getattr(response.stop_details, 'category', 'inconnue')}"
        )

    text = next((b.text for b in response.content if b.type == "text"), "")
    data = json.loads(text)

    return Drafts(
        x=data["x"],
        threads=data["threads"],
        substack_title=data["substack_title"],
        substack_outline=data["substack_outline"],
        substack_body=data["substack_body"],
        angle=data["angle"],
        skipped_reason=data.get("skipped_reason") or None,
    )
