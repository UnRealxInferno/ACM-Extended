disableSerialization;
private _acmeCanvas = call ACME_fnc_uiCanvas;
_acmeCanvas params ["_uiX", "_uiY", "_uiW", "_uiH"];

private _cleanup = {
    {
        private _c = uiNamespace getVariable [_x, controlNull];
        if (!isNull _c) then {ctrlDelete _c;};
        uiNamespace setVariable [_x, controlNull];
    } forEach ["ACME_DebugMenuCtrlL", "ACME_DebugMenuCtrlR", "ACME_DebugMenuCtrlS", "ACME_DebugMenuCtrl"];
};

private _debugEnabled = false;
if (!isNil "ACME_debug_enabled") then {_debugEnabled = _debugEnabled || {ACME_debug_enabled};};
_debugEnabled = _debugEnabled || {missionNamespace getVariable ["ACME_debug_enabled", false]};
_debugEnabled = _debugEnabled || {uiNamespace getVariable ["ACME_debug_enabled", false]};
_debugEnabled = _debugEnabled || {missionNamespace getVariable ["ACME_debug_forceOverlay", false]};
if (!_debugEnabled) exitWith {call _cleanup;};

private _display = findDisplay 46;
if (isNull _display) then {_display = uiNamespace getVariable ["RscDisplayMission", displayNull];};
if (isNull _display) exitWith {
    if ((diag_tickTime - (uiNamespace getVariable ["ACME_DebugMenu_NoDisplayLog", -999])) > 5) then {
        uiNamespace setVariable ["ACME_DebugMenu_NoDisplayLog", diag_tickTime];
    };
};

private _old = uiNamespace getVariable ["ACME_DebugMenuCtrl", controlNull];
if (!isNull _old) then {ctrlDelete _old; uiNamespace setVariable ["ACME_DebugMenuCtrl", controlNull];};

private _ctrlL = uiNamespace getVariable ["ACME_DebugMenuCtrlL", controlNull];
if (!isNull _ctrlL) then {
    if !((ctrlParent _ctrlL) isEqualTo _display) then {ctrlDelete _ctrlL; _ctrlL = controlNull;};
};
private _ctrlR = uiNamespace getVariable ["ACME_DebugMenuCtrlR", controlNull];
if (!isNull _ctrlR) then {
    if !((ctrlParent _ctrlR) isEqualTo _display) then {ctrlDelete _ctrlR; _ctrlR = controlNull;};
};
private _ctrlS = uiNamespace getVariable ["ACME_DebugMenuCtrlS", controlNull];
if (!isNull _ctrlS) then {
    if !((ctrlParent _ctrlS) isEqualTo _display) then {ctrlDelete _ctrlS; _ctrlS = controlNull;};
};

if (isNull _ctrlL) then {
    _ctrlL = _display ctrlCreate ["RscStructuredText", -1];
    // PILLAR navy 0B1530 rather than pure black, so the overlay reads as part of the program rather than as a
    // generic engine panel. slightly more opaque than the old black, because navy is lighter and needs it to
    // hold contrast against a bright sky.
    _ctrlL ctrlSetBackgroundColor [0.043, 0.082, 0.188, 0.86];
    _ctrlL ctrlShow true;
    _ctrlL ctrlSetFade 0;
    uiNamespace setVariable ["ACME_DebugMenuCtrlL", _ctrlL];
};
if (isNull _ctrlR) then {
    _ctrlR = _display ctrlCreate ["RscStructuredText", -1];
    _ctrlR ctrlSetBackgroundColor [0.043, 0.082, 0.188, 0.86];
    _ctrlR ctrlShow true;
    _ctrlR ctrlSetFade 0;
    uiNamespace setVariable ["ACME_DebugMenuCtrlR", _ctrlR];
};
if (isNull _ctrlS) then {
    _ctrlS = _display ctrlCreate ["RscStructuredText", -1];
    _ctrlS ctrlSetBackgroundColor [0.043, 0.082, 0.188, 0.86];
    _ctrlS ctrlShow false;
    _ctrlS ctrlSetFade 0;
    uiNamespace setVariable ["ACME_DebugMenuCtrlS", _ctrlS];
};

private _userScale = missionNamespace getVariable ["ACME_debug_scale", 1];
// a readability-first stacked debug layout.
// it uses larger monospaced text, paired-value rows and section breathing room.
private _scale = (((_userScale max 0.50) min 1.15) * 0.68) max 0.48 min 0.78;
private _gap = 0.004;
// safeZoneX is still centered on some ultrawide/triple-head layouts. safeZoneXAbs is the true physical left edge.
private _x0 = safeZoneXAbs + 0.002;
private _y0 = safeZoneY + 0.020;
private _h = (safeZoneH - 0.028) max 0.20;
private _w = ((_uiW - 0.012 - _gap) / 2) min 0.497;
private _stateX = _x0 + (2 * (_w + _gap));
private _stateAvailW = (safeZoneXAbs + safeZoneWAbs - 0.002) - _stateX;
private _stateW = _w min _stateAvailW;
private _useStateColumn = _stateW >= (_w * 0.72);
_ctrlL ctrlSetPosition [_x0, _y0, _w, _h];
_ctrlL ctrlCommit 0;
_ctrlR ctrlSetPosition [_x0 + _w + _gap, _y0, _w, _h];
_ctrlR ctrlCommit 0;
if (_useStateColumn) then {
    _ctrlS ctrlSetPosition [_stateX, _y0, _stateW, _h];
    _ctrlS ctrlCommit 0;
    _ctrlS ctrlShow true;
} else {
    _ctrlS ctrlShow false;
};
_ctrlL ctrlSetStructuredText parseText format ["<t size='%1' font='EtelkaMonospacePro' color='#D9A441'>ACME DEBUG loading</t>", _scale];
_ctrlR ctrlSetStructuredText parseText "";
_ctrlS ctrlSetStructuredText parseText "";

// THE PILLAR PALETTE, ADAPTED FOR A DARK HUD.
// the print palette is navy 0B1530, red BE1818, cream F0E7D2, amber D9A441 and green 3B8F4A. two of those cannot
// be used at their print values as TEXT on a dark panel: BE1818 and 3B8F4A are dark enough that they read as
// muddy rather than as red and green, and a status colour that cannot be told apart at a glance is worse than no
// colour at all.
// so the two status colours are lifted along their own hue and everything structural stays exactly as printed.
// each lifted value names the swatch it came from, so the relationship survives a later palette change.
private _cTitle = "#D9A441";  // PILLAR amber, exactly as printed. the structural accent.
private _cSect  = "#F0E7D2";  // PILLAR cream, exactly as printed. section headers.
private _cLabel = "#C0B7A2";  // PILLAR cream-dim, exactly as printed. the label half of every pair.
private _cGood  = "#5FB56E";  // PILLAR green 3B8F4A, lifted for legibility on navy.
private _cWarn  = "#D9A441";  // PILLAR amber, exactly as printed.
private _cBad   = "#E04141";  // PILLAR red BE1818, lifted for legibility on navy.
private _cCrit  = "#FF5A5A";  // PILLAR red, lifted further again. reserved for a value that needs acting on now.
private _cMute  = "#8A8474";  // between cream-dim and the navy field. present, and never competing for the eye.

private _fnSafe = {
    params ["_v"];
    private _s = str _v;
    if (_v isEqualType "") then {_s = _v;};
    _s = (_s splitString "&") joinString "&amp;";
    _s = (_s splitString "<") joinString "&lt;";
    _s = (_s splitString ">") joinString "&gt;";
    _s
};
private _fnNum = {
    params ["_unit", "_var", "_def"];
    private _v = _unit getVariable [_var, _def];
    if (_v isEqualType 0) exitWith {_v};
    _def
};
private _fnBoolTxt = {
    params ["_b", ["_trueBad", false]];
    if (_b) then {
        if (_trueBad) then {"<t color='#ff5555'>true</t>"} else {"<t color='#88ff88'>true</t>"}
    } else {
        if (_trueBad) then {"<t color='#88ff88'>false</t>"} else {"<t color='#ff5555'>false</t>"}
    }
};
private _fnArray = {
    params ["_name"];
    private _v = missionNamespace getVariable [_name, []];
    if (_v isEqualType []) exitWith {_v};
    []
};
private _fnPushUnique = {
    params ["_arr", "_item"];
    if (!isNull _item && {!(_item in _arr)}) then {_arr pushBack _item;};
    _arr
};
private _fnTag = {
    params ["_label", "_value", "_color"];
    format ["%1 <t color='%3'>%2</t>", _label, _value, _color]
};
private _fnPadRight = {
    params ["_s", "_w"];
    if !(_s isEqualType "") then {_s = str _s;};
    while {count _s < _w} do {_s = _s + " ";};
    if ((count _s) > _w) then {_s = _s select [0, _w];};
    _s
};
private _fnPadLeft = {
    params ["_s", "_w"];
    if !(_s isEqualType "") then {_s = str _s;};
    while {count _s < _w} do {_s = " " + _s;};
    if ((count _s) > _w) then {_s = _s select [((count _s) - _w), _w];};
    _s
};
private _fnKV = {
    params ["_label", "_value", "_color", ["_labelW", 7], ["_valueW", 7]];
    private _s = if (_value isEqualType "") then {_value} else {str _value};
    // align by the decimal point. the integer part, which is everything left of the ".", or the whole token if there is
    // none, is right-aligned to _ipW without truncating, so the decimal points, and the ones-places of integers,
    // fall in one vertical line at column _ipW. the fraction, and any unit suffix such as l, percent or s riding
    // after it, trails to the right. 4 columns are reserved for the fraction, such as ".000" or ".00L". the field is
    // then padded to a constant _valueW, so the next column starts at the same place every row.
    private _ipW = (_valueW - 4) max 1;
    private _dot = _s find ".";
    private _ip = if (_dot > -1) then {_s select [0, _dot]} else {_s};
    private _frac = if (_dot > -1) then {_s select [_dot]} else {""};
    while {count _ip < _ipW} do {_ip = " " + _ip;};
    private _txt = _ip + _frac;
    while {count _txt < _valueW} do {_txt = _txt + " ";};
    format ["%1 <t color='%3'>%2</t>", [_label, _labelW] call _fnPadRight, _txt, _color]
};
private _fnCountdown = {
    params ["_t"];
    if (_t <= 0) exitWith {"due"};
    private _rem = round ((_t - CBA_missionTime) max 0);
    if (_rem <= 0) exitWith {"due"};
    format ["%1s", _rem]
};
private _fnColorHR = {
    params ["_v"];
    if (_v <= 0) exitWith {_cMute};
    if (_v < 40 || {_v >= 180}) exitWith {_cBad};
    if (_v < 60 || {_v >= 130}) exitWith {_cWarn};
    _cGood
};
private _fnColorRR = {
    params ["_v"];
    if (_v <= 0) exitWith {_cMute};
    if (_v < 8 || {_v > 30}) exitWith {_cBad};
    if (_v < 10 || {_v > 24}) exitWith {_cWarn};
    _cGood
};
private _fnColorSpO2 = {
    params ["_v"];
    if (_v <= 0) exitWith {_cMute};
    if (_v < 90) exitWith {_cBad};
    if (_v < 94) exitWith {_cWarn};
    _cGood
};
private _fnColorMAP = {
    params ["_v"];
    if (_v <= 0) exitWith {_cMute};
    if (_v < 55 || {_v > 130}) exitWith {_cBad};
    if (_v < 65 || {_v > 110}) exitWith {_cWarn};
    _cGood
};
private _fnColorSys = {
    params ["_v"];
    if (_v <= 0) exitWith {_cMute};
    if (_v < 80 || {_v > 190}) exitWith {_cBad};
    if (_v < 90 || {_v > 160}) exitWith {_cWarn};
    _cGood
};
private _fnColorBlood = {
    params ["_v"];
    if (_v < 0) exitWith {_cMute};
    if (_v < 3.6) exitWith {_cBad};
    if (_v < 4.4) exitWith {_cWarn};
    _cGood
};
private _fnColorICP = {
    params ["_v"];
    if (_v >= 30) exitWith {_cBad};
    if (_v > 20) exitWith {_cWarn};
    _cGood
};
private _fnColorCPP = {
    params ["_v", "_target"];
    if (_v < 50) exitWith {_cBad};
    if (_v < _target) exitWith {_cWarn};
    _cGood
};
private _fnColorSeverity = {
    params ["_v"];
    if (_v >= 0.65) exitWith {_cBad};
    if (_v >= 0.30) exitWith {_cWarn};
    _cGood
};
private _fnColorAcid = {
    params ["_v"];
    if (_v >= 0.65) exitWith {_cBad};
    if (_v >= 0.30) exitWith {_cWarn};
    _cGood
};
private _fnColorRhythm = {
    params ["_native", "_custom"];
    if (_native in [1,2,3,4,5]) exitWith {_cBad};
    if (_custom >= 100) exitWith {_cWarn};
    _cGood
};

