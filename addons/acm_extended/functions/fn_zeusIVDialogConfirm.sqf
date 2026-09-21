// the confirm handler for ACME_IVModule_Dialog. it reads the limb, the access site and the gauge, and places the
// IV on the stashed target.
//
// it does THREE things, and the third is the one that matters.
//   1. it drives ACM_circulation_setIVLocal on the machine that owns the unit, so ACM knows the access site
//      exists and fluids run through it.
//   2. it writes the same activity-log line a hand placement writes, through ACME_fnc_ivLogSite.
//   3. it writes the catheter hub into the limb's mark array.
// without the third, a curator-placed IV would have no removal path at all. the gauge removal buttons were hidden
// in v0.9.999r-42 and an IV comes out by grabbing its hub in the IV screen. a line with no mark has no hub to
// grab. so the mark is not decoration, it is the removal.
disableSerialization;
private _display = findDisplay 87900;
if (isNull _display) exitWith {};

private _unit = uiNamespace getVariable ["ACME_IVModule_target", objNull];
if (isNull _unit) exitWith {
    _display closeDisplay 2;
    ["Place IV module: target no longer valid.", 2] call ace_common_fnc_displayTextStructured;
};

private _limbSel  = lbCurSel 87901;
private _siteSel  = lbCurSel 87902;
private _gaugeSel = lbCurSel 87903;
if (_limbSel  < 0) then { _limbSel  = 0; };
if (_siteSel  < 0) then { _siteSel  = 1; };
if (_gaugeSel < 0) then { _gaugeSel = 1; };

// the neck row is the external jugular. ACM has no neck body part, so the addon models it on the head, with left
// on access site 0 and right on 1, which is what fn_ivMinigameRegister does. see its own note on that.
private _isEJ = (_limbSel == 4);
private _bodyPart = ["leftarm", "rightarm", "leftleg", "rightleg", "head"] select _limbSel;
// the mark and the vein catalog want the addon's own limb name, which is "ej" for the neck. ACM wants "head".
private _markPart = if (_isEJ) then { "ej" } else { _bodyPart };
// THE SITE COLUMN CARRIES BOTH SETS AND GREYS THE ONES THAT DO NOT APPLY, in fn_zeusIVDialogSite.
//   0 Upper, 1 Middle, 2 Lower   heights up an arm or a leg
//   3 Left,  4 Right             sides of the neck, which is what the external jugular actually has
// it used to list the three heights whatever the limb, and a hint line said that on the neck Upper meant left and
// Middle meant right. the operator had to hold that mapping in their head while looking at a word that said
// something else. the greying makes the invalid rows unselectable, so a clamp here is a backstop rather than the
// mechanism.
private _siteName = if (_isEJ) then {
    ["left", "right"] param [((_siteSel - 3) max 0 min 1), "left"]
} else {
    ["upper", "middle", "lower"] param [(_siteSel max 0 min 2), "middle"]
};
// the access site index ACM is given. it is the one mapping, fn_ivSiteIndex, rather than a fourth copy of it.
private _accessSite = [_siteName] call ACME_fnc_ivSiteIndex;

private _gauge = [14, 16, 18, 20] select _gaugeSel;
// the ACM gauge types. 1 is 16g and 2 is 14g, both ACM's. this addon adds 5 for 18g and 6 for 20g, which the
// getIVFlowRate override reads to scale the flow down for the smaller bores.
private _type = switch (_gauge) do {
    case 14: { 2 };
    case 18: { 5 };
    case 20: { 6 };
    default { 1 };
};

_display closeDisplay 1;

// refuse a second line in the same hole rather than stacking two catheters on one access site.
// CAUTION: the test sets a flag and the exit is at the TOP LEVEL of this file. an exitWith placed inside the
// nested if would leave that block only, and the placement below would still run.
private _bpIdx = ["head", "body", "leftarm", "rightarm", "leftleg", "rightleg"] find _bodyPart;
private _occupied = false;
if (_bpIdx >= 0) then {
    private _st = _unit getVariable ["ACM_circulation_IV_Placement", []];
    if (_st isEqualType [] && {_bpIdx < count _st}) then {
        private _row = _st select _bpIdx;
        if (_row isEqualType [] && {_accessSite < count _row}) then {
            _occupied = (_row select _accessSite) > 0;
        };
    };
};
if (_occupied) exitWith {
    ["Place IV module: that access site already carries an IV.", 2] call ace_common_fnc_displayTextStructured;
};

["ACM_circulation_setIVLocal", [objNull, _unit, _bodyPart, _type, true, _accessSite], _unit] call CBA_fnc_targetEvent;

// the hub mark, so the line can be pulled in the IV screen.
// the mark array is [bodyPart, view, u, v, kind, holeTex, frame, gauge, missTime, scale, site, rot, alpha], as
// written by fn_ivMinigameAddMark. fn_ivMinigamePullStop reads element 0 for the limb, element 4 for the kind
// and element 10 for the access site, so those four have to be right and the rest are render detail.
// the view texture and the vein coordinates come from fn_ivSiteData, which is the same source the screen uses to
// draw the limb, so the hub lands on the vein rather than at a guessed point.
private _sd = [_markPart, _siteName] call ACME_fnc_ivSiteData;
if (_sd isEqualType [] && {count _sd >= 6}) then {
    _sd params ["_viewTex", "_bandTex", "_bandU", "_bandV", "_veinU", "_veinV"];

    // Match the fixed anatomical-side family used by manual IV/EJ placement.
    private _frame = if (_markPart in ["leftarm", "leftleg"]) then {"_15_left"} else {"_15_right"};
    if (_isEJ) then {
        _frame = if (_siteName isEqualTo "left") then { "_ej_15_right" } else { "_ej_15_left" };
    };
    private _mark = [_markPart, _viewTex, _veinU, _veinV, "hub", "", _frame, _gauge, -1, 1, _siteName, 0, 1, 0];
    [_unit, "ivMarks", ["add", [_mark], [_unit] call ACME_fnc_clinicalEpoch]] call ACME_fnc_ownerDispatch;
};

// the same line a hand placement writes, from the same function, so the two read alike in the record.
if (!isNil "ace_medical_treatment_fnc_addToLog") then {
    private _siteText = [_markPart, _siteName] call ACME_fnc_ivLogSite;
    if (_siteText isEqualTo "") then {
        [_unit, "activity", "Established IV", []] call ace_medical_treatment_fnc_addToLog;
    } else {
        [_unit, "activity", "Established IV, %1", [_siteText]] call ace_medical_treatment_fnc_addToLog;
    };
};

[format ["%1g IV placed on %2, %3.", _gauge, name _unit, ([_markPart, _siteName] call ACME_fnc_ivLogSite)], 2.5] call ace_common_fnc_displayTextStructured;
