// Pair provider treatment events before routing to the patient owner. Elevated casualties are flattened through
// the authored release path before torso/roll-to-back work. Stethoscope is a special launcher: ACE reports success
// after the 0.001 s launch action, but the real continuous action stays open until its dialog closes. Keep the
// elevation suspension lease alive for that full interval so the casualty does not repeatedly drop/raise under the
// auscultation camera.
["ace_treatmentStarted", {
    params ["_medic", "_patient", "_bodyPart", ["_classname", ""]];
    if (isNull _patient || {!local _medic} || {!(_patient getVariable ["ACME_headElevated", false])}) exitWith {};
    private _classLC = toLowerANSI _classname;
    // Recovery position replaces Semi-Fowler rather than borrowing a temporary flat-treatment lease.
    // Begin lowering during the three-second treatment window so success lands directly in the authored
    // recovery pose instead of re-elevating the casualty after the native callback.
    if (_classLC == "recoveryposition") exitWith {
        [_medic, _patient, true] call ACME_fnc_headElevateStop;
    };
    private _cfg = configFile >> "ace_medical_treatment_actions" >> _classname;
    private _roll = (getNumber (_cfg >> "ACM_rollToBack")) > 0;
    private _isBody = if (_bodyPart isEqualType "") then {toLower _bodyPart == "body"} else {_bodyPart == 1};
    if !(_roll || _isBody) exitWith {};
    private _serial = (missionNamespace getVariable ["ACME_headElev_treatmentSerial", 0]) + 1;
    missionNamespace setVariable ["ACME_headElev_treatmentSerial", _serial];
    private _id = format ["%1:%2:%3", clientOwner, netId _medic, _serial];
    private _token = _patient getVariable ["ACME_headElev_poseToken", ""];
    // Gear ownership is independent now. Every temporary flat maneuver preserves the Semi-Fowler support carrier
    // out of the way, while exact chest-access classes use the separate backpack-vest lease runtime.
    private _keepVestOut = false;
    _medic setVariable ["ACME_headElev_treatment", [_patient, _classname, _id, _token, _keepVestOut]];
    [_patient, _medic, _id, true, _token, _keepVestOut] call ACME_fnc_headElevTreatmentEvent;
}] call CBA_fnc_addEventHandler;

// Ordinary treatments release their elevation lease on native success. UseStethoscope does not: that success is
// only the minigame launcher completing, not the end of auscultation.
["ace_treatmentSucceded", {
    params ["_medic", "_patient", "_bodyPart", ["_classname", ""]];
    if (!local _medic) exitWith {};
    private _entry = _medic getVariable ["ACME_headElev_treatment", []];
    if ((_entry param [0, objNull]) != _patient) exitWith {};
    private _storedClass = toLowerANSI (_entry param [1, ""]);
    private _eventClass = toLowerANSI _classname;
    if (_storedClass == "usestethoscope" && {_eventClass == "usestethoscope"}) exitWith {};
    if (_storedClass != _eventClass) exitWith {};
    _medic setVariable ["ACME_headElev_treatment", []];
    [_patient, _medic, _entry select 2, false, _entry select 3, _entry param [4, false]] call ACME_fnc_headElevTreatmentEvent;
}] call CBA_fnc_addEventHandler;

// A normal failure closes an exact-class lease. The stethoscope controller intentionally emits
// ACM_ContinuousAction when its dialog actually closes, so accept that event as the real end of UseStethoscope.
["ace_treatmentFailed", {
    params ["_medic", "_patient", "_bodyPart", ["_classname", ""]];
    if (!local _medic) exitWith {};
    private _entry = _medic getVariable ["ACME_headElev_treatment", []];
    if ((_entry param [0, objNull]) != _patient) exitWith {};
    private _storedClass = toLowerANSI (_entry param [1, ""]);
    private _eventClass = toLowerANSI _classname;
    private _scopeEnd = _storedClass == "usestethoscope" && {_eventClass in ["usestethoscope", "acm_continuousaction"]};
    if (!_scopeEnd && {_storedClass != _eventClass}) exitWith {};
    _medic setVariable ["ACME_headElev_treatment", []];
    [_patient, _medic, _entry select 2, false, _entry select 3, _entry param [4, false]] call ACME_fnc_headElevTreatmentEvent;
}] call CBA_fnc_addEventHandler;
