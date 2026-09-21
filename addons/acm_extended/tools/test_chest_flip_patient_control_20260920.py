from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FUN = ROOT / "functions"

def read(name):
    return (FUN / name).read_text(encoding="utf-8", errors="replace")

def test_single_authority_excludes_manual_prone_obtunded_and_stale_procedure_state():
    src = read("fn_chestSealCanPhysicalRoll.sqf")
    assert 'ACE_isUnconscious' in src
    assert 'ace_medical_unconscious' in src
    assert 'ACM_core_Lying_State' in src
    assert 'ACM_LyingState' in src
    assert 'stance _patient' not in src
    assert 'ACME_obtunded' not in src
    assert 'ACME_CS_ProcedureGrounded' in src  # documentation only
    # It must require actual lying/rest animation after wake, not just a possibly stale logical flag.
    assert 'animationState _patient' in src
    assert 'ace_medical_engine_uncon_anim_faceup' in src
    assert 'ace_medical_engine_uncon_anim_facedown' in src

def test_flip_button_uses_only_authoritative_roll_eligibility():
    src = read("fn_chestSealFlip.sqf")
    assert 'ACME_fnc_chestSealCanPhysicalRoll' in src
    assert 'stance _patient' not in src
    assert 'ACME_obtunded' not in src
    assert 'ACME_CS_ProcedureGrounded' not in src
    assert 'ACME_CS_VirtualFlip", true' in src

def test_flip_rechecks_after_provider_prep_before_patient_dispatch():
    src = read("fn_chestSealFlipTick.sqf")
    guard = src.index('if !([_patient] call ACME_fnc_chestSealCanPhysicalRoll)')
    dispatch = src.index('call ACME_fnc_chestSealRoll')
    assert guard < dispatch
    assert 'ACME_CS_VirtualFlip", true' in src[guard:dispatch]

def test_patient_owner_rejects_stale_or_remote_roll_before_side_effects():
    src = read("fn_chestSealRoll.sqf")
    gate = src.index('if !([_patient] call ACME_fnc_chestSealCanPhysicalRoll) exitWith {};')
    head = src.index('call ACME_fnc_headElevYieldForRoll')
    anim = src.index('call ACME_fnc_patientAnimRequest')
    assert gate < head < anim
    assert 'stance _patient' not in src
    assert 'ACME_obtunded' not in src
    assert 'ACME_CS_ProcedureGrounded' not in src
    # Both delayed animation callbacks must re-check live eligibility.
    assert src.count('call ACME_fnc_chestSealCanPhysicalRoll') >= 3

def test_workspace_open_and_close_cannot_convert_conscious_prone_into_roll_permission():
    begin = read("fn_chestSealPatientBegin.sqf")
    end = read("fn_chestSealPatientEnd.sqf")
    assert 'private _preGrounded = [_patient] call ACME_fnc_chestSealCanPhysicalRoll;' in begin
    assert 'stance _patient) == "PRONE"' not in begin
    restore = end.split('private _restoreSide = {', 1)[1]
    assert 'call ACME_fnc_chestSealCanPhysicalRoll' in restore
    assert 'stance _p) == "PRONE"' not in restore
    assert 'ACME_obtunded' not in restore