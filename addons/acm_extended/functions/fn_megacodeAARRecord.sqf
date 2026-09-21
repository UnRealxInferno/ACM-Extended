/* Append one objective event to a Megacode patient's persistent AAR timeline. */
params [["_u",objNull,[objNull]], ["_code","event",[""]], ["_text","",[""]], ["_level",0,[0]]];
if (isNull _u || {!(_u getVariable ["ACME_isMegacode",false])} || {_text == ""}) exitWith {};
private _start = _u getVariable ["ACME_MC_aarStart",CBA_missionTime];
private _events = _u getVariable ["ACME_MC_aarEvents",[]];
_events pushBack [(CBA_missionTime - _start) max 0,_code,_text,_level];
if (count _events > 160) then {_events deleteRange [0,(count _events)-160];};
_u setVariable ["ACME_MC_aarEvents",_events,true];
