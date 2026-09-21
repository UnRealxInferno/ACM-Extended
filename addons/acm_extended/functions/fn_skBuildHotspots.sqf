/* Reuse native patient artwork; tint only selectable IV/IO and IM overlays.
   The UI tick refreshes native clinical state separately and never publishes it. */
disableSerialization;
private _display = findDisplay 84000;
if (isNull _display) exitWith {};
private _group = _display displayCtrl 84140;
private _patient = _display getVariable ["ACME_SK_ReturnPatient", objNull];
if (isNull _patient) then {_patient = ACE_player;};
private _body = (uiNamespace getVariable ["ACME_SK_View", "syringe"]) == "body";
private _tagEditMode = uiNamespace getVariable ["ACME_SK_TagEditMode", false];
private _carouselBusy = uiNamespace getVariable ["ACME_SK_CarouselBusy", false];
private _layoutReady = diag_tickTime >= (_display getVariable ["ACME_SK_LayoutBusyUntil", 0]);
private _route = uiNamespace getVariable ["ACME_SK_Route", "vascular"];
private _flush = uiNamespace getVariable ["ACME_SK_SelFlush", ""];
if (_flush != "") then {_route = "vascular"; uiNamespace setVariable ["ACME_SK_Route", _route];};
private _syringeStore = [ACE_player] call ACME_fnc_skStoreEnsureIds;
// Resolve the same fallback selection the carousel uses. Requiring a pre-existing stable ID here could leave
// the route visually selected while every site stayed hidden until the carousel happened to repaint first.
private _syringeIndex = [_syringeStore] call ACME_fnc_skSelectedIndex;
private _deliveryReady = (_flush != "") || {_syringeIndex >= 0};
private _routeChanged = (_display getVariable ["ACME_SK_LastRoute", ""]) != _route;
_display setVariable ["ACME_SK_LastRoute", _route];
[_display, _routeChanged] call ACME_fnc_skUpdateBody;
private _rect = _display getVariable ["ACME_SK_BodyRect", [0,0,0,0]];
_rect params ["_bx", "_by", "_bw", "_bh"];
// fn_skUpdateBody owns group visibility. Never re-show it after applying patient masks.
// Split route selector: selected side green, unselected side grey. A selected flush is necessarily vascular, so
// the IM side is disabled until the flush is cleared.
private _ivBtn = _display displayCtrl 84151;
private _imBtn = _display displayCtrl 84154;
private _ivBack = _display displayCtrl 84155;
private _imBack = _display displayCtrl 84156;
private _green = [0.20,0.65,0.20,0.92];
private _gray = [0.20,0.20,0.20,0.72];
if (!isNull _ivBack) then {_ivBack ctrlSetBackgroundColor (if (_route == "vascular") then {_green} else {_gray});};
if (!isNull _imBack) then {_imBack ctrlSetBackgroundColor (if (_route == "im") then {_green} else {_gray});};
if (!isNull _ivBtn) then {
    _ivBtn ctrlSetText "IV / IO";
    _ivBtn ctrlEnable true;
    _ivBtn ctrlSetTextColor [1,1,1,1];
};
if (!isNull _imBtn) then {
    _imBtn ctrlSetText "IM";
    _imBtn ctrlEnable (_flush == "");
    _imBtn ctrlSetTextColor (if (_flush == "") then {[1,1,1,1]} else {[0.6,0.6,0.6,1]});
};
[] call ACME_fnc_skEpinephrineDose;
private _imColor = +(missionNamespace getVariable ["ACME_SK_IMColor", [0.28, 0.60, 1, 0.42]]);
// Match ACM's circulation/body-map green for selectable vascular access. IM keeps its existing blue aura.
private _vascularColor = [0.20, 0.65, 0.20, 0.42];
{
    _x params ["", "_part", "_site", "_imageID", "_inputID", "_uv"];
    private _input = _display displayCtrl _inputID;
    private _image = _group controlsGroupCtrl _imageID;
    private _have = if (_site < 0) then {[_patient, _part, 0] call ACM_circulation_fnc_hasIO} else {[_patient, _part, 0, _site] call ACM_circulation_fnc_hasIV};
    private _show = _body && {!_tagEditMode} && {!_carouselBusy} && {_layoutReady} && {_deliveryReady} && {_route == "vascular"} && {_have} && {!isNull _image} && {ctrlShown _image};
    _input ctrlShow _show;
    _input ctrlEnable _show;
    if (!_show) then {_input setVariable ["ACME_SK_Hover", false];};
    if (_have && {!isNull _image}) then {
        private _tint = +_vascularColor;
        _tint set [3, if (_show && {_input getVariable ["ACME_SK_Hover", false]}) then {1} else {0.42}];
        _image ctrlSetTextColor _tint;
    };
    _uv params ["_u", "_v", "_w", "_h"];
    // Two physical pixels of tolerance around the nontransparent artwork.
    _input ctrlSetPosition [_bx + _u * _bw - 2 * pixelW, _by + _v * _bh - 2 * pixelH, _w * _bw + 4 * pixelW, _h * _bh + 4 * pixelH];
    _input ctrlCommit 0;
    _input ctrlSetTooltip ([_part, _site max 0, _site < 0] call ACME_fnc_skSiteName);
} forEach (call ACME_fnc_skSiteGeometry);
{
    _x params ["_part", "_imageID", "_inputID", "_uv"];
    private _image = _group controlsGroupCtrl _imageID;
    private _input = _display displayCtrl _inputID;
    // IM is an anatomical route, not an existing-access route. Selecting IM should always reveal its valid
    // muscle targets. The actual administration path still verifies that a prepared syringe exists before staging.
    private _show = _body && {!_tagEditMode} && {!_carouselBusy} && {_layoutReady} && {_route == "im"};
    if (!isNull _input) then {
        _input ctrlShow _show;
        _input ctrlEnable _show;
        if (!_show) then {_input setVariable ["ACME_SK_Hover", false];};
    };
    private _tint = +_imColor;
    _tint set [3, if (!isNull _input && {_input getVariable ["ACME_SK_Hover", false]}) then {1} else {0.42}];
    if (_show && {!isNull _image}) then {
        // updateBodyImage repaints the native limb colors every refresh. Reassert the IM blue after that repaint.
        _image ctrlShow true;
        _image ctrlSetTextColor _tint;
    };
    _uv params ["_u", "_v", "_w", "_h"];
    if (!isNull _input) then {
        _input ctrlSetPosition [_bx + _u * _bw, _by + _v * _bh, _w * _bw, _h * _bh];
        _input ctrlCommit 0;
        _input ctrlSetTooltip format ["%1 (IM)", [_part, "short"] call ACME_fnc_bodyPartName];
    };
} forEach (call ACME_fnc_skIMGeometry);
