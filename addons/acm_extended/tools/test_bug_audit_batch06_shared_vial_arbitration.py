from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FUN = ROOT / "functions"
CIRC = ROOT.parent / "circulation" / "functions"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def fn(name: str) -> str:
    return read(FUN / name)


def test_shared_vial_holder_requires_owner_acknowledged_lease_without_alive_patient_gate():
    holder = fn("fn_vialHolder.sqf")
    ensure = fn("fn_vialLeaseEnsure.sqf")
    assert "ACME_fnc_vialLeaseEnsure" in holder
    assert "then {_holder} else {objNull}" in holder
    assert "alive _holder" not in holder
    assert '"ACME_vialLeaseAccepted"' in ensure
    assert '"vialLease"' in ensure
    assert "serverTime" in ensure


def test_owner_serializes_one_shared_source_and_dead_patient_remains_valid_inventory():
    commit = fn("fn_vialLeaseCommit.sqf")
    assert "local _holder" in commit
    assert 'getVariable ["ACME_vialLease"' in commit
    assert '_leaseLive = !isNull _leaseMedic && {alive _leaseMedic}' in commit
    assert "alive _holder" not in commit
    assert "_medic distance _holder" in commit
    assert "objectParent _medic" in commit
    assert '_now + 4' in commit


def test_shared_source_mutation_refuses_unleased_client():
    for name in ("fn_vialTake.sqf", "fn_vialRefund.sqf"):
        src = fn(name)
        assert '"ACME_vialLeaseAccepted"' in src
        assert '(_lease param [0,objNull]) isEqualTo _holder' in src
        assert '(_lease param [2,0]) > serverTime' in src


def test_switch_and_close_release_shared_vial_lease():
    switch = read(CIRC / "fnc_Syringe_SwitchTargetInventory.sqf")
    close = fn("fn_skClose.sqf")
    assert "ACME_fnc_vialLeaseRelease" in switch
    assert "ACME_fnc_vialHolder" in switch
    assert "ACME_fnc_vialLeaseRelease" in close


def test_result_refreshes_stock_after_async_claim_and_owner_dispatch_is_registered():
    result = fn("fn_vialLeaseResult.sqf")
    dispatch = fn("fn_ownerDispatch.sqf")
    init = fn("fn_ownerInit.sqf")
    config = read(ROOT / "config.cpp")
    assert '"ACME_vialLeaseResult"' in init
    assert 'case "vialLease"' in dispatch
    assert "ACME_fnc_vialLeaseCommit" in dispatch
    assert "Syringe_UpdateMedicationList" in result
    for name in ("vialLeaseCommit", "vialLeaseEnsure", "vialLeaseRelease", "vialLeaseResult"):
        assert f"class {name} {{}};" in config


def test_lease_release_is_token_scoped_so_stale_clients_cannot_clear_new_owner():
    commit = fn("fn_vialLeaseCommit.sqf")
    assert '_leaseMedic isEqualTo _medic && {_leaseToken isEqualTo _token}' in commit
    release = fn("fn_vialLeaseRelease.sqf")
    assert '"release",_token' in release