private _playerRef = if (!isNil "ACE_player" && {!isNull ACE_player}) then {ACE_player} else {player};
private _patient = missionNamespace getVariable ["ACME_debug_target", objNull];
if (!isNull _patient && {!(_patient isKindOf "CAManBase")}) then {_patient = objNull;};
if (isNull _patient) then {
    private _last = missionNamespace getVariable ["ACME_debug_lastTreatmentTarget", objNull];
    if (!isNull _last && {_last isKindOf "CAManBase"}) then {_patient = _last;};
};
if (isNull _patient) then {
    private _cands = [];
    { { _cands = [_cands, _x] call _fnPushUnique; } forEach ([_x] call _fnArray); } forEach [
        "ACME_infusion_activePatients",
        "ACME_tbi_activePatients",
        "ACME_circ_activePatients",
        "ACME_autoBP_patients",
        "ACME_cs_activePatients",
        "ACME_hpmk_activePatients",
        "ACME_nrb_activePatients"
    ];
    {
        if ((_x getVariable ["ACME_rhythm_active", 0]) >= 100) then {_cands = [_cands, _x] call _fnPushUnique;};
        if (_x getVariable ["ACME_tbi_HasTBI", false]) then {_cands = [_cands, _x] call _fnPushUnique;};
        if (_x getVariable ["ACME_infusion_HasBagMedications", false]) then {_cands = [_cands, _x] call _fnPushUnique;};
    } forEach allUnits;
    if (_cands isEqualTo []) then {
        _patient = _playerRef;
    } else {
        _cands = [_cands, [], {_playerRef distance _x}, "ASCEND"] call BIS_fnc_sortBy;
        _patient = _cands select 0;
    };
};

private _ver = getText (configFile >> "CfgPatches" >> "ACM_Extended" >> "version");
if (_ver == "") then { _ver = missionNamespace getVariable ["ACME_infusion_version", "?"]; };
private _rc = missionNamespace getVariable ["ACME_debugRevision", ""];
if (_rc isEqualType "" && {_rc != ""}) then {_ver = format ["%1-%2", _ver, _rc];};
private _linesL = [];
private _linesR = [];
private _linesS = [];
private _pName = if (isNull _patient) then {"none"} else {[name _patient] call _fnSafe};
private _targetMode = if (_patient isEqualTo (missionNamespace getVariable ["ACME_debug_lastTreatmentTarget", objNull])) then {"treating"} else {"auto"};

_linesL pushBack format ["<t color='%1' size='1.00'>ACME DEBUG v%2</t> <t color='%3'>DETAILS 2/2</t>", _cTitle, _ver, _cSect];
_linesL pushBack format ["<t color='%1'>%2 | %3 | Ctrl+PgUp/PgDn</t>", _cMute, _pName, _targetMode];
_linesL pushBack format ["<t color='%1'>dbg on | force %2 | tick %3</t>", _cMute, missionNamespace getVariable ["ACME_debug_forceOverlay", false], diag_tickTime toFixed 1];
_linesL pushBack format ["<t color='%1'>trk i%2 t%3 c%4 bp%5</t>", _cMute, count (["ACME_infusion_activePatients"] call _fnArray), count (["ACME_tbi_activePatients"] call _fnArray), count (["ACME_circ_activePatients"] call _fnArray), count (["ACME_autoBP_patients"] call _fnArray)];

if (isNull _patient) exitWith {
    _linesL pushBack format ["<t color='%1'>no patient available</t>", _cWarn];
    _ctrlL ctrlSetStructuredText parseText format ["<t size='%1' font='EtelkaMonospacePro'>%2</t>", _scale, _linesL joinString "<br/>"];
    _ctrlR ctrlSetStructuredText parseText "";
    _ctrlS ctrlSetStructuredText parseText "";
};

private _aliveTxt = if (alive _patient) then {format ["<t color='%1'>alive</t>", _cGood]} else {format ["<t color='%1'>dead</t>", _cBad]};
private _hr = if (alive _patient) then {round ([_patient, "ace_medical_heartRate", 0] call _fnNum)} else {0};
private _rr = round ([_patient, "ACM_breathing_RespirationRate", 0] call _fnNum);
private _spo2 = round ([_patient, "ace_medical_spo2", 0] call _fnNum);
// B103: do not label ACM's Blood_Volume compartment as the patient's total volume.
// ACE bloodVolume is the immediately hemodynamically available circulating sum. Effective
// blood volume remains ACM's distinct weighted value.
private _normalBlood = missionNamespace getVariable ["ACME_hypo_bloodNormal", 6];
private _circVol = [_patient, "ace_medical_bloodVolume", (_patient getVariable ["ACME_circulatingVolume", _normalBlood])] call _fnNum;
private _bloodComp = [_patient, "ACM_circulation_Blood_Volume", _normalBlood] call _fnNum;
private _plasmaComp = [_patient, "ACM_circulation_Plasma_Volume", 0] call _fnNum;
private _salineComp = [_patient, "ACM_circulation_Saline_Volume", 0] call _fnNum;
private _overloadComp = [_patient, "ACM_circulation_Overload_Volume", 0] call _fnNum;
private _effVol = ((_bloodComp + (_plasmaComp * 0.3) - _overloadComp) min _normalBlood) max 0;
private _bloodDeficit = if (_circVol >= 0) then {(_normalBlood - _circVol) max 0} else {-1};
private _bloodPct = if (_circVol >= 0 && {_normalBlood > 0}) then {round ((_circVol / _normalBlood) * 100)} else {-1};
private _sys = 0;
private _dia = 0;
if (!isNil "ace_medical_status_fnc_getBloodPressure") then {
    private _bp = [_patient] call ace_medical_status_fnc_getBloodPressure;
    if (_bp isEqualType [] && {count _bp >= 2}) then {
        _dia = round (_bp select 0);
        _sys = round (_bp select 1);
    };
};
private _map = if (_sys > 0) then {round ((_sys + 2 * _dia) / 3)} else {round ([_patient, "ACM_circulation_MAP", 0] call _fnNum)};

_linesL pushBack format ["<t color='%1'>VITALS</t>", _cSect];
private _alivePlain = if (alive _patient) then {"alive"} else {"dead"};
private _aliveColor = if (alive _patient) then {_cGood} else {_cBad};
_linesL pushBack ([
    ["State", _alivePlain, _aliveColor, 6, 7] call _fnKV,
    ["HR", _hr, [_hr] call _fnColorHR, 6, 7] call _fnKV
] joinString "     " );
_linesL pushBack ([
    ["BP", format ["%1/%2", _sys, _dia], [_sys] call _fnColorSys, 6, 7] call _fnKV,
    ["MAP", _map, [_map] call _fnColorMAP, 6, 7] call _fnKV
] joinString "     " );
_linesL pushBack ([
    ["RR", _rr, [_rr] call _fnColorRR, 6, 7] call _fnKV,
    ["SpO2", format ["%1%%", _spo2], [_spo2] call _fnColorSpO2, 6, 7] call _fnKV
] joinString "     " );
_linesL pushBack ([
    ["Circ", format ["%1L", _circVol toFixed 2], [_circVol] call _fnColorBlood, 6, 7] call _fnKV,
    ["Eff", format ["%1L", _effVol toFixed 2], [_effVol] call _fnColorBlood, 6, 7] call _fnKV
] joinString "     " );
_linesL pushBack ([
    ["Blood", format ["%1L", _bloodComp toFixed 2], _cMute, 6, 7] call _fnKV,
    ["Plasma", format ["%1L", _plasmaComp toFixed 2], _cMute, 6, 7] call _fnKV
] joinString "     " );
_linesL pushBack ([
    ["Cryst", format ["%1L", _salineComp toFixed 2], _cMute, 6, 7] call _fnKV,
    ["Over", format ["%1L", _overloadComp toFixed 2], _cMute, 6, 7] call _fnKV
] joinString "     " );
_linesL pushBack ([
    ["Def", format ["%1L", _bloodDeficit toFixed 2], [_circVol] call _fnColorBlood, 6, 7] call _fnKV,
    ["Pct", format ["%1%%", _bloodPct], [_circVol] call _fnColorBlood, 6, 7] call _fnKV
] joinString "     " );

