from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
F = ROOT / "addons/acm_extended/functions"
CORE = ROOT / "addons/core/overrides"


def read(path: Path) -> str:
    return path.read_text(errors="ignore")


def fn(name: str) -> str:
    return read(F / f"fn_{name}.sqf")


def test_dead_equipment_menu_keeps_state_driven_recovery_actions():
    src = read(CORE / "fnc_canTreatCached.sqf")
    start = src.index("private _deadEquipmentActions")
    end = src.index("private _deadThoracicActions", start)
    block = src[start:end]

    for action in (
        "ACME_VentOpenPatient",
        "ACME_DisconnectETVent",
        "ACME_SwapVentBattery",
        "ACME_RemoveNRB",
        "ACME_UnwrapHPMK",
        "ACME_ExposeChestHPMK",
        "ACME_CoverChestHPMK",
        "ACME_RemoveHPMK",
    ):
        assert action in block

    # Access is based on equipment state, not a second live-patient requirement.
    assert '"ACME_vent_onPatient"' in block
    assert '"ACME_vent_recovering"' in block
    assert '"ACME_nrb_on"' in block
    assert '"ACME_hpmk_state"' in block
    assert "alive _target" not in block.replace("!alive _target", "")


def test_dead_vent_actions_only_manage_an_existing_device():
    src = read(CORE / "fnc_canTreatCached.sqf")
    start = src.index('case "ACME_VentOpenPatient"')
    end = src.index('case "ACME_RemoveNRB"', start)
    block = src[start:end]

    assert '"ACME_vent_onPatient", false' in block
    assert '"ACME_vent_recovering", false' in block
    assert '"ACME_vent_circuit", false' in block or '"ACME_vent_configured", false' in block
    # Never turn corpse access into a way to deploy a new spare ventilator.
    assert '"ACME_Ventilator"' not in block

    disconnect = fn("ventDisconnectPatient")
    custody = fn("ventCustodyRequest")
    assert "!alive _patient" not in disconnect
    assert "!alive _patient" not in custody
    assert '"return"' in disconnect
    assert 'if (_op == "return")' in custody


def test_dead_nrb_stops_flow_without_deleting_the_mask():
    src = fn("nrbTick")
    start = src.index("if (!alive _u) then")
    end = src.index('if !(_u getVariable ["ACME_nrb_on", false])', start)
    dead = src[start:end]

    assert "[_u] call _fnc_stopSfx" in dead
    assert "continue" in dead
    # _fnc_stopSfx only clears active delivery; death must not write ACME_nrb_on=false.
    assert '[_u, false' not in dead
    assert '"ACME_nrb_on", false' not in dead

    remove = fn("nrbRemove")
    assert '"nrbState"' in remove
    assert "!alive _patient" not in remove


def test_dead_hpmk_state_can_be_exposed_unwrapped_and_recovered():
    cached = read(CORE / "fnc_canTreatCached.sqf")
    start = cached.index("private _deadEquipmentActions")
    end = cached.index("private _deadThoracicActions", start)
    block = cached[start:end]
    for state, action in (
        ('_hpmkState in ["wrapped", "exposed"]', "ACME_UnwrapHPMK"),
        ('_hpmkState == "wrapped"', "ACME_ExposeChestHPMK"),
        ('_hpmkState == "exposed"', "ACME_CoverChestHPMK"),
        ('_hpmkState == "prepped"', "ACME_RemoveHPMK"),
    ):
        assert action in block
        assert state in block

    for name in ("hpmkUnwrap", "hpmkExposeChest", "hpmkCoverChest", "hpmkRemove"):
        src = fn(name)
        assert "!alive _patient" not in src
        assert "ACME_fnc_hpmkStateCommit" in src


def test_death_keeps_equipment_but_workers_stay_frozen():
    death = fn("deathFreeze")
    assert "HPMK/NRB/ventilator custody" in death
    for field in ("ACME_nrb_on", "ACME_hpmk_state", "ACME_vent_onPatient"):
        assert f'setVariable ["{field}", false' not in death
        assert f'setVariable ["{field}", ""' not in death

    # Equipment persistence must not restart physiology on a corpse.
    assert "!alive _patient" in fn("ventDriveTick")
    assert "!alive _u" in fn("hpmkTick")
    nrb = fn("nrbTick")
    assert "if (!alive _u) then" in nrb
    assert nrb.index("if (!alive _u) then") < nrb.index("// the oxygen draw from the tank")
