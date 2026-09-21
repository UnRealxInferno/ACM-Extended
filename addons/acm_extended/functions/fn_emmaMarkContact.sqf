// mark the last real patient contact of the local player, for patient-side EMMA routing.
// this is intentionally local to the player, because it prevents overlapping casualties from fighting over one
// display.
// _this is [_medic, _patient].
params [["_medic", objNull], ["_patient", objNull]];

if (isNull _medic || {isNull _patient}) exitWith {};
if !(_medic isKindOf "CAManBase") exitWith {};
if !(_patient isKindOf "CAManBase") exitWith {};
if (_patient isEqualTo _medic) exitWith {};

private _localPlayer = missionNamespace getVariable ["ACE_player", player];
if (isNull _localPlayer) exitWith {};
if !(_medic isEqualTo _localPlayer) exitWith {};

_medic setVariable ["ACME_emma_lastContactPatient", _patient, false];
_medic setVariable ["ACME_emma_lastContactTime", CBA_missionTime, false];

// EMMA routing stays provider-local. The old patient-side per-UID public timestamp had no reader,
// added network traffic on every contact, and unnecessarily exposed a stable player identifier in patient state.