// Show each admitted drug effect separately from the shared hypnotic/adjunct result.
([_patient] call ACME_fnc_sedationComponents) params ["_ketLoad", "_propLoad", "_midLoad", "_fentLoad", "_adjunct", "_sedLoad"];
private _rocLoad = [_patient] call ACME_fnc_rocuroniumOnBoard;
// Raw medication counts make a newly accepted RSI push visible immediately, before the normal onset envelope has
// risen far enough to affect physiology. This is diagnostic only; treatment logic continues to use effective load.
private _ketRaw = 0;
private _rocRaw = 0;
if (!isNil "ace_medical_status_fnc_getMedicationCount") then {
    { _ketRaw = _ketRaw + ([_patient, _x, true] call ace_medical_status_fnc_getMedicationCount); } forEach ["Ketamine", "Ketamine_IV"];
    { _rocRaw = _rocRaw + ([_patient, _x, true] call ace_medical_status_fnc_getMedicationCount); } forEach ["Rocuronium", "Rocuronium_IV"];
};
private _paralyzed = _patient getVariable ["ACME_roc_paralyzed", false];
private _ettIn = _patient getVariable ["ACME_ETT_Inserted", false];
if (_sedLoad > 0.001 || {_fentLoad > 0.001} || {_rocLoad > 0.05} || {_ketRaw > 0.001} || {_rocRaw > 0.001} || {_paralyzed} || {_ettIn}) then {
    _linesL pushBack format ["<t color='%1'>RSI / AIRWAY</t>", _cSect];
    // sedationComponents already returns induction-normalized hypnotic loads: 1.0 is the
    // configured induction threshold after hypnotic synergy/opioid adjuncts. Do not compare
    // the normalized ketamine component to the raw legacy ketamine threshold a second time.
    private _sedated = _patient getVariable ["ACME_ket_sedated", false];
    private _induction = _sedLoad >= 1;
    private _sedTxt = if (_sedated) then {"YES"} else {if (_induction) then {"induction threshold"} else {"below induction"}};
    private _cSed = if (_sedated || {_induction}) then {_cGood} else {_cMute};
    _linesL pushBack (["SEDATED", _sedTxt, _cSed, 8, 20] call _fnKV);
    private _ketTxt = if (_ketLoad <= 0.001 && {_ketRaw > 0.001}) then {"accepted, onset pending"} else {format ["x%1 induction", _ketLoad toFixed 2]};
    _linesL pushBack (["Ketamine", _ketTxt, _cMute, 10, 22] call _fnKV);
    _linesL pushBack (["Propofol", _propLoad toFixed 2, _cMute, 10, 7] call _fnKV);
    _linesL pushBack (["Sed total", _sedLoad toFixed 2, _cMute, 10, 7] call _fnKV);
    _linesL pushBack (["Fentanyl", format ["%1%2 attenuation / x%3 adjunct", round (_fentLoad*100), "%", _adjunct toFixed 2], _cMute, 10, 28] call _fnKV);
    // SUGAMMADEX: the rocuronium reversal. it shows how much paralytic it has neutralized and how far through its
    // roughly 2.5 min onset it is. it reverses the block only, and the awareness event above is untouched by it.
    private _sugRaw = [_patient] call ACME_fnc_sugammadexOnBoard;
    if (_sugRaw > 0.01) then {
        private _sugRamp = _patient getVariable ["ACME_sug_ramp", 0];
        private _sugRev  = _patient getVariable ["ACME_sug_reversalEffective", 0];
        private _sugMgKg = _patient getVariable ["ACME_sug_mgPerKg", 0];
        // mg/kg is the number that matters: 16 mg/kg is the field dose that reverses a fresh intubating dose. anything
        // well under that may lift the block only briefly and then let it come back, which is recurarization.
        private _sugCol = if (_sugMgKg >= 16) then {_cGood} else { if (_sugMgKg >= 8) then {_cWarn} else {_cBad} };
        _linesL pushBack ([
            ["SUGAMMADEX", format ["%1 mg/kg  onset %2%3  rev %4", _sugMgKg toFixed 1, round (_sugRamp * 100), "%", _sugRev toFixed 2], _sugCol, 10, 26] call _fnKV
        ] joinString "     " );
    };
    // the midazolam onset. it is a valid sedative and it is slow, at about 5 min. until this ramp reaches 100 percent
    // it is not yet carrying its sedation, so paralyzing now gives awake paralysis.
    private _mzEff = _patient getVariable ["ACME_midaz_sedEffective", 0];
    private _mzRamp = _patient getVariable ["ACME_midaz_sedRamp", 0];
    if (_mzEff > 0 || {(_patient getVariable ["ACME_midaz_onsetT0", -1]) >= 0}) then {
        _linesL pushBack ([
            ["MIDAZ", format ["onset %1%2", round (_mzRamp * 100), "%"], if (_mzRamp >= 1) then {_cGood} else {_cWarn}, 8, 16] call _fnKV
        ] joinString "     " );
    };
    // the PARALYZED line: the rocuronium block state, with the awake-paralysis danger called out in red.
    private _awake = _patient getVariable ["ACME_roc_awakeParalysis", false];
    private _apnea = _patient getVariable ["ACME_roc_apnea", false];
    private _blockThr = missionNamespace getVariable ["ACME_roc_blockThreshold", 0.5];
    private _parTxt = if (_paralyzed) then {
        if (_awake) then {"YES - AWAKE (danger!)"} else {"YES (apnea, ventilate)"}
    } else {
        if (_rocLoad >= _blockThr) then {"onset..."} else {if (_rocLoad > 0.05) then {"sub-dose"} else {if (_rocRaw > 0.001) then {"accepted, onset pending"} else {"no"}}}
    };
    private _cPar = if (_awake) then {_cBad} else {if (_paralyzed) then {_cWarn} else {_cMute}};
    _linesL pushBack ([
        ["PARALYZED", _parTxt, _cPar, 9, 22] call _fnKV
    ] joinString "     " );
    // AWARENESS: the latched RSI error. once earned it persists through later sedation, because sedating them
    // afterwards does not un-happen it. this is the line the aar should be scoring.
    if (_patient getVariable ["ACME_roc_awarenessEvent", false]) then {
        private _awSecs = _patient getVariable ["ACME_roc_awarenessSeconds", 0];
        _linesL pushBack ([
            ["AWARENESS", format ["EVENT (%1s aware)", round _awSecs], _cBad, 9, 22] call _fnKV
        ] joinString "     " );
    };
    // the VENT line: is a running vent driving this patient, and is the minute ventilation adequate?
    private _driving = _patient getVariable ["ACME_vent_driving", false];
    private _ventTxt = if (_driving) then {
        private _adq = _patient getVariable ["ACME_vent_mvAdequacy", 0];
        private _bpm = _patient getVariable ["ACME_vent_bpm", 0];
        private _vt  = _patient getVariable ["ACME_vent_vt", 0];
        format ["driving  %1x%2  MV %3%4", _bpm, _vt, round (_adq * 100), "%"]
    } else {
        if (_ettIn) then {"intubated, not connected"} else {"off"}
    };
    private _cVent = if (_driving) then {_cGood} else {_cMute};
    _linesL pushBack ([
        ["VENT", _ventTxt, _cVent, 6, 24] call _fnKV
    ] joinString "     " );
};

// the lidocaine serum level, a human-readable dose accumulation, plus the seizure activity.
private _lidoLvl = _patient getVariable ["ACME_lido_serumLevel", 0];
private _seizSt  = _patient getVariable ["ACME_lido_seizureState", ""];
if (_lidoLvl > 0.05 || {_seizSt != ""}) then {
    _linesL pushBack format ["<t color='%1'>LIDOCAINE / SEIZURE</t>", _cSect];
    private _seizThr = missionNamespace getVariable ["ACME_lido_seizureThreshold", 12];
    private _cardThr = missionNamespace getVariable ["ACME_lido_cardiacThreshold", 15];
    private _arrThr  = missionNamespace getVariable ["ACME_lido_arrestThreshold", 25];
    // the highest band the level reaches wins, as a sequential override.
    private _band = "therapeutic"; private _cBand = _cGood;
    if (_lidoLvl >= 5)        then { _band = "early CNS";   _cBand = _cWarn; };
    if (_lidoLvl >= _seizThr) then { _band = "SEIZURE";     _cBand = _cBad;  };
    if (_lidoLvl >= _cardThr) then { _band = "cardiac tox"; _cBand = _cBad;  };
    if (_lidoLvl >= _arrThr)  then { _band = "ARREST";      _cBand = _cBad;  };
    _linesL pushBack ([
        ["Serum", format ["%1 mcg/mL", _lidoLvl toFixed 1], _cBand, 7, 11] call _fnKV,
        ["Band", _band, _cBand, 6, 12] call _fnKV
    ] joinString "     " );
    // the seizure phase and the benzo: the effective midazolam administrations on board against what is needed, which
    // is refractory with the level.
    private _seizTxt = if (_seizSt == "") then {"none"} else {_seizSt};
    private _cSeiz = switch (_seizSt) do { case "active": {_cBad}; case "postictal": {_cWarn}; default {_cMute} };
    private _mida = [_patient] call ACME_fnc_benzoOnBoard;
    private _bNeed = (missionNamespace getVariable ["ACME_lido_seizureBenzoBase", 1]) + ((missionNamespace getVariable ["ACME_lido_seizureBenzoRefractory", 0.1]) * ((_lidoLvl - _seizThr) max 0));
    private _cBenzo = if (_mida >= _bNeed) then {_cGood} else {_cWarn};
    _linesL pushBack ([
        ["Seizure", _seizTxt, _cSeiz, 7, 10] call _fnKV,
        ["Benzo", format ["%1/%2", _mida toFixed 1, _bNeed toFixed 1], _cBenzo, 6, 9] call _fnKV
    ] joinString "     " );
};

