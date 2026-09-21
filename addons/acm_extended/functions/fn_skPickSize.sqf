// In-place syringe-size selection. No dialog teardown, no cursor recenter, no full UI redraw.
params ["_ctrl","_index"];
if (_index < 0) exitWith {};
private _size = _ctrl lbValue _index;
if (_size <= 0) exitWith {};
[_size] call ACME_fnc_skApplySize;
