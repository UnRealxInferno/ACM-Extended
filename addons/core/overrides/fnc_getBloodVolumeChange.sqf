#include "..\script_component.hpp"
/*
 * ACM Extended canonical blood-volume transaction bridge.
 *
 * The full implementation lives in ACM_circulation_fnc_getBloodVolumeChange.
 * Keeping a second copied implementation under the ACE public symbol allowed
 * the two volume/acid-base paths to drift independently.  Route every ACE-side
 * caller through the same circulation implementation instead.
 */

params ["_unit", "_deltaT", "_syncValues"];
private _acmeBinding = "NA4:getBloodVolumeChange";
private _acmeReconcile = "B106:volumeBridge";

[_unit, _deltaT, _syncValues] call ACM_circulation_fnc_getBloodVolumeChange
