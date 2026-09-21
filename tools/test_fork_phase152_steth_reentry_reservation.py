#!/usr/bin/env python3
"""RC6 regression: async posterior-to-supine auscultation must reserve the scope generation and old Unload must be harmless."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FUN = ROOT / "addons" / "acm_extended" / "functions"

def read(path):
    return path.read_text(encoding="utf-8", errors="replace")

entry = read(FUN / "fn_stethoscopeEntryFlip.sqf")
entry_tick = read(FUN / "fn_stethoscopeEntryFlipTick.sqf")
begin = read(FUN / "fn_beginStethoscopeAction.sqf")
close = read(FUN / "fn_stethoscopeClose.sqf")
use = read(ROOT / "addons" / "breathing" / "functions" / "fnc_useStethoscope.sqf")
startup = read(FUN / "fn_initForkStartupRuntime.sqf")
iv = read(FUN / "fn_ivExtravasationState.sqf")

# Posterior re-entry reserves ContinuousAction BEFORE the asynchronous roll and suppresses native menu reopen.
assert 'ACM_core_ContinuousAction_Active", true' in entry
assert 'ACM_core_ContinuousAction_Epoch' in entry
assert 'ace_medical_gui_pendingReopen = false;' in entry
assert 'ACME_stethEntryEpoch' in entry

# The eventual scope adopts that exact reservation instead of failing on Active=true or creating another epoch.
assert '["_reservedEpoch", -1, [0]]' in begin
assert 'private _adoptingReservation = _reservedEpoch >= 0;' in begin
assert 'private _reservationValid' in begin
assert '_reservedEpoch' in use
assert 'false, 81000, _entryEpoch' in use
assert '[_provider, _patient, _bodyPart, true, _entryEpoch] call ACM_breathing_fnc_useStethoscope;' in entry_tick

# A stale entry worker or stale old dialog cannot cancel the new scope generation.
assert 'private _reservationCurrent' in entry_tick
assert 'if (!_reservationCurrent) exitWith {};' in entry_tick
assert 'private _wasFlipActive' in close
assert 'if (_wasFlipActive) then {' in close
assert 'ACME_stethPatientLeaseToken' in use
assert 'ACME_stethChestLeaseId' in use
assert 'ACME_stethPatientLeaseToken' in close
assert 'ACME_stethChestLeaseId' in close

# Reported HEMTT macro padding warning is removed.
assert 'GET_IV_COMPLICATIONS_FLOW_X(_patient,_partIndex,_x)' in iv
assert 'GET_IV_COMPLICATIONS_FLOW_X(_patient, _partIndex, _x)' not in iv

# Reported final-newline files stay newline terminated.
for rel in [
    "addons/acm_extended/functions/fn_chestSealCanPhysicalRoll.sqf",
    "addons/acm_extended/functions/fn_chestSealPatientBegin.sqf",
    "addons/acm_extended/functions/fn_infusionDrawStock.sqf",
    "addons/acm_extended/functions/fn_skListSelect.sqf",
    "addons/acm_extended/functions/fn_skMedicationSelect.sqf",
    "addons/acm_extended/functions/fn_stethoscopeClose.sqf",
    "addons/main/script_version.hpp",
]:
    assert (ROOT / rel).read_bytes().endswith(b"\n"), rel

assert 'ACME_buildBatch = "B122";' in startup
assert 'ACME_debugRevision = "rc6";' in startup

print("PASS rc6: stethoscope re-entry reservation + stale unload isolation + HEMTT warning cleanup")
