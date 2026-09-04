"""Publisher — couche isolée, inerte dans le MVP.

Aucun adaptateur ne publie quoi que ce soit à ce stade, et c'est délibéré : la
contrainte est « publication interdite sans validation humaine », et le moyen
le plus sûr de la tenir est qu'aucun code de publication n'existe encore.

Les adaptateurs sont néanmoins déclarés pour figer le contrat : ajouter une
plateforme se fera en ajoutant une classe ici, sans toucher au reste de la
chaîne — c'est l'un des critères de réussite du projet.
"""

from __future__ import annotations

from dataclasses import dataclass

from .facts import Drafts


class PublishNotConfigured(RuntimeError):
    """Levée quand on tente de publier une plateforme non branchée."""


@dataclass(frozen=True)
class PublishResult:
    platform: str
    published: bool
    detail: str


class Publisher:
    """Contrat commun à toutes les plateformes."""

    platform = "inconnu"
    #: Ce qu'il faudra brancher, documenté pour la phase 3.
    official_api = "non déterminée"

    def publish(self, drafts: Drafts, dry_run: bool = True) -> PublishResult:
        if dry_run:
            return PublishResult(self.platform, False, "dry-run : rien n'a été envoyé")
        raise PublishNotConfigured(
            f"{self.platform} n'est pas branché. "
            f"Intégration officielle prévue : {self.official_api}. "
            "Publie manuellement à partir du fichier approuvé."
        )


class XPublisher(Publisher):
    platform = "x"
    official_api = "X API v2, endpoint POST /2/tweets"


class ThreadsPublisher(Publisher):
    platform = "threads"
    official_api = "Threads API (Meta), endpoint /threads_publish"


class SubstackPublisher(Publisher):
    platform = "substack"
    # Substack n'expose pas d'API d'écriture publique. On ne contourne pas :
    # l'article approuvé est copié à la main dans l'éditeur.
    official_api = "aucune API d'écriture publique — copie manuelle assumée"


ADAPTERS: dict[str, Publisher] = {
    p.platform: p for p in (XPublisher(), ThreadsPublisher(), SubstackPublisher())
}
