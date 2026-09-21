// Enter live ragdoll on the patient owner without changing pose, position or clinical consciousness.
// addForce supports Man and its third argument requests engine unconscious/ragdoll directly.
// A small downward impulse releases a settled animation; no awake frame or prone switchMove is needed.
params ["_patient"];
if (isNull _patient || {!alive _patient} || {!local _patient}
    || {!isNull objectParent _patient}) exitWith {false};
if (!isAwake _patient) exitWith {true};
private _point = _patient selectionPosition "Spine3";
if (vectorMagnitude _point < 0.05) then {_point = [0,0,0.78];};
_patient addForce [[0,0,-1],_point,true];
true
