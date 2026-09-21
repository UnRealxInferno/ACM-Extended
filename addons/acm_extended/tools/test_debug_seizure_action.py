from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8-sig", errors="strict")


def test_debug_seizure_action_is_head_only_and_debug_gated():
    config = read("config.cpp")
    assert "class ACME_DebugInduceSeizure: CheckPulse" in config
    assert 'displayName = "Induce Seizure (debug)";' in config
    assert 'allowedSelections[] = {"Head"};' in config
    assert '[] call ACME_fnc_debugEnabled' in config
    assert "ACME_fnc_debugInduceSeizure" in config


def test_debug_seizure_is_in_existing_debug_submenu():
    menu = read("functions/fn_initMedicalMenuConfig.sqf")
    assert '"Induce Seizure (debug)"' in menu
    assert '["debug", "Debug", "advanced"' in menu
    assert "{[] call ACME_fnc_debugEnabled}" in menu


def test_debug_seizure_routes_to_patient_owner():
    dispatch = read("functions/fn_ownerDispatch.sqf")
    fn = read("functions/fn_debugInduceSeizure.sqf")
    assert 'case "debugSeizure"' in dispatch
    assert '["ACME_ownerCommand",[_patient,"debugSeizure"' in fn
    assert "if (!local _patient)" in fn


def test_debug_seizure_uses_real_shared_seizure_state():
    fn = read("functions/fn_debugInduceSeizure.sqf")
    tox = read("functions/fn_lidoToxTick.sqf")
    assert "ACME_debugSeizureUntil" in fn
    assert "ACME_circ_activePatients pushBackUnique _patient" in fn
    assert "ACME_fnc_seizureCollapse" in fn
    assert '"ACME_lido_seizureState","active"' in fn
    assert '"ACME_seizure_rrDrive"' in fn
    assert "ACME_fnc_seizureMotion" in fn
    assert 'private _debugCause = _debugUntil > _now;' in tox
    assert '|| _debugCause' in tox
    assert "_debugCause ||" in tox


def test_debug_seizure_cleans_up_with_full_heal():
    clear = read("functions/fn_clearAllAilments.sqf")
    assert '"ACME_debugSeizureUntil"' in clear
