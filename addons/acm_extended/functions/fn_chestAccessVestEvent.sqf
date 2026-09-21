// Owner-side identified lease for temporary chest-access plate-carrier removal.
params [
    ["_patient", objNull, [objNull]],
    ["_medic", objNull, [objNull]],
    ["_id", "", [""]],
    ["_start", true, [false]],
    ["_classname", "", [""]]
];
if (isNull _patient || {_id == ""}) exitWith {};
if (!local _patient) exitWith {[_patient, "chestAccessVestEvent", _this] call ACME_fnc_ownerDispatch;};

private _leases = _patient getVariable ["ACME_chestAccess_leases", createHashMap];
if (_start) then {
    _leases set [_id, [_medic, CBA_missionTime, toLowerANSI _classname]];
} else {
    _leases deleteAt _id;
};
_patient setVariable ["ACME_chestAccess_leases", _leases, true];

// Thoracostomy is a long minigame rather than one treatment timer. Publish a procedure flag from the live lease
// set so a roll or another action cannot return the carrier before the thoracostomy screen actually closes.
private _thoraActive = false;
{
    private _entry = _leases get _x;
    if ((_entry param [2,"",[""]]) == "thoracostomy") exitWith {_thoraActive = true;};
} forEach keys _leases;
_patient setVariable ["ACME_Thora_ChestAccessActive", _thoraActive, true];

if (_start) then {
    [_patient, _medic, "access"] call ACME_fnc_chestAccessVestAcquire;
} else {
    if ((count _leases) == 0) then {[_patient] call ACME_fnc_chestAccessVestRestore;};
};
