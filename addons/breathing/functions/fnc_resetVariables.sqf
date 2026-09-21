#include "..\script_component.hpp"
/*
 * Author: Blue
 * Reset breathing variables to default values. (LOCAL)
 *
 * Arguments:
 * 0: Patient <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call ACM_breathing_fnc_resetVariables;
 *
 * Public: No
 */

params ["_patient"];

_patient setVariable [QGVAR(ChestInjury_State), false, true];

_patient setVariable [QGVAR(Pneumothorax_State), 0, true];
_patient setVariable [QGVAR(TensionPneumothorax_State), false, true];

_patient setVariable [QGVAR(TensionPneumothorax_Time), nil, true];

_patient setVariable [QGVAR(Hemothorax_State), 0, true];
_patient setVariable [QGVAR(Hemothorax_Fluid), 0, true];

_patient setVariable [QGVAR(ChestSeal_State), false, true];

_patient setVariable [QGVAR(Thoracostomy_State), nil, true];
_patient setVariable [QGVAR(Thoracostomy_UsedKit), false, true];

_patient setVariable [QGVAR(PulseOximeter_Display), [[0,0],[0,0]], true];
_patient setVariable [QGVAR(PulseOximeter_Placement), [false,false], true];
_patient setVariable [QGVAR(PulseOximeter_PFH), -1];
_patient setVariable [QGVAR(PulseOximeter_LastSync), [-1,-1]];

_patient setVariable [QGVAR(Hardcore_Pneumothorax), false, true];

_patient setVariable [QGVAR(BVM_provider), objNull, true];
_patient setVariable [QGVAR(BVM_Medic), objNull, true];
_patient setVariable [QGVAR(isUsingBVM), false, true];

_patient setVariable [QGVAR(BVM_ConnectedOxygen), false, true];

_patient setVariable [QGVAR(BVM_lastBreath), nil, true];
_patient setVariable [QGVAR(BVM_lastBreathOxygen), nil, true];

// ACME aspiration is a breathing injury even though its runtime lives in acm_extended. Full-heal must retire the
// persistent shunt/edema presentation as well as the native ACM chest states.
_patient setVariable ["ACME_aspiration_load", 0, true];
_patient setVariable ["ACME_aspiration_injury", 0, true];
_patient setVariable ["ACME_aspiration_edema", 0, true];
_patient setVariable ["ACME_aspiration_edemaActive", false, true];
_patient setVariable ["ACME_aspiration_shunt", 0, true];
_patient setVariable ["ACME_aspiration_RRDrive", 0, true];
_patient setVariable ["ACME_aspiration_SpO2Penalty", 0, true];
_patient setVariable ["ACME_aspiration_lastRRAdj", 0, false];
_patient setVariable ["ACME_aspiration_lastEmesisKey", "", false];
_patient setVariable ["ACME_aspiration_tickAt", nil, false];

_patient setVariable [QGVAR(RespirationRate), (ACM_TARGETVITALS_RR(_patient)), true];

[_patient, true] call FUNC(updateLungState);
