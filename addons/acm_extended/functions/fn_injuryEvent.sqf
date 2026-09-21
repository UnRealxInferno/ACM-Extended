/* New wounds from this native damage application only; never re-roll old injury history. */
params ["_patient", "_newWounds", ["_headDelta", 0]];
if (!local _patient || {!alive _patient}) exitWith {};
if (missionNamespace getVariable ["ACME_sys_tbi", true]) then {[_patient, _newWounds, _headDelta] call ACME_fnc_headInjuryTBI;};
// Junctional spawning is registered directly on ace_medical_woundReceived in
// fn_registerInjuryPresentationRuntime. Do not roll it here as well: if a fork does allow the legacy
// woundsHandlerBase override, calling it from both paths would double the configured junctional chance.
[_patient] call ACME_fnc_ownerRegister;
