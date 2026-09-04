"""Les garde-fous sont la garantie « ne jamais inventer ». Ils sont testés
sur des sorties délibérément malveillantes."""

import pytest

from content_agent import guards, historian
from content_agent.facts import Drafts


@pytest.fixture
def fact(repo):
    return historian.analyze_commit("HEAD", repo=str(repo), with_github=False)


def _drafts(**overrides):
    base = dict(
        x="J'ai ajouté un écran de nouveautés.",
        threads="J'ai ajouté un écran de nouveautés. Ça m'a pris plus longtemps que prévu.",
        substack_title="Un écran de nouveautés",
        substack_outline="- Contexte\n- Décision\n- Apprentissage",
        substack_body="Le contexte, la décision, ce que j'en retiens.",
        angle="L'écran de nouveautés",
    )
    base.update(overrides)
    return Drafts(**base)


def test_clean_drafts_pass(fact):
    assert guards.verify(_drafts(), fact) == []


def test_invented_user_metric_is_rejected(fact):
    violations = guards.verify(_drafts(x="Déjà 5000 utilisateurs sur l'app !"), fact)
    kinds = {v.kind for v in violations}
    assert "affirmation interdite" in kinds
    assert "nombre inventé" in kinds


def test_invented_percentage_is_rejected(fact):
    violations = guards.check_no_banned_claims(_drafts(threads="45 % plus rapide."))
    assert any("pourcentage" in v.detail for v in violations)


def test_invented_testimonial_is_rejected(fact):
    violations = guards.check_no_banned_claims(
        _drafts(substack_body="Un utilisateur m'a écrit pour me remercier.")
    )
    assert any("témoignage" in v.detail for v in violations)


def test_revenue_claim_is_rejected(fact):
    violations = guards.check_no_banned_claims(_drafts(x="Premier mois à 300 euros."))
    assert any("revenu" in v.detail for v in violations)


def test_numbers_from_the_facts_are_allowed(fact):
    # 2 fichiers et 30 lignes ajoutées viennent réellement du commit.
    violations = guards.check_no_invented_numbers(
        _drafts(x=f"{fact.files_changed} fichiers, {fact.lines_added} lignes."), fact
    )
    assert violations == []


def test_x_length_limit(fact):
    violations = guards.check_platform_limits(_drafts(x="a" * 281))
    assert any(v.kind == "longueur" for v in violations)


def test_threads_length_limit(fact):
    violations = guards.check_platform_limits(_drafts(threads="a" * 501))
    assert any(v.kind == "longueur" for v in violations)


@pytest.mark.parametrize(
    "secret",
    [
        "sk-ant-api03-AAAAAAAABBBBBBBB",
        "appl_UlQUPWYbfJUrWXoDkEkNxuQHZkY",
        "ghp_AAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        "matthias.cadet25@gmail.com",
        "AuthKey_ZG2YP58NX5.p8",
    ],
)
def test_secrets_never_reach_the_output(fact, secret):
    violations = guards.verify(_drafts(x=f"Ma config : {secret}"), fact)
    assert any(v.kind == "secret" for v in violations), secret


def test_redaction_masks_secrets_in_logs():
    redacted = guards.redact("clé sk-ant-api03-AAAAAAAABBBBBBBB dans le log")
    assert "sk-ant" not in redacted
    assert "[masqué]" in redacted


def test_skipped_drafts_bypass_verification(fact):
    skipped = Drafts("", "", "", "", "", "", skipped_reason="rien à raconter")
    assert guards.verify(skipped, fact) == []
