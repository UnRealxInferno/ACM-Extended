#include "..\script_component.hpp"
/*
 * Author: Blue
 * Handle Sarin effects. (LOCAL)
 *
 * Arguments:
 * 0: Patient <OBJECT>
 * 1: Buildup <NUMBER>
 * 2: Is Exposed? <BOOL>
 * 3: Is Exposed Externally? <BOOL>
 * 4: Active PPE <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, 1, true, true, [false,false,false,0]] call ACM_CBRN_fnc_effectSarin;
 *
 * Public: No
 */

params ["_patient", "_buildup", "_isExposed", "_isExposedExternal", "_activePPE"];
_activePPE params ["_filtered", "_protectedBody", "_protectedEyes", "_filterLevel"];

// ACME unifies ACM's severe nerve-agent seizure with the same generalized seizure machine used by TBI and
// lidocaine toxicity. The old local camera-jitter "seizure" presentation is deliberately retired; once Sarin
// reaches the severe neurologic band the casualty gets the same LOC, apnea, postictal state, benzo response and
// 1.35x GestureSpasm3-6 convulsion sequence as every other ACME seizure source. The default threshold is 10,
// matching the exact buildup where ACM's original Midazolam-suppressible seizure/shake behavior began.
private _sarinSeizureThreshold = missionNamespace getVariable ["ACME_sarin_seizureThreshold", 10];
private _sarinSeizureCause = _buildup >= _sarinSeizureThreshold;
if ((_patient getVariable ["ACME_sarinSeizureCause", false]) != _sarinSeizureCause) then {
    _patient setVariable ["ACME_sarinSeizureCause", _sarinSeizureCause, true];
};
if (_sarinSeizureCause && {!isNil "ACME_circ_activePatients"}) then {
    ACME_circ_activePatients pushBackUnique _patient;
};

if (_buildup < 0.1) exitWith {};

if (_isExposed && GET_PAIN(_patient) < 0.3) then {
    [_patient, 0.2] call ACEFUNC(medical,adjustPainLevel);
};

//_patient setVariable [QGVAR(Nausea_Severity), _buildup, true];

if (_buildup < 10) exitWith {};

// The old ACM implementation used intermittent first-person camera shake here. ACME no longer synthesizes
// seizures through camera jitter; the shared seizure state machine below the severe threshold owns the presentation.
if (_buildup < 60) exitWith {};

private _atropineDose = ([_patient, "Atropine", false] call ACEFUNC(medical_status,getMedicationCount)) + ([_patient, "Atropine_IV", false] call ACEFUNC(medical_status,getMedicationCount));

if (_atropineDose < 4 && !(HAS_AIRWAY_SPASM(_patient))) then {
    _patient setVariable [QGVAR(AirwaySpasm), true, true];
};

if !(IS_UNCONSCIOUS(_patient)) then {
    [QACEGVAR(medical,CriticalVitals), _patient] call CBA_fnc_localEvent;
};

if (_buildup >= 100) then {
    [_patient, "Sarin Overexposure"] call ACEFUNC(medical_status,setDead);
};
