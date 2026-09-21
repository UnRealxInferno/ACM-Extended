#!/usr/bin/env python3
"""RC5 source contracts: layered junctional art, animated carrier removal, persistent chest-seal provider hold."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FUN = ROOT / "addons" / "acm_extended" / "functions"

def read(path):
    return path.read_text(encoding="utf-8", errors="replace")

junction = read(FUN / "fn_updateJunctionalImage.sqf")
acquire = read(FUN / "fn_chestAccessVestAcquire.sqf")
provider = read(FUN / "fn_chestAccessVestProvider.sqf")
patient_begin = read(FUN / "fn_chestSealPatientBegin.sqf")
open_fn = read(FUN / "fn_chestSealOpen.sqf")
flip_tick = read(FUN / "fn_chestSealFlipTick.sqf")
close_fn = read(FUN / "fn_chestSealClose.sqf")
pose_start = read(FUN / "fn_treatmentPoseStart.sqf")
pose_stop = read(FUN / "fn_treatmentPoseStop.sqf")
runtime = read(FUN / "fn_initChestSealProcedureRuntime.sqf")
startup = read(FUN / "fn_initForkStartupRuntime.sqf")
cfg = read(ROOT / "addons" / "acm_extended" / "config.cpp")
treatment = read(ROOT / "addons" / "core" / "overrides" / "fnc_treatment.sqf")

# Junctional packing/XStat is an overlay on top of the unchanged base wound and never fades.
assert '_woundC ctrlShow (_state in ["open", "packed", "xstat"]);' in junction
assert '_packedC ctrlShow (_state in ["packed", "xstat"]);' in junction
assert 'junctionalwound_packed_leftarm_ca.paa' in junction
assert 'junctionalwound_xstat_leftarm_ca.paa' in junction
assert 'ctrlSetFade 0' in junction
for forbidden in ["ACME_JuncVisualFadeStart", "ACME_junctionalImageFadeInSec", "ctrlCommit _left"]:
    assert forbidden not in junction

# Carrier removal uses the exact patient lift/release theatre from Semi-Fowler and medic4 provider handling.
assert '"ACME_HeadElevPatientGrab"' in acquire
assert '"ACME_HeadElevPatientRelease"' in acquire
assert 'removeVest _p;' in acquire
assert 'ACME_fnc_headElevPinPose' in acquire
assert 'ACME_fnc_chestAccessVestProvider' in provider
assert 'ACME_fnc_rollProviderStart' in provider
assert '[_patient, _medic, "chestseal"] call ACME_fnc_chestAccessVestAcquire;' in patient_begin

# Generic chest treatments wait for the animated carrier-removal sequence before native treatment begins.
assert 'ACME_chestAccessPreflightActive' in treatment
assert 'ACME_chestAccess_readyServer' in treatment
assert 'private _started = _args call ace_medical_treatment_fnc_treatment;' in treatment
assert 'if (!_started) then {' in treatment
assert 'ACME_fnc_chestAccessVestEvent' in treatment
assert treatment.index('ACME_chestAccessPreflightActive') < treatment.index('ACM_core_fnc_treatmentNative')

# Chest-seal provider remains in a persistent hands-on-chest pose and Flip hands directly back to it.
assert 'class ACME_ChestSealWorkspace' in cfg
assert 'class chestSealProviderHoldStart {};' in cfg
assert 'case "chestSealWorkspace": {"ACME_ChestSealWorkspace"};' in pose_start
assert 'ACME_CS_workspaceHoldAt' in runtime
assert '["chestSealWorkspace", ACME_CS_workspaceHoldAt]' in runtime
assert '_directChestHandoff' in pose_start
assert '["_handoff", false' in pose_stop
assert 'ACME_fnc_chestSealProviderHoldStart' in open_fn
assert 'ACME_fnc_chestSealProviderHoldStart' in flip_tick
assert '"chestSealWorkspace"' in close_fn

assert 'ACME_buildBatch = "B121";' in startup
assert 'ACME_debugRevision = "rc5";' in startup

print("PASS rc5: junctional layering + carrier lift/remove + persistent chest workspace")
