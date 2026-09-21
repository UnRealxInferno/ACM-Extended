// Smoothly park a detached simple-object prop without allowing stale callbacks to pull it back later.
// [_prop, targetATL, vectorDir, vectorUp, duration] call ACME_fnc_propEaseTo
params [
    ["_prop", objNull, [objNull]],
    ["_target", [0,0,0], [[]]],
    ["_dir", [0,1,0], [[]]],
    ["_up", [0,0,1], [[]]],
    ["_duration", 0.24, [0]]
];
if (isNull _prop || {count _target < 3}) exitWith {};
_duration = (_duration max 0.05) min 0.75;
private _start = getPosATL _prop;
private _serial = (_prop getVariable ["ACME_propEaseSerial", 0]) + 1;
_prop setVariable ["ACME_propEaseSerial", _serial, false];
private _t0 = CBA_missionTime;
private _pfh = [{
    params ["_args", "_handle"];
    _args params ["_prop", "_serial", "_start", "_target", "_dir", "_up", "_t0", "_duration"];
    if (isNull _prop || {(_prop getVariable ["ACME_propEaseSerial", -1]) != _serial}) exitWith {[_handle] call CBA_fnc_removePerFrameHandler;};
    private _u = ((CBA_missionTime - _t0) / _duration) max 0 min 1;
    // smoothstep: zero velocity at both endpoints, avoiding the old teleport/pop.
    private _s = (_u * _u) * (3 - (2 * _u));
    private _pos = [
        (_start select 0) + (((_target select 0) - (_start select 0)) * _s),
        (_start select 1) + (((_target select 1) - (_start select 1)) * _s),
        (_start select 2) + (((_target select 2) - (_start select 2)) * _s)
    ];
    _prop setPosATL _pos;
    if (_u >= 1) then {
        _prop setPosATL _target;
        _prop setVectorDirAndUp [_dir, _up];
        [_handle] call CBA_fnc_removePerFrameHandler;
    };
}, 0, [_prop, _serial, _start, +_target, +_dir, +_up, _t0, _duration]] call CBA_fnc_addPerFrameHandler;
