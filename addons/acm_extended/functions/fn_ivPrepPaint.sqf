/* Uniform alcohol redness in a permanent layer below bands, bruises and IV marks.
   A swept, soft-edged footprint fills a non-overlapping grid. Repeated passes
   refresh the same coverage; speed, random offsets and alpha stacking cannot
   produce blotches. The bounded visual grid never caps the medic's scrub work. */
disableSerialization;
params ["_fx", "_fy"];
private _dlg = uiNamespace getVariable ["ACME_IV_DLG", displayNull];
if (isNull _dlg) exitWith {0};
private _rect = uiNamespace getVariable ["ACME_IV_BodyRect", []];
if (count _rect < 4) exitWith {0};
_rect params ["_bx", "_by", "_bw", "_bh"];
private _layer = _dlg displayCtrl 86508;
// Never fall back to creating redness on top of clinical marks.
if (isNull _layer) exitWith {uiNamespace getVariable ["ACME_IV_PrepTotal", 0]};
private _layerPos = ctrlPosition _layer;
private _lx = _layerPos select 0;
private _ly = _layerPos select 1;
private _af = uiNamespace getVariable ["ACME_IV_AspectFix", 0.5625];
private _total = uiNamespace getVariable ["ACME_IV_PrepTotal", 0];
private _last = uiNamespace getVariable ["ACME_IV_PrepLast", []];
private _fresh = count _last < 3;
private _dist = if (_fresh) then {0} else {sqrt ((_fx - (_last select 0))^2 + (_fy - (_last select 1))^2)};
private _step = missionNamespace getVariable ["ACME_iv_prepSpacing", 0.011];
if (!_fresh && {_dist <= (_step max 0.003)}) exitWith {_total};
// A cursor teleport does not paint a stripe through skin never scrubbed.
if (_dist > 0.20) then {_fresh = true;};
_total = _total + 1;
uiNamespace setVariable ["ACME_IV_PrepTotal", _total];
private _sum = uiNamespace getVariable ["ACME_IV_PrepSum", [0,0]];
_sum = [(_sum select 0) + _fx, (_sum select 1) + _fy];
uiNamespace setVariable ["ACME_IV_PrepSum", _sum];
uiNamespace setVariable ["ACME_IV_PrepLast", [_fx, _fy, diag_tickTime]];

private _cells = uiNamespace getVariable ["ACME_IV_PrepCells", createHashMap];
private _ctrls = uiNamespace getVariable ["ACME_IV_PrepCtrls", []];
private _cell = 0.008;
private _cap = 768;
private _radius = ((missionNamespace getVariable ["ACME_iv_prepDabSize", 0.032]) * 0.5) max _cell;
private _alpha = ((missionNamespace getVariable ["ACME_iv_prepDabAlpha", 0.085]) max 0.01) min 0.25;
private _tint = missionNamespace getVariable ["ACME_iv_prepTint", [0.80,0.42,0.40]];
private _samples = if (_fresh) then {1} else {(ceil (_dist / (_cell * 0.5))) max 1 min 48};
private _sweep = createHashMap;
for "_sample" from 1 to _samples do {
    private _f = _sample / _samples;
    private _u = if (_fresh) then {_fx} else {(_last select 0) + (_fx - (_last select 0)) * _f};
    private _v = if (_fresh) then {_fy} else {(_last select 1) + (_fy - (_last select 1)) * _f};
    for "_gx" from (floor ((_u - _radius) / _cell)) to (floor ((_u + _radius) / _cell)) do {
        for "_gy" from (floor ((_v - _radius) / _cell)) to (floor ((_v + _radius) / _cell)) do {
            private _cu = (_gx + 0.5) * _cell;
            private _cv = (_gy + 0.5) * _cell;
            private _distance = sqrt ((_cu - _u)^2 + (_cv - _v)^2);
            private _coverage = (( _radius - _distance) / (_cell * 0.75)) max 0 min 1;
            if (_coverage > 0.001 && {_cu >= 0} && {_cu <= 1} && {_cv >= 0} && {_cv <= 1}) then {
                private _ck = format ["%1#%2", _gx, _gy];
                private _oldCoverage = (_sweep getOrDefault [_ck, [0,0,0]]) select 2;
                _sweep set [_ck, [_gx, _gy, _coverage max _oldCoverage]];
            };
        };
    };
};
// Apply each cell only once per input sample, even when swept footprints overlap.
{
    private _ck = _x;
    _y params ["_gx", "_gy", "_coverage"];
    private _known = _cells getOrDefault [_ck, []];
    if (_known isEqualTo [] && {count _cells >= _cap}) then {
        private _oldest = "";
        private _oldTime = 1e12;
        {private _t = _y param [1,0]; if (_t < _oldTime) then {_oldTime = _t; _oldest = _x;};} forEach _cells;
        if (_oldest != "") then {
            private _oldCtrl = (_cells get _oldest) param [0,controlNull];
            if (!isNull _oldCtrl) then {ctrlDelete _oldCtrl;};
            _cells deleteAt _oldest;
        };
    };
    private _c = _known param [0,controlNull];
    if (isNull _c) then {
        _c = _dlg ctrlCreate ["ACME_IV_Clean", -1, _layer];
        _c ctrlSetText "#(argb,8,8,3)color(1,1,1,1)";
        // Shared grid boundaries never overlap: revisiting a patch
        // cannot multiply its opacity or hide a puncture above it.
        _c ctrlSetPosition [_bx + _bw * _gx * _cell - _lx, _by + _bh * _gy * _cell - _ly, _bw * _cell, _bh * _cell];
        _c ctrlEnable false;
        _known = [_c, diag_tickTime, 0, 1, 0];
        _ctrls pushBack _known;
        _cells set [_ck, _known];
    };
    _coverage = _coverage max (_known param [4,0]);
    _known set [1, diag_tickTime];
    _known set [2, _alpha * _coverage];
    _known set [4, _coverage];
    _c ctrlSetTextColor [_tint select 0, _tint select 1, _tint select 2, _alpha * _coverage];
    _c ctrlCommit 0;
    _c ctrlShow true;
} forEach _sweep;
_ctrls = _ctrls select {!isNull (_x param [0,controlNull])};
uiNamespace setVariable ["ACME_IV_PrepCtrls", _ctrls];
uiNamespace setVariable ["ACME_IV_PrepCells", _cells];

// Skin prep may leave transient antiseptic redness, but it is not an IV injury. A successful cannulation must not
// acquire a bruise merely because the provider scrubbed the site. Bruising is reserved for a missed/blown stick,
// infiltration or extravasation. Hide the legacy prep-bruise control if an older view cache created one.
private _prepBruise = uiNamespace getVariable ["ACME_IV_PrepBruise", controlNull];
if (!isNull _prepBruise) then {
    _prepBruise ctrlSetTextColor [1,1,1,0];
    _prepBruise ctrlShow false;
    _prepBruise ctrlCommit 0;
};
_total
