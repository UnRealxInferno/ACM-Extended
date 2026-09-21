#include "..\script_component.hpp"
/* NA3. Shared entry for UI and ACM's AdministerShock API. Work is committed only by the patient owner. */
params ["_medic", "_patient"];
if (isNull _patient || {isNull _medic}) exitWith {};
private _seq = (missionNamespace getVariable ["ACME_shockSequence", 0]) + 1;
missionNamespace setVariable ["ACME_shockSequence", _seq];
private _id = format ["%1:%2:%3", clientOwner, _seq, diag_frameNo];
private _epoch = [_patient] call ACME_fnc_clinicalEpoch;
private _lastShock = _patient getVariable ["ACM_circulation_AED_LastShock", -60];
private _monitorTarget = missionNamespace getVariable ["ACM_circulation_AED_Monitor_Target", objNull];
private _sync = if (_monitorTarget isEqualTo _patient) then {
    uiNamespace getVariable ["ACME_sync_localArmed", _patient getVariable ["ACME_sync_armed", false]]
} else {
    _patient getVariable ["ACME_sync_armed", false]
};
[_patient, "shock", [_medic, _patient, _id, _epoch, _lastShock, _sync, serverTime]] call ACME_fnc_ownerDispatch;
