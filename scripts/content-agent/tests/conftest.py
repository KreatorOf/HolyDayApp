import subprocess
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))


def _run(args, cwd):
    subprocess.run(args, cwd=cwd, check=True, capture_output=True)


@pytest.fixture
def repo(tmp_path):
    """Un vrai dépôt git jetable : l'Historian lit git, on ne le simule pas."""
    _run(["git", "init", "-q", "-b", "main"], tmp_path)
    _run(["git", "config", "user.email", "test@example.invalid"], tmp_path)
    _run(["git", "config", "user.name", "Test"], tmp_path)

    (tmp_path / "marketing").mkdir()
    (tmp_path / "marketing" / "brand.md").write_text("Ton humble.", encoding="utf-8")
    (tmp_path / "marketing" / "content-history.md").write_text(
        "# Historique\n\n<!-- publications -->\n", encoding="utf-8"
    )

    # Les fichiers marketing sont commités à part : le commit analysé par les
    # tests ne doit contenir que la feature.
    _run(["git", "add", "marketing"], tmp_path)
    _run(["git", "commit", "-q", "-m", "chore: marketing"], tmp_path)

    src = tmp_path / "Feature.swift"
    src.write_text("\n".join(f"// ligne {i}" for i in range(20)), encoding="utf-8")
    test = tmp_path / "FeatureTests.swift"
    test.write_text("\n".join(f"// test {i}" for i in range(10)), encoding="utf-8")
    _run(["git", "add", "-A"], tmp_path)
    _run(["git", "commit", "-q", "-m", "[FEAT] Ajoute l'écran de nouveautés"], tmp_path)
    return tmp_path
