"""Le mode hors ligne : la chaîne doit fonctionner sans réseau ni clé API,
et sa sortie doit passer les garde-fous comme n'importe quelle autre."""

from content_agent import guards, historian, writer


def test_offline_drafts_are_built_from_facts_only(repo):
    fact = historian.analyze_commit("HEAD", repo=str(repo), with_github=False)
    drafts = writer.write_offline(fact)

    assert fact.subject in drafts.x
    assert drafts.substack_outline
    assert not drafts.is_skip


def test_offline_drafts_pass_the_guards(repo):
    fact = historian.analyze_commit("HEAD", repo=str(repo), with_github=False)
    drafts = writer.write_offline(fact)
    assert guards.verify(drafts, fact) == []


def test_offline_never_calls_the_network(repo, monkeypatch):
    # Si `anthropic` était importé, l'import échouerait ici.
    monkeypatch.setitem(__import__("sys").modules, "anthropic", None)
    fact = historian.analyze_commit("HEAD", repo=str(repo), with_github=False)
    assert writer.write_offline(fact).x


def test_schema_requires_every_field():
    required = set(writer.SCHEMA["required"])
    assert required == set(writer.SCHEMA["properties"])
    assert writer.SCHEMA["additionalProperties"] is False


def test_api_failures_surface_as_actionable_messages(repo, monkeypatch, capsys):
    """Une panne de facturation ou de réseau doit donner une consigne, pas une trace."""
    from content_agent import writer as writer_module
    from content_agent.cli import main

    def boom(*_args, **_kwargs):
        raise writer_module.WriterError("Crédits API épuisés.")

    monkeypatch.setattr(writer_module, "write", boom)
    code = main(["--repo", str(repo), "--no-github", "draft", "HEAD"])

    assert code == 1
    assert "Traceback" not in capsys.readouterr().err
