"""Run the real HEMTT parser/linter so successful packaging cannot hide code warnings."""
import os
from pathlib import Path
import re
import shutil
import subprocess

import pytest


ROOT = Path(__file__).resolve().parents[3]


def test_hemtt_check_has_no_code_diagnostics():
    hemtt = os.environ.get("HEMTT") or shutil.which("hemtt")
    if not hemtt:
        pytest.skip("HEMTT is required for release diagnostics")

    result = subprocess.run(
        [hemtt, "check", "--error-on-all", "--no-color"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=180,
    )
    diagnostics = re.sub(r"\x1b\[[0-9;]*m", "", result.stdout + result.stderr)
    assert result.returncode == 0, diagnostics
    # Some HEMTT commands can emit diagnostics while returning zero. Check the text as well.
    assert not re.search(r"^\s*(?:error|warning)(?:\[[^\]]+\])?:", diagnostics, re.M | re.I), diagnostics
