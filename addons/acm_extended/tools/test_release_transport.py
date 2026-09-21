"""Release boundary: experimental drag handles stay on dev, shared transport stays available."""
from pathlib import Path
import re

ADDONS = Path(__file__).resolve().parents[2]


def test_release_has_no_drag_handle_entrypoints_or_runtime():
    leftovers = []
    for path in ADDONS.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in {".sqf", ".cpp", ".hpp"}:
            continue
        if re.search(r"drag\s*handle", path.name + path.read_text(encoding="utf-8-sig"), re.I):
            leftovers.append(str(path.relative_to(ADDONS)))
    assert not leftovers, f"Experimental drag handle leaked into release: {leftovers}"


def test_release_keeps_native_transport_and_shared_rope_dependencies():
    core = (ADDONS / "core/CfgFunctions.hpp").read_text()
    assert "class canDrag {" in core
    assert "class canCarry {" in core
    config = (ADDONS / "acm_extended/config.cpp").read_text()
    assert '"ace_fastroping"' in config
    assert "class ACM_LyingState_GetUp {" in config
    assert "class ACME_LyingState_GetUp_Player {" in config
    post_init = (ADDONS / "acm_extended/functions/fn_postInit.sqf").read_text()
    assert "call ACME_fnc_registerHeadElevationTransportRuntime;" in post_init
