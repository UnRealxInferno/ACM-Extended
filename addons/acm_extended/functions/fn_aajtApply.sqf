/* Apply an AAJT-S at the selected anatomical site. Body is Zone 3 REBOA; legs are unilateral inguinal;
   arms are unilateral axillary. The casualty owner serializes the physical device commit so simultaneous
   providers cannot consume two AAJT-S devices for one placement. */
params ["_medic", "_patient", "_bodyPart"];
if (isNull _patient || {isNull _medic}) exitWith {false};
if (!local _patient) exitWith {
    [_patient, "aajtApply", [_medic, _patient, _bodyPart]] call ACME_fnc_ownerDispatch;
    true
};

private _p = toLowerANSI _bodyPart;
private _already = switch (_p) do {
    case "body": {_patient getVariable ["ACME_AAJT_zone3", false]};
    case "leftleg";
    case "rightleg": {_patient getVariable ["ACME_AAJT_inguinal", false]};
    case "leftarm": {_patient getVariable ["ACME_AAJT_axillaleft", false]};
    case "rightarm": {_patient getVariable ["ACME_AAJT_axillaright", false]};
    default {true};
};
if (_already) exitWith {
    [_patient, "aajtApplying", ["", false]] call ACME_fnc_ownerDispatch;
    ["ACME_aajtReturnItem", [_medic], _medic] call CBA_fnc_targetEvent;
    ["AAJT-S application cancelled: another provider already placed the device.", 2.5, _medic] call ACME_fnc_netNotice;
    false
};

[_patient, "aajtApplying", ["", false]] call ACME_fnc_ownerDispatch;
private _two = {private _n = floor _this; if (_n < 10) then {"0" + str _n} else {str _n}};
private _d = daytime; private _hh = floor _d; private _mm = (_d - _hh) * 60; private _ss = (_mm - floor _mm) * 60;
private _atStr = format ["%1:%2:%3", _hh call _two, _mm call _two, _ss call _two];
private _site = "";
switch (_p) do {
    case "body": {
        [_patient, "zone3", [true, _atStr]] call ACME_fnc_aajtStateCommit;
        [_patient, "leftleg", true] call ACME_fnc_aajtSetLegTQ;
        [_patient, "rightleg", true] call ACME_fnc_aajtSetLegTQ;
        [_patient] call ACME_fnc_aajtDownedTick;
        _site = "Zone 3 REBOA";
    };
    case "leftleg";
    case "rightleg": {
        [_patient, "inguinal", [true, _atStr, _p]] call ACME_fnc_aajtStateCommit;
        [_patient, _p, true] call ACME_fnc_aajtSetLegTQ;
        _site = format ["%1 inguinal", if (_p == "leftleg") then {"left"} else {"right"}];
    };
    case "leftarm": {
        [_patient, "leftarm", [true, _atStr]] call ACME_fnc_aajtStateCommit;
        [_patient, "leftarm", true] call ACME_fnc_aajtSetLegTQ;
        _site = "left axilla";
    };
    case "rightarm": {
        [_patient, "rightarm", [true, _atStr]] call ACME_fnc_aajtStateCommit;
        [_patient, "rightarm", true] call ACME_fnc_aajtSetLegTQ;
        _site = "right axilla";
    };
    default {};
};
if (_site == "") exitWith {
    ["ACME_aajtReturnItem", [_medic], _medic] call CBA_fnc_targetEvent;
    false
};
[_patient] call ACME_fnc_aajtPainTick;
[format ["AAJT-S applied: %1.", _site], 3, _medic] call ACME_fnc_netNotice;
[_patient, "activity", "%1 applied an AAJT-S (%2)", [[_medic, false, true] call ace_common_fnc_getName, _site]] call ace_medical_treatment_fnc_addToLog;
true
