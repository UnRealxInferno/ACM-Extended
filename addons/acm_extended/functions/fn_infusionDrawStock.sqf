/* Prep Infusion stock/tally refresh.
 *
 * ACM_circulation_fnc_Syringe_Draw is the sole live plunger writer. Prep Infusion only mirrors
 * stock and controls the Inject button. The medication backing list is refreshed only while the
 * syringe is empty and released, so a partial draw can be released, re-grabbed, increased, or
 * returned toward the vial without a hidden list rebuild changing its source identity.
 */
disableSerialization;
private _display = findDisplay 84000;
if (isNull _display || {isNil "ACME_infusion_pendingContext"}) exitWith {};

private _list = _display displayCtrl 84006;
if (isNull _list) exitWith {};

private _drawn = missionNamespace getVariable ["ACM_circulation_SyringeDraw_DrawnAmount", 0];
if (!(_drawn isEqualType 0) || {!finite _drawn}) then {_drawn = 0;};
_drawn = _drawn max 0;

private _moving = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Moving", false];

// Never rebuild the hidden medication selector around a syringe that already contains solution.
// The normal Narc Box/native draw path likewise keeps one medication identity until the syringe is empty.
if (!_moving && {_drawn <= 0.0005}) then {
    [_display] call ACME_fnc_skMedicationSync;
};
_list ctrlShow false;

private _med = missionNamespace getVariable ["ACM_circulation_SyringeDraw_Medication", ""];
private _allowed = missionNamespace getVariable ["ACME_infusion_allowedMedications", []];
private _busy = (missionNamespace getVariable ["ACME_infusion_pendingInject", ""]) != "";

(_display displayCtrl 84003) ctrlEnable (
    !_busy
    && {!_moving}
    && {_drawn > 0.0005}
    && {_med in _allowed}
);

[_display] call ACME_fnc_skMedicationStockRefresh;
[] call ACME_fnc_infusionRefreshTally;