// the esmolol drip: how much is dripping, the serum estimate and the therapeutic band.
private _esmDrive = _patient getVariable ["ACME_esmolol_driveMgMin", 0];
private _esmSerum = _patient getVariable ["ACME_esmolol_serumLevel", 0];
if (_esmDrive > 0.001 || {_esmSerum > 0.01}) then {
    _linesL pushBack format ["<t color='%1'>ESMOLOL</t>", _cSect];
    private _loBand = missionNamespace getVariable ["ACME_esmolol_serumTherapeuticLow", 0.5];
    private _hiBand = missionNamespace getVariable ["ACME_esmolol_serumTherapeuticHigh", 2.0];
    // a sequential override: subtherapeutic, then therapeutic, then heavy block, then overdose, which is a toxic
    // beta-blockade.
    private _band = "subtherapeutic"; private _cBand = _cWarn;
    if (_esmSerum >= _loBand) then { _band = "therapeutic"; _cBand = _cGood; };
    if (_esmSerum >  _hiBand) then { _band = "heavy block"; _cBand = _cWarn; };
    private _odMax = missionNamespace getVariable ["ACME_esmolol_serumOverdoseMax", 5.0];
    private _od = linearConversion [_hiBand, _odMax, _esmSerum, 0, 1, true];
    if (_od > 0) then { _band = "OVERDOSE"; _cBand = _cBad; };
    _linesL pushBack ([
        ["Drip",  format ["%1 mg/min", _esmDrive toFixed 2], _cMute, 6, 12] call _fnKV,
        ["Serum", format ["%1 mcg/mL", _esmSerum toFixed 2], _cBand, 7, 12] call _fnKV,
        ["Band",  _band, _cBand, 6, 12] call _fnKV
    ] joinString "     " );
    if (_od > 0) then {
        _linesL pushBack ([
            ["Overdose", format ["%1%2", round (_od * 100), "%"], _cBad, 9, 8] call _fnKV,
            ["Effects", "AV block (brady) + hypotension", _cBad, 8, 30] call _fnKV
        ] joinString "     " );
    };
};

// the amiodarone and magnesium fast-infusion rates, for calibration and fast-push penalty visibility.
private _cSt = _patient getVariable ["ACME_circ_State", createHashMap];
private _amioR = _cSt getOrDefault ["amioRateMgMin", 0];
private _magR  = _cSt getOrDefault ["magRateMgMin", 0];
if (_amioR > 0.5 || {_magR > 0.5}) then {
    _linesL pushBack format ["<t color='%1'>INFUSION RATE</t>", _cSect];
    private _fnRow = {
        params ["_lbl", "_rate", "_frac"];
        private _c = _cMute;  // below the fast onset, so no penalty.
        if (_frac > 0) then {_c = _cWarn;};  // into the fast zone.
        if (_frac >= 0.999) then {_c = _cBad;};  // maxed.
        [_lbl, format ["%1 mg/min", round _rate], _c, 5, 12] call _fnKV
    };
    private _row = [];
    if (_amioR > 0.5) then { _row pushBack (["Amio", _amioR, _cSt getOrDefault ["amioFast", 0]] call _fnRow); };
    if (_magR  > 0.5) then { _row pushBack (["Mag",  _magR,  _cSt getOrDefault ["magFast", 0]]  call _fnRow); };
    _linesL pushBack (_row joinString "     ");
    private _maxFast = (_cSt getOrDefault ["amioFast", 0]) max (_cSt getOrDefault ["magFast", 0]);
    if (_maxFast > 0) then {
        _linesL pushBack ([["Fast push", format ["%1%2 (brady/hypotension)", round (_maxFast * 100), "%"], _cBad, 9, 30] call _fnKV] joinString "     ");
    };
};

// calcium, both chloride and gluconate: the elemental serum, the narrow therapeutic band, and the dose and rate
// overdose.
private _caSerum = _patient getVariable ["ACME_ca_serumLevel", 0];
private _caElem  = _cSt getOrDefault ["caElemMgMin", 0];
private _caSalt  = _cSt getOrDefault ["caRateMgMin", 0];
private _caOd    = _cSt getOrDefault ["caOverdose", 0];
if (_caSerum > 0.01 || {_caElem > 0.5} || {_caOd > 0}) then {
    // which salts are running, chloride or gluconate, for the readout.
    private _caCl = false; private _caGl = false;
    {
        if ((_x param [17, 0]) > 0 && {(_x param [14, 0]) > 0}) then {
            switch (_x param [11, ""]) do {
                case "CalciumChloride":  { _caCl = true; };
                case "CalciumGluconate": { _caGl = true; };
            };
        };
    } forEach (_patient getVariable ["ACME_infusion_BagMedications", []]);
    private _salt = switch (true) do {
        case (_caCl && _caGl): {"CaCl2 + gluconate"};
        case _caCl: {"CaCl2"};
        case _caGl: {"gluconate"};
        default {"(washing out)"};
    };
    _linesL pushBack format ["<t color='%1'>CALCIUM  <t color='%2' size='0.85'>%3</t></t>", _cSect, _cMute, _salt];
    private _caHigh = missionNamespace getVariable ["ACME_ca_serumTherapeuticHigh", 1.0];
    private _caArr  = missionNamespace getVariable ["ACME_ca_serumOverdoseArrest", 4.0];
    private _arrhyF = missionNamespace getVariable ["ACME_ca_overdoseArrhythmiaFrac", 0.55];
    private _band = "therapeutic"; private _cBand = _cGood;
    if (_caOd > 0)       then { _band = "OVERDOSE: vasodilation, low BP"; _cBand = _cWarn; };
    if (_caOd >= _arrhyF) then { _band = "OVERDOSE: bradycardia/arrhythmia"; _cBand = _cBad; };
    if (_caOd >= 0.75)   then { _band = "OVERDOSE: peri-arrest"; _cBand = _cBad; };
    _linesL pushBack ([
        ["Serum", format ["%1 / %2 mg/dL", _caSerum toFixed 2, _caHigh toFixed 1], _cBand, 6, 14] call _fnKV,
        ["Rate",  format ["%1 mg/min (elem %2)", round _caSalt, round _caElem], _cMute, 5, 24] call _fnKV
    ] joinString "     " );
    _linesL pushBack ([["Band", _band, _cBand, 5, 30] call _fnKV] joinString "     ");
    if (_caOd > 0) then {
        _linesL pushBack ([["Overdose", format ["%1%2", round (_caOd * 100), "%"], _cBad, 9, 8] call _fnKV] joinString "     ");
    };
};

// amiodarone: the serum and the therapeutic band. the consequences are hypotension and the cumulative torsades
// ceiling.
private _amioSerum = _patient getVariable ["ACME_amio_serumLevel", 0];
private _amioRate  = _cSt getOrDefault ["amioRateMgMin", 0];
private _amioCum   = _patient getVariable ["ACME_rhythm_amioCum", 0];
if (_amioSerum > 0.01 || {_amioRate > 0.5} || {_amioCum > 1}) then {
    _linesL pushBack format ["<t color='%1'>AMIODARONE</t>", _cSect];
    private _aLo = missionNamespace getVariable ["ACME_amio_serumTherapeuticLow", 1.0];
    private _aHi = missionNamespace getVariable ["ACME_amio_serumTherapeuticHigh", 2.5];
    private _aCeil = missionNamespace getVariable ["ACME_rhythm_amioCeilingMg", 2200];
    private _band = "subtherapeutic"; private _cBand = _cWarn;
    if (_amioSerum >= _aLo) then { _band = "therapeutic"; _cBand = _cGood; };
    if (_amioSerum >  _aHi) then { _band = "high (fast infusion)"; _cBand = _cWarn; };
    private _amioFastFrac = _cSt getOrDefault ["amioFast", 0];
    _linesL pushBack ([
        ["Serum", format ["%1 mg/L", _amioSerum toFixed 2], _cBand, 6, 10] call _fnKV,
        ["Rate",  format ["%1 mg/min", round _amioRate], _cMute, 5, 12] call _fnKV,
        ["Band",  _band, _cBand, 5, 20] call _fnKV
    ] joinString "     " );
    private _cCum = if (_amioCum >= _aCeil) then {_cBad} else {if (_amioCum >= _aCeil * 0.75) then {_cWarn} else {_cMute}};
    _linesL pushBack ([
        ["Cumulative", format ["%1 / %2 mg (QT/torsades ceiling)", round _amioCum, round _aCeil], _cCum, 10, 30] call _fnKV
    ] joinString "     " );
    if (_amioFastFrac > 0) then {
        _linesL pushBack ([["Fast infusion", format ["%1%2 (hypotension)", round (_amioFastFrac * 100), "%"], _cBad, 13, 20] call _fnKV] joinString "     ");
    };
};

// the serum levels for every other running infusion, from the generalized pk: the level and the therapeutic
// band.
private _pkTable = missionNamespace getVariable ["ACME_infusion_pk", createHashMap];
private _serumRows = [];
{
    private _pkMed = _x;
    _y params ["", "", ["_tLo", 0], ["_tHi", 0], ["_unit", "mcg/mL"]];
    private _lvl = _patient getVariable [format ["ACME_serum_%1", _pkMed], 0];
    if (_lvl > 0.0001) then {
        private _c = _cWarn;  // subtherapeutic.
        if (_lvl >= _tLo) then { _c = _cGood; };  // therapeutic.
        if (_lvl >  _tHi) then { _c = _cWarn; };  // above the band.
        private _dec = if (_lvl < 0.1) then {3} else {2};
        _serumRows pushBack ([_pkMed, format ["%1 %2", _lvl toFixed _dec, _unit], _c, 12, 14] call _fnKV);
    };
} forEach _pkTable;
if (count _serumRows > 0) then {
    _linesL pushBack format ["<t color='%1'>SERUM LEVELS</t>", _cSect];
    // two columns per row, for compactness.
    for "_i" from 0 to (count _serumRows - 1) step 2 do {
        private _row = [_serumRows select _i];
        if (_i + 1 < count _serumRows) then { _row pushBack (_serumRows select (_i + 1)); };
        _linesL pushBack (_row joinString "     ");
    };
};

