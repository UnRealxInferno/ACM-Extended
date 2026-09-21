#include "..\script_component.hpp"
/*
 * Clear temporary progressive bandage hemostasis after success or interruption.
 * Permanent wound changes remain entirely owned by ACE's normal bandage success callback.
 *
 * Arguments:
 * 0: Patient <OBJECT>
 * 1: Unique treatment token <STRING>
 */
params ["_patient", "_token"];

if (isNull _patient || {!local _patient} || {_token isEqualTo ""}) exitWith {};

private _active = _patient getVariable [QGVAR(BandageProgress), createHashMap];
if !(_active isEqualType createHashMap) exitWith {};

_active deleteAt _token;
_patient setVariable [QGVAR(BandageProgress), _active, true];
[_patient] call ACEFUNC(medical_status,updateWoundBloodLoss);
