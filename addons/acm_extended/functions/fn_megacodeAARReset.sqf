/* Start a fresh objective AAR session on a Megacode patient. */
params [["_u",objNull,[objNull]]];
if (isNull _u || {!(_u getVariable ["ACME_isMegacode",false])}) exitWith {false};
_u setVariable ["ACME_MC_aarStart",CBA_missionTime,true];
_u setVariable ["ACME_MC_aarEvents",[],true];
_u setVariable ["ACME_MC_aarLast",createHashMap,false];
_u setVariable ["ACME_MC_aarSeenMeds",[],false];
_u setVariable ["ACME_MC_aarWorstSpO2",100,true];
_u setVariable ["ACME_MC_aarLowestSBP",999,true];
[_u,"session","AAR session started",0] call ACME_fnc_megacodeAARRecord;
true
