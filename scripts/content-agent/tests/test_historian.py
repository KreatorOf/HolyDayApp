from content_agent import historian


def test_analyzes_a_known_commit(repo):
    fact = historian.analyze_commit("HEAD", repo=str(repo), with_github=False)

    assert fact.subject == "[FEAT] Ajoute l'écran de nouveautés"
    assert fact.files_changed == 2
    assert fact.lines_added == 30
    assert fact.touches_tests is True
    assert "Swift" in fact.languages
    assert fact.short_sha and len(fact.short_sha) >= 7


def test_diff_excerpt_is_bounded(repo):
    fact = historian.analyze_commit("HEAD", repo=str(repo), with_github=False)
    assert len(fact.diff_excerpt) <= historian.DIFF_EXCERPT_MAX_CHARS


def test_unknown_ref_raises(repo):
    try:
        historian.analyze_commit("n-existe-pas", repo=str(repo), with_github=False)
    except historian.HistorianError:
        return
    raise AssertionError("un ref inconnu doit lever HistorianError")


def test_chore_commit_is_not_publishable(repo):
    fact = historian.analyze_commit("HEAD", repo=str(repo), with_github=False)
    chore = type(fact)(**{**fact.__dict__, "subject": "chore: bump deps"})
    publishable, reason = historian.is_publishable(chore)
    assert publishable is False
    assert "maintenance" in reason


def test_tiny_change_is_not_publishable(repo):
    fact = historian.analyze_commit("HEAD", repo=str(repo), with_github=False)
    tiny = type(fact)(**{**fact.__dict__, "lines_added": 1, "lines_removed": 0})
    publishable, reason = historian.is_publishable(tiny)
    assert publishable is False
    assert "trop petit" in reason


def test_real_feature_is_publishable(repo):
    fact = historian.analyze_commit("HEAD", repo=str(repo), with_github=False)
    publishable, reason = historian.is_publishable(fact)
    assert publishable is True, reason
