// the per-frame SYNC visual update while the LifePak monitor is open.
// it pulses the green armed led, from dim to bright green, in the indicator slot, and paints small green downward
// arrows, matching the ekg green, above each QRS while armed.
// the ekg is a fixed-column sweep, at 176 columns where ekg_line_x(i) is 801 plus 4 times i px, so the QRS columns
// sit at a stable screen x. we scan the full waveform target array, aed_ekgrefreshdisplay, for r-wave columns,
// meaning the deepest sample of each complex, min-spaced, and center one arrow over each.
// _this is [<DISPLAY>].
params [["_display", displayNull]];
private _canvas = call ACME_fnc_uiCanvas;
_canvas params ["_uiX", "_uiY", "_uiW", "_uiH"];
if (isNull _display) exitWith {};

private _flagCount = missionNamespace getVariable ["ACME_sync_flagCount", 16];
private _flagRows  = missionNamespace getVariable ["ACME_sync_flagRows", 6];
private _tgt = missionNamespace getVariable ["ACM_circulation_AED_Monitor_Target", objNull];
private _armed = (!isNull _tgt) && {uiNamespace getVariable ["ACME_sync_localArmed", _tgt getVariable ["ACME_sync_armed", false]]};

private _fnc_hideAll = {
    for "_i" from 0 to (_flagCount * _flagRows - 1) do {
        private _f = _display displayCtrl (7283210 + _i);
        if (!isNull _f) then { _f ctrlShow false; };
    };
};

// pulse the armed led.
private _led = _display displayCtrl 7283201;
if (!isNull _led) then {
    if (_armed) then {
        private _P = (missionNamespace getVariable ["ACME_sync_ledPulsePeriod", 1.0]) max 0.1;
        private _pulse = 0.5 + 0.5 * sin ((CBA_missionTime / _P) * 360);  // one full dim-bright-dim cycle per _P seconds.
        private _alpha = 0.35 + (0.65 * _pulse);
        _led ctrlSetTextColor (["success", _alpha] call ACME_fnc_a11yColor);
        _led ctrlShow true;
    } else {
        _led ctrlShow false;
    };
};

if (!_armed) exitWith { call _fnc_hideAll };

// scan the displayed buffer, the one the sweep reveals column by column, rather than the full next-pass refresh
// buffer. a QRS only exists in this array once the sweep cursor has drawn it, so a carrot appears as its complex
// is swept in, rather than all the carrots pre-printing before the sweep.
private _ekg = _tgt getVariable ["ACM_circulation_AED_EKGDisplay", []];
private _n = count _ekg;
if (_n < 3) exitWith { call _fnc_hideAll };

// the geometry, replicating pxtoscreen.
private _sizem = 1.05;
private _gw = _uiW * 0.55;
private _gh = _gw * 4/3;
private _gx = _uiX + (_uiW - (_gw * _sizem)) / 2;
private _gy = _uiY + (_uiH - (_gh * _sizem)) / 2;

private _flagYpx = missionNamespace getVariable ["ACME_sync_flagYpx", 570];  // the top of the carrot, just above the r peaks.
private _flagWpx = missionNamespace getVariable ["ACME_sync_flagWpx", 18];  // the total triangle width.
private _flagHpx = missionNamespace getVariable ["ACME_sync_flagHpx", 16];  // the total triangle height.
private _thresh = missionNamespace getVariable ["ACME_sync_qrsThreshold", -25];  // a height below this is an r wave.
private _minSpacing = missionNamespace getVariable ["ACME_sync_minColSpacing", 6];

// find the QRS columns: the deepest sample of each r wave, a local minimum below the threshold, with a minimum
// column spacing so a broad complex yields a single arrow.
private _cols = [];
private _last = -1000;
{
    if (_x < _thresh && {(_forEachIndex - _last) >= _minSpacing}) then {
        private _prev = if (_forEachIndex > 0) then { _ekg select (_forEachIndex - 1) } else { 0 };
        private _next = if (_forEachIndex < (_n - 1)) then { _ekg select (_forEachIndex + 1) } else { 0 };
        if (_x <= _prev && {_x <= _next}) then {
            _cols pushBack _forEachIndex;
            _last = _forEachIndex;
        };
    };
} forEach _ekg;

// draw a small downward triangle over each detected QRS, generated from _flagRows stacked rows: the top row spans
// the full width and each lower row narrows, so the stack points down at the r wave.
private _rowHpx = _flagHpx / _flagRows;
private _fi = 0;
{
    if (_fi < _flagCount) then {
        private _cxpx = 801 + (4 * _x);  // ekg_line_x(col): center it over the r wave.
        for "_r" from 0 to (_flagRows - 1) do {
            private _rowWpx = _flagWpx * (_flagRows - _r) / _flagRows;  // the top is widest, so it points at the bottom.
            private _xpx = _cxpx - (_rowWpx / 2);
            private _ypx = _flagYpx + (_r * _rowHpx);
            private _f = _display displayCtrl (7283210 + _fi * _flagRows + _r);
            if (!isNull _f) then {
                _f ctrlSetPosition [
                    _xpx / 2048 * _gw + _gx,
                    _ypx / 2048 * _gh + _gy,
                    _rowWpx / 2048 * _gw,
                    _rowHpx / 2048 * _gh
                ];
                _f ctrlCommit 0;
                _f ctrlShow true;
            };
        };
        _fi = _fi + 1;
    };
} forEach _cols;

// hide every row of the unused carrots.
for "_i" from (_fi * _flagRows) to (_flagCount * _flagRows - 1) do {
    private _f = _display displayCtrl (7283210 + _i);
    if (!isNull _f) then { _f ctrlShow false; };
};