if (missionNamespace getVariable ["ACME_debug_showTBI", true]) then {
    _linesL pushBack format ["<t color='%1'>TBI / ICP</t>", _cSect];
    private _state = _patient getVariable ["ACME_tbi_State", createHashMap];
    if (count _state == 0) then {
        _linesL pushBack format ["<t color='%1'>no TBI state</t>", _cMute];
    } else {
        private _icp = _state getOrDefault ["icp", 0];
        private _cpp = _map - _icp;
        private _cppTarget = missionNamespace getVariable ["ACME_tbi_cppTarget", 70];
        private _sev = _state getOrDefault ["severity", 0];
        private _hern = _state getOrDefault ["herniating", false];
        private _cush = _state getOrDefault ["cushing", false];
        private _gateOpen = _state getOrDefault ["herniationGateOpen", false];
        private _na = round (_state getOrDefault ["sodium", 0]);
        private _cNa = if (_na <= 0) then {_cMute} else {if (_na < 130 || {_na > 150}) then {_cWarn} else {_cGood}};
        _linesL pushBack ([
            ["ICP", round _icp, [_icp] call _fnColorICP, 6, 7] call _fnKV,
            ["CPP", format ["%1/%2", round _cpp, round _cppTarget], [_cpp, _cppTarget] call _fnColorCPP, 6, 7] call _fnKV,
            ["sev", _sev toFixed 2, [_sev] call _fnColorSeverity, 6, 7] call _fnKV
        ] joinString " " );
        _linesL pushBack ([
            format ["%1 %2", ["cush", 5] call _fnPadRight, [_cush, true] call _fnBoolTxt],
            format ["%1 %2", ["hern", 5] call _fnPadRight, [_hern, true] call _fnBoolTxt],
            ["stage", _state getOrDefault ["herniationStage", 0], if ((_state getOrDefault ["herniationStage", 0]) > 0) then {_cBad} else {_cGood}, 6, 7] call _fnKV
        ] joinString " " );
        _linesL pushBack ([
            format ["%1 %2", ["gate", 5] call _fnPadRight, [_gateOpen, true] call _fnBoolTxt],
            ["remain", format ["%1s", round (_state getOrDefault ["herniationGateRemaining", 0])], _cMute, 6, 7] call _fnKV,
            ["Na", _na, _cNa, 6, 7] call _fnKV
        ] joinString " " );
    };
};

if (missionNamespace getVariable ["ACME_debug_showInfusions", true]) then {
    _linesL pushBack format ["<t color='%1'>INFUSIONS</t>", _cSect];
    private _active = _patient getVariable ["ACME_infusion_HasBagMedications", false];
    private _bags = _patient getVariable ["ACME_infusion_BagMedications", []];
    _linesL pushBack ([format ["%1 %2", ["act", 7] call _fnPadRight, [_active] call _fnBoolTxt], ["meds", count _bags, if ((count _bags) > 0) then {_cWarn} else {_cGood}, 6, 7] call _fnKV] joinString " " );
    private _shown = 0;
    {
        if (_shown < 5) then {
            private _label = if (_x isEqualType []) then {str _x} else {[str _x] call _fnSafe};
            _linesL pushBack format ["<t color='%1'>%2</t>", _cMute, _label];
            _shown = _shown + 1;
        };
    } forEach _bags;
};

_linesR pushBack format ["<t color='%1' size='1.00'>SYSTEMS</t>", _cTitle];
_linesR pushBack ([
    format ["%1 %2", ["TBI", 4] call _fnPadRight, [missionNamespace getVariable ["ACME_sys_tbi", true]] call _fnBoolTxt],
    format ["%1 %2", ["Circ", 5] call _fnPadRight, [missionNamespace getVariable ["ACME_sys_circ", true]] call _fnBoolTxt],
    format ["%1 %2", ["Rhythm", 7] call _fnPadRight, [missionNamespace getVariable ["ACME_sys_rhythm", true]] call _fnBoolTxt]
] joinString "  " );

