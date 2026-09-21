/* Remove the AAJT-S placement addressed by the selected body part. The casualty owner is the only device-state
   writer and returns exactly one reusable AAJT-S to the provider whose removal actually won. */
params ["_medic", "_patient", "_bodyPart"];
if (isNull _patient || {isNull _medic}) exitWith {false};
if (!local _patient) exitWith {
    [_patient, "aajtRemove", [_medic, _patient, _bodyPart]] call ACME_fnc_ownerDispatch;
    true
};
private _p = toLowerANSI _bodyPart;
private _removed = false;
private _site = "";
switch (_p) do {
    case "body": {
        if (_patient getVariable ["ACME_AAJT_zone3", false]) then {
            [_patient, "zone3", [false]] call ACME_fnc_aajtStateCommit;
            [_patient, "leftleg", false] call ACME_fnc_aajtSetLegTQ;
            [_patient, "rightleg", false] call ACME_fnc_aajtSetLegTQ;
            [_patient] call ACME_fnc_aajtDownedStop;
            _removed = true;
            _site = "Zone 3 REBOA";
        };
    };
    case "leftleg";
    case "rightleg": {
        if ((_patient getVariable ["ACME_AAJT_inguinal", false]) && {(_patient getVariable ["ACME_AAJT_inguinalSide", ""]) == _p}) then {
            [_patient, "inguinal", [false]] call ACME_fnc_aajtStateCommit;
            [_patient, _p, false] call ACME_fnc_aajtSetLegTQ;
            _removed = true;
            _site = "inguinal";
        };
    };
    case "leftarm": {
        if (_patient getVariable ["ACME_AAJT_axillaleft", false]) then {
            [_patient, "leftarm", [false]] call ACME_fnc_aajtStateCommit;
            [_patient, "leftarm", false] call ACME_fnc_aajtSetLegTQ;
            _removed = true;
            _site = "left axilla";
        };
    };
    case "rightarm": {
        if (_patient getVariable ["ACME_AAJT_axillaright", false]) then {
            [_patient, "rightarm", [false]] call ACME_fnc_aajtStateCommit;
            [_patient, "rightarm", false] call ACME_fnc_aajtSetLegTQ;
            _removed = true;
            _site = "right axilla";
        };
    };
    default {};
};
if (!_removed) exitWith {false};
[_patient] call ACME_fnc_junctionalStartBleed;
["ACME_aajtReturnItem", [_medic], _medic] call CBA_fnc_targetEvent;
[format ["AAJT-S removed (%1).", _site], 2.5, _medic] call ACME_fnc_netNotice;
[_patient, "activity", "%1 removed an AAJT-S", [[_medic, false, true] call ace_common_fnc_getName]] call ace_medical_treatment_fnc_addToLog;
true
