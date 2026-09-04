"""Developer Historian — lit git et GitHub, produit une fiche factuelle.

Cette couche n'interprète rien et n'appelle aucun modèle. Elle relève. Si une
information n'est pas dans git, elle n'apparaît pas dans le `FeatureFact`, et
elle ne pourra donc pas être écrite plus loin dans la chaîne.
"""

from __future__ import annotations

import json
import subprocess

from .facts import FeatureFact, FileChange

# Le diff complet d'une feature peut faire des milliers de lignes. On en envoie
# un extrait : assez pour comprendre la nature du changement, pas assez pour
# noyer le modèle ni pour faire exploser le coût.
DIFF_EXCERPT_MAX_CHARS = 6000

_EXTENSION_LANGUAGES = {
    ".swift": "Swift",
    ".kt": "Kotlin",
    ".kts": "Kotlin",
    ".rb": "Ruby",
    ".py": "Python",
    ".yml": "YAML",
    ".yaml": "YAML",
    ".sh": "Shell",
    ".md": "Markdown",
    ".json": "JSON",
    ".xml": "XML",
    ".xcstrings": "Localisation",
}


class HistorianError(RuntimeError):
    pass


def _git(args: list[str], repo: str) -> str:
    result = subprocess.run(
        ["git", "-C", repo, *args],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise HistorianError(f"git {' '.join(args)} : {result.stderr.strip()}")
    return result.stdout


def _gh(args: list[str], repo: str) -> str | None:
    """Appel GitHub optionnel : son absence dégrade, elle ne casse pas.

    Le MVP doit rester utilisable hors ligne et sans `gh` installé.
    """
    try:
        result = subprocess.run(
            ["gh", *args],
            cwd=repo,
            capture_output=True,
            text=True,
            check=False,
            timeout=15,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return None
    if result.returncode != 0:
        return None
    return result.stdout


def _languages(files: list[FileChange]) -> list[str]:
    seen: list[str] = []
    for change in files:
        for ext, lang in _EXTENSION_LANGUAGES.items():
            if change.path.endswith(ext) and lang not in seen:
                seen.append(lang)
    return seen


def _parse_numstat(raw: str) -> list[FileChange]:
    changes: list[FileChange] = []
    for line in raw.splitlines():
        parts = line.split("\t")
        if len(parts) != 3:
            continue
        added_raw, removed_raw, path = parts
        # git écrit « - » pour les fichiers binaires.
        added = int(added_raw) if added_raw.isdigit() else 0
        removed = int(removed_raw) if removed_raw.isdigit() else 0
        changes.append(FileChange(path=path, added=added, removed=removed, status="M"))
    return changes


def _pull_request_for(sha: str, repo: str) -> tuple[int | None, str | None, str | None]:
    raw = _gh(
        ["pr", "list", "--search", sha, "--state", "merged", "--json", "number,title,body", "--limit", "1"],
        repo,
    )
    if not raw:
        return None, None, None
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        return None, None, None
    if not data:
        return None, None, None
    pr = data[0]
    return pr.get("number"), pr.get("title"), pr.get("body")


def analyze_commit(ref: str = "HEAD", repo: str = ".", with_github: bool = True) -> FeatureFact:
    """Construit la fiche factuelle d'un commit."""
    fields = _git(["show", "-s", "--format=%H%n%h%n%s%n%aI%n%b", ref], repo).split("\n")
    if len(fields) < 4:
        raise HistorianError(f"Commit introuvable : {ref}")

    sha, short_sha, subject, author_date = fields[0], fields[1], fields[2], fields[3]
    body = "\n".join(fields[4:]).strip()

    files = _parse_numstat(_git(["show", "--numstat", "--format=", ref], repo))
    diff = _git(["show", "--format=", "--unified=3", ref], repo)

    branch = _git(["rev-parse", "--abbrev-ref", "HEAD"], repo).strip()

    pr_number = pr_title = pr_body = None
    if with_github:
        pr_number, pr_title, pr_body = _pull_request_for(sha, repo)

    return FeatureFact(
        sha=sha,
        short_sha=short_sha,
        subject=subject,
        body=body,
        author_date=author_date,
        branch=branch,
        files=files,
        languages=_languages(files),
        pr_number=pr_number,
        pr_title=pr_title,
        pr_body=pr_body,
        files_changed=len(files),
        lines_added=sum(f.added for f in files),
        lines_removed=sum(f.removed for f in files),
        touches_tests=any(f.is_test for f in files),
        diff_excerpt=diff[:DIFF_EXCERPT_MAX_CHARS],
    )


def is_publishable(fact: FeatureFact) -> tuple[bool, str]:
    """Tout commit ne mérite pas une publication.

    La règle éditoriale « éviter de transformer chaque commit en publication »
    est appliquée ici, en amont du modèle : inutile de payer une génération
    pour un renommage de variable. Le seuil est volontairement grossier — c'est
    un filtre, pas un jugement de valeur.
    """
    subject = fact.subject.lower()

    trivial_prefixes = ("chore", "style", "docs", "merge ", "revert ", "wip")
    if subject.startswith(trivial_prefixes):
        return False, f"Commit de maintenance ({fact.subject.split(':')[0]})"

    if fact.files_changed == 0:
        return False, "Aucun fichier modifié"

    only_noise = all(
        f.path.endswith((".lock", ".png", ".jpg", ".pbxproj")) for f in fact.files
    )
    if only_noise:
        return False, "Ne touche que des fichiers générés ou binaires"

    if fact.lines_added + fact.lines_removed < 10:
        return False, "Changement trop petit pour porter un sujet"

    return True, ""
