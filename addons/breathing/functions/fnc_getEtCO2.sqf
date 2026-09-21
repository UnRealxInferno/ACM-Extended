#include "..\script_component.hpp"
/* Fork-native EtCO2 query: ACM baseline physiology plus Extended ventilator/CPR modifiers. */
params ["_patient"];
if (isNull _patient || {!alive _patient}) exitWith {0};
private _cpr = [_patient] call ACM_core_fnc_cprActive;
private _rr = _patient getVariable ["ACM_breathing_RespirationRate", 0];
if (!_cpr && {_rr < 1}) exitWith {0};

private _value = call {
    /* mmHg
        Cardiac Arrest - 0
        Effective CPR - 10-20
        Unconscious - 30-35
        Conscious (Normal) - 35-45
        ROSC (Momentary) - 45-50
    */
    private _timeSinceROSC = (CBA_missionTime - (_patient getVariable [QEGVAR(circulation,ROSC_Time), -45]));
    private _exit = false;
    private _minFrom = 0;
    private _maxFrom = 0;
    private _value = 0;
    private _minTo = 0;
    private _maxTo = 0;

    private _airwayState = (GET_AIRWAYSTATE(_patient) / 0.95) min 1;
    private _breathingState = (GET_BREATHINGSTATE(_patient) / 0.85) min 1;

    private _bloodVolumeEffect = 1 min (GET_EFF_BLOOD_VOLUME(_patient) / 5.9);

    if (_timeSinceROSC < 45) exitWith {
        linearConversion [0, 30, _timeSinceROSC, 50 * _bloodVolumeEffect, 30 * _bloodVolumeEffect, true];
    };

    private _desiredRespirationRate = _patient getVariable [QEGVAR(core,TargetVitals_RespirationRate), 16];

    if ((GET_HEART_RATE(_patient) < 20) || IN_CRDC_ARRST(_patient) || !(alive _patient)) then {
        if (alive (_patient getVariable [QACEGVAR(medical,CPR_provider), objNull])) then {
            _minFrom = 100;
            _maxFrom = 120;
            _value = GET_HEART_RATE(_patient);
            _minTo = 10;
            _maxTo = 20;
        } else {
            _exit = true;
        };
    } else {
        _value = GET_RESPIRATION_RATE(_patient);
        if (_value < _desiredRespirationRate) then {
            _minFrom = 1;
            _maxFrom = _desiredRespirationRate;
            if (IS_UNCONSCIOUS(_patient)) then {
                _minTo = 35;
                _maxTo = 30;
            } else {
                _minTo = 45;
                _maxTo = 35;
            };
        } else {
            _minFrom = _desiredRespirationRate;
            _maxFrom = 50;
            if (IS_UNCONSCIOUS(_patient)) then {
                _minTo = 30;
                _maxTo = 15;
            } else {
                _minTo = 35;
                _maxTo = 20;
            };
        };
    };

    if (_exit) exitWith {0};

    linearConversion [_minFrom, _maxFrom, (_value * (_airwayState min _breathingState)), _minTo * _bloodVolumeEffect, _maxTo * _bloodVolumeEffect, true];
};
if (!finite _value || {_value <= 0}) exitWith {0};
if (missionNamespace getVariable ["ACME_sys_vent", true] && {_patient getVariable ["ACME_vent_driving", false]}) then {
    private _adequacy = _patient getVariable ["ACME_vent_mvAdequacy", 1];
    if (!(_adequacy isEqualType 0) || {!finite _adequacy}) then {_adequacy = 1;};
    _value = ((_value / (_adequacy max 0.25)) * 0.85) + (_value * 0.15);
};
if (_cpr) then {
    _value = _value * linearConversion [0, 45, _patient getVariable ["ACME_vent_cprBadTime", 0], 1, 0.4, true];
};
_value max 0 min 90
