#include "..\script_component.hpp"
/*
 * Author: Blue
 * Assign cardiac arrest rhythm to patient and begin PFH (LOCAL)
 *
 * Arguments:
 * 0: Patient <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call ACM_circulation_fnc_handleCardiacArrest;
 *
 * Public: No
 */

params ["_patient", ["_resume", false]];
private _acmeBinding = "NA4:handleCardiacArrest";
if (isNull _patient || {!local _patient} || {!alive _patient} || {!(IN_CRDC_ARRST(_patient))}) exitWith {};
if (_patient getVariable ["ACME_clinicalRestoring", false]) exitWith {};

if (_patient getVariable [QGVAR(Cardiac_RhythmState), -1] == ACM_Rhythm_Asystole) exitWith {};

/*
    0 - Sinus
    1 - Asystole
    2 - Ventricular Fibrillation
    3 - (Pulseless) Ventricular Tachycardia
    4 - Ventricular Tachycardia
    5 - Pulseless Electrical Activity (Reversible)
*/

if (_patient getVariable [QGVAR(CardiacArrest_PFH), -1] >= 0) exitWith {};
if (_resume && {_patient getVariable [QGVAR(Cardiac_RhythmState), -1] == ACM_Rhythm_PEA}) exitWith {
    [_patient, true] call FUNC(handleReversibleCardiacArrest);
};
private _reversible = _patient getVariable [QGVAR(ReversibleCardiacArrest_PFH), -1];
if (_reversible >= 0) then {[_reversible] call CBA_fnc_removePerFrameHandler;};
_patient setVariable [QGVAR(ReversibleCardiacArrest_PFH), -1, false];
_patient setVariable [QGVAR(ReversibleCardiacArrest_State), false, true];

if (!_resume || {isNil {_patient getVariable QGVAR(CardiacArrest_DeteriorationTime)}}) then {_patient setVariable [QGVAR(CardiacArrest_DeteriorationTime), CBA_missionTime, true];};

if (GET_BLOOD_VOLUME(_patient) < ACM_ASYSTOLE_BLOODVOLUME) exitWith {
    _patient setVariable [QGVAR(Cardiac_RhythmState), ACM_Rhythm_Asystole, true]; // asystole
};

if (!_resume) then {
private _targetRhythm = _patient getVariable [QGVAR(CardiacArrest_TargetRhythm), ACM_Rhythm_Sinus];

private _requested = _patient getVariable ["ACME_nativeRequestedRhythm", -1];
if (_requested in [1,2,3,5]) then {_targetRhythm = _requested;};
if (!(_requested in [1,2,3,5]) && {_targetRhythm in [ACM_Rhythm_Sinus, ACM_Rhythm_VT, ACM_Rhythm_PVT]}) then {
    _targetRhythm = [ACM_Rhythm_VF,ACM_Rhythm_PVT] select (((random 100) * (GET_BLOOD_VOLUME(_patient) / BLOOD_VOLUME_CLASS_2_HEMORRHAGE)) > 50);
};
if (_targetRhythm == ACM_Rhythm_PEA) then {
    private _brady = (random 1) < (missionNamespace getVariable ["ACME_peaBradyChance", 0]);
    private _peaHR = if (_brady) then {
        round (random [
            missionNamespace getVariable ["ACME_peaBradyMinHR", 60],
            missionNamespace getVariable ["ACME_peaBradyModeHR", 72],
            missionNamespace getVariable ["ACME_peaBradyMaxHR", 86]
        ])
    } else {
        round (random [
            missionNamespace getVariable ["ACME_peaNormalMinHR", 60],
            missionNamespace getVariable ["ACME_peaNormalModeHR", 80],
            missionNamespace getVariable ["ACME_peaNormalMaxHR", 100]
        ])
    };
    _patient setVariable ["ACME_peaElectricalHR", _peaHR, true];
    _patient setVariable ["ACME_peaElectricalStart", CBA_missionTime, true];
};
_patient setVariable [QGVAR(Cardiac_RhythmState), _targetRhythm, true];
_patient setVariable [QGVAR(CardiacArrest_TargetRhythm), nil];

if !(alive (_patient getVariable [QACEGVAR(medical,CPR_provider), objNull])) then {
    _patient setVariable [QGVAR(CPR_StoppedTime), CBA_missionTime, true];
};

};
private _deteriorateInterval = 10 + (random 8);

