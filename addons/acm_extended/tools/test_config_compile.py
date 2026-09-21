"""Compile the complete addon config with HEMTT, including its semantic lints."""
import os
from pathlib import Path
import re
import shutil
import subprocess

CONFIG = Path(__file__).resolve().parents[1] / "config.cpp"


def test_full_addon_config_passes_hemtt(tmp_path):
    hemtt = os.environ.get("HEMTT") or shutil.which("hemtt")
    if not hemtt:
        import pytest
        pytest.skip("HEMTT is required for config compilation")

    output = tmp_path / "acme-config.json"
    result = subprocess.run(
        [hemtt, "--no-color", "utils", "config", "convert", str(CONFIG), str(output)],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=120,
    )
    diagnostics = re.sub(r"\x1b\[[0-9;]*m", "", result.stdout + result.stderr)
    assert result.returncode == 0, diagnostics
    # HEMTT 1.21's converter can return zero after emitting config lint errors.
    assert not re.search(r"\berror(?:\[[^\]]+\])?:", diagnostics, re.IGNORECASE), diagnostics
    assert output.is_file(), diagnostics
