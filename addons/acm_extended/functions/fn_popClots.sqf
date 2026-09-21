// B120: one coagulopathy event partially reopens one previously controlled wound.  Earlier code reopened every
// bandaged wound on the casualty at once, which made a single 8-second roll look like all dressings failed.
params ["_unit", ["_fraction", 0.20]];
if (isNull _unit || {!alive _unit} || {!local _unit}) exitWith {0};
_fraction = _fraction max 0 min 0.75;

private _open = _unit getVariable ["ace_medical_openWounds", createHashMap];
private _bandaged = _unit getVariable ["ace_medical_bandagedWounds", createHashMap];
private _candidates = [];
{
    private _part = _x;
    private _rows = _bandaged getOrDefault [_part, []];
    {
        private _amt = _x param [1, 0];
        if (_amt > 0.01) then {
            // Larger controlled wounds are more likely to be the one whose clot fails.
            _candidates pushBack [_part, _forEachIndex, (_amt max 0.01)];
        };
    } forEach _rows;
} forEach (keys _bandaged);
if (_candidates isEqualTo []) exitWith {0};

private _total = 0;
{_total = _total + (_x select 2);} forEach _candidates;
private _roll = random (_total max 0.001);
private _pick = _candidates select 0;
{
    _roll = _roll - (_x select 2);
    if (_roll <= 0) exitWith {_pick = _x;};
} forEach _candidates;
_pick params ["_part", "_idx"];
private _bWounds = _bandaged getOrDefault [_part, []];
if (_idx < 0 || {_idx >= count _bWounds}) exitWith {0};
private _bw = _bWounds select _idx;
private _bid = _bw param [0, -1];
private _bamt = _bw param [1, 0];
if (_bamt <= 0.01) exitWith {0};
private _move = (_bamt * _fraction) max 0.01 min _bamt;
private _oWounds = _open getOrDefault [_part, []];
private _oi = _oWounds findIf {(_x select 0) == _bid};
if (_oi > -1) then {
    private _ow = _oWounds select _oi;
    _ow set [1, (_ow select 1) + _move];
    _oWounds set [_oi, _ow];
} else {
    private _new = +_bw;
    _new set [1, _move];
    _oWounds pushBack _new;
};
_bw set [1, (_bamt - _move) max 0];
_bWounds set [_idx, _bw];
_bandaged set [_part, _bWounds];
_open set [_part, _oWounds];
[_unit, [["openWounds", _open, true]]] call ACM_core_fnc_setAceMedicalState;
[_unit, [["bandagedWounds", _bandaged, true]]] call ACM_core_fnc_setAceMedicalState;
[_unit] call ace_medical_status_fnc_updateWoundBloodLoss;
if (_unit isEqualTo ACE_player) then {
    ["A clot partially reopened one wound.", 2] call ace_common_fnc_displayTextStructured;
};
1