private _PFH = [{
    params ["_args", "_idPFH"];
    _args params ["_patient", "_deteriorateInterval", "_owner", "_epoch"];
    private _ownsHandle = (_patient getVariable [QGVAR(CardiacArrest_PFH), -1]) == _idPFH;
    if (!local _patient || {clientOwner != _owner} || {_epoch != ([_patient] call ACME_fnc_clinicalEpoch)} || {!_ownsHandle}) exitWith {
        if (_ownsHandle) then {_patient setVariable [QGVAR(CardiacArrest_PFH), -1, false];};
        [_idPFH] call CBA_fnc_removePerFrameHandler;
    };

    private _currentRhythm = _patient getVariable [QGVAR(Cardiac_RhythmState), ACM_Rhythm_Sinus];

    if (!(alive _patient) || !(IN_CRDC_ARRST(_patient)) || _currentRhythm in [ACM_Rhythm_Asystole,ACM_Rhythm_PEA]) exitWith {
        _patient setVariable [QGVAR(CardiacArrest_PFH), -1];

        if !(alive _patient) then {
            _patient setVariable [QGVAR(Cardiac_RhythmState), ACM_Rhythm_Asystole, true];
        };

        [_idPFH] call CBA_fnc_removePerFrameHandler;
    };

    private _noCPRTime = (CBA_missionTime - (_patient getVariable [QGVAR(CPR_StoppedTime), CBA_missionTime])) max 0;
    private _CPREffect = (((_patient getVariable [QGVAR(CPR_StoppedTotal), 0]) / 120) min 1);

    if (alive (_patient getVariable [QACEGVAR(medical,CPR_provider), objNull]) || {_noCPRTime < (45 * _CPREffect)}) exitWith {};

    private _lastDeteriorateTime = CBA_missionTime - (_patient getVariable [QGVAR(CardiacArrest_DeteriorationTime), CBA_missionTime]);

    if (((random 1) < (0.4 * GVAR(cardiacArrestDeteriorationRate))) && {_lastDeteriorateTime > (30 + random(30))}) then {
        private _targetRhythm = (_currentRhythm - 1) max 1;

        _patient setVariable [QGVAR(Cardiac_RhythmState), _targetRhythm, true];
        _patient setVariable [QGVAR(CardiacArrest_DeteriorationTime), CBA_missionTime, true];
    };
}, (15 + (random 15)), [_patient, _deteriorateInterval, clientOwner, [_patient] call ACME_fnc_clinicalEpoch]] call CBA_fnc_addPerFrameHandler;

_patient setVariable [QGVAR(CardiacArrest_PFH), _PFH];

// Handle deteriorating into asystole due to bloodloss
[{
    params ["_patient", "_owner", "_epoch", "_worker"];

    !local _patient || {clientOwner != _owner} || {_epoch != ([_patient] call ACME_fnc_clinicalEpoch)} || {(_patient getVariable [QGVAR(CardiacArrest_PFH), -1]) != _worker} || (GET_BLOOD_VOLUME(_patient) < ACM_ASYSTOLE_BLOODVOLUME) || !(alive _patient) || !(IN_CRDC_ARRST(_patient))
}, {
    params ["_patient", "_owner", "_epoch", "_worker"];
    if (!local _patient || {clientOwner != _owner} || {_epoch != ([_patient] call ACME_fnc_clinicalEpoch)} || {(_patient getVariable [QGVAR(CardiacArrest_PFH), -1]) != _worker} || {!(IN_CRDC_ARRST(_patient))}) exitWith {};

    if (alive _patient && (GET_BLOOD_VOLUME(_patient) < ACM_ASYSTOLE_BLOODVOLUME)) then {
        _patient setVariable [QGVAR(Cardiac_RhythmState), ACM_Rhythm_Asystole, true];
    };
}, [_patient, clientOwner, [_patient] call ACME_fnc_clinicalEpoch, _PFH], 3600] call CBA_fnc_waitUntilAndExecute;
