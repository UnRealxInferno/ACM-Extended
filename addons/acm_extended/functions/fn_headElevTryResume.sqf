// a debounced restore, called a short delay after a maneuver ends.
// it bails if the restore was canceled or if the elevation itself was canceled, and it holds, re-checking, while
// CPR is still running on the casualty, so a continuous CPR session keeps them flat until it finishes. then they
// pop back up to elevated.
// the arg is [_patient].
params ["_patient", ["_token", ""]];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {[_patient, "headElevTryResume", [_patient, _token]] call ACME_fnc_ownerDispatch;};
if (_token == "") then {_token = _patient getVariable ["ACME_headElev_poseToken", ""];};
if ((_patient getVariable ["ACME_headElev_poseToken", ""]) != _token) exitWith {};
if !(_patient getVariable ["ACME_headElev_ResumePending", false]) exitWith {};
if (_patient getVariable ["ACME_CS_ProcedureActive", false]) exitWith {
    [{_this call ACME_fnc_headElevTryResume;}, [_patient, _token], 0.5] call CBA_fnc_waitAndExecute;
};
private _readyAt = _patient getVariable ["ACME_headElev_suspendReadyAt", -1];
if (_readyAt > CBA_missionTime) exitWith {
    [{_this call ACME_fnc_headElevTryResume;}, [_patient, _token], ((_readyAt - CBA_missionTime) max 0.05) + 0.05] call CBA_fnc_waitAndExecute;
};
private _leases = _patient getVariable ["ACME_headElev_treatments", createHashMap];
{
    private _entry = _leases get _x;
    private _medic = _entry param [0, objNull];
    if (isNull _medic || {!alive _medic} || {_medic getVariable ["ACE_isUnconscious", false]}
        || {CBA_missionTime - (_entry param [1, CBA_missionTime]) > 300}) then {_leases deleteAt _x;};
} forEach keys _leases;
if (count _leases > 0) exitWith {
    [{_this call ACME_fnc_headElevTryResume;}, [_patient, _token], 0.75] call CBA_fnc_waitAndExecute;
};
if !(_patient getVariable ["ACME_headElevated", false]) exitWith {
    _patient setVariable ["ACME_headElev_ResumePending", false, true];
};
if ([_patient] call ACM_core_fnc_cprActive) exitWith {
    [{ _this call ACME_fnc_headElevTryResume }, [_patient, _token], 0.75] call CBA_fnc_waitAndExecute;
};
_patient setVariable ["ACME_headElev_ResumePending", false, true];
[_patient] call ACME_fnc_headElevResume;
