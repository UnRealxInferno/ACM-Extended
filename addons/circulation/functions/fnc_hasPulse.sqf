#include "..\script_component.hpp"
/*
 * Author: Blue / ACME
 * Return whether the patient has mechanical circulation and, when requested,
 * whether that pulse is palpable.
 *
 * ACME extension: an optional body-part argument gives manual palpation a
 * site-specific pressure threshold without changing legacy callers such as
 * AED/pulse-ox logic that only pass the original two arguments.
 *
 * Arguments:
 * 0: Patient <OBJECT>
 * 1: Palpable? <BOOL> (default false)
 * 2: Body part <STRING> (optional; head/arms/legs)
 *
 * Return Value:
 * Has pulse / palpable pulse? <BOOL>
 */

params ["_patient", ["_palpable", false], ["_bodyPart", ""]];

if (!(alive _patient) || {[_patient] call FUNC(recentAEDShock)} || {!(GET_CIRCULATIONSTATE(_patient))} || {IN_CRDC_ARRST(_patient)}) exitWith {false};

if (!_palpable) exitWith {true};

// Preserve ACM's legacy generic palpable-pulse behavior for callers that do
// not specify a site. This prevents a manual-palpation improvement from
// changing AED rhythm classification, pulse-ox dropout or automatic BP logic.
if (_bodyPart isEqualTo "") exitWith {!(IN_CRITICAL_STATE(_patient))};

private _part = toLowerANSI _bodyPart;
private _pressureCutoff = switch (_part) do {
    case "head": {60};       // carotid
    case "leftarm";
    case "rightarm": {80};  // radial
    case "leftleg";
    case "rightleg": {70};  // femoral
    default {60};
};

GET_BLOOD_PRESSURE(_patient) params ["_bpDiastolic", "_bpSystolic"];
private _pulsePressure = (_bpSystolic - _bpDiastolic) max 0;

// A pulse needs enough peak pressure to reach the selected site and at least a
// small pulsatile pressure gradient. This lets a shocked patient remain
// perfusing while losing radial/femoral palpability before the carotid.
(_bpSystolic >= _pressureCutoff) && {_pulsePressure >= 8};
