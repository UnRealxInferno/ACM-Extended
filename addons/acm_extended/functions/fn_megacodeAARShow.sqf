/* Build an objective instructor AAR, copy it to clipboard, and open the existing Megacode LOG page. */
params [["_u",objNull,[objNull]], ["_medic",ACE_player,[objNull]]];
if (isNull _u || {!(_u getVariable ["ACME_isMegacode",false])}) exitWith {};
private _events = +(_u getVariable ["ACME_MC_aarEvents",[]]);
private _start = _u getVariable ["ACME_MC_aarStart",CBA_missionTime];

private _fmtTime = {
    params ["_s"];
    _s = floor (_s max 0);
    private _m = floor (_s/60); private _r = _s mod 60;
    format ["%1:%2",_m,if (_r<10) then {format ["0%1",_r]} else {str _r}]
};
private _first = {
    params ["_code","_events"];
    private _i = _events findIf {(_x param [1,""]) == _code};
    if (_i < 0) exitWith {-1};
    (_events select _i) param [0,-1]
};
private _arrestT = ["arrest",_events] call _first;
private _cprT = ["cpr",_events] call _first;
private _roscT = ["rosc",_events] call _first;
private _airwayT = -1;
private _iAir = _events findIf {(_x param [1,""]) == "airway" && {toLowerANSI (_x param [2,""]) find "cuff" >= 0}};
if (_iAir >= 0) then {_airwayT = (_events select _iAir) param [0,-1];};
private _epiT = -1;
private _iEpi = _events findIf {(_x param [1,""]) == "med" && {toLowerANSI (_x param [2,""]) find "epinephrine" >= 0}};
if (_iEpi >= 0) then {_epiT = (_events select _iEpi) param [0,-1];};

private _lines = [];
_lines pushBack "ACM EXTENDED - MEGACODE OBJECTIVE AAR";
_lines pushBack format ["Session elapsed: %1",[(CBA_missionTime-_start)] call _fmtTime];
_lines pushBack format ["Worst SpO2: %1%%",round (_u getVariable ["ACME_MC_aarWorstSpO2",100])];
private _lsbp = _u getVariable ["ACME_MC_aarLowestSBP",999];
_lines pushBack format ["Lowest SBP: %1",if (_lsbp>=998) then {"n/a"} else {format ["%1 mmHg",round _lsbp]}];
if (_arrestT >= 0) then {
    _lines pushBack format ["Arrest at %1",[_arrestT] call _fmtTime];
    _lines pushBack format ["Arrest -> CPR: %1",if (_cprT>=_arrestT) then {format ["%1 s",round (_cprT-_arrestT)]} else {"not recorded"}];
    _lines pushBack format ["Arrest -> first epinephrine: %1",if (_epiT>=_arrestT) then {format ["%1 s",round (_epiT-_arrestT)]} else {"not recorded"}];
    _lines pushBack format ["Arrest -> ROSC: %1",if (_roscT>=_arrestT) then {format ["%1 s",round (_roscT-_arrestT)]} else {"no ROSC recorded"}];
};
if (_airwayT >= 0) then {_lines pushBack format ["Definitive airway at %1",[_airwayT] call _fmtTime];};
_lines pushBack "";
_lines pushBack "TIMELINE";
{
    _lines pushBack format ["[%1] %2",[(_x param [0,0])] call _fmtTime,_x param [2,""]];
} forEach _events;
private _report = _lines joinString (toString [13,10]);
copyToClipboard _report;

// Reuse the existing LOG page as the instructor display. The persistent object timeline remains untouched.
uiNamespace setVariable ["ACME_MC_log",[]];
{
    private _lvl = _x param [3,0];
    private _hex = switch (_lvl) do {case 2:{"#ff8f8f"}; case 1:{"#ffd27a"}; default {"#cfe8ff"};};
    [[format ["AAR +%1s  %2",round (_x param [0,0]),_x param [2,""]],_hex]] call ACME_fnc_megacodeLog;
} forEach _events;
if (!isNull _medic) then {
    [_u,_medic] call ACME_fnc_megacodeOpenPanel;
    [{[87300,"log"] call ACME_fnc_megacodeMenu;},[],0.15] call CBA_fnc_waitAndExecute;
    ["Megacode AAR copied to clipboard and loaded into LOG.",2.5,_medic] call ace_common_fnc_displayTextStructured;
};
