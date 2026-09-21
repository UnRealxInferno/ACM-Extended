#include "..\script_component.hpp"
/*
 * Author: Blue
 * Handle hemothorax process (LOCAL)
 *
 * Arguments:
 * 0: Patient <OBJECT>
 * 1: Resume existing clot PFH only <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call ACM_breathing_fnc_handleHemothorax;
 *
 * Public: No
 */

params ["_patient", ["_resumeOnly", false]];

private _state = _patient getVariable [QGVAR(Hemothorax_State), 0];

// Normal injury calls create/increment the hemothorax. Resume-only is used when TXA is given to an already-active
// hemothorax whose clot PFH was lost, and must never increase injury severity simply because medication was given.
if (_resumeOnly && {_state <= 0}) exitWith {};
if (!_resumeOnly && {_state >= 10}) exitWith {};

if (!_resumeOnly) then {
    if (_state == 0) then {
        _state = 5 + round (random 5);
    } else {
        _state = _state + 1;
    };

    _patient setVariable [QGVAR(Hemothorax_State), _state, true];
    [_patient, (linearConversion [1, 6, _state, 0.3, 1, true])] call ACEFUNC(medical,adjustPainLevel);
};

if (_patient getVariable [QGVAR(Hemothorax_PFH), -1] != -1) exitWith {};

private _time = [(10 + (random 10)), (15 + (random 15))] select GVAR(Hardcore_HemothoraxBleeding);

private _PFH = [{
    params ["_args", "_idPFH"];
    _args params ["_patient"];

    private _hemothoraxState = _patient getVariable [QGVAR(Hemothorax_State), 0];

    // Retire a completed/dead episode before any setting-specific early return. This prevents stale PFHs and keeps
    // the non-Hardcore path able to reach a true zero state.
    if (!(alive _patient) || {_hemothoraxState <= 0}) exitWith {
        _patient setVariable [QGVAR(Hemothorax_PFH), -1];
        [_idPFH] call CBA_fnc_removePerFrameHandler;
    };

    private _plateletCount = _patient getVariable [QEGVAR(circulation,Platelet_Count), 3];
    private _TXACount = ([_patient, "TXA_IV", false] call ACEFUNC(medical_status,getMedicationCount)) min 2;

    // Hardcore intentionally leaves a low-grade residual source at state 1-2 when untreated. TXA is treatment,
    // so it must still be allowed to complete the native clot process. With Hardcore disabled this branch never
    // runs and state 1-2 can clot normally.
    if (GVAR(Hardcore_HemothoraxBleeding) && {_hemothoraxState <= 2} && {_TXACount < 0.1}) exitWith {};

    // Preserve ACM's circulation/platelet gates, but do not make severe hypovolemia an absolute TXA lockout.
    // Previously a casualty below 3.6 L effective blood volume could have active TXA and still remain permanently
    // unable to make a hemothorax clot attempt. Untreated profound shock retains the original gate.
    // B135: a resuscitating hemothorax is allowed to stabilize. CPR restores enough forward circulation for
    // clotting attempts, and TXA that was already delivered systemically remains active during arrest. Do not let
    // HR<20 turn an otherwise treatable hemothorax into a permanent source. Untreated profound shock still blocks
    // clotting, while TXA retains the existing low-volume exception.
    private _cprActive = [_patient] call EFUNC(core,cprActive);
    private _hemostaticPerfusion = (GET_HEART_RATE(_patient) >= 20) || {_cprActive} || {_TXACount > 0.1};
    if (!_hemostaticPerfusion
        || {(_plateletCount < 1 && {_TXACount < 0.1})}
        || {(GET_EFF_BLOOD_VOLUME(_patient) < 3.6) && {_TXACount < 0.1}}) exitWith {};

    private _clotChance = ((0.25 * _plateletCount / 4) max (0.5 * (_TXACount min 1.2))) min 1;

    if (random 1 < _clotChance) then {
        private _clearAmount = 1;

        if (_TXACount >= 1) then {
            _clearAmount = ([2,3] select (random 1 < (0.25 * _TXACount)));
        };

        _hemothoraxState = (_hemothoraxState - _clearAmount) max 0;
        _patient setVariable [QGVAR(Hemothorax_State), _hemothoraxState, true];

        if (_hemothoraxState <= 0) then {
            _patient setVariable [QGVAR(Hemothorax_PFH), -1];
            [_idPFH] call CBA_fnc_removePerFrameHandler;
        };
    };
}, _time, [_patient]] call CBA_fnc_addPerFrameHandler;

_patient setVariable [QGVAR(Hemothorax_PFH), _PFH];
