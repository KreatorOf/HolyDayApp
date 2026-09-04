"""Le contrat entre l'analyse et la rédaction.

Toute la garantie « ne jamais inventer » repose sur ce module. Le Developer
Historian ne produit que des `FeatureFact`, et le Content Writer ne reçoit
*rien d'autre* qu'un `FeatureFact` — jamais le dépôt, jamais le diff brut,
jamais l'historique complet. Ce qui n'est pas ici ne peut pas être écrit.

Aucun champ n'est un jugement : ce sont des relevés. « Cette feature est
utile aux utilisateurs » n'a pas sa place ici, « 3 fichiers de tests
modifiés » si.
"""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field


@dataclass(frozen=True)
class FileChange:
    """Un fichier touché, tel que git le rapporte."""

    path: str
    added: int
    removed: int
    status: str  # A, M, D, R...

    @property
    def is_test(self) -> bool:
        low = self.path.lower()
        return "test" in low or "spec" in low


@dataclass(frozen=True)
class FeatureFact:
    """Fiche factuelle d'un changement, extraite de git et de GitHub.

    Sérialisable en JSON : c'est cette forme exacte qui est envoyée au modèle,
    ce qui rend la frontière auditable — on peut relire ce qui a été transmis.
    """

    sha: str
    short_sha: str
    subject: str
    body: str
    author_date: str
    branch: str

    files: list[FileChange] = field(default_factory=list)
    languages: list[str] = field(default_factory=list)

    pr_number: int | None = None
    pr_title: str | None = None
    pr_body: str | None = None

    # Relevés dérivés, tous vérifiables dans `files`.
    files_changed: int = 0
    lines_added: int = 0
    lines_removed: int = 0
    touches_tests: bool = False

    # Extraits littéraux du diff, tronqués. Servent au modèle à comprendre le
    # changement sans avoir à deviner — jamais à être cités tels quels.
    diff_excerpt: str = ""

    def to_json(self) -> str:
        return json.dumps(asdict(self), ensure_ascii=False, indent=2)

    @property
    def numbers(self) -> set[str]:
        """Tous les nombres que ce fait autorise à écrire.

        `guards.check_no_invented_numbers` s'en sert pour rejeter un brouillon
        qui contiendrait un chiffre venu d'ailleurs — typiquement une métrique
        d'utilisateurs inventée.
        """
        allowed = {
            str(self.files_changed),
            str(self.lines_added),
            str(self.lines_removed),
            str(len(self.files)),
        }
        if self.pr_number is not None:
            allowed.add(str(self.pr_number))
        for change in self.files:
            allowed.add(str(change.added))
            allowed.add(str(change.removed))
        # Les nombres présents dans le texte du commit sont, eux aussi, factuels.
        allowed.update(_extract_numbers(self.subject))
        allowed.update(_extract_numbers(self.body))
        if self.pr_title:
            allowed.update(_extract_numbers(self.pr_title))
        if self.pr_body:
            allowed.update(_extract_numbers(self.pr_body))
        return allowed


def _extract_numbers(text: str) -> set[str]:
    import re

    return set(re.findall(r"\d+", text or ""))


@dataclass(frozen=True)
class Drafts:
    """Ce que le Content Writer produit. Rien n'est publié à ce stade."""

    x: str
    threads: str
    substack_title: str
    substack_outline: str
    substack_body: str
    angle: str
    skipped_reason: str | None = None

    @property
    def is_skip(self) -> bool:
        return self.skipped_reason is not None

    def all_text(self) -> str:
        """Concaténation utilisée par les garde-fous."""
        return "\n".join(
            [
                self.x,
                self.threads,
                self.substack_title,
                self.substack_outline,
                self.substack_body,
                self.angle,
            ]
        )
