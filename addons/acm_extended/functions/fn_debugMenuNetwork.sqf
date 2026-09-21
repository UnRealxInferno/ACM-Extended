/*
 * ACME debug page 2/2: network / engineering transport state only.
 * Clinical state intentionally lives on page 1 so screenshots of the main page are self-contained.
 */
disableSerialization;

private _cleanup = {
    {
        private _c = uiNamespace getVariable [_x, controlNull];
        if (!isNull _c) then {ctrlDelete _c;};
        uiNamespace setVariable [_x, controlNull];
    } forEach ["ACME_DebugMenuCtrlL", "ACME_DebugMenuCtrlR", "ACME_DebugMenuCtrlS", "ACME_DebugMenuCtrl"];
};
if (!(call ACME_fnc_debugEnabled)) exitWith {call _cleanup;};

private _display = findDisplay 46;
if (isNull _display) then {_display = uiNamespace getVariable ["RscDisplayMission", displayNull];};
if (isNull _display) exitWith {};

private _ctrlL = uiNamespace getVariable ["ACME_DebugMenuCtrlL", controlNull];
if (!isNull _ctrlL && {!((ctrlParent _ctrlL) isEqualTo _display)}) then {ctrlDelete _ctrlL; _ctrlL = controlNull;};
if (isNull _ctrlL) then {
    _ctrlL = _display ctrlCreate ["RscStructuredText", -1];
    _ctrlL ctrlSetBackgroundColor [0.043, 0.082, 0.188, 0.88];
    uiNamespace setVariable ["ACME_DebugMenuCtrlL", _ctrlL];
};
_ctrlL ctrlShow true;
{
    private _c = uiNamespace getVariable [_x, controlNull];
    if (!isNull _c) then {_c ctrlShow false;};
} forEach ["ACME_DebugMenuCtrlR", "ACME_DebugMenuCtrlS", "ACME_DebugMenuCtrl"];

private _canvas = call ACME_fnc_uiCanvas;
_canvas params ["_uiX", "_uiY", "_uiW", "_uiH"];
private _x = safeZoneXAbs + 0.002;
private _y = safeZoneY + 0.014;
private _w = ((_uiW * 0.24) max 0.24) min 0.31;
private _h = (safeZoneH - 0.024) max 0.30;
_ctrlL ctrlSetPosition [_x, _y, _w, _h];
_ctrlL ctrlCommit 0;

private _userScale = missionNamespace getVariable ["ACME_debug_scale", 1];
private _scale = (((_userScale max 0.50) min 1.15) * 0.58) max 0.42 min 0.66;
private _cTitle = "#D9A441";
private _cSect = "#F0E7D2";
private _cLabel = "#C0B7A2";
private _cGood = "#5FB56E";
private _cWarn = "#D9A441";
private _cBad = "#E04141";
private _cMute = "#8A8474";
private _safe = {
    params ["_v"];
    private _s = if (_v isEqualType "") then {_v} else {str _v};
    _s = (_s splitString "&") joinString "&amp;";
    _s = (_s splitString "<") joinString "&lt;";
    _s = (_s splitString ">") joinString "&gt;";
    _s
};
private _padRight = {
    params ["_s", "_w"];
    if !(_s isEqualType "") then {_s = str _s;};
    while {count _s < _w} do {_s = _s + " ";};
    if ((count _s) > _w) then {_s = _s select [0, _w];};
    _s
};
private _alignValue = {
    params ["_v", ["_w", 12]];
    private _s = if (_v isEqualType "") then {_v} else {str _v};
    private _integerW = (_w - 4) max 1;
    private _dot = _s find ".";
    private _integer = if (_dot > -1) then {_s select [0, _dot]} else {_s};
    private _suffix = if (_dot > -1) then {_s select [_dot]} else {""};
    while {count _integer < _integerW} do {_integer = " " + _integer;};
    private _txt = _integer + _suffix;
    while {count _txt < _w} do {_txt = _txt + " ";};
    _txt
};
private _pair = {
    params ["_a", "_av", "_ac", "_b", "_bv", "_bc"];
    private _aTxt = [_a, 8] call _padRight;
    private _bTxt = [_b, 8] call _padRight;
    private _avTxt = [([_av, 12] call _alignValue)] call _safe;
    private _bvTxt = [([_bv, 12] call _alignValue)] call _safe;
    format ["<t color='%7'>%1</t> <t color='%3'>%2</t>  <t color='%7'>%4</t> <t color='%6'>%5</t>", _aTxt, _avTxt, _ac, _bTxt, _bvTxt, _bc, _cLabel]
};
private _sect = {params ["_s"]; format ["<t color='%1'>%2</t>", _cSect, _s];};

private _patient = missionNamespace getVariable ["ACME_debug_target", objNull];
if (!isNull _patient && {!(_patient isKindOf "CAManBase")}) then {_patient = objNull;};
if (isNull _patient) then {
    private _last = missionNamespace getVariable ["ACME_debug_lastTreatmentTarget", objNull];
    if (!isNull _last && {_last isKindOf "CAManBase"}) then {_patient = _last;};
};
if (isNull _patient) then {_patient = ACE_player;};

private _ver = getText (configFile >> "CfgPatches" >> "ACM_Extended" >> "version");
if (_ver == "") then {_ver = missionNamespace getVariable ["ACME_infusion_version", "?"];};
private _rc = missionNamespace getVariable ["ACME_debugRevision", ""];
if (_rc isEqualType "" && {_rc != ""}) then {_ver = format ["%1-%2", _ver, _rc];};
private _batch = missionNamespace getVariable ["ACME_buildBatch", "?"];
private _pName = if (isNull _patient) then {"NO PATIENT"} else {name _patient};
private _lines = [];
_lines pushBack format ["<t color='%1' size='1.02'>ACME DEBUG v%2</t>  <t color='%1'>NETWORK 2/2</t>", _cTitle, _ver];
_lines pushBack format ["<t color='%1'>%2  |  %3  |  Ctrl+PgUp/PgDn</t>", _cMute, [_pName] call _safe, _batch];

