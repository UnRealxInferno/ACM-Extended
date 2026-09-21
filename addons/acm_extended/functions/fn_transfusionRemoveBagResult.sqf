// Medic-side acknowledgement for owner-authoritative native Remove Bag.
params [
    ["_patient", objNull, [objNull]],
    ["_requestId", "", [""]],
    ["_accepted", false, [false]],
    ["_bag", [], [[]]],
    ["_part", "", [""]],
    ["_reason", "", [""]]
];
if (!hasInterface || {isNull ACE_player}) exitWith {};

private _pending = uiNamespace getVariable ["ACME_txRemovePending", ""];
private _ownsUiRequest = _pending == _requestId;
if (_ownsUiRequest) then {uiNamespace setVariable ["ACME_txRemovePending", ""];};

if (!_accepted || {count _bag < 7}) exitWith {
    if (_reason != "") then {[_reason, 2.5, ACE_player, 13] call ace_common_fnc_displayTextStructured;};
    if (_ownsUiRequest && {!isNull _patient} && {alive ACE_player}) then {
        [ACE_player, _patient, _part] call ACM_circulation_fnc_openTransfusionMenu;
    };
};

_bag params ["_type", "_remainingVolume", "_accessType", "_accessSite", "_iv", "_bloodType", "_volume"];
private _returnVolume = if (_type == "FBTK") then {
    private _tol = missionNamespace getVariable ["ACME_fbtk_fullToleranceMl", 1];
    if (!(_tol isEqualType 0) || {!finite _tol}) then {_tol = 1;};
    _tol = (_tol max 0) min 5;
    if (_remainingVolume >= ((_volume - _tol) max 0)) then {_volume} else {[_remainingVolume] call ACM_circulation_fnc_getReturnVolume}
} else {
    [_remainingVolume] call ACM_circulation_fnc_getReturnVolume
};

private _returned = true;
if (_returnVolume > 0) then {
    if (_type == "FBTK" && {_returnVolume >= 250}) then {
        ["ACM_circulation_requestFreshBloodBag", [ACE_player, _patient, _returnVolume]] call CBA_fnc_serverEvent;
    } else {
        private _item = [_type, _returnVolume, _bloodType] call ACM_circulation_fnc_formatFluidBagName;
        _returned = ([ACE_player, _item] call ace_common_fnc_addToInventory) select 0;
    };
} else {
    if (_type == "FBTK") then {
        private _item = format ["ACM_FieldBloodTransfusionKit_%1", _volume];
        _returned = ([ACE_player, _item] call ace_common_fnc_addToInventory) select 0;
    };
};
if (!_returned) then {[localize "STR_ACE_Common_Inventory_Full", 1.5, ACE_player] call ace_common_fnc_displayTextStructured;};

if (!isNil "ace_medical_treatment_fnc_addToLog") then {
    private _name = if (_type == "FBTK") then {format ["FBTK %1 mL", _returnVolume]} else {
        [([_type, _returnVolume, _bloodType, true] call ACM_circulation_fnc_formatFluidBagName)] call ACM_circulation_fnc_getFluidBagString
    };
    [_patient, "activity", "%1 removed %2 from %3", [[ACE_player, false, true] call ace_common_fnc_getName, _name, ([_part] call ACM_core_fnc_getBodyPartString)]] call ace_medical_treatment_fnc_addToLog;
};

if (_ownsUiRequest && {!isNull _patient} && {alive ACE_player}) then {
    [ACE_player, _patient, _part] call ACM_circulation_fnc_openTransfusionMenu;
};
