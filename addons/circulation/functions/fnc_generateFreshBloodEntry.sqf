#include "..\script_component.hpp"
/*
 * Author: Blue
 * Generates new fresh blood entry based on patient, and returns relevant ID.
 *
 * Arguments:
 * 0: Patient <OBJECT>
 * 1: Volume <NUMBER>
 *
 * Return Value:
 * 0: Fresh Blood Entry ID <NUMBER>
 *
 * Example:
 * [player] call ACM_circulation_fnc_generateFreshBloodEntry;
 *
 * Public: No
 */

params ["_patient", "_volume"];

private _collectionTime = CBA_missionTime;
private _bloodType = [_patient] call FUNC(generateBloodType);
private _alive = alive _patient;

private _freshBloodlist = (missionNamespace getVariable [QGVAR(FreshBloodList), createHashMap]);

// Unique fresh-blood item classes exist for IDs 1..512. Allocation is server-authoritative in B96, so scan the
// actual registry for the first free configured ID rather than deriving an ID from HashMap count. This also keeps
// holes safe if an entry is ever retired later. ID 0 is reserved by the compatibility seed entry.
private _id = 1;
while {_id <= 512 && {!((_freshBloodlist getOrDefault [_id, []]) isEqualTo [])}} do { _id = _id + 1; };
if (_id > 512) exitWith {-1};

_freshBloodlist set [_id, [_patient,_volume,_bloodType,_alive,_collectionTime]];

missionNamespace setVariable [QGVAR(FreshBloodList), _freshBloodlist, true];

_id;
