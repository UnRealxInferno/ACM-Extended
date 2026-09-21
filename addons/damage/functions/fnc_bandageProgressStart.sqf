#include "..\script_component.hpp"
/*
 * ACM Extended: progressive hemorrhage control while a bandage is being applied.
 *
 * The treatment itself remains transactional: the wound is not permanently modified until ACE's normal
 * bandage callback succeeds.  While the timer is active, this publishes the amount of bleeding the completed
 * dressing is predicted to control.  updateWoundBloodLoss eases toward that amount as progress advances.
 *
 * Arguments:
 * 0: Patient <OBJECT>
 * 1: Body part <STRING>
 * 2: Treatment classname <STRING>
 * 3: Treatment duration <NUMBER>
 * 4: Unique treatment token <STRING>
 */
params ["_patient", "_bodyPart", "_classname", "_duration", "_token"];

if (isNull _patient || {!local _patient} || {_token isEqualTo ""}) exitWith {};

_bodyPart = toLowerANSI _bodyPart;
_duration = _duration max 0.01;

private _bandageClasses = [
    "BasicBandage",
    "FieldDressing",
    "PackingBandage",
    "ElasticBandage",
    "QuikClot",
    "PressureBandage",
    "EmergencyTraumaDressing",
    "ACME_PackJunctional",
    "ACME_WrapJunctional"
];
if !(_classname in _bandageClasses) exitWith {};

// Predict the exact external-wound bleed reduction that ACE's normal successful bandage callback will apply.
// The global ACE effectiveness coefficient is included so custom server bandage-effectiveness settings remain
// reflected in the progressive control rather than only at the instant the treatment completes.
private _predictedReduction = 0;
if !(_classname in ["ACME_PackJunctional", "ACME_WrapJunctional"]) then {
    private _coefficient = missionNamespace getVariable ["ace_medical_treatment_bandageEffectiveness", 1];
    private _targetWounds = [_patient, _classname, _bodyPart, _coefficient] call ACEFUNC(medical_treatment,findMostEffectiveWounds);
    {
        _x params ["", "", "_bleeding"];
        _y params ["", "", "_impact"];
        _predictedReduction = _predictedReduction + ((_impact max 0) * (_bleeding max 0));
    } forEach _targetWounds;
};

// Junctional Combat Gauze and the subsequent pressure dressing have their own arterial bleed channel, so their
// progress records are useful even though ordinary ACE-wound predicted reduction may be zero. The junctional
// worker reads the same records: Combat Gauze ramps open bleeding toward the packed 50% state, then the pressure
// dressing ramps that packed state toward full wrapped control.
if (_predictedReduction <= 0 && {!(_classname in ["ACME_PackJunctional", "ACME_WrapJunctional"])}) exitWith {};

private _active = _patient getVariable [QGVAR(BandageProgress), createHashMap];
if !(_active isEqualType createHashMap) then { _active = createHashMap; };
_active set [_token, [_bodyPart, _predictedReduction, serverTime, _duration, _classname]];
_patient setVariable [QGVAR(BandageProgress), _active, true];

// Recalculate immediately so the treatment owns bleeding control from the first circulation update onward.
[_patient] call ACEFUNC(medical_status,updateWoundBloodLoss);
