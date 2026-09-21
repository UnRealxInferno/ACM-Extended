// add a color-coded "Junctional Wound" row to the medical-menu injury list for the selected part.
// it hooks ACM's own pre-render event, ace_medical_gui_updateInjuryListWounds, which passes the _woundEntries array
// by reference, so pushing onto it adds a rendered row with no override needed.
// _this is [_ctrl, _target, _selectionN, _woundEntries, _bodyPartName].
// a unique magenta family, unused by ACE's white, orange and tan wound colors, marks it as distinct and a life
// threat: open is bright magenta, packed is lighter and secured is muted.
params ["_ctrl", "_target", "_selectionN", "_woundEntries"];
if (isNull _target || {_selectionN < 0}) exitWith {};

private _p = (["head","body","leftarm","rightarm","leftleg","rightleg"]) param [_selectionN, ""];
if (_p == "" || {_p == "head"}) exitWith {};

// hardcore descriptors: name the wound by its anatomical region, so axillary for the armpit and arms and inguinal
// for the groin and legs, instead of the generic junctional.
private _hcDesc = ((missionNamespace getVariable ["ACME_hc_descriptors", false]) isEqualTo true);
private _base = if (_hcDesc) then {
    if (_p in ["leftarm","rightarm"]) then {"Axillary Wound"} else {"Inguinal Wound"}
} else {"Junctional Wound"};

switch (_target getVariable [format ["ACME_Junc_%1", _p], ""]) do {
    case "open":    { _woundEntries pushBack [_base,                       (["danger2", 1] call ACME_fnc_a11yColor)]; };
    case "packed":  { _woundEntries pushBack [_base + " [packed]",        (["warm", 1] call ACME_fnc_a11yColor)]; };
    case "wrapped": { _woundEntries pushBack [_base + " [Wrapped]",       [0.82, 0.73, 0.57, 1]]; };
    case "xstat":   {
        // an XStat seated gives a green "[XStat]", meaning controlled but unresolved and needing surgery. if the 2-hour
        // dwell has lapsed and it has rebled, flip to a red warning so the medic sees it has failed.
        private _rebled = _target getVariable [format ["ACME_Junc_XStatRebled_%1", _p], false];
        if (alive _target && {_rebled}) then {
            _woundEntries pushBack [_base + " [XStat. REBLEEDING]", (["danger", 1] call ACME_fnc_a11yColor)];
        } else {
            _woundEntries pushBack [_base + " [XStat]",              (["success", 1] call ACME_fnc_a11yColor)];
        };
    };
    default {};
};
