/* Owner-authoritative hard power loss for a patient-mounted ventilator.
 * UI chrome/sounds stay on the operator client; durable patient/device state is committed only here. */
params [
    ["_patient", objNull, [objNull]],
    ["_reason", "Ventilator stopped", [""]],
    ["_medic", objNull, [objNull]],
    ["_custody", "", [""]]
];
if (isNull _patient) exitWith {false};
if (!local _patient) exitWith {
    [_patient, "ventHardStop", [_patient, _reason, _medic, _custody]] call ACME_fnc_ownerDispatch;
    true
};

// A stale panel from an older device/custody episode must never power down the replacement device.
if (_custody != "" && {(_patient getVariable ["ACME_vent_custodyId", ""]) != _custody}) exitWith {false};
if (!isNull _medic && {(!alive _medic) || {!([_medic] call ace_common_fnc_isAwake)}
    || {(_medic distance _patient) > ace_medical_gui_maxDistance}}) exitWith {false};

private _wasDriving = _patient getVariable ["ACME_vent_driving", false];
_patient setVariable ["ACME_vent_powerOn", false, true];
_patient setVariable ["ACME_vent_hasBooted", false, true];

// Setup flags precede driving so the owner-local drive worker cannot re-arm the circuit mid-stop.
[_patient, "ACME_vent_connected", false] call ACME_fnc_setVarNet;
[_patient, "ACME_vent_configured", false] call ACME_fnc_setVarNet;
[_patient, "ACME_vent_measRR", 0] call ACME_fnc_setVarNet;
[_patient, "ACME_vent_breathTimes", []] call ACME_fnc_setVarNet;
[_patient, "ACME_vent_breathAcc", 0] call ACME_fnc_setVarNet;
[_patient, "ACME_vent_driveT0", -1] call ACME_fnc_setVarNet;
[_patient, "ACME_vent_rrDrive", -1] call ACME_fnc_setVarNet;
[_patient, "ACME_vent_mvAdequacy", 0] call ACME_fnc_setVarNet;
[_patient, "ACME_vent_cpapTherapy", false] call ACME_fnc_setVarNet;
[_patient, "ACME_vent_alarms", []] call ACME_fnc_setVarNet;
[_patient, "ACME_vent_alarmPrio", 0] call ACME_fnc_setVarNet;
[_patient, "ACME_vent_alarmSilencedUntil", 0] call ACME_fnc_setVarNet;

if (_wasDriving && {(_patient getVariable ["ACM_breathing_BVM_provider", objNull]) isEqualTo _patient}) then {
    [_patient, [["bvmProvider", objNull], ["bvmConnectedOxygen", false]], true] call ACM_breathing_fnc_setRuntimeState;
};
[_patient, "ACME_vent_driving", false] call ACME_fnc_setVarNet;

if (_wasDriving) then {
    [_patient, "activity", "Ventilator stopped while driving ventilation", "Ventilator stopped during invasive ventilation", []] call ACME_fnc_medLog;
};
true
