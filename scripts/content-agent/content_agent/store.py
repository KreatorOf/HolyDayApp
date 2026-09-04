"""Persistance des brouillons et journalisation.

Un brouillon vit dans `marketing/pending/` tant qu'il n'est pas traité, puis
part dans `marketing/published/` une fois approuvé. Rien n'est jamais écrasé :
le nom de fichier porte le sha du commit.

Tout ce qui est écrit passe par `guards.redact` — le journal ne doit pas être
le maillon par lequel une clé fuit.
"""

from __future__ import annotations

import datetime as _dt
import json
from dataclasses import asdict
from pathlib import Path

from .facts import Drafts, FeatureFact
from .guards import redact


class Store:
    def __init__(self, root: Path):
        self.root = root
        self.marketing = root / "marketing"
        self.pending = self.marketing / "pending"
        self.published = self.marketing / "published"
        self.log_path = self.marketing / "content-agent.log"

    # --- Lectures ---

    def brand(self) -> str:
        path = self.marketing / "brand.md"
        if not path.exists():
            raise FileNotFoundError(f"Identité éditoriale absente : {path}")
        return path.read_text(encoding="utf-8")

    def history(self) -> str:
        path = self.marketing / "content-history.md"
        return path.read_text(encoding="utf-8") if path.exists() else "(aucune publication)"

    # --- Écritures ---

    def save_pending(self, fact: FeatureFact, drafts: Drafts) -> Path:
        self.pending.mkdir(parents=True, exist_ok=True)
        path = self.pending / f"{fact.short_sha}.json"
        payload = {
            "sha": fact.sha,
            "short_sha": fact.short_sha,
            "subject": fact.subject,
            "generated_at": _dt.datetime.now(_dt.UTC).isoformat(),
            "drafts": asdict(drafts),
        }
        path.write_text(
            redact(json.dumps(payload, ensure_ascii=False, indent=2)), encoding="utf-8"
        )
        return path

    def mark_published(self, fact: FeatureFact, drafts: Drafts, platforms: list[str]) -> Path:
        self.published.mkdir(parents=True, exist_ok=True)
        target = self.published / f"{fact.short_sha}.json"
        payload = {
            "sha": fact.sha,
            "approved_at": _dt.datetime.now(_dt.UTC).isoformat(),
            "platforms": platforms,
            "drafts": asdict(drafts),
        }
        target.write_text(
            redact(json.dumps(payload, ensure_ascii=False, indent=2)), encoding="utf-8"
        )
        pending = self.pending / f"{fact.short_sha}.json"
        if pending.exists():
            pending.unlink()
        self.append_history(fact, drafts, platforms)
        return target

    def append_history(self, fact: FeatureFact, drafts: Drafts, platforms: list[str]) -> None:
        path = self.marketing / "content-history.md"
        if not path.exists():
            return
        day = _dt.date.today().isoformat()
        line = f"{day} | {', '.join(platforms)} | {drafts.angle} | {fact.short_sha}\n"
        content = path.read_text(encoding="utf-8")
        marker = "<!-- publications -->"
        if marker in content:
            content = content.replace(marker, f"{marker}\n{redact(line)}", 1)
        else:
            content += redact(line)
        path.write_text(content, encoding="utf-8")

    def log(self, message: str) -> None:
        self.marketing.mkdir(parents=True, exist_ok=True)
        stamp = _dt.datetime.now(_dt.UTC).isoformat()
        with self.log_path.open("a", encoding="utf-8") as handle:
            handle.write(f"{stamp} {redact(message)}\n")
