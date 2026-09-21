// toggle grabbing the plunger during flush/compound draw flow.
// Preserve ACM's sticky cursor behavior: click once to grab, the cursor stays centered on the moving plunger,
// and click the same plunger again to release.
private _stage = uiNamespace getVariable ["ACME_SK_WasteStage", ""];
if (_stage == "") exitWith {};

disableSerialization;
private _dlg = findDisplay 84000;
if (isNull _dlg) exitWith {};

private _moving = !(uiNamespace getVariable ["ACME_SK_WasteMoving", false]);
uiNamespace setVariable ["ACME_SK_WasteMoving", _moving];

private _plunger = _dlg displayCtrl 84009;
if (!isNull _plunger) then {
    if (_moving) then {
        // Snap to the real control center once at grab time. The PFH then keeps X sticky and lets Y follow the hand.
        (ctrlPosition _plunger) params ["_px", "_py", "_pw", "_ph"];
        setMousePosition [_px + (_pw / 2), _py + (_ph / 2)];
        _plunger ctrlSetTooltip "Click again to release the plunger";
    } else {
        _plunger ctrlSetTooltip "Click to grab the plunger";
    };
};
