/* B66 tandem Body Map / carousel layout.
   Resting: large body + compact carousel. Promoted: body contracts while the same carousel grows.
   The retention zone is strictly bounded below the attached Edit Syringe Tag row and above Draw Syringe. */
disableSerialization;
private _acmeCanvas = call ACME_fnc_uiCanvas;
_acmeCanvas params ["_uiX", "_uiY", "_uiW", "_uiH"];
// UI event handlers may pass a Control in _this. Rendering is intentionally immediate, so never parse _this as a numeric duration.
private _duration = 0;
// Client-performance rule: the prepared-syringe carousel/layout is an instantaneous UI state change.
// ctrlCommit interpolation across dozens of picture/text controls caused visible frame hitches on lower-end clients.
_duration = 0;
private _d = findDisplay 84000;
if (isNull _d) exitWith {};
if ((uiNamespace getVariable ["ACME_SK_View", "syringe"]) != "body") exitWith {};
private _editMode = uiNamespace getVariable ["ACME_SK_TagEditMode",false];
private _expanded = (uiNamespace getVariable ["ACME_SK_CarouselExpanded", false]) || {_editMode};
private _bodyRect = +(_d getVariable [if (_expanded) then {"ACME_SK_BodyRectExpanded"} else {"ACME_SK_BodyRectCompact"}, [0,0,0,0]]);
private _carRect = +(_d getVariable [if (_expanded) then {"ACME_SK_CarouselRectExpanded"} else {"ACME_SK_CarouselRectCompact"}, [0,0,0,0]]);
if ((_bodyRect select 2) <= 0 || {(_carRect select 2) <= 0}) exitWith {};
_d setVariable ["ACME_SK_BodyRect", _bodyRect];
_d setVariable ["ACME_SK_CarouselRect", _carRect];
_d setVariable ["ACME_SK_LayoutBusyUntil", diag_tickTime + (_duration max 0)];

private _group = _d displayCtrl 84140;
if (!isNull _group) then {
    // B69: ctrlShow true on a controls group can transiently reveal EVERY child overlay. Carousel promotion used
    // to do that on every geometry pass, briefly flashing hidden HPMK/AED/etc. Let skUpdateBody exclusively own
    // re-showing/masking the group; layout may only suppress it while the dedicated tag editor is open.
    if (_editMode) then {_group ctrlShow false;};
    _group ctrlSetPosition _bodyRect;
    _group ctrlCommit _duration;
    _bodyRect params ["","","_bw","_bh"];
    {
        if ((ctrlParentControlsGroup _x) isEqualTo _group) then {
            _x ctrlSetPosition [0,0,_bw,_bh];
            _x ctrlCommit _duration;
        };
    } forEach allControls _group;
};

// Patient-name only. Put it in the upper quarter of the actual screen-to-head gap, centered on the body map.
// This keeps visible padding from both the top edge and the head at every UI scale instead of pinning a magic Y.
private _patientHeader = _d displayCtrl 84002;
if (!isNull _patientHeader) then {
    // Body Map owns a patient-name-only header. Reassert it on every layout pass so carousel/view transitions can
    // never leave the native header blank or replace it with a body-part/preparation string.
    private _namePatient = _d getVariable ["ACME_SK_ReturnPatient", objNull];
    if (isNull _namePatient) then {_namePatient = uiNamespace getVariable ["ACME_SK_Patient", objNull];};
    if (!isNull _namePatient) then {_patientHeader ctrlSetText (name _namePatient);};
    private _hr = +(_d getVariable ["ACME_SK_PatientHeaderNativeRect", ctrlPosition _patientHeader]);
    private _screenTop = safeZoneY + safeZoneH*0.004;
    private _headTop = (_bodyRect select 1) + (_bodyRect select 3)*0.055;
    private _available = (_headTop - _screenTop) max (_hr select 3);
    // B68: place the name slightly farther down in the screen-to-head gap while preserving padding to both edges.
    private _headerCenterY = _screenTop + _available*0.30;
    private _minY = _screenTop + safeZoneH*0.003;
    private _maxY = _headTop - (_hr select 3) - safeZoneH*0.008;
    _hr set [0, _uiX + _uiW/2 - (_hr select 2)/2];
    _hr set [1, ((_headerCenterY - (_hr select 3)/2) max _minY) min _maxY];
    _patientHeader ctrlShow (!_editMode);
    _patientHeader ctrlSetPosition _hr;
    _patientHeader ctrlCommit _duration;
};

// B68: raise the body/route/edit stack together to create a clean syringe workspace below it.
private _routeY = safeZoneY + safeZoneH * (if (_expanded) then {0.228} else {0.630});
private _tw = _uiW / 11;
private _th = safeZoneH / 32;
private _tx = _uiX + _uiW / 2 - _tw / 2;
private _gap = 2 * pixelW;
private _half = (_tw - _gap) / 2;
private _routeCtrls = [
    [84155, [_tx,_routeY,_half,_th]],
    [84151, [_tx,_routeY,_half,_th]],
    [84156, [_tx+_half+_gap,_routeY,_half,_th]],
    [84154, [_tx+_half+_gap,_routeY,_half,_th]]
];
{
    private _c = _d displayCtrl (_x select 0);
    if (!isNull _c) then {_c ctrlSetPosition (_x select 1); _c ctrlCommit _duration;};
} forEach _routeCtrls;

// B66: Edit Syringe Tag is geometrically owned by this same layout pass as IV/IO + IM. It therefore moves with
// the route row on both expansion and collapse instead of reading a still-animating ctrlPosition and getting stuck.
private _editGap = safeZoneH*0.004;
private _editRect = [_tx, _routeY + _th + _editGap, _tw, _th];
_d setVariable ["ACME_SK_EditTagBodyRect", _editRect];
if (!_editMode) then {
    private _editBtn = _d displayCtrl 84470;
    if (!isNull _editBtn) then {
        _editBtn ctrlSetPosition _editRect;
        _editBtn ctrlCommit _duration;
    };
};

_carRect params ["_carX","_carY","_carW","_carH"];
private _zone = _d displayCtrl 84481;
if (!isNull _zone) then {
    // Retention/hit space begins below Edit Syringe Tag and ends safely ABOVE Draw Syringe. Never force a minimum
    // height that can cross the button when UI scale is unusual.
    private _zoneY = (_editRect select 1) + (_editRect select 3) + safeZoneH*0.007;
    private _actionCtrl = _d displayCtrl 84820;
    private _durationCtrl = _d displayCtrl 84830;
    private _boundCtrl = if (!isNull _durationCtrl && {ctrlShown _durationCtrl}) then {_durationCtrl} else {_actionCtrl};
    private _boundRect = if (!isNull _boundCtrl) then {ctrlPosition _boundCtrl} else {ctrlPosition (_d displayCtrl 84150)};
    private _zoneBottom = (_boundRect select 1) - safeZoneH*0.012;
    private _zoneH = (_zoneBottom - _zoneY) max 0;
    _zone ctrlSetPosition [_carX,_zoneY,_carW,_zoneH];
    private _zoneUsable = !_editMode && {_zoneH > 4*pixelH};
    _zone ctrlShow _zoneUsable;
    _zone ctrlEnable _zoneUsable;
    _zone ctrlCommit _duration;
};
