// Keep any plate carrier removed for the chest-seal procedure parked beyond the casualty's head.
// The prop is detached and non-simulated, so front/back rolls never drag it across the chest.
params [["_patient", objNull, [objNull]]];
if (isNull _patient || {!local _patient}) exitWith {};

private _props = [];
private _chestProp = _patient getVariable ["ACME_CS_vestProp", objNull];
if (!isNull _chestProp) then {_props pushBackUnique _chestProp;};

// A Semi-Fowler casualty may already have a carrier prop owned by the head-elevation system.
private _headProp = _patient getVariable ["ACME_headElev_propObj", objNull];
if ((_patient getVariable ["ACME_CS_ProcedureActive", false]) && {!isNull _headProp}) then {
    _props pushBackUnique _headProp;
};
if (_props isEqualTo []) exitWith {};

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
private _up = surfaceNormal [_px, _py];

{
    detach _x;
    _x disableCollisionWith _patient;
    _patient disableCollisionWith _x;
    [_x, [_px, _py, 0.02], _axis, _up, missionNamespace getVariable ["ACME_headElev_propEaseTime", 0.24]] call ACME_fnc_propEaseTo;
} forEach _props;