_lines pushBack (["MACHINE"] call _sect);
private _role = if (isDedicated) then {"dedi"} else {if (isServer) then {"host"} else {"client"}};
_lines pushBack (["Role", _role, if (isServer) then {_cGood} else {_cLabel}, "MP", if (isMultiplayer) then {"yes"} else {"no"}, if (isMultiplayer) then {_cGood} else {_cMute}] call _pair);
_lines pushBack (["Client", clientOwner, _cLabel, "Server", if (isServer) then {"local"} else {"remote"}, if (isServer) then {_cGood} else {_cLabel}] call _pair);

_lines pushBack (["PATIENT OWNERSHIP"] call _sect);
private _own = if (isNull _patient) then {-1} else {owner _patient};
private _loc = !isNull _patient && {local _patient};
private _netId = if (isNull _patient) then {"-"} else {netId _patient};
_lines pushBack (["Owner", _own, if (_loc) then {_cGood} else {_cWarn}, "Local", if (_loc) then {"yes"} else {"no"}, if (_loc) then {_cGood} else {_cWarn}] call _pair);
_lines pushBack format ["<t color='%1'>NetID</t> <t color='%2'>%3</t>", _cLabel, _cMute, [_netId] call _safe];
private _epoch = if (isNull _patient) then {-1} else {[_patient] call ACME_fnc_clinicalEpoch};
_lines pushBack (["Epoch", _epoch, _cLabel, "Alive", if (!isNull _patient && {alive _patient}) then {"yes"} else {"no"}, if (!isNull _patient && {alive _patient}) then {_cGood} else {_cWarn}] call _pair);

_lines pushBack (["NETWORK LAYERS"] call _sect);
private _naChest = missionNamespace getVariable ["ACME_NA2_chestInstalled", false];
private _naOwner = missionNamespace getVariable ["ACME_NA2_ownerInstalled", false];
_lines pushBack (["Chest", if (_naChest) then {"on"} else {"off"}, if (_naChest) then {_cGood} else {_cBad}, "Owner", if (_naOwner) then {"on"} else {"off"}, if (_naOwner) then {_cGood} else {_cBad}] call _pair);
private _rev = missionNamespace getVariable ["ACME_networkAuditRevision", "none"];
_lines pushBack format ["<t color='%1'>Revision</t> <t color='%2'>%3</t>", _cLabel, _cMute, [_rev] call _safe];

_lines pushBack (["CHEST-SEAL TRANSPORT"] call _sect);
private _pend = 0;
private _pendMap = missionNamespace getVariable ["ACME_CS_pending", nil];
if (!isNil "_pendMap" && {(typeName _pendMap) isEqualTo "HASHMAP"}) then {_pend = count (keys _pendMap);};
private _sessTxt = "n/a";
private _sessCol = _cMute;
if (isServer) then {
    private _sess = 0;
    private _sessMap = missionNamespace getVariable ["ACME_CS_sessions", nil];
    if (!isNil "_sessMap" && {(typeName _sessMap) isEqualTo "HASHMAP"}) then {_sess = count (keys _sessMap);};
    _sessTxt = str _sess;
    _sessCol = if (_sess > 0) then {_cLabel} else {_cGood};
};
_lines pushBack (["Pending", _pend, if (_pend > 0) then {_cWarn} else {_cGood}, "Sessions", _sessTxt, _sessCol] call _pair);
private _roster = uiNamespace getVariable ["ACME_CS_presenceTargets", []];
if !(_roster isEqualType []) then {_roster = [];};
_roster = _roster - [uiNamespace getVariable ["ACME_CS_presenceViewer", player]];
private _rate = missionNamespace getVariable ["ACME_CS_presenceRate", 0.07];
if (!(_rate isEqualType 0) || {!finite _rate}) then {_rate = 0.07;};
_lines pushBack (["Viewers", count _roster, if ((count _roster) > 0) then {_cGood} else {_cMute}, "Rate", format ["%1s", _rate toFixed 2], _cLabel] call _pair);

_lines pushBack (["COMPATIBILITY"] call _sect);
private _missing = missionNamespace getVariable ["ACME_compatMissing", []];
if !(_missing isEqualType []) then {_missing = [];};
_lines pushBack (["Issues", count _missing, if (_missing isEqualTo []) then {_cGood} else {_cBad}, "Checked", if (missionNamespace getVariable ["ACME_compatChecked", false]) then {"yes"} else {"no"}, if (missionNamespace getVariable ["ACME_compatChecked", false]) then {_cGood} else {_cWarn}] call _pair);
{
    _lines pushBack format ["<t color='%1'>%2</t>", _cBad, [_x] call _safe];
} forEach (_missing select [0, (count _missing) min 8]);
if ((count _missing) > 8) then {_lines pushBack format ["<t color='%1'>+%2 more compatibility issues</t>", _cWarn, (count _missing) - 8];};

_lines pushBack format ["<t color='%1'>Page 1 contains all clinical screenshot data</t>", _cMute];

private _render = {
    params ["_s"];
    _ctrlL ctrlSetStructuredText parseText format ["<t size='%1' font='EtelkaMonospacePro'>%2</t>", _s, _lines joinString "<br/>"];
};
[_scale] call _render;
private _need = ctrlTextHeight _ctrlL;
if (_need > _h) then {
    private _fit = ((_scale * (((_h * 0.985) / _need) min 1)) max 0.35) min _scale;
    [_fit] call _render;
};
