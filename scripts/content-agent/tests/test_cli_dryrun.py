"""Bout en bout : dry-run, validation humaine, et refus de publier."""

import json

import pytest

from content_agent.cli import main
from content_agent.facts import Drafts
from content_agent.publisher import ADAPTERS, PublishNotConfigured


def test_analyze_emits_facts_only(repo, capsys):
    code = main(["--repo", str(repo), "--no-github", "analyze", "HEAD"])
    out = capsys.readouterr().out
    assert code == 0
    assert json.loads(out.split("\n\n")[0])["subject"].startswith("[FEAT]")


def test_draft_offline_writes_a_pending_file(repo, capsys):
    code = main(["--repo", str(repo), "--offline", "--no-github", "draft", "HEAD"])
    assert code == 0
    pending = list((repo / "marketing" / "pending").glob("*.json"))
    assert len(pending) == 1
    assert "Garde-fous : aucune violation" in capsys.readouterr().out


def test_draft_logs_without_secrets(repo):
    main(["--repo", str(repo), "--offline", "--no-github", "draft", "HEAD"])
    log = (repo / "marketing" / "content-agent.log").read_text(encoding="utf-8")
    assert "sk-ant" not in log
    assert "brouillon" in log


def test_publishers_are_inert_in_dry_run():
    drafts = Drafts("x", "t", "titre", "plan", "corps", "angle")
    for name, adapter in ADAPTERS.items():
        result = adapter.publish(drafts, dry_run=True)
        assert result.published is False, name
        assert "dry-run" in result.detail


def test_publishers_refuse_real_publication():
    drafts = Drafts("x", "t", "titre", "plan", "corps", "angle")
    for name, adapter in ADAPTERS.items():
        with pytest.raises(PublishNotConfigured):
            adapter.publish(drafts, dry_run=False)


def test_review_requires_an_existing_draft(repo, capsys):
    code = main(["--repo", str(repo), "--no-github", "review", "deadbee"])
    assert code == 1
    assert "Aucun brouillon" in capsys.readouterr().err


def test_approval_moves_the_draft_and_writes_history(repo, monkeypatch, capsys):
    main(["--repo", str(repo), "--offline", "--no-github", "draft", "HEAD"])
    sha = next((repo / "marketing" / "pending").glob("*.json")).stem

    monkeypatch.setattr("builtins.input", lambda *_: "a")
    code = main(["--repo", str(repo), "--no-github", "review", sha])

    assert code == 0
    assert not list((repo / "marketing" / "pending").glob("*.json"))
    assert (repo / "marketing" / "published" / f"{sha}.json").exists()
    history = (repo / "marketing" / "content-history.md").read_text(encoding="utf-8")
    assert sha in history


def test_cancel_keeps_the_draft_pending(repo, monkeypatch):
    main(["--repo", str(repo), "--offline", "--no-github", "draft", "HEAD"])
    sha = next((repo / "marketing" / "pending").glob("*.json")).stem

    monkeypatch.setattr("builtins.input", lambda *_: "c")
    code = main(["--repo", str(repo), "--no-github", "review", sha])

    assert code == 0
    assert (repo / "marketing" / "pending" / f"{sha}.json").exists()
