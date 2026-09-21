// LifePak SYNC button. The local dialog owns immediate operator intent; the casualty owner publishes device state.
private _tgt = missionNamespace getVariable ["ACM_circulation_AED_Monitor_Target", objNull];
if (isNull _tgt) exitWith {};
private _medic = missionNamespace getVariable ["ACM_circulation_AED_Monitor_Medic", objNull];
if (isNull _medic) then {_medic = ACE_player;};
if (isNull _medic) exitWith {};

private _armed = !(uiNamespace getVariable ["ACME_sync_localArmed", _tgt getVariable ["ACME_sync_armed", false]]);
uiNamespace setVariable ["ACME_sync_localArmed", _armed];
[_tgt, "syncArmed", [_medic, _armed, [_tgt] call ACME_fnc_clinicalEpoch]] call ACME_fnc_ownerDispatch;

private _display = uiNamespace getVariable ["ACM_circulation_AEDMonitor_DLG", displayNull];
if (!isNull _display) then {
    private _led = _display displayCtrl 7283201;
    if (!isNull _led) then {_led ctrlShow _armed;};
};
[format ["SYNC %1", ["DISARMED", "ARMED"] select _armed], 2] call ace_common_fnc_displayTextStructured;
