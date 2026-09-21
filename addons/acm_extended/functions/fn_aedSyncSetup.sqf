// the onload hook for ACM's LifePak monitor dialog. ACM left its onload empty, so we repurpose it.
// it builds the SYNC key, its green armed led, and a pool of QRS sync-flag ticks at runtime rather than patching
// the controls of the dialog. re-opening the control list of an ACM display risks dropping inherited members, per
// the body-image lesson. then it starts a per-frame handler that paints the flags above each QRS while SYNC is
// armed. the controls die with the display, so a fresh monitor re-creates them, with no leak and no config risk.
// _this is a display, or [display].
params [["_display", displayNull]];
private _canvas = call ACME_fnc_uiCanvas;
_canvas params ["_uiX", "_uiY", "_uiW", "_uiH"];
if (_display isEqualType []) then { _display = _display param [0, displayNull]; };
if (isNull _display) then { _display = uiNamespace getVariable ["ACM_circulation_AEDMonitor_DLG", displayNull]; };
if (isNull _display) exitWith {};

// pxtoscreen, replicated in sqf, because the config coordinate macros are not available at runtime. there are two
// mappings, matching ACM's defines exactly.
// _fnc_px maps the ekg px-grid, grid_w. use it for anything that must line up with the waveform.
// _fnc_pxBG maps the background texture, grid_w times sizem. ACM draws the LifePak panel 1.05 times wider than the
// px-grid, anchored at the same left edge, so printed features, the SYNC label and its indicator slot, sit
// progressively right of the px-grid. the drift grows with the screen width, which is why the led looked low and
// left in 32:9. the SYNC hotspot and led must map through the background rather than the px-grid.
private _sizem = 1.05;  // acm_gui_aed_sizem.
private _gw = _uiW * 0.55;
private _gh = _gw * 4 / 3;
private _gx = _uiX + (_uiW - (_gw * _sizem)) / 2;
private _gy = _uiY + (_uiH - (_gh * _sizem)) / 2;
private _fnc_px = {
    params ["_px", "_py", "_pw", "_ph"];
    [_px / 2048 * _gw + _gx, _py / 2048 * _gh + _gy, _pw / 2048 * _gw, _ph / 2048 * _gh]
};
private _fnc_pxBG = {
    params ["_px", "_py", "_pw", "_ph"];
    [_px / 2048 * (_gw * _sizem) + _gx, _py / 2048 * (_gh * _sizem) + _gy, _pw / 2048 * (_gw * _sizem), _ph / 2048 * (_gh * _sizem)]
};

// the SYNC key hotspot: a transparent RscButton over the LifePak SYNC button. the positions are pixel coordinates
// on the 2048-wide panel texture and are tunable at runtime, through ACME_sync_btnPx as [x, y, w, h] and
// ACME_sync_ledPx as [x, y, w, h]. they are untested estimates.
private _btnPx = missionNamespace getVariable ["ACME_sync_btnPx", [1548, 704, 134, 53]];
private _ledPx = missionNamespace getVariable ["ACME_sync_ledPx", [1564, 719, 30, 30]];

private _btn = _display ctrlCreate ["ACME_AEDSyncButton", 7283200];
_btn ctrlSetPosition (_btnPx call _fnc_pxBG);
_btn ctrlSetText "";
_btn ctrlSetBackgroundColor [0, 0, 0, 0];
_btn ctrlSetTextColor [0, 0, 0, 0];
private _hcDescriptors = ((missionNamespace getVariable ["ACME_hc_descriptors", false]) isEqualTo true);
private _syncTooltip = ["Synchronized Cardiovert", "SYNC"] select _hcDescriptors;
_btn ctrlSetTooltip _syncTooltip;
_btn ctrlCommit 0;
_btn ctrlAddEventHandler ["ButtonClick", { call ACME_fnc_syncToggle }];

// the green SYNC armed led: a dot in the gray indicator slot left of the SYNC text, pulsing between dim and bright
// green, which the per-frame tick handles.
// note that it is mapped through _fnc_pxBG, the background scale, rather than the px-grid. the printed SYNC label
// and slot sit on the 1.05x background, so the px-grid mapping put the led about 40 px left of the slot, which is
// why earlier size and position tweaks never seemed to move it: they were swamped by that drift. the texture and
// rect are tunable.
private _led = _display ctrlCreate ["RscPicture", 7283201];
_led ctrlSetPosition (_ledPx call _fnc_pxBG);
_led ctrlSetText (missionNamespace getVariable ["ACME_sync_ledTexture", "#(argb,8,8,3)color(1,1,1,1)"]);
_led ctrlSetTextColor (["success", 1] call ACME_fnc_a11yColor);
_led ctrlCommit 0;
private _tgt = missionNamespace getVariable ["ACM_circulation_AED_Monitor_Target", objNull];
private _initialArmed = !isNull _tgt && {_tgt getVariable ["ACME_sync_armed", false]};
uiNamespace setVariable ["ACME_sync_localArmed", _initialArmed];
_led ctrlShow _initialArmed;

// the flag pool. each QRS carrot is a small downward triangle generated from stacked procedural-fill rows, with the
// top row widest, narrowing to a point, because the solid-fill picture renders reliably where the structured-text
// glyph did not. there are _rows rows per carrot, and the idc is 7283210 plus carrot times _rows plus row.
private _flagCount = missionNamespace getVariable ["ACME_sync_flagCount", 16];
private _flagRows  = missionNamespace getVariable ["ACME_sync_flagRows", 6];
private _flagColor = ["success", 1] call ACME_fnc_a11yColor;
for "_i" from 0 to (_flagCount - 1) do {
    for "_r" from 0 to (_flagRows - 1) do {
        private _f = _display ctrlCreate ["RscPicture", 7283210 + _i * _flagRows + _r];
        _f ctrlSetText "#(argb,8,8,3)color(1,1,1,1)";
        _f ctrlSetTextColor _flagColor;
        _f ctrlShow false;
        _f ctrlCommit 0;
    };
};

// paint the flags while SYNC is armed, and self-terminate when the display closes.
[{
    params ["_args", "_idPFH"];
    _args params ["_display"];
    if (isNull _display) exitWith { [_idPFH] call CBA_fnc_removePerFrameHandler; };
    [_display] call ACME_fnc_syncFlagsTick;
}, 0.1, [_display]] call CBA_fnc_addPerFrameHandler;
