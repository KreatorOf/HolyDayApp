"""Interface en ligne de commande.

Le dry-run est le défaut, pas une option : publier demande un geste explicite.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from . import guards, historian, writer
from .facts import Drafts, FeatureFact
from .publisher import ADAPTERS, PublishNotConfigured
from .store import Store

BOLD, DIM, RED, GREEN, YELLOW, RESET = (
    "\033[1m", "\033[2m", "\033[31m", "\033[32m", "\033[33m", "\033[0m",
)


def _repo_root(start: Path) -> Path:
    for candidate in [start, *start.parents]:
        if (candidate / ".git").exists():
            return candidate
    return start


def _render(fact: FeatureFact, drafts: Drafts) -> None:
    print(f"\n{BOLD}Commit{RESET} {fact.short_sha} — {fact.subject}")
    print(
        f"{DIM}{fact.files_changed} fichiers, +{fact.lines_added}/-{fact.lines_removed}"
        f"{', tests touchés' if fact.touches_tests else ''}{RESET}"
    )
    if fact.pr_number:
        print(f"{DIM}PR #{fact.pr_number} — {fact.pr_title}{RESET}")

    if drafts.is_skip:
        print(f"\n{YELLOW}Aucune publication proposée{RESET} : {drafts.skipped_reason}")
        return

    print(f"\n{DIM}Angle : {drafts.angle}{RESET}")
    print(f"\n{BOLD}── X ──{RESET} {DIM}({len(drafts.x)}/280){RESET}\n{drafts.x}")
    print(f"\n{BOLD}── Threads ──{RESET} {DIM}({len(drafts.threads)}/500){RESET}\n{drafts.threads}")
    print(f"\n{BOLD}── Substack ──{RESET}\n{drafts.substack_title}\n")
    print(drafts.substack_outline)
    print(f"\n{DIM}{drafts.substack_body}{RESET}")


def _report(violations: list[guards.Violation]) -> None:
    if not violations:
        print(f"\n{GREEN}Garde-fous : aucune violation.{RESET}")
        return
    print(f"\n{RED}Garde-fous : {len(violations)} violation(s).{RESET}")
    for violation in violations:
        print(f"  {RED}✗{RESET} [{violation.kind}] {violation.detail}")


def _build(args, store: Store) -> tuple[FeatureFact, Drafts, list[guards.Violation]]:
    fact = historian.analyze_commit(args.ref, repo=str(store.root), with_github=not args.no_github)

    publishable, reason = historian.is_publishable(fact)
    if not publishable and not args.force:
        drafts = Drafts("", "", "", "", "", "", skipped_reason=reason)
        return fact, drafts, []

    if args.offline:
        drafts = writer.write_offline(fact)
    else:
        drafts = writer.write(fact, store.brand(), store.history())

    return fact, drafts, guards.verify(drafts, fact)


def cmd_analyze(args, store: Store) -> int:
    """Fiche factuelle seule — aucun appel au modèle."""
    fact = historian.analyze_commit(args.ref, repo=str(store.root), with_github=not args.no_github)
    publishable, reason = historian.is_publishable(fact)
    print(fact.to_json())
    print(
        f"\n{'Publiable' if publishable else 'Non publiable'}"
        + (f" : {reason}" if reason else "")
    )
    return 0


def cmd_draft(args, store: Store) -> int:
    fact, drafts, violations = _build(args, store)
    _render(fact, drafts)
    _report(violations)

    if drafts.is_skip:
        store.log(f"skip {fact.short_sha} : {drafts.skipped_reason}")
        return 0

    if violations:
        store.log(f"rejet {fact.short_sha} : {len(violations)} violation(s)")
        print(f"\n{RED}Brouillon rejeté, rien n'a été enregistré.{RESET}")
        return 1

    path = store.save_pending(fact, drafts)
    store.log(f"brouillon {fact.short_sha} enregistré")
    print(f"\n{GREEN}Enregistré{RESET} : {path.relative_to(store.root)}")
    print(f"{DIM}Relis, puis : content-agent review {fact.short_sha}{RESET}")
    return 0


def cmd_review(args, store: Store) -> int:
    path = store.pending / f"{args.sha}.json"
    if not path.exists():
        print(f"{RED}Aucun brouillon en attente pour {args.sha}{RESET}", file=sys.stderr)
        return 1

    payload = json.loads(path.read_text(encoding="utf-8"))
    drafts = Drafts(**payload["drafts"])
    fact = historian.analyze_commit(payload["sha"], repo=str(store.root), with_github=False)
    _render(fact, drafts)

    print(f"\n{BOLD}[A]{RESET}pprouver  {BOLD}[E]{RESET}diter  {BOLD}[C]{RESET}Annuler")
    choice = input("> ").strip().lower()

    if choice.startswith("c"):
        print("Annulé. Le brouillon reste en attente.")
        return 0

    if choice.startswith("e"):
        print(f"{DIM}Édite {path}, puis relance `review`.{RESET}")
        return 0

    if not choice.startswith("a"):
        print("Réponse non reconnue, rien n'a été fait.")
        return 1

    # Approbation : on revérifie, car le fichier a pu être édité à la main.
    violations = guards.verify(drafts, fact)
    _report(violations)
    if violations:
        print(f"\n{RED}Approbation refusée tant que les garde-fous échouent.{RESET}")
        return 1

    platforms = args.platforms or ["x", "threads", "substack"]
    for name in platforms:
        adapter = ADAPTERS.get(name)
        if adapter is None:
            print(f"{YELLOW}Plateforme inconnue, ignorée : {name}{RESET}")
            continue
        try:
            result = adapter.publish(drafts, dry_run=not args.publish)
            print(f"  {name} : {result.detail}")
        except PublishNotConfigured as error:
            print(f"  {YELLOW}{name} : {error}{RESET}")

    target = store.mark_published(fact, drafts, platforms)
    store.log(f"approuvé {fact.short_sha} pour {', '.join(platforms)}")
    print(f"\n{GREEN}Approuvé{RESET} : {target.relative_to(store.root)}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="content-agent",
        description="Documente une feature à partir de son commit.",
    )
    parser.add_argument("--repo", default=None, help="Racine du dépôt (défaut : détection auto)")
    parser.add_argument("--offline", action="store_true", help="Sans appel au modèle")
    parser.add_argument("--no-github", action="store_true", help="Ne pas interroger gh")
    sub = parser.add_subparsers(dest="command", required=True)

    p_analyze = sub.add_parser("analyze", help="Fiche factuelle seule")
    p_analyze.add_argument("ref", nargs="?", default="HEAD")
    p_analyze.set_defaults(func=cmd_analyze)

    p_draft = sub.add_parser("draft", help="Génère les brouillons")
    p_draft.add_argument("ref", nargs="?", default="HEAD")
    p_draft.add_argument("--force", action="store_true", help="Même si jugé non publiable")
    p_draft.set_defaults(func=cmd_draft)

    p_review = sub.add_parser("review", help="Valide un brouillon en attente")
    p_review.add_argument("sha")
    p_review.add_argument("--platforms", nargs="*", default=None)
    p_review.add_argument(
        "--publish",
        action="store_true",
        help="Tente une publication réelle (aucun adaptateur n'est branché dans le MVP)",
    )
    p_review.set_defaults(func=cmd_review)

    args = parser.parse_args(argv)
    root = Path(args.repo) if args.repo else _repo_root(Path.cwd())
    store = Store(root)

    try:
        return args.func(args, store)
    except (historian.HistorianError, writer.WriterError, FileNotFoundError) as error:
        print(f"{RED}{error}{RESET}", file=sys.stderr)
        return 1
