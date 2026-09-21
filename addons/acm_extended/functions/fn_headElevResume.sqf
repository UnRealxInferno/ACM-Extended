// Restore the elevated animation after a temporary flat maneuver, provided elevation itself was not canceled.
// B122: the Semi-Fowler support carrier was never re-worn during suspension, so resume only re-seats that same
// prop. A backpack-supported temporary chest-access vest is restored separately after its final chest-access lease.
params ["_patient"];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {[_patient, "headElevResume", [_patient]] call ACME_fnc_ownerDispatch;};
if (!alive _patient) exitWith {[_patient] call ACME_fnc_headElevDeathRelease;};
if !(_patient getVariable ["ACME_headElevated", false]) exitWith {};
if !(_patient getVariable ["ACME_headElev_Suspended", false]) exitWith {};

// If the elevated patient uses a backpack, a chest-access action may have temporarily parked the worn carrier.
// Restore it only when no chest-access owner still needs the chest clear. This is independent of the elevation
// support carrier, which remains removed for the entire logical Semi-Fowler placement when no backpack exists.
[_patient] call ACME_fnc_chestAccessVestRestore;

_patient setVariable ["ACME_headElev_suspendKeepVestOut", false, true];
_patient setVariable ["ACME_headElev_suspendVestLoadout", [], false];
_patient setVariable ["ACME_headElev_suspendReadyAt", -1, false];
_patient setVariable ["ACME_headElev_Suspended", false, true];
_patient setVariable ["ACME_headElev_basePosASL", getPosASL _patient, true];
_patient setVariable ["ACME_headElev_baseDir", getDir _patient, true];

// No-backpack Semi-Fowler: move the same support carrier from its parked position back behind the upper back.
// Backpack Semi-Fowler: there is no head-elevation carrier prop and this is intentionally a no-op.
[_patient] call ACME_fnc_headElevPropApply;
[_patient] call ACME_fnc_headElevApplyTilt;