if (missionNamespace getVariable ["ACME_debug_showCirc", true]) then {
    private _circState = _patient getVariable ["ACME_circ_State", createHashMap];
    private _shock = _circState getOrDefault ["shockSeverity", 0];
    private _bpOffset = [_patient, "ACME_circ_bpOffset", 0] call _fnNum;
    private _hrPin = [_patient, "ACME_rhythm_HRPin", 0] call _fnNum;
    private _pressor = _circState getOrDefault ["pressorSupport", 0];
    private _pde = [_patient, "ACME_pde_support", 0] call _fnNum;
    private _distal = [_patient, "ACME_circ_distalPressorSpike", 0] call _fnNum;
    private _ca = [_patient, "ACME_calciumCredit", 0] call _fnNum;
    private _citrate = [_patient, "ACME_citrateLoad", 0] call _fnNum;
    private _svr = [_patient, "ace_medical_peripheralResistance", 100] call _fnNum;
    private _vaso = [_patient, "ACM_circulation_Vasoconstriction_State", 0] call _fnNum;
    private _acid = _circState getOrDefault ["totalAcidosis", (_circState getOrDefault ["acidosis", 0])];
    private _metAcid = _circState getOrDefault ["metabolicAcidosis", _acid];
    private _respAcid = _circState getOrDefault ["respiratoryAcidosis", 0];
    private _salineAcid = _circState getOrDefault ["salineAcidosis", 0];
    private _shockFrac = _circState getOrDefault ["shockMetAcidFrac", 0];
    private _respDeficit = _circState getOrDefault ["respiratoryAcidosisDeficit", 0];
    private _paCO2 = _circState getOrDefault ["paCO2", (missionNamespace getVariable ["ACME_circ_paCO2Normal", 40])];
    private _paCO2Burden = _circState getOrDefault ["paCO2Burden", 0];
    private _paCO2Rise = _circState getOrDefault ["paCO2Rise", 0];
    private _paCO2Clear = _circState getOrDefault ["paCO2Clear", 0];
    private _respAcidTarget = _circState getOrDefault ["respAcidosisTarget", 0];
    private _ventFrac = _circState getOrDefault ["respVentFrac", 1];
    private _hasExhale = _circState getOrDefault ["respHasExhalation", true];
    private _etco2Estimate = _circState getOrDefault ["etco2Estimate", -1];
    private _etco2Observed = _circState getOrDefault ["etco2Observed", -1];
    private _co2Gap = _circState getOrDefault ["paCO2EtCO2Gap", 0];
    private _acidArrest = _circState getOrDefault ["acidArrestDriver", false];
    private _bvmActive = _circState getOrDefault ["respBVMActive", false];
    private _acidEffMAP = _circState getOrDefault ["acidEffMAP", 0];
    private _hypoGain = _circState getOrDefault ["hypoAcidGainMult", 1];
    private _hypoRecover = _circState getOrDefault ["hypoAcidRecoveryMult", 1];
    private _tbiCppAcid = _circState getOrDefault ["tbiCppAcidFrac", 0];
    private _rawSupport = _circState getOrDefault ["rawPressorSupport", (_pressor + _pde + _distal)];
    private _effSupport = _circState getOrDefault ["effectivePressorSupport", _rawSupport];
    private _supportLoss = _circState getOrDefault ["pressorSupportLoss", ((_rawSupport - _effSupport) max 0)];
    private _acidBlunt = _circState getOrDefault ["acidPressorBluntFrac", 0];
    private _hypoBlunt = _circState getOrDefault ["hypoPressorBluntFrac", (_circState getOrDefault ["hypoBlunt", 0])];
    private _coag = _circState getOrDefault ["coagMult", 1];
    private _acidCoag = _circState getOrDefault ["acidCoagMult", 1];
    private _caCoag = _circState getOrDefault ["calciumCoagMult", 1];
    private _hypoCoag = _circState getOrDefault ["hypoCoagMult", 1];
    private _salineMl = _patient getVariable ["ACME_circ_salineGivenMl", (_circState getOrDefault ["salineGivenMl", 0])];

    _linesR pushBack format ["<t color='%1'>PERFUSION</t>", _cSect];
    _linesR pushBack ([
        ["Shock", _shock toFixed 2, [_shock] call _fnColorSeverity, 7, 7] call _fnKV,
        ["MAP delta", round _bpOffset, if (abs _bpOffset > 30) then {_cWarn} else {_cGood}, 7, 7] call _fnKV
    ] joinString "        " );
    _linesR pushBack ([
        ["HR pin", round _hrPin, if (_hrPin > 0) then {_cWarn} else {_cGood}, 7, 7] call _fnKV,
        ["SVR", round _svr, if (_svr < 70 || {_svr > 140}) then {_cWarn} else {_cGood}, 7, 7] call _fnKV
    ] joinString "        " );
    _linesR pushBack ([
        ["VC", _vaso toFixed 1, if (abs _vaso > 25) then {_cWarn} else {_cGood}, 7, 7] call _fnKV,
        ["Ca", _ca toFixed 2, if (_ca > 0) then {_cGood} else {_cMute}, 7, 7] call _fnKV
    ] joinString "        " );
    _linesR pushBack ([
        ["Citrate", _citrate toFixed 2, if (_citrate > 0.5) then {_cWarn} else {_cGood}, 7, 7] call _fnKV
    ] joinString "        " );
    _linesR pushBack "";

    _linesR pushBack format ["<t color='%1'>PRESSORS</t>", _cSect];
    _linesR pushBack ([
        ["Raw", _rawSupport toFixed 2, if (_rawSupport > 0) then {_cWarn} else {_cGood}, 7, 7] call _fnKV,
        ["Eff", _effSupport toFixed 2, if (_effSupport > 0) then {_cGood} else {_cMute}, 7, 7] call _fnKV
    ] joinString "        " );
    _linesR pushBack ([
        ["Lost", _supportLoss toFixed 2, if (_supportLoss > 0.5) then {_cBad} else {if (_supportLoss > 0.05) then {_cWarn} else {_cGood}}, 7, 7] call _fnKV,
        ["Acid %", format ["%1%%", round (_acidBlunt * 100)], if (_acidBlunt > 0.25) then {_cBad} else {if (_acidBlunt > 0.10) then {_cWarn} else {_cGood}}, 7, 7] call _fnKV
    ] joinString "        " );
    _linesR pushBack ([
        ["Cold %", format ["%1%%", round (_hypoBlunt * 100)], if (_hypoBlunt > 0.25) then {_cBad} else {if (_hypoBlunt > 0.10) then {_cWarn} else {_cGood}}, 7, 7] call _fnKV,
        ["Inf", _pressor toFixed 2, if (_pressor > 0.6) then {_cWarn} else {_cGood}, 7, 7] call _fnKV
    ] joinString "        " );
    _linesR pushBack ([
        ["PDE", _pde toFixed 2, if (_pde > 0.4) then {_cWarn} else {_cGood}, 7, 7] call _fnKV,
        ["Distal", _distal toFixed 2, if (_distal > 0.2) then {_cBad} else {_cGood}, 7, 7] call _fnKV
    ] joinString "        " );
    _linesR pushBack "";

    _linesR pushBack format ["<t color='%1'>ACIDOSIS</t>", _cSect];
    _linesR pushBack ([
        ["Total", _acid toFixed 3, [_acid] call _fnColorAcid, 7, 7] call _fnKV,
        ["Metab", _metAcid toFixed 3, [_metAcid] call _fnColorAcid, 7, 7] call _fnKV
    ] joinString "        " );
    _linesR pushBack ([
        ["Resp", _respAcid toFixed 3, [_respAcid] call _fnColorAcid, 7, 7] call _fnKV,
        ["Shock", _shockFrac toFixed 3, if (_shockFrac > 0.5) then {_cBad} else {if (_shockFrac > 0.1) then {_cWarn} else {_cGood}}, 7, 7] call _fnKV
    ] joinString "        " );
    _linesR pushBack ([
        ["Vent", _respDeficit toFixed 3, if (_respDeficit > 0.5) then {_cBad} else {if (_respDeficit > 0.1) then {_cWarn} else {_cGood}}, 7, 7] call _fnKV,
        ["CPP", _tbiCppAcid toFixed 3, if (_tbiCppAcid > 0.4) then {_cBad} else {if (_tbiCppAcid > 0) then {_cWarn} else {_cGood}}, 7, 7] call _fnKV
    ] joinString "        " );
    // the dwell timers, in minutes: how long perfusion has been failing, and how long the patient has been
    // under-ventilating. these gate the onset of each acidosis, so they explain why it is or is not building yet.
    private _shkDwell = (_circState getOrDefault ["shockDwell", 0]) / 60;
    private _hypDwell = (_circState getOrDefault ["hypoventDwell", 0]) / 60;
    _linesR pushBack ([
        ["ShkMin", _shkDwell toFixed 1, if (_shkDwell > 10) then {_cBad} else {if (_shkDwell > 3) then {_cWarn} else {_cGood}}, 7, 7] call _fnKV,
        ["HypMin", _hypDwell toFixed 1, if (_hypDwell > 5) then {_cBad} else {if (_hypDwell > 1) then {_cWarn} else {_cGood}}, 7, 7] call _fnKV
    ] joinString "        " );
    _linesR pushBack ([
        ["AcidMAP", round _acidEffMAP, if (_acidEffMAP < 20) then {_cBad} else {if (_acidEffMAP < 55) then {_cWarn} else {_cGood}}, 7, 7] call _fnKV,
        ["PaCO2", _paCO2 toFixed 1, if (_paCO2 > 70) then {_cBad} else {if (_paCO2 > 50) then {_cWarn} else {_cGood}}, 7, 7] call _fnKV
    ] joinString "        " );
    _linesR pushBack ([
        ["EtCO2", if (_etco2Observed < 0) then {"n/a"} else {_etco2Observed toFixed 0}, if (_etco2Observed < 0) then {_cMute} else {if (_etco2Observed > 55 || {_etco2Observed < 20}) then {_cWarn} else {_cGood}}, 7, 7] call _fnKV,
        ["Gap", _co2Gap toFixed 1, if (_co2Gap > 20) then {_cBad} else {if (_co2Gap > 8) then {_cWarn} else {_cGood}}, 7, 7] call _fnKV
    ] joinString "        " );
    _linesR pushBack ([
        ["Exhale", if (_hasExhale) then {"yes"} else {"no"}, if (_hasExhale) then {_cGood} else {_cBad}, 7, 7] call _fnKV,
        ["BVM", if (_bvmActive) then {"yes"} else {"no"}, if (_bvmActive) then {_cGood} else {_cBad}, 7, 7] call _fnKV
    ] joinString "        " );
    // blast lung.
    private _blastSev = _patient getVariable ["ACME_blastLung_State", 0];
    if (_blastSev > 0) then {
        private _blastVented = (_patient getVariable ["ACME_vent_driving", false]) && {(_patient getVariable ["ACME_vent_mvAdequacy", 0]) > 0.6} && {(_patient getVariable ["ACME_vent_fio2", 21]) >= 50};
        _linesR pushBack "";
        _linesR pushBack format ["<t color='%1'>BLAST LUNG</t>", _cSect];
        _linesR pushBack ([
            ["Sev", _blastSev toFixed 2, if (_blastSev > 0.6) then {_cBad} else {_cWarn}, 7, 7] call _fnKV,
            ["Vent", if (_blastVented) then {"ok"} else {"NO"}, if (_blastVented) then {_cGood} else {_cBad}, 7, 7] call _fnKV
        ] joinString "        " );
    };
    // the ventilator: the mode, the delivery and the barotrauma.
    if (_patient getVariable ["ACME_vent_driving", false]) then {
        private _vMode = _patient getVariable ["ACME_vent_mode", "-"];
        private _vPip  = _patient getVariable ["ACME_vent_pip", 0];
        private _vPipS = _patient getVariable ["ACME_vent_pipState", 0];
        private _vVti  = _patient getVariable ["ACME_vent_vti", 0];
        private _vVte  = _patient getVariable ["ACME_vent_vte", 0];
        private _vComp = _patient getVariable ["ACME_vent_compliance", 1];
        private _vBaro = _patient getVariable ["ACME_vent_baroInjury", 0];
        private _vEvts = _patient getVariable ["ACME_vent_baroEvents", 0];
        _linesR pushBack "";
        _linesR pushBack ("VENTILATOR  " + _vMode);
        _linesR pushBack ([
            ["PIP", str (round _vPip), switch (_vPipS) do { case 2: {_cBad}; case 1: {_cWarn}; default {_cGood} }, 7, 7] call _fnKV,
            ["Comp", _vComp toFixed 2, if (_vComp < 0.5) then {_cBad} else {if (_vComp < 0.8) then {_cWarn} else {_cGood}}, 7, 7] call _fnKV
        ] joinString "        " );
        _linesR pushBack ([
            ["VTi", str (round _vVti), _cGood, 7, 7] call _fnKV,
            ["VTe", str (round _vVte), _cGood, 7, 7] call _fnKV
        ] joinString "        " );
        _linesR pushBack ([
            ["VILI", _vBaro toFixed 2, if (_vBaro > 0) then {_cBad} else {_cGood}, 7, 7] call _fnKV,
            ["Baro", str _vEvts, if (_vEvts > 0) then {_cBad} else {_cGood}, 7, 7] call _fnKV
        ] joinString "        " );
    };
    _linesR pushBack ([
        ["CO2 +", _paCO2Rise toFixed 3, if (_paCO2Rise > 0) then {_cBad} else {_cGood}, 7, 7] call _fnKV,
        ["CO2 -", _paCO2Clear toFixed 3, if (_paCO2Clear > 0) then {_cGood} else {_cMute}, 7, 7] call _fnKV
    ] joinString "        " );
    _linesR pushBack ([
        ["hCl", _salineAcid toFixed 3, [_salineAcid] call _fnColorAcid, 7, 7] call _fnKV,
        ["NS", format ["%1mL", round _salineMl], if (_salineMl >= (missionNamespace getVariable ["ACME_salineAcidosis_startMl", 500])) then {_cWarn} else {_cGood}, 7, 7] call _fnKV
    ] joinString "        " );
    _linesR pushBack ([
        ["ColdG", format ["x%1", _hypoGain toFixed 2], if (_hypoGain > 1.05) then {_cWarn} else {_cGood}, 7, 7] call _fnKV,
        ["Recover", format ["x%1", _hypoRecover toFixed 2], if (_hypoRecover < 0.95) then {_cWarn} else {_cGood}, 7, 7] call _fnKV
    ] joinString "        " );
    _linesR pushBack "";

    _linesR pushBack format ["<t color='%1'>COAGULATION</t>", _cSect];
    _linesR pushBack ([
        ["Total", format ["x%1", _coag toFixed 2], if (_coag > 1.5) then {_cBad} else {if (_coag > 1.1) then {_cWarn} else {_cGood}}, 7, 7] call _fnKV,
        ["Acid", format ["x%1", _acidCoag toFixed 2], if (_acidCoag > 1.05) then {_cWarn} else {_cGood}, 7, 7] call _fnKV
    ] joinString "        " );
    _linesR pushBack ([
        ["Ca", format ["x%1", _caCoag toFixed 2], if (_caCoag > 1.05) then {_cWarn} else {_cGood}, 7, 7] call _fnKV,
        ["Cold", format ["x%1", _hypoCoag toFixed 2], if (_hypoCoag > 1.05) then {_cWarn} else {_cGood}, 7, 7] call _fnKV
    ] joinString "        " );
    private _nsLast = _patient getVariable ["ACME_circ_salineTrackLastSource", ""];
    if (_nsLast != "") then {
        _linesR pushBack ([
            ["NS tick", _nsLast, _cMute, 7, 7] call _fnKV,
            ["At", (_patient getVariable ["ACME_circ_salineTrackLastAt", 0]) toFixed 1, _cMute, 7, 7] call _fnKV
        ] joinString "        " );
    };
};

_linesR pushBack "";
_linesR pushBack format ["<t color='%1'>RHYTHM / AED</t>", _cSect];
private _nativeRhythm = round ([_patient, "ACM_circulation_Cardiac_RhythmState", 0] call _fnNum);
private _customRhythm = round ([_patient, "ACME_rhythm_active", 0] call _fnNum);
private _aedRhythm = round ([_patient, "ACM_circulation_AED_EKGRhythm", _nativeRhythm] call _fnNum);
private _visualRhythm = if (_customRhythm >= 100 && {!(_aedRhythm in [-1,1,2])}) then {_customRhythm} else {_aedRhythm};
private _rhColor = [_nativeRhythm, _customRhythm] call _fnColorRhythm;
_linesR pushBack ([
    ["Active", _customRhythm, _rhColor, 7, 7] call _fnKV,
    ["Native", _nativeRhythm, _rhColor, 7, 7] call _fnKV
] joinString "        " );
_linesR pushBack ([
    ["Visual", _visualRhythm, if (_visualRhythm > 0) then {_cWarn} else {_cGood}, 7, 7] call _fnKV,
    ["Beat", if (missionNamespace getVariable ["ACME_aedBeatClockEnabled", false]) then {"on"} else {"off"}, if (missionNamespace getVariable ["ACME_aedBeatClockEnabled", false]) then {_cBad} else {_cGood}, 7, 7] call _fnKV
] joinString "        " );
_linesR pushBack ([
    ["QRS", if (missionNamespace getVariable ["ACME_aedQrsBeepLockEnabled", false]) then {"on"} else {"off"}, if (missionNamespace getVariable ["ACME_aedQrsBeepLockEnabled", false]) then {_cBad} else {_cGood}, 7, 7] call _fnKV,
    ["Period", ([_patient, "ACME_AED_BeatPeriod", 0] call _fnNum) toFixed 2, if (([_patient, "ACME_AED_BeatPeriod", 0] call _fnNum) > 0) then {_cGood} else {_cMute}, 7, 7] call _fnKV
] joinString "        " );

