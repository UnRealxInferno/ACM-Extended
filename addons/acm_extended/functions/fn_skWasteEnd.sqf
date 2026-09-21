// exit the saline-flush waste flow and return the draw dialog to a normal empty syringe.
// it clears the waste state, which stops the plunger pfh on its next tick, restores the own plunger move handler and
// draw button of ACM, re-shows push and inject, re-enables the drug menu, and zeroes the fill. it is safe to call
// defensively, on a size switch or a teardown.
// call it as [] call ACME_fnc_skWasteEnd.
disableSerialization;
private _dlg = findDisplay 84000;

uiNamespace setVariable ["ACME_SK_WasteStage", ""];
uiNamespace setVariable ["ACME_SK_WasteMoving", false];
uiNamespace setVariable ["ACME_SK_WasteFloorMl", 0];
uiNamespace setVariable ["ACME_SK_WasteFill", 0];
uiNamespace setVariable ["ACME_SK_WasteNS", 0];
uiNamespace setVariable ["ACME_SK_CompoundComponents", []];
uiNamespace setVariable ["ACME_SK_CompoundVials", []];
uiNamespace setVariable ["ACME_SK_CompoundDrawCount", 0];
private _pfh = uiNamespace getVariable ["ACME_SK_WastePFH", -1];
if (_pfh >= 0) then { [_pfh] call CBA_fnc_removePerFrameHandler; uiNamespace setVariable ["ACME_SK_WastePFH", -1]; };

ACM_circulation_SyringeDraw_DrawnAmount = 0;
ACM_circulation_SyringeDraw_Moving = false;

if (isNull _dlg) exitWith {};
// restore the own plunger move handler of ACM, onmousebuttonup into syringe_draw_move, and clear the tooltip.
private _plunger = _dlg displayCtrl 84009;
if (!isNull _plunger) then {
    _plunger ctrlSetEventHandler ["MouseButtonUp", "call ACM_circulation_fnc_Syringe_Draw_Move"];
    _plunger ctrlSetTooltip "";
};

// re-enable the drug menu.
private _medList = _dlg displayCtrl 84006;
if (!isNull _medList) then { _medList ctrlEnable true; };
private _medListBtn = _dlg displayCtrl 84007;
if (!isNull _medListBtn) then { _medListBtn ctrlEnable true; };

// restore the normal draw button of ACM, and re-show push and inject.
private _btn = _dlg displayCtrl 84003;
if (!isNull _btn) then {
    _btn ctrlSetText "Draw";
    _btn ctrlSetTooltip "";
    _btn ctrlEnable true;
    _btn ctrlSetEventHandler ["ButtonClick", "[0] call ACM_circulation_fnc_Syringe_Draw_Button"];
    _btn ctrlCommit 0;
};
// restore the push button, 84004, to its normal state, and re-show inject, 84005.
private _push = _dlg displayCtrl 84004;
if (!isNull _push) then {
    _push ctrlShow true;
    _push ctrlEnable true;
    _push ctrlSetText (localize "STR_ACM_Circulation_Syringe_DrawPush");
    _push ctrlSetTooltip "";
    _push ctrlSetEventHandler ["ButtonClick", "[1] call ACM_circulation_fnc_Syringe_Draw_Button"];
    _push ctrlCommit 0;
};
private _inj = _dlg displayCtrl 84005;
if (!isNull _inj) then { _inj ctrlShow false; _inj ctrlEnable false; };
if (!isNull _push) then {_push ctrlShow false;};
