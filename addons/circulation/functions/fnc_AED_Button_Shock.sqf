#include "..\script_component.hpp"
/* LifePak shock button. Base ACM stores the patient itself in AED_Provider as a device sentinel, not the human
 * operator. Use the medic captured when this local monitor dialog opened. */
params ["_patient"];
if (isNull _patient) exitWith {};
private _medic = missionNamespace getVariable [QGVAR(AED_Monitor_Medic), objNull];
if (isNull _medic) then {_medic = ACE_player;};
if (isNull _medic) exitWith {};
[_medic, _patient] call ACME_fnc_shockRequest;
