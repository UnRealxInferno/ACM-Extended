// Temporary plate-carrier removal for actions that need a genuinely unobstructed chest while a backpack is worn.
// This is deliberately class-exact so BVM, airway adjuncts and unrelated descendants do not inherit it merely
// because they share an ACM parent. Chest-seal and thoracostomy minigames own their separate long procedure scope.
private _classes = ["usestethoscope", "checkbreathing", "acme_inspectchest", "cpr"];
missionNamespace setVariable ["ACME_chestAccess_classes", _classes];

["ace_treatmentStarted", {
    params ["_medic", "_patient", "_bodyPart", ["_classname", ""]];
    if (isNull _medic || {isNull _patient} || {!local _medic}) exitWith {};
    private _class = toLowerANSI _classname;
    if !(_class in (missionNamespace getVariable ["ACME_chestAccess_classes", []])) exitWith {};

    // The treatment wrapper may already have completed the physical carrier-removal preflight and created this
    // exact lease. In that case treatmentStarted only confirms ownership; never replay the lift/removal sequence.
    private _existing = _medic getVariable ["ACME_chestAccess_treatment", []];
    if ((_existing param [0,objNull]) isEqualTo _patient
        && {(_existing param [1,""]) == _class}
        && {(_existing param [2,""]) != ""}) exitWith {};

    private _serial = (missionNamespace getVariable ["ACME_chestAccess_serial", 0]) + 1;
    missionNamespace setVariable ["ACME_chestAccess_serial", _serial];
    private _id = format ["%1:%2:%3", clientOwner, netId _medic, _serial];
    _medic setVariable ["ACME_chestAccess_treatment", [_patient, _class, _id]];
    [_patient, _medic, _id, true, _class] call ACME_fnc_chestAccessVestEvent;
}] call CBA_fnc_addEventHandler;

["ace_treatmentSucceded", {
    params ["_medic", "_patient", "_bodyPart", ["_classname", ""]];
    if (isNull _medic || {!local _medic}) exitWith {};
    private _entry = _medic getVariable ["ACME_chestAccess_treatment", []];
    if ((_entry param [0, objNull]) != _patient) exitWith {};
    private _stored = _entry param [1, ""];
    private _event = toLowerANSI _classname;
    if (_stored != _event) exitWith {};

    // Stethoscope success only launches its held scope. The continuous-action failure event below is the true end.
    if (_stored == "usestethoscope") exitWith {};

    // CPR success starts the continuous compression session. Keep the chest clear until that session actually ends.
    if (_stored == "cpr") exitWith {
        [{
            params ["_p", "_m", "_id"];
            isNull _p || {isNull _m} || {!alive _m} || {!([_p] call ACM_core_fnc_cprActive)}
        }, {
            params ["_p", "_m", "_id"];
            if (!isNull _m && {local _m}) then {
                private _cur = _m getVariable ["ACME_chestAccess_treatment", []];
                if ((_cur param [2, ""]) == _id) then {_m setVariable ["ACME_chestAccess_treatment", []];};
            };
            if (!isNull _p) then {[_p, _m, _id, false, "cpr"] call ACME_fnc_chestAccessVestEvent;};
        }, [_patient, _medic, _entry param [2, ""]], 600, {
            params ["_p", "_m", "_id"];
            if (!isNull _p) then {[_p, _m, _id, false, "cpr"] call ACME_fnc_chestAccessVestEvent;};
        }] call CBA_fnc_waitUntilAndExecute;
    };

    _medic setVariable ["ACME_chestAccess_treatment", []];
    [_patient, _medic, _entry param [2, ""], false, _stored] call ACME_fnc_chestAccessVestEvent;
}] call CBA_fnc_addEventHandler;

["ace_treatmentFailed", {
    params ["_medic", "_patient", "_bodyPart", ["_classname", ""]];
    if (isNull _medic || {!local _medic}) exitWith {};
    private _entry = _medic getVariable ["ACME_chestAccess_treatment", []];
    if ((_entry param [0, objNull]) != _patient) exitWith {};
    private _stored = _entry param [1, ""];
    private _event = toLowerANSI _classname;
    private _scopeEnd = _stored == "usestethoscope" && {_event in ["usestethoscope", "acm_continuousaction"]};
    if (!_scopeEnd && {_stored != _event}) exitWith {};
    _medic setVariable ["ACME_chestAccess_treatment", []];
    [_patient, _medic, _entry param [2, ""], false, _stored] call ACME_fnc_chestAccessVestEvent;
}] call CBA_fnc_addEventHandler;
