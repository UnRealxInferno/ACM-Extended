// start a compound syringe draw. the syringe begins empty, with the plunger at the top. you select a drug, drag the
// plunger down to draw it, and press "Draw" to lock that component in, which advances the plunger floor to the
// current fill. select another drug, draw again on top, and so on up to the syringe capacity. "Save" commits the
// whole mixed syringe to the drawn list with a generated label, and named products such as ketofol are recognized
// by their exact recipe.
// this reuses the flush waste plunger machinery, in the "compound" stage.
// call ACME_fnc_skCompoundBegin.
disableSerialization;
private _acmeCanvas = call ACME_fnc_uiCanvas;
_acmeCanvas params ["_uiX", "_uiY", "_uiW", "_uiH"];
private _dlg = findDisplay 84000;
if (isNull _dlg) exitWith {};

// if a flush waste flow is active, leave it first.
if ((uiNamespace getVariable ["ACME_SK_WasteStage", ""]) != "") then { [] call ACME_fnc_skWasteEnd; };

private _size = ACM_circulation_SyringeDraw_Size;
private _cap = _size;
uiNamespace setVariable ["ACME_SK_WasteCap", _cap];
uiNamespace setVariable ["ACME_SK_WasteStage", "compound"];  // it shares the plunger pfh with the flush flow.
uiNamespace setVariable ["ACME_SK_WasteFloorMl", 0];  // it starts empty and advances as components lock in.
uiNamespace setVariable ["ACME_SK_WasteMoving", false];
uiNamespace setVariable ["ACME_SK_WasteFill", 0];
["clear", "", 0, _dlg] call ACME_fnc_vialSession;
uiNamespace setVariable ["ACME_SK_CompoundComponents", []];  // the list of [med, ml] locked in so far.
uiNamespace setVariable ["ACME_SK_CompoundVials", []];  // the vials consumed, removed only on save.
uiNamespace setVariable ["ACME_SK_CompoundDrawCount", 0];

// the full-barrel plunger travel.
ACM_circulation_SyringeDraw_MaxDose = _cap;

// the geometry comes from ACM.
private _limitTop    = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Ctrl_LimitTop", -1];
private _limitBottom = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Ctrl_LimitBottom", -1];
private _plungerVisIdc = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Ctrl_PlungerVisual", -1];
private _adjust = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Ctrl_PlungerAdjustment", 0];
if (_limitTop < 0 || {_limitBottom < 0}) exitWith {
    ["Draw dialog not ready. Reopen and try again.", 2.5, ACE_player, 13] call ace_common_fnc_displayTextStructured;
};

// seat the plunger at the top, meaning empty.
private _plunger = _dlg displayCtrl 84009;
private _plungerVis = _dlg displayCtrl _plungerVisIdc;
(ctrlPosition _plunger) params ["_px", "", "_pw", "_ph"];
_plunger ctrlSetPosition [_px, _limitTop, _pw, _ph];
_plunger ctrlCommit 0;
if (!isNull _plungerVis) then {
    (ctrlPosition _plungerVis) params ["_vx", "", "_vw", "_vh"];
    _plungerVis ctrlSetPosition [_vx, (_limitTop - _adjust), _vw, _vh];
    _plungerVis ctrlCommit 0;
};
ACM_circulation_SyringeDraw_DrawnAmount = 0;
ACM_circulation_SyringeDraw_Moving = false;

// the plunger is draggable through the shared waste toggle and pfh.
_plunger ctrlSetEventHandler ["MouseButtonUp", "call ACME_fnc_skWasteToggleMove"];
_plunger ctrlSetTooltip "Click to grab the plunger, drag down to draw, click again to release";

// button 84003 becomes "Draw", which adds a component, and button 84004 becomes "Save", which commits the
// compound.
private _btnDraw = _dlg displayCtrl 84003;
if (!isNull _btnDraw) then {
    _btnDraw ctrlSetText "Draw";
    _btnDraw ctrlSetBackgroundColor [0.05,0.05,0.05,0.65];
    _btnDraw ctrlSetTooltip "Draw the selected drug into the syringe (locks it in as a component)";
    _btnDraw ctrlEnable true;
    _btnDraw ctrlSetEventHandler ["ButtonClick", "call ACME_fnc_skCompoundDraw"];
    _btnDraw ctrlCommit 0;
};
private _btnSave = _dlg displayCtrl 84004;
if (!isNull _btnSave) then {
    _btnSave ctrlShow true;
    _btnSave ctrlEnable true;
    _btnSave ctrlSetText "Save";
    _btnSave ctrlSetBackgroundColor [0.05,0.05,0.05,0.65];
    _btnSave ctrlSetTooltip "Save the compound syringe to the Syringe Menu";
    _btnSave ctrlSetEventHandler ["ButtonClick", "call ACME_fnc_skCompoundSave"];
    _btnSave ctrlCommit 0;
};
// hide inject during compounding.
private _btnInj = _dlg displayCtrl 84005;
if (!isNull _btnInj) then { _btnInj ctrlShow false; _btnInj ctrlEnable false; };


