// Toggle the latest owner-local transfusion flow state for one established access site.
params [
    ["_patient", objNull, [objNull]],
    ["_part", "", [""]],
    ["_iv", true, [true]],
    ["_site", -1, [0]],
    ["_epoch", -1, [0]],
    ["_medic", objNull, [objNull]]
];
if (isNull _patient || {!local _patient} || {_epoch != ([_patient] call ACME_fnc_clinicalEpoch)}) exitWith {false};
private _pi = ACME_infusion_bodyParts find (toLowerANSI _part);
if (_pi < 0) exitWith {false};
private _hasAccess = if (_iv) then {[_patient, _part, 0, _site] call ACM_circulation_fnc_hasIV} else {[_patient, _part, 0] call ACM_circulation_fnc_hasIO};
if (!_hasAccess) exitWith {
    if (!isNull _medic) then {[_medic, "That access is no longer available."] call ACME_fnc_clinicalNotice;};
    false
};

if (_iv) then {
    private _flow = +(_patient getVariable ["ACM_circulation_FluidBagsFlow_IV", []]);
    if (_pi >= count _flow || {_site < 0}) exitWith {false};
    private _row = +(_flow select _pi);
    if (_site >= count _row) exitWith {false};
    _row set [_site, [1, 0] select ((_row select _site) > 0)];
    _flow set [_pi, _row];
    [_patient, [["fluidBagsFlowIV", _flow]], true] call ACM_circulation_fnc_setRuntimeState;
} else {
    private _flow = +(_patient getVariable ["ACM_circulation_FluidBagsFlow_IO", []]);
    if (_pi >= count _flow) exitWith {false};
    _flow set [_pi, [1, 0] select ((_flow select _pi) > 0)];
    [_patient, [["fluidBagsFlowIO", _flow]], true] call ACM_circulation_fnc_setRuntimeState;
};
true
