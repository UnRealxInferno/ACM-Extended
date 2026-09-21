#include "..\script_component.hpp"
/*
 * Author: Blue
 * Get time required to perform medical suction
 *
 * Arguments:
 * 0: Patient <OBJECT>
 * 1: Suction Device Type <NUMBER>
 *   0: Manual Suction Bag
 *   1: ACCUVAC
 *
 * Return Value:
 * Suction Time <NUMBER>
 *
 * Example:
 * [cursorTarget, 0] call ACM_airway_fnc_getSuctionTime;
 *
 * Public: No
 */

params ["_patient", ["_type", 0]];

private _checkedServer = _patient getVariable ["ACME_airwayCheckedServer", -1];
private _airwayCheckFresh = if (_checkedServer >= 0) then {
    (serverTime - _checkedServer) <= 45
} else {
    // Backward compatibility for native/saved state created before the shared serverTime stamp existed.
    ((_patient getVariable [QGVAR(AirwayChecked_Time), -45]) + 45) >= CBA_missionTime
};
if (!_airwayCheckFresh) exitWith {12};

private _obstructionState = (_patient getVariable [QGVAR(AirwayObstructionVomit_State), 0]) + (_patient getVariable [QGVAR(AirwayObstructionBlood_State), 0]);

private _return = round ((3 max (_obstructionState * 1.25)) min 8);

if (_type == 1) exitWith {_return min 6};

_return;
