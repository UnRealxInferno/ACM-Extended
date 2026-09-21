/*
 * Author: Blue
 * Update lung state of patient
 *
 * Arguments:
 * 0: Patient <OBJECT>
 * 1: Was Healed <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, false] call ACM_breathing_fnc_updateLungState;
 *
 * Public: No
 */

params ["_patient", ["_healed", false]];

if (_healed) exitWith {
    _patient setVariable ["ACM_breathing_Stethoscope_LungState", [0,0], true];
};

private _lungState = +(_patient getVariable ["ACM_breathing_Stethoscope_LungState", [0,0]]);
private _previous = +_lungState;

// State 3 is dynamic edema presentation, not a structural unilateral injury. Clear stale edema first and rebuild it
// from current overload/aspiration physiology below. States 1/2 remain the authoritative traumatic lung finding.
for "_i" from 0 to 1 do {
    if ((_lungState param [_i,0]) == 3) then {_lungState set [_i,0];};
};

private _affectedIndex = _lungState findIf {_x in [1,2]};
if (_affectedIndex == -1) then {
    _affectedIndex = round (random 1);
};

private _state = 0;

private _PTXState = _patient getVariable ["ACM_breathing_Pneumothorax_State", 0];
private _TPTXState = _patient getVariable ["ACM_breathing_TensionPneumothorax_State", false];
private _HTXFluid = _patient getVariable ["ACM_breathing_Hemothorax_Fluid", 0];

switch (true) do {
    case (_TPTXState || _HTXFluid > 1.1): {
        _state = 2;
    };
    case (_PTXState > 0 || _HTXFluid > 0.3): {
        _state = 1;
    };
    default {};
};

// ACME: pulmonary edema can be volume-overload edema or aspiration-pneumonitis capillary leak. Both are diffuse.
// A traumatic finding on a side remains higher priority than crackles on that same side.
private _overload = _patient getVariable ["ACM_circulation_Overload_Volume", 0];
private _aspEdema = (_patient getVariable ["ACME_aspiration_edema",0]) max 0 min 1;
private _edemaActive = (_overload > (missionNamespace getVariable ["ACME_edema_threshold",0.5]))
    || {_aspEdema >= (missionNamespace getVariable ["ACME_aspiration_edemaCrackleThreshold",0.12])};

// Rebuild the presentation so draining fluid can remove an old traumatic or edema finding.
// Preserve the native affected side while trauma remains, and broadcast only actual changes.
_lungState = [[0,0],[3,3]] select _edemaActive;
if (_state > 0) then {_lungState set [_affectedIndex,_state];};
if !(_lungState isEqualTo _previous) then {
    _patient setVariable ["ACM_breathing_Stethoscope_LungState",_lungState,true];
};
