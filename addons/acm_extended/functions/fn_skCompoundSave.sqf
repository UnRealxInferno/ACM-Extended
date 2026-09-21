// Save the current compound immediately, then reset the existing Narc Box page in place.
// No delayed dialog teardown/reopen: this prevents cursor focus/magnetization and makes Save feel immediate.
disableSerialization;
private _dlg = findDisplay 84000;
if (isNull _dlg) exitWith {};
if ((uiNamespace getVariable ["ACME_SK_WasteStage", ""]) != "compound") exitWith {};

private _components = uiNamespace getVariable ["ACME_SK_CompoundComponents", []];
if (_components isEqualTo []) exitWith {
    ["Draw at least one drug before saving.", 2.5, ACE_player, 13] call ace_common_fnc_displayTextStructured;
};

call ACME_fnc_skPendingTagCommit;
if !(call ACME_fnc_skCompoundCommit) exitWith {};
call ACME_fnc_skRefreshDrawn;
call ACME_fnc_skPendingTagReset;

// Fresh syringe preparation is initialized immediately on the same controls.
[] call ACME_fnc_skCompoundBegin;
call ACME_fnc_skListRefresh;
call ACME_fnc_skPendingTagRender;

// Acknowledge Save without blocking input. Only the label/color flash is delayed; the next draw can start now.
private _saveBtn = _dlg displayCtrl 84004;
if (!isNull _saveBtn) then {
    _saveBtn ctrlSetText "Saved!";
    _saveBtn ctrlSetBackgroundColor (["success",0.88] call ACME_fnc_a11yColor);
    _saveBtn ctrlEnable true;
    _saveBtn ctrlCommit 0;
    private _token = format ["%1:%2",clientOwner,diag_tickTime];
    _dlg setVariable ["ACME_SK_SaveFeedbackToken",_token];
    [{
        params ["_display","_tok"];
        if (isNull _display || {!(_display isEqualTo findDisplay 84000)} || {(_display getVariable ["ACME_SK_SaveFeedbackToken",""]) != _tok}) exitWith {};
        private _b = _display displayCtrl 84004;
        if (!isNull _b) then {
            _b ctrlSetText "Save";
            _b ctrlSetBackgroundColor [0.05,0.05,0.05,0.65];
            _b ctrlEnable true;
            _b ctrlCommit 0.08;
        };
    },[_dlg,_token],0.45] call CBA_fnc_waitAndExecute;
};
