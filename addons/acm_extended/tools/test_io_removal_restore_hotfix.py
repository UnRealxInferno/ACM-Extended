from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
CFG = (ROOT / "config.cpp").read_text()
MENU = (ROOT / "functions" / "fn_menuActionInfo.sqf").read_text()
SET_LOCAL = (ROOT.parent / "circulation" / "functions" / "fnc_setIVLocal.sqf").read_text()


def class_block(name: str) -> str:
    m = re.search(rf"class\s+{re.escape(name)}(?:\s*:\s*[A-Za-z0-9_]+)?\s*\{{(.*?)\n\s*\}};", CFG, re.S)
    assert m, f"{name} missing"
    return m.group(1)


def test_native_io_rows_are_retired_after_iv_parent_is_hidden():
    hidden = CFG.index('class RemoveIV_16_Upper { condition = "false"; };')
    fast = CFG.index('class RemoveIO_FAST1 { condition = "false"; };', hidden)
    ez = CFG.index('class RemoveIO_EZ { condition = "false"; };', fast)
    custom = CFG.index('class ACME_RemoveIO_FAST1 {', ez)
    assert hidden < fast < ez < custom


def test_fast1_custom_removal_is_self_contained():
    b = class_block("ACME_RemoveIO_FAST1")
    assert 'displayName = "$STR_ACM_Circulation_RemoveIO_FAST1";' in b
    assert 'allowedSelections[] = {"Body"};' in b
    assert '[_patient, _bodyPart, 4] call ACM_circulation_fnc_hasIO' in b
    assert '[_medic, _patient, _bodyPart, 4, false, false] call ACM_circulation_fnc_setIV' in b
    assert 'treatmentTime = 3.5;' in b


def test_ez_custom_removal_is_self_contained():
    b = class_block("ACME_RemoveIO_EZ")
    assert 'displayName = "$STR_ACM_Circulation_RemoveIO_EZ";' in b
    for part in ("LeftArm", "RightArm", "LeftLeg", "RightLeg"):
        assert f'"{part}"' in b
    assert '[_patient, _bodyPart, 3] call ACM_circulation_fnc_hasIO' in b
    assert '[_medic, _patient, _bodyPart, 3, false, false] call ACM_circulation_fnc_setIV' in b


def test_custom_io_removals_stay_in_iv_access_menu_bucket():
    assert '_name in ["acme_removeio_fast1", "acme_removeio_ez"]' in MENU
    assert '["medication", "iv_access", false]' in MENU


def test_io_remove_still_clears_owner_local_io_state():
    assert 'private _state = GET_IO(_patient);' in SET_LOCAL
    assert '_state set [_part, _type];' in SET_LOCAL
    assert '_patient setVariable [QGVAR(IO_Placement), _state, true];' in SET_LOCAL