if (missionNamespace getVariable ["ACME_debug_showAutoBP", true]) then {
    _linesR pushBack "";
    _linesR pushBack format ["<t color='%1'>AUTO BP</t>", _cSect];
    private _bpActive = _patient getVariable ["ACME_autoBP_Active", false];
    private _bpNext = _patient getVariable ["ACME_autoBP_NextTime", 0];
    private _cuffBusy = _patient getVariable ["ACM_circulation_AED_PressureCuffBusy", false];
    _linesR pushBack ([
        ["Active", if (_bpActive) then {"yes"} else {"no"}, if (_bpActive) then {_cGood} else {_cBad}, 7, 7] call _fnKV,
        ["Cuff", if (_cuffBusy) then {"busy"} else {"ready"}, if (_cuffBusy) then {_cWarn} else {_cGood}, 7, 7] call _fnKV
    ] joinString "        " );
    _linesR pushBack ([
        ["Next", [_bpNext] call _fnCountdown, if (_bpActive) then {_cWarn} else {_cMute}, 7, 7] call _fnKV,
        ["Int", format ["%1s", missionNamespace getVariable ["ACME_autoBP_interval", 120]], _cMute, 7, 7] call _fnKV
    ] joinString "        " );
    _linesR pushBack ([
        ["Tracked", count (["ACME_autoBP_patients"] call _fnArray), _cMute, 7, 7] call _fnKV
    ] joinString "        " );
};

// B110: readable ACM state surface. The pause-menu dump carries every raw ACM/ACME/ACE-medical variable;
// this column keeps the high-value state machine fields visible in real time without burying them in a raw dump.
private _boolWord = {
    params ["_v"];
    if (_v) then {"yes"} else {"no"}
};
private _boolColor = {
    params ["_v", ["_trueBad", false]];
    if (_trueBad) exitWith {if (_v) then {_cBad} else {_cGood}};
    if (_v) then {_cGood} else {_cMute}
};
private _shortItem = {
    params ["_v"];
    if !(_v isEqualType "") exitWith {str _v};
    if (_v == "") then {"none"} else {_v}
};

_linesS pushBack format ["<t color='%1' size='1.00'>ACM STATES</t>", _cTitle];
_linesS pushBack format ["<t color='%1'>CORE</t>", _cSect];
private _acmUnc = _patient getVariable ["ACE_isUnconscious", false];
private _acmArrest = _patient getVariable ["ace_medical_inCardiacArrest", false];
private _acmCrit = _patient getVariable ["ACM_core_CriticalVitals_State", false];
private _acmKO = _patient getVariable ["ACM_core_KnockOut_State", false];
_linesS pushBack ([
    ["Uncon", [_acmUnc] call _boolWord, [_acmUnc, true] call _boolColor, 7, 7] call _fnKV,
    ["Arrest", [_acmArrest] call _boolWord, [_acmArrest, true] call _boolColor, 7, 7] call _fnKV
] joinString "        ");
_linesS pushBack ([
    ["Critical", [_acmCrit] call _boolWord, [_acmCrit, true] call _boolColor, 7, 7] call _fnKV,
    ["KO", [_acmKO] call _boolWord, [_acmKO, true] call _boolColor, 7, 7] call _fnKV
] joinString "        ");
_linesS pushBack ([
    ["Lying", [(_patient getVariable ["ACM_core_Lying_State", false])] call _boolWord, _cLabel, 7, 7] call _fnKV,
    ["Sitting", [(_patient getVariable ["ACM_core_Sitting_State", false])] call _boolWord, _cLabel, 7, 7] call _fnKV
] joinString "        ");
_linesS pushBack ([
    ["TgtHR", round (_patient getVariable ["ACM_core_TargetVitals_HeartRate", 0]), _cMute, 7, 7] call _fnKV,
    ["TgtRR", round (_patient getVariable ["ACM_core_TargetVitals_RespirationRate", 0]), _cMute, 7, 7] call _fnKV
] joinString "        ");

_linesS pushBack "";
_linesS pushBack format ["<t color='%1'>AIRWAY</t>", _cSect];
private _airReflex = _patient getVariable ["ACM_airway_AirwayReflex_State", true];
_linesS pushBack ([
    ["Reflex", [_airReflex] call _boolWord, if (_airReflex) then {_cGood} else {_cBad}, 7, 7] call _fnKV,
    ["Collapse", _patient getVariable ["ACM_airway_AirwayCollapse_State", 0], _cLabel, 7, 7] call _fnKV
] joinString "        ");
_linesS pushBack ([
    ["Vomit", _patient getVariable ["ACM_airway_AirwayObstructionVomit_State", 0], _cLabel, 7, 7] call _fnKV,
    ["Blood", _patient getVariable ["ACM_airway_AirwayObstructionBlood_State", 0], _cLabel, 7, 7] call _fnKV
] joinString "        ");
_linesS pushBack ([
    ["OPA", [_patient getVariable ["ACM_airway_AirwayItem_Oral", ""]] call _shortItem, _cLabel, 7, 10] call _fnKV,
    ["NPA", [_patient getVariable ["ACM_airway_AirwayItem_Nasal", ""]] call _shortItem, _cLabel, 7, 10] call _fnKV
] joinString "    ");
_linesS pushBack ([
    ["Recover", [(_patient getVariable ["ACM_airway_RecoveryPosition_State", false])] call _boolWord, _cLabel, 7, 7] call _fnKV,
    ["Tilt", [(_patient getVariable ["ACM_airway_HeadTilt_State", false])] call _boolWord, _cLabel, 7, 7] call _fnKV
] joinString "        ");
_linesS pushBack ([
    ["SurgAW", [(_patient getVariable ["ACM_airway_SurgicalAirway_State", false])] call _boolWord, _cLabel, 7, 7] call _fnKV,
    ["Cuff", [(_patient getVariable ["ACM_airway_SurgicalAirway_CuffInflated", false])] call _boolWord, _cLabel, 7, 7] call _fnKV
] joinString "        ");

_linesS pushBack "";
_linesS pushBack format ["<t color='%1'>BREATHING / CHEST</t>", _cSect];
private _ptx = _patient getVariable ["ACM_breathing_Pneumothorax_State", 0];
private _tptx = _patient getVariable ["ACM_breathing_TensionPneumothorax_State", false];
private _hemoState = _patient getVariable ["ACM_breathing_Hemothorax_State", 0];
private _hemoFluid = _patient getVariable ["ACM_breathing_Hemothorax_Fluid", 0];
_linesS pushBack ([
    ["PTX", _ptx, if (_ptx > 0) then {_cWarn} else {_cGood}, 7, 7] call _fnKV,
    ["Tension", [_tptx] call _boolWord, [_tptx, true] call _boolColor, 7, 7] call _fnKV
] joinString "        ");
_linesS pushBack ([
    ["Hemo", _hemoState, if (_hemoState > 0) then {_cWarn} else {_cGood}, 7, 7] call _fnKV,
    ["Fluid", format ["%1L", _hemoFluid toFixed 2], if (_hemoFluid > 1.4) then {_cBad} else {if (_hemoFluid > 0.3) then {_cWarn} else {_cGood}}, 7, 7] call _fnKV
] joinString "        ");
_linesS pushBack ([
    ["ChestInj", [(_patient getVariable ["ACM_breathing_ChestInjury_State", false])] call _boolWord, _cLabel, 7, 7] call _fnKV,
    ["Seal", [(_patient getVariable ["ACM_breathing_ChestSeal_State", false])] call _boolWord, _cLabel, 7, 7] call _fnKV
] joinString "        ");
_linesS pushBack ([
    ["Thora", _patient getVariable ["ACM_breathing_Thoracostomy_State", -1], _cLabel, 7, 7] call _fnKV,
    ["Lungs", str (_patient getVariable ["ACM_breathing_Stethoscope_LungState", [0,0]]), _cLabel, 7, 10] call _fnKV
] joinString "    ");
_linesS pushBack ([
    ["BVM", [(_patient getVariable ["ACM_breathing_isUsingBVM", false])] call _boolWord, _cLabel, 7, 7] call _fnKV,
    ["BVM O2", [(_patient getVariable ["ACM_breathing_BVM_ConnectedOxygen", false])] call _boolWord, _cLabel, 7, 7] call _fnKV
] joinString "        ");

_linesS pushBack "";
_linesS pushBack format ["<t color='%1'>CIRCULATION</t>", _cSect];
_linesS pushBack ([
    ["Circ", format ["%1L", _circVol toFixed 2], [_circVol] call _fnColorBlood, 7, 7] call _fnKV,
    ["EffVol", format ["%1L", _effVol toFixed 2], [_effVol] call _fnColorBlood, 7, 7] call _fnKV
] joinString "        ");
_linesS pushBack ([
    ["Vaso", (_patient getVariable ["ACM_circulation_Vasoconstriction_State", 0]) toFixed 2, _cLabel, 7, 7] call _fnKV,
    ["Platelet", (_patient getVariable ["ACM_circulation_Platelet_Count", 3]) toFixed 2, _cLabel, 7, 7] call _fnKV
] joinString "        ");
_linesS pushBack ([
    ["Calcium", (_patient getVariable ["ACM_circulation_Calcium_Count", 0]) toFixed 2, _cLabel, 7, 7] call _fnKV,
    ["Rhythm", _patient getVariable ["ACM_circulation_Cardiac_RhythmState", 0], _cLabel, 7, 7] call _fnKV
] joinString "        ");
_linesS pushBack ([
    ["RevArr", [(_patient getVariable ["ACM_circulation_ReversibleCardiacArrest_State", false])] call _boolWord, _cLabel, 7, 7] call _fnKV,
    ["Resist", [(_patient getVariable ["ACM_circulation_CardiacArrest_ShockResistant", false])] call _boolWord, _cLabel, 7, 7] call _fnKV
] joinString "        ");
_linesS pushBack ([
    ["CPR", [(_patient getVariable ["ACM_circulation_isPerformingCPR", false])] call _boolWord, _cLabel, 7, 7] call _fnKV,
    ["CircOK", [(_patient getVariable ["ACM_circulation_CirculationState", true])] call _boolWord, _cLabel, 7, 7] call _fnKV
] joinString "        ");

