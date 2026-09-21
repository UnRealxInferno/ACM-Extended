params ["_medic","_patient"];
if (!hasInterface) exitWith {};
{uiNamespace setVariable [format ["ACME_VFX_Debug_%1",_x],0];} forEach ["hypoxia","hypotension","hypercapnia","ketamine","syncope"];
uiNamespace setVariable ["ACME_VFX_ForceRefresh",true];
uiNamespace setVariable ["ACME_VFX_WetForceRefresh",true];
if (!isNull _medic) then {["Visual FX debug overrides cleared.",1.5,_medic] call ace_common_fnc_displayTextStructured;};
