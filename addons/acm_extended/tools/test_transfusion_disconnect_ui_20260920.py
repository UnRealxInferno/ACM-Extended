from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT.parent / "circulation/functions/fnc_openTransfusionMenu.sqf"

def source():
    return SRC.read_text(encoding="utf-8", errors="replace")

def test_dynamic_access_overlays_fail_closed_on_open():
    s = source()
    assert "IDC_TRANSFUSIONMENU_BG_IO_TORSO" in s
    assert "ctrlShow false" in s
    assert "IDC_TRANSFUSIONMENU_BG_TOURNIQUET_LEFTARM" in s

def test_menu_has_generation_and_exact_display_ownership():
    s = source()
    assert "TransfusionMenu_Generation" in s
    assert '_display isNotEqualTo (findDisplay IDC_TRANSFUSIONMENU)' in s
    assert '["ACM_TX_PFH", _pfh]' in s
    assert 'displayAddEventHandler ["Unload"' in s

def test_old_pfh_cannot_clear_new_menu_globals():
    s = source()
    assert "Superseded display. Retire only this PFH" in s
    assert "== _generation" in s
    assert "TransfusionMenu_Target), objNull]) isEqualTo _patient" in s

def test_disconnect_checks_null_before_distance_and_vehicle_math():
    s = source()
    guard = s.index("private _patientCondition = isNull _patient;")
    distance = s.index("_patient distance2D _medic", guard)
    branch = s.index("if (!_patientCondition && {!_medicCondition}) then", guard)
    assert guard < branch < distance

def test_render_arrays_are_shape_checked_and_fail_closed():
    s = source()
    assert "DEFAULT_TOURNIQUET_VALUES" in s
    assert "ACM_IV_PLACEMENT_DEFAULT_0" in s
    assert "ACM_IO_PLACEMENT_DEFAULT_0" in s
    assert "_IVArray param [_forEachIndex + 2, [0,0,0]]" in s
    assert "_IOArray param [_forEachIndex + 1, 0]" in s

def test_pfh_captures_actual_provider_not_future_ace_player():
    s = source()
    assert "[_display, _medic, _patient, _inVehicle, _menuGeneration, _closeID]" in s
    assert "[_display, ACE_player, GVAR(TransfusionMenu_Target), _inVehicle]" not in s
