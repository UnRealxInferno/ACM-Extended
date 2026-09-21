// Keep the temporary chest-access plate carrier parked beyond the casualty's head.
// This prop is used only when a backpack is already supporting Semi-Fowler, or when a chest-access action on an
// otherwise flat casualty needs the vest out of the examination/compression field. The prop never follows a roll
// across the chest: it is detached and re-seated in world space from the patient's current head axis.
params [["_patient", objNull, [objNull]]];
if (isNull _patient || {!local _patient}) exitWith {};

private _prop = _patient getVariable ["ACME_chestAccess_vestProp", objNull];
if (isNull _prop) exitWith {};

private _pel = _patient modelToWorldVisual (_patient selectionPosition "pelvis");
private _hed = _patient modelToWorldVisual (_patient selectionPosition "head");
private _dx = (_hed select 0) - (_pel select 0);
private _dy = (_hed select 1) - (_pel select 1);
private _mag = sqrt ((_dx * _dx) + (_dy * _dy));
if (_mag < 0.05) then {
    private _dir = getDir _patient;
    _dx = sin _dir;
    _dy = cos _dir;
    _mag = 1;
};
private _axis = [_dx / _mag, _dy / _mag, 0];
private _gap = missionNamespace getVariable ["ACME_headElev_propGroundGap", 0.45];
private _px = (_hed select 0) + ((_axis select 0) * _gap);
private _py = (_hed select 1) + ((_axis select 1) * _gap);

detach _prop;
_prop disableCollisionWith _patient;
_patient disableCollisionWith _prop;
[_prop, [_px, _py, 0.02], _axis, surfaceNormal [_px, _py], missionNamespace getVariable ["ACME_headElev_propEaseTime", 0.24]] call ACME_fnc_propEaseTo;
