/* Release any shared vial-source lease owned by this client. */
params [["_medic", objNull, [objNull]]];
if (isNull _medic) exitWith {false};
private _accepted = missionNamespace getVariable ["ACME_vialLeaseAccepted", []];
if (_accepted isEqualType [] && {count _accepted >= 2}) then {
    _accepted params ["_holder","_token"];
    if (!isNull _holder && {_token != ""}) then {[_holder,"vialLease",[_medic,"release",_token]] call ACME_fnc_ownerDispatch;};
};
private _pending = missionNamespace getVariable ["ACME_vialLeasePending", []];
if (_pending isEqualType [] && {count _pending >= 2}) then {
    _pending params ["_holder","_token"];
    if (!isNull _holder && {_token != ""}) then {[_holder,"vialLease",[_medic,"release",_token]] call ACME_fnc_ownerDispatch;};
};
missionNamespace setVariable ["ACME_vialLeaseAccepted", []];
missionNamespace setVariable ["ACME_vialLeasePending", []];
missionNamespace setVariable ["ACME_vialLeaseRenewAt", 0];
true
