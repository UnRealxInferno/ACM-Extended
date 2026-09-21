// Semi-Fowler's requires a casualty who is physically down. A stale lying flag must never
// make an independently standing or crouching patient eligible.
params [["_patient", objNull, [objNull]], ["_medic", objNull, [objNull]]];
if (isNull _patient || {!alive _patient}) exitWith {false};
if !(_patient isKindOf "CAManBase") exitWith {false};
if (_patient isEqualTo _medic) exitWith {false};
if (_patient getVariable ["ACME_headElevated", false]) exitWith {false};
if (!isNull objectParent _patient || {!isNull attachedTo _patient}) exitWith {false};
if (_patient call ace_common_fnc_isBeingDragged || {_patient call ace_common_fnc_isBeingCarried}) exitWith {false};
private _stance = stance _patient;
if (_stance in ["STAND", "CROUCH"]) exitWith {false};
private _down = (_patient getVariable ["ACE_isUnconscious", false])
    || {lifeState _patient == "INCAPACITATED"}
    || {_patient getVariable ["ACM_core_Lying_State", false]};
_down && {_stance == "PRONE" || {!isAwake _patient}}