// start the shared plunger pfh, the same one the flush uses. it clamps the plunger between the current floor and
// the capacity, and in compound mode the floor is the accumulated fill, so each new draw pulls on top of the
// last.
private _old = uiNamespace getVariable ["ACME_SK_WastePFH", -1];
if (_old >= 0) then { [_old] call CBA_fnc_removePerFrameHandler; };
private _h = [{
    params ["_a", "_hid"];
    private _d = findDisplay 84000;
    private _stage = uiNamespace getVariable ["ACME_SK_WasteStage", ""];
    if (isNull _d || {!(_stage in ["waste", "draw", "compound"])}) exitWith {
        [_hid] call CBA_fnc_removePerFrameHandler;
        uiNamespace setVariable ["ACME_SK_WastePFH", -1];
    };

    // compound. ACM's own draw loop grays the medication list the instant anything is in the barrel, because in ACM's
    // model one syringe is one drug. for compounding we want to pick the next drug with a partial syringe, so while
    // the plunger is not being dragged, the list is forced back on every frame. this is what lets you add a second and
    // third drug instead of the list staying grayed after the first draw. during an active drag it stays grayed, so
    // the drug cannot be swapped mid-pull.
    if (_stage == "compound" && {!(uiNamespace getVariable ["ACME_SK_WasteMoving", false])}) then {
        private _ml  = _d displayCtrl 84006;
        private _mlb = _d displayCtrl 84007;
        if (!isNull _ml  && {!(ctrlEnabled _ml)})  then { _ml  ctrlEnable true; };
        if (!isNull _mlb && {!(ctrlEnabled _mlb)}) then { _mlb ctrlEnable true; };
        // pick up a newly chosen drug ourselves. ACM's loop only refreshes the selected medication when the barrel is
        // empty, and with a partial compound syringe it grays out and stops tracking, so we read the list selection and
        // set the drawn medication and its maxdose directly, exactly as ACM's _fnc_updateselectedmedication does.
        if (!isNull _ml) then {
            private _sel = lbCurSel _ml;
            if (_sel >= 0) then {
                private _selMed = _ml lbData _sel;
                if (_selMed != "" && {_selMed != ACM_circulation_SyringeDraw_Medication}) then {
                    ACM_circulation_SyringeDraw_Medication = _selMed;
                    ACM_circulation_SyringeDraw_MedicationSelected = true;
                    // keep the plunger travel bounded by the full syringe, because a compound draws multiple drugs, rather than by the
                    // volume of a single vial.
                    ACM_circulation_SyringeDraw_MaxDose = ACM_circulation_SyringeDraw_Size;
                };
            };
        };
    };

    if !(uiNamespace getVariable ["ACME_SK_WasteMoving", false]) exitWith {};

    private _cap = uiNamespace getVariable ["ACME_SK_WasteCap", 10];
    private _size = ACM_circulation_SyringeDraw_Size;
    private _floorMl = uiNamespace getVariable ["ACME_SK_WasteFloorMl", 0];
    private _limitTop    = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Ctrl_LimitTop", -1];
    private _limitBottom = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Ctrl_LimitBottom", -1];
    private _adjust = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Ctrl_PlungerAdjustment", 0];
    private _visIdc = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Ctrl_PlungerVisual", -1];
    private _plunger = _d displayCtrl 84009;
    private _plungerVis = _d displayCtrl _visIdc;
    if (isNull _plunger) exitWith {};

    // in compound mode the floor is the bottom of the allowed travel, because you can only draw more and never push
    // back a locked component. the plunger moves between the floor, the minimum fill, and the capacity, the maximum
    // fill.
    private _floorY = linearConversion [0, _size, _floorMl, _limitTop, _limitBottom, true];
    // B25: the current syringe is allowed to draw only from vials the provider has explicitly selected.
    // One click binds one physical vial. The plunger stops at 0.00 mL for that vial; clicking the medication again
    // deliberately unlocks the next vial. There is no automatic rollover through inventory.
    private _medNow = ACM_circulation_SyringeDraw_Medication;
    private _lockedSame = 0;
    if (!isNil "_medNow" && {_medNow != ""}) then {
        {if ((_x param [0,""]) == _medNow) then {_lockedSame = _lockedSame + (_x param [1,0]);};} forEach (uiNamespace getVariable ["ACME_SK_CompoundComponents", []]);
    };
    private _unlockedForMed = if (isNil "_medNow" || {_medNow == ""}) then {0} else {["limit", _medNow, _lockedSame + (((uiNamespace getVariable ["ACME_SK_WasteFill",_floorMl]) - _floorMl) max 0), _d] call ACME_fnc_vialSession};
    private _newAvailable = (_unlockedForMed - _lockedSame) max 0;
    private _maxFill = (_floorMl + ((_size - _floorMl) min _newAvailable)) max _floorMl min _size;
    private _maxY = linearConversion [0, _size, _maxFill, _limitTop, _limitBottom, true];
    ACM_circulation_SyringeDraw_MaxDose = _maxFill;

    // Use the actual grab-control center for both mouse bounds and plunger motion. The previous loop added
    // ACM's bottom-bound padding back to the computed fill every frame, even within the barrel. That padding
    // is larger than half the control height, so a stationary mouse fed itself downward until the syringe filled.
    // Like the native infusion draw, clamp the incoming cursor only; never move it to a fill-derived position.
    (ctrlPosition _plunger) params ["_plungerX", "", "_plungerW", "_plungerH"];
    private _mouseOffset = _plungerH / 2;
    private _bottomMouse = _maxY + _mouseOffset;
    private _floorYMouse = _floorY + _mouseOffset;
    getMousePosition params ["_mouseX", "_mouseY"];
    // Preserve ACM's sticky-plunger behavior, but anchor the hardware cursor to the ACTUAL grab-control center.
    // The old canvas-center anchor became wrong after the in-place Narc Box/page geometry changes and could pin the
    // cursor far above the syringe. X follows the plunger center; Y is constrained to the valid draw travel.
    private _mouseYClamped = _bottomMouse min _mouseY max _floorYMouse;
    setMousePosition [_plungerX + (_plungerW / 2), _mouseYClamped];
    private _rawY = (_mouseYClamped - _mouseOffset) min _maxY max _floorY;
    private _rawFill = linearConversion [_limitTop, _limitBottom, _rawY, 0, _size, true];

    // B25: use ACM-like direct plunger motion. Returning medication toward the vial follows the hand normally;
    // only the physical vial and syringe boundaries clamp the travel.
    private _fill = _rawFill max _floorMl min _maxFill;
    private _newY = linearConversion [0, _size, _fill, _limitTop, _limitBottom, true];
    // B70: linear conversion/mouse-center rounding can strand ~0.01 mL above the current component floor. When the
    // hand is physically at that floor, snap to the exact floor value. This is not resistance or dose rounding: it
    // only resolves the endpoint and therefore allows the current medication to be returned completely.
    if ((_rawY - _floorY) <= (2 * pixelH) && {(_fill - _floorMl) <= 0.015}) then {
        _fill = _floorMl;
        _newY = _floorY;
    };
    // B73: the opposite endpoint matters just as much: when the hand reaches the current vial's physical draw limit,
    // snap the final <=0.01 mL into the syringe. This makes the vial actually read 0.00 instead of stranding 0.01.
    if ((_maxY - _rawY) <= (2 * pixelH) && {(_maxFill - _fill) <= 0.015}) then {
        _fill = _maxFill;
        _newY = _maxY;
    };

    _plunger ctrlSetPosition [_plungerX, _newY, _plungerW, _plungerH];
    _plunger ctrlCommit 0;
    if (!isNull _plungerVis) then {
        (ctrlPosition _plungerVis) params ["_vx", "", "_vw", "_vh"];
        _plungerVis ctrlSetPosition [_vx, (_newY - _adjust), _vw, _vh];
        _plungerVis ctrlCommit 0;
    };
    ACM_circulation_SyringeDraw_DrawnAmount = _fill;
    uiNamespace setVariable ["ACME_SK_WasteFill", _fill];
}, 0, []] call CBA_fnc_addPerFrameHandler;
uiNamespace setVariable ["ACME_SK_WastePFH", _h];