_linesS pushBack "";
_linesS pushBack format ["<t color='%1'>CLOTTING / DISABILITY</t>", _cSect];
_linesS pushBack ([
    ["Coag", [(_patient getVariable ["ACM_damage_Coagulation_Active", false])] call _boolWord, _cLabel, 7, 7] call _fnKV,
    ["IBCoag", [(_patient getVariable ["ACM_damage_IBCoagulation_Active", false])] call _boolWord, _cLabel, 7, 7] call _fnKV
] joinString "        ");
_linesS pushBack format ["Fract %1", str (_patient getVariable ["ACM_disability_Fracture_State", [0,0,0,0,0,0]])];
_linesS pushBack format ["Splint %1", str (_patient getVariable ["ace_medical_treatment_splints", [0,0,0,0,0,0]])];
_linesS pushBack format ["TQ     %1", str (_patient getVariable ["ACM_disability_Tourniquet_Time", [0,0,0,0,0,0]])];

private _cbrnExposure = _patient getVariable ["ACM_cbrn_Exposed_State", false];
private _cbrnContam = _patient getVariable ["ACM_cbrn_Contaminated_State", false];
private _cbrnLung = _patient getVariable ["ACM_cbrn_LungTissueDamage", 0];
private _cbrnAir = _patient getVariable ["ACM_cbrn_AirwayInflammation", 0];
if (_cbrnExposure || {_cbrnContam} || {_cbrnLung > 0} || {_cbrnAir > 0}) then {
    _linesS pushBack "";
    _linesS pushBack format ["<t color='%1'>CBRN</t>", _cSect];
    _linesS pushBack ([
        ["Exposed", [_cbrnExposure] call _boolWord, [_cbrnExposure, true] call _boolColor, 7, 7] call _fnKV,
        ["Contam", [_cbrnContam] call _boolWord, [_cbrnContam, true] call _boolColor, 7, 7] call _fnKV
    ] joinString "        ");
    _linesS pushBack ([
        ["Airway", _cbrnAir toFixed 2, if (_cbrnAir > 0) then {_cWarn} else {_cGood}, 7, 7] call _fnKV,
        ["Lung", _cbrnLung toFixed 2, if (_cbrnLung > 0) then {_cWarn} else {_cGood}, 7, 7] call _fnKV
    ] joinString "        ");
};

// On ordinary-width displays there is no safe third column. Keep a compact clinical subset visible by appending
// it to the right column; the full raw state set remains available from ACME DEBUG TO CLIPBOARD.
if (!_useStateColumn) then {
    _linesR pushBack "";
    _linesR pushBack format ["<t color='%1'>ACM STATE SUMMARY</t>", _cTitle];
    _linesR append (_linesS select [2, ((count _linesS) - 2) min 16]);
};

// NETWORK.
// it goes last on the right, because it is read when something is wrong rather than while treating.
// every row goes through _fnKV at the same widths as the rest of the overlay, so the values sit in the same two
// vertical lines as the clinical sections above and the eye does not have to re-find the column.
// nothing here is invented. each variable was read out of the NA2 sources before it was displayed, and the ones
// that live in the global namespace as hashmaps are read defensively, so a build without the network layer shows
// an honest "off" rather than an error.
if (missionNamespace getVariable ["ACME_debug_showNetwork", true]) then {
    _linesR pushBack "";
    _linesR pushBack format ["<t color='%1'>NETWORK</t>", _cSect];

    // the machine's own role. these never change during a mission and they frame everything below.
    private _isSrv = isServer;
    private _isDed = isDedicated;
    _linesR pushBack ([
        ["Role", (if (_isDed) then {"dedi"} else {if (_isSrv) then {"host"} else {"client"}}), (if (_isSrv) then {_cGood} else {_cLabel}), 7, 7] call _fnKV,
        ["MP", (if (isMultiplayer) then {"yes"} else {"no"}), (if (isMultiplayer) then {_cGood} else {_cMute}), 7, 7] call _fnKV
    ] joinString "        " );

    // WHO OWNS THE PATIENT. this is the single most useful line on the whole panel when a treatment is not
    // taking. the owner runs the simulation, so a patient owned by another machine will ignore work done here
    // unless it was routed, which is exactly what the NA2 owner layer exists to do.
    private _own = if (isNull _patient) then {-1} else {owner _patient};
    private _isLoc = (!isNull _patient) && {local _patient};
    _linesR pushBack ([
        ["Owner", _own, (if (_isLoc) then {_cGood} else {_cWarn}), 7, 7] call _fnKV,
        ["Local", (if (_isLoc) then {"yes"} else {"no"}), (if (_isLoc) then {_cGood} else {_cWarn}), 7, 7] call _fnKV
    ] joinString "        " );

    // the two network layers. these are INITIALISATION GUARDS set at the top of their own functions, so "on"
    // means the layer loaded here and proves nothing about a round trip reaching anyone else. an "off" with a
    // "yes" on MP above is still the first thing to check.
    private _naChest = missionNamespace getVariable ["ACME_NA2_chestInstalled", false];
    private _naOwner = missionNamespace getVariable ["ACME_NA2_ownerInstalled", false];
    _linesR pushBack ([
        ["Chest", (if (_naChest) then {"on"} else {"off"}), (if (_naChest) then {_cGood} else {_cBad}), 7, 7] call _fnKV,
        ["OwnLyr", (if (_naOwner) then {"on"} else {"off"}), (if (_naOwner) then {_cGood} else {_cBad}), 7, 7] call _fnKV
    ] joinString "        " );

    // OUTSTANDING EDIT REQUESTS. a request is held until the server answers or the thirty second window closes,
    // so a number that sits above zero and does not fall is a stalled round trip rather than a busy medic.
    private _pend = 0;
    private _pendMap = missionNamespace getVariable ["ACME_CS_pending", nil];
    if (!isNil "_pendMap") then { if ((typeName _pendMap) isEqualTo "HASHMAP") then { _pend = count (keys _pendMap); }; };
    // SESSIONS ARE SERVER ONLY. fn_chestSealSession:4 exits unless isServer, so the map is populated on the
    // server and empty everywhere else. a plain 0 on a client reads as nobody treating, which is a lie, so a
    // client shows a dash instead of a number.
    private _sessTxt = "n/a";
    private _sessCol = _cMute;
    if (_isSrv) then {
        private _sess = 0;
        private _sessMap = missionNamespace getVariable ["ACME_CS_sessions", nil];
        if (!isNil "_sessMap") then { if ((typeName _sessMap) isEqualTo "HASHMAP") then { _sess = count (keys _sessMap); }; };
        _sessTxt = str _sess;
        if (_sess > 0) then { _sessCol = _cLabel; };
    };
    // PEND is machine-wide chest seal bookkeeping, not every treatment transaction and not only the patient on
    // screen. the client retries an unacknowledged request every 2 s; the 30 s lifetime is enforced by server
    // rejection rather than by a client timeout, so a number that sits and does not fall is a server that is
    // not answering.
    _linesR pushBack ([
        ["Pend", _pend, (if (_pend > 0) then {_cWarn} else {_cGood}), 7, 7] call _fnKV,
        ["Sess", _sessTxt, _sessCol, 7, 7] call _fnKV
    ] joinString "        " );

    // THE LIVE GESTURE STREAM.
    // this read was WRONG on the first cut. it took ACME_CS_roster, which is a CBA EVENT NAME and has no
    // setVariable writer anywhere in the addon, so the count was permanently zero and the panel reported no
    // viewers while the stream was working normally. a false diagnostic is worse than a blank field.
    // the receiver for that event, fn_chestSealNetInit:22, stores the list under ACME_CS_presenceTargets, and
    // fn_chestSealPresenceSend:39 reads that same variable and subtracts the local viewer before sending. this
    // is that line, copied, so the count means remote recipients rather than the roster including yourself.
    // rate is the configured send INTERVAL in seconds, not measured traffic, latency or delivery. a larger
    // number is slower.
    private _roster = uiNamespace getVariable ["ACME_CS_presenceTargets", []];
    if !(_roster isEqualType []) then { _roster = []; };
    _roster = _roster - [uiNamespace getVariable ["ACME_CS_presenceViewer", player]];
    private _pRate = missionNamespace getVariable ["ACME_CS_presenceRate", 0.07];
    if (!(_pRate isEqualType 0) || {!finite _pRate}) then { _pRate = 0.07; };
    _linesR pushBack ([
        ["Viewers", count _roster, (if ((count _roster) > 0) then {_cGood} else {_cMute}), 7, 7] call _fnKV,
        ["Rate", format ["%1s", _pRate toFixed 2], _cLabel, 7, 7] call _fnKV
    ] joinString "        " );

    // the audit build marker, so a report can name the network revision it came from without guessing.
    private _naRev = missionNamespace getVariable ["ACME_networkAuditRevision", "none"];
    if !(_naRev isEqualType "") then { _naRev = "none"; };
    _linesR pushBack format ["<t color='%1'>net rev %2</t>", _cMute, [_naRev] call _fnSafe];
};

_linesR pushBack format ["<t color='%1'>target follows active treatment</t>", _cMute];
private _fnRenderDebugColumns = {
    params ["_renderScale"];
    _ctrlL ctrlSetStructuredText parseText format ["<t size='%1' font='EtelkaMonospacePro'>%2</t>", _renderScale, _linesL joinString "<br/>"];
    _ctrlR ctrlSetStructuredText parseText format ["<t size='%1' font='EtelkaMonospacePro'>%2</t>", _renderScale, _linesR joinString "<br/>"];
    if (_useStateColumn) then {
        _ctrlS ctrlSetStructuredText parseText format ["<t size='%1' font='EtelkaMonospacePro'>%2</t>", _renderScale, _linesS joinString "<br/>"];
    } else {
        _ctrlS ctrlSetStructuredText parseText "";
    };
};

[_scale] call _fnRenderDebugColumns;
private _requiredH = (ctrlTextHeight _ctrlL) max (ctrlTextHeight _ctrlR);
if (_useStateColumn) then {_requiredH = _requiredH max (ctrlTextHeight _ctrlS);};
if (_requiredH > _h) then {
    // Keep the original wide panel, but scale down only enough to keep every diagnostic row visible.
    private _fitScale = ((_scale * (((_h * 0.985) / _requiredH) min 1)) max 0.42) min _scale;
    [_fitScale] call _fnRenderDebugColumns;
};
