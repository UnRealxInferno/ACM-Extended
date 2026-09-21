"""Read the shipped ECG samples to check QRS width and beat alignment.
Arma still needs to verify cause selection and live monitor transitions.
"""
import ast
from pathlib import Path
import re

ADDONS = Path(__file__).resolve().parents[2]
GENERATOR = ADDONS / "circulation/functions/fnc_displayAEDMonitor_generateEKG.sqf"


def templates():
    source = GENERATOR.read_text(encoding="utf-8-sig")
    shared = re.search(
        r"private _template = if .*? then \{\s*(\[[^\]]+\])\s*\} else \{\s*(\[[^\]]+\])",
        source,
        re.S,
    )
    assert shared, "sinus and default PEA must use the common organized template"
    wide = re.search(
        r"case 5:\s*\{\s*if \(_widePEA\) then \{.*?_template = (\[[^\]]+\]);\s*_rIndex = (\d+);",
        source,
        re.S,
    )
    assert wide, "wide PEA must be selected explicitly"
    indices = re.search(
        r"private _rIndex = if .*? then \{(\d+)\} else \{(\d+)\};",
        source,
        re.S,
    )
    assert indices
    dt = float(re.search(r"private _dt = ([0-9.]+);", source).group(1))
    return (
        (ast.literal_eval(shared.group(1)), int(indices.group(1))),
        (ast.literal_eval(shared.group(2)), int(indices.group(2))),
        (ast.literal_eval(wide.group(1)), int(wide.group(2))),
        dt,
    )


def qrs_span_seconds(samples, dt):
    # Compare the prominent depolarization, excluding low-amplitude P and T samples.
    cutoff = max(abs(value) for value in samples) * 0.30
    active = [index for index, value in enumerate(samples) if abs(value) >= cutoff]
    return (active[-1] - active[0] + 1) * dt


def test_default_pea_has_narrow_qrs_and_metabolic_pea_is_wide():
    fast, normal, wide, dt = templates()
    for samples, _ in (fast, normal):
        assert qrs_span_seconds(samples, dt) < 0.12
    assert qrs_span_seconds(wide[0], dt) > 0.12


def test_all_morphologies_keep_the_r_peak_on_the_electrical_beat():
    fast, normal, wide, _ = templates()
    for samples, r_index in (fast, normal, wide):
        assert samples.index(min(samples)) == r_index
        assert sum(value == min(samples) for value in samples) == 1


def test_default_pea_preserves_separate_p_qrs_and_t_components():
    _, (samples, r_index), _, _ = templates()
    assert any(value < 0 for value in samples[:r_index - 1]), "missing P component"
    assert samples[r_index + 1] > 0, "missing S deflection"
    assert any(value < 0 for value in samples[r_index + 3:]), "missing T component"
