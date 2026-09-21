// paint the current side: the body image, the debug-only 5th-ics zone guide and the instruction line.
disableSerialization;
private _display = uiNamespace getVariable ["ACME_Thora_DLG", displayNull];
if (isNull _display) exitWith {};
private _side = uiNamespace getVariable ["ACME_Thora_Side", "right"];

(_display displayCtrl 86601) ctrlSetText (["\acm_extended\ui\chest_right_ca.paa", "\acm_extended\ui\chest_left_ca.paa"] select (_side == "left"));

// redraw the committed incision of this side, if any. it persists per patient and side, and reappears if a tube is
// removed.
private _patient = uiNamespace getVariable ["ACME_Thora_Patient", objNull];
[] call ACME_fnc_thoraRenderBruises;
private _inc = if (isNull _patient) then { [] } else { _patient getVariable [format ["ACME_thora_incision_%1", _side], []] };
if (count _inc == 3) then {
    _inc params ["_ist", "_iang", "_ilenCm"];
    private _ilenUV = (_ilenCm * (missionNamespace getVariable ["ACME_thora_pxPerCm", 60])) / 2048;
    [_ist, _iang, _ilenUV] call ACME_fnc_thoraDrawIncision;
} else {
    [[0, 0], 0, 0] call ACME_fnc_thoraDrawIncision;
};

[] call ACME_fnc_thoraRenderPrep;
[] call ACME_fnc_thoraRenderOpen;
[] call ACME_fnc_thoraRenderTube;

// Arm mask: base chest -> prep/interventions -> arm overlay -> active cursor/palpation. Z-order comes from control
// creation order in fn_thoraInit; this render pass only selects the correct side and keeps it aligned to the body.
private _arm = uiNamespace getVariable ["ACME_Thora_ArmOverlay", controlNull];
if (!isNull _arm) then {
    private _rect = uiNamespace getVariable ["ACME_Thora_BodyRect", []];
    if (count _rect == 4) then {
        _arm ctrlSetPosition _rect;
        _arm ctrlCommit 0;
    };
    _arm ctrlSetText (["\acm_extended\ui\chest_right_arm_overlay_ca.paa", "\acm_extended\ui\chest_left_arm_overlay_ca.paa"] select (_side == "left"));
    _arm ctrlSetTextColor [1,1,1,1];
    _arm ctrlShow true;
};

// the zone guide is debug-only: it is shown only when the debug menu is enabled and ACME_thora_showZone is on.
// normal play always hides it, because the 5th ics is palpated by feel. it is drawn asset-free as a translucent box
// at the accept ellipse.
private _zone = _display displayCtrl 86604;
private _dbg = (missionNamespace getVariable ["ACME_debug_enabled", false]) || {uiNamespace getVariable ["ACME_debug_enabled", false]};
if (_dbg && {missionNamespace getVariable ["ACME_thora_showZone", false]}) then {
    private _rect = uiNamespace getVariable ["ACME_Thora_BodyRect", []];
    private _ell = uiNamespace getVariable [["ACME_Thora_ZoneRight", "ACME_Thora_ZoneLeft"] select (_side == "left"), [0.5, 0.44, 0.05, 0.045]];
    if (count _rect == 4 && {count _ell == 4}) then {
        _rect params ["_bx", "_by", "_bw", "_bh"];
        _ell params ["_cu", "_cv", "_ru", "_rv"];
        _zone ctrlSetPosition [_bx + ((_cu - _ru) * _bw), _by + ((_cv - _rv) * _bh), (2 * _ru) * _bw, (2 * _rv) * _bh];
        _zone ctrlCommit 0;
        _zone ctrlShow true;
    } else {
        _zone ctrlShow false;
    };
} else {
    _zone ctrlShow false;
};

