// connect the floating line to the seated hub.
// call it as [_fx, _fy] call ACME_fnc_ivMinigameLineConnect, with the body fractions of the click.
// it finds the nearest unconnected hub on this limb and view. a click that lands nowhere near one does nothing,
// so the line stays in hand.
params ["_fx", "_fy"];
if !([] call ACME_fnc_ivUiValid) exitWith {false};
private _patient = uiNamespace getVariable ["ACME_IV_Patient", objNull];
if (isNull _patient) exitWith { false };
private _bp = uiNamespace getVariable ["ACME_IV_BodyPart", "leftarm"];
private _view = uiNamespace getVariable ["ACME_IV_View", ""];
private _af = uiNamespace getVariable ["ACME_IV_AspectFix", 0.5625];

private _marks = _patient getVariable ["ACME_IV_Marks", []];
private _bestI = -1;
private _bestD = 1e9;
{
    _x params ["_mbp", "_mview", "_mu", "_mv", "_mkind", ["_mtex", ""]];
    // only a bare hub takes a line. one that already has tubing on it is done.
    if (_mbp == _bp && {_mview == _view} && {_mkind == "hub"} && {_mtex == ""}) then {
        private _du = _fx - _mu;
        private _dv = (_fy - _mv) * (1 / _af);
        private _d = sqrt ((_du * _du) + (_dv * _dv));
        if (_d < _bestD) then { _bestD = _d; _bestI = _forEachIndex; };
    };
} forEach _marks;
if (_bestI < 0 || {_bestD > 0.06}) exitWith { false };

private _mark = _marks select _bestI;
private _mframe = _mark param [6, ""];
private _mgauge = _mark param [7, 16];
if !(_mgauge in [14, 16, 18, 20]) then { _mgauge = 16; };
private _dir = if (_mframe == "") then { "base" } else { _mframe select [1] };

// The connected line art carries the hub and tubing in one picture. Commit against this hub's stable signature
// on the casualty owner instead of replacing a possibly stale whole mark array from this medic client.
private _texture = format [
    "\acm_extended\ui\iv\iv_line\connected\%1g\%2\iv_line_connected_%1g_%2_ca.paa",
    _mgauge, _dir
];
private _sig = [_mark param [0,""], _mark param [1,""], _mark param [2,0], _mark param [3,0], _mark param [10,""], _mgauge];
[_patient, "ivMarks", ["connect", [_sig, _texture], [_patient] call ACME_fnc_clinicalEpoch]] call ACME_fnc_ownerDispatch;

uiNamespace setVariable ["ACME_IV_Held", "none"];
uiNamespace setVariable ["ACME_IV_InsStage", ""];
[] call ACME_fnc_ivMinigameRenderMarks;
private _dlg = uiNamespace getVariable ["ACME_IV_DLG", displayNull];
if (!isNull _dlg) then {
    private _heldC = uiNamespace getVariable ["ACME_IV_HeldCursorCtrl", controlNull];
    if (!isNull _heldC) then { _heldC ctrlShow false; };
    (_dlg displayCtrl 86503) ctrlSetText (if (uiNamespace getVariable ["ACME_IV_BandOn", false]) then {
        "Line connected. Take the band off before it will run."
    } else {
        "Line connected."
    });
};
[] call ACME_fnc_ivMinigameSaveState;
playSound "ACE_Sound_Click";
if (!isNil "ace_medical_treatment_fnc_addToLog") then {
    [_patient, "activity",
 "Connected a line to the %1g IV on the %2",
 "IV line connected, %1g, %2",
 [_mgauge, [_bp, "short"] call ACME_fnc_bodyPartName]] call ACME_fnc_medLog;
};
true
