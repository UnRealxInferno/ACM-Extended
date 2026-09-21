// Unload is the final authority for this display instance.
// It must release audio, patient positioning, the continuous-action reservation and the provider's frozen pose.
// The normal controller PFH still performs the same cancellation path; every operation below is token-scoped and
// therefore safe when both paths run on adjacent frames.
disableSerialization;
params ["_display"];
if (isNull _display) exitWith {};

private _tickPFH = _display getVariable ["ACME_stethTickPFH", -1];
if (_tickPFH isEqualType 0 && {_tickPFH >= 0}) then {[_tickPFH] call CBA_fnc_removePerFrameHandler;};
_display setVariable ["ACME_stethTickPFH", -1];

private _wasFlipActive = _display getVariable ["ACME_stethFlipActive", false];
private _flipPFH = _display getVariable ["ACME_stethFlipPFH", -1];
if (_flipPFH isEqualType 0 && {_flipPFH >= 0}) then {[_flipPFH] call CBA_fnc_removePerFrameHandler;};
_display setVariable ["ACME_stethFlipPFH", -1];
_display setVariable ["ACME_stethFlipToken", ""];
_display setVariable ["ACME_stethFlipActive", false];

{
    _x params ["_emitter","_sound"];
    if (!isNull _sound) then {deleteVehicle _sound;};
    if (!isNull _emitter) then {deleteVehicle _emitter;};
} forEach (_display getVariable ["ACME_stethChannels",[]]);
_display setVariable ["ACME_stethChannels",[]];
_display setVariable ["ACME_stethPressed",false];

private _medic = _display getVariable ["ACME_stethMedic",objNull];
private _patient = _display getVariable ["ACME_stethPatient",objNull];

// Only THIS display's live Flip may abort a roll. A normal/late Unload must never cancel a newer scope's
// pre-entry roll or Flip just because it happens to target the same patient.
if (_wasFlipActive) then {
    if (!isNull _medic && {local _medic}) then {
        [_medic,"stethoscopeFlip"] call ACME_fnc_rollProviderCancel;
    };
    if (!isNull _patient) then {
        [_patient] call ACME_fnc_patientRollCancel;
    };
};
private _poseEpoch = _display getVariable ["ACME_stethPoseEpoch",-1];
private _continuousEpoch = _display getVariable ["ACME_continuousEpoch",-1];

// Release this provider's casualty animation lease immediately. The normal onCancel path sees the cleared lease
// and becomes a no-op, so a missed PFH frame can never leave the patient pinned by a dead stethoscope session.
if (!isNull _medic) then {
    private _ownedPatientToken = _display getVariable ["ACME_stethPatientLeaseToken", ""];
    private _lease = _medic getVariable ["ACME_stethPatientAnimLease",[]];
    private _leaseToken = _lease param [1,""];
    if (_ownedPatientToken != "" && {_leaseToken == _ownedPatientToken}) then {
        private _leasePatient = _lease param [0,objNull];
        if (!isNull _leasePatient) then {
            [_leasePatient,_ownedPatientToken] call ACME_fnc_patientAnimRelease;
        };
        _medic setVariable ["ACME_stethPatientAnimLease",[],false];
    };

    // Release the exact carrier lease stamped onto this display. Clear the provider's current lease pointer only
    // when it still points at the same ID; a late old Unload is otherwise harmless to the newer scope.
    private _ownedChestLeaseId = _display getVariable ["ACME_stethChestLeaseId", ""];
    if (_ownedChestLeaseId != "") then {
        private _chestLease = _medic getVariable ["ACME_chestAccess_treatment", []];
        if ((_chestLease param [2,""]) == _ownedChestLeaseId) then {
            _medic setVariable ["ACME_chestAccess_treatment", []];
        };
        if (!isNull _patient) then {
            [_patient, _medic, _ownedChestLeaseId, false, "usestethoscope"] call ACME_fnc_chestAccessVestEvent;
        };
    };
};

// Retire only the continuous-action generation that created this display. This is the critical fallback for
// abnormal dialog teardown: a dead stethoscope display must never leave ACM_core_ContinuousAction_Active stuck true.
if (_continuousEpoch >= 0
    && {(missionNamespace getVariable ["ACM_core_ContinuousAction_Epoch",-2]) == _continuousEpoch}) then {
    ACM_core_ContinuousAction_Active = false;
    if (!isNull _medic
        && {(_medic getVariable ["ACM_core_ContinuousAction_Session", []]) isEqualTo [_patient, _continuousEpoch]}) then {
        _medic setVariable ["ACM_core_ContinuousAction_Session", [], true];
    };
};

// Release only the exact stethoscope treatment-pose generation. treatmentPoseStop restores animSpeedCoef,
// clears the remote/JIP hold and returns the provider through the move graph.
if (!isNull _medic && {_poseEpoch >= 0}
    && {(_medic getVariable ["ACME_treatmentPoseEpoch",-2]) == _poseEpoch}) then {
    [_medic,"stethoscope",_poseEpoch] call ACME_fnc_treatmentPoseStop;

    // A malformed/partially-cleared pose record used to make treatmentPoseStop return before the speed reset.
    // Because the exact pose epoch still belongs to this closed scope, it is safe to repair that one orphan here.
    if (local _medic && {getAnimSpeedCoef _medic == 0}) then {
        _medic setAnimSpeedCoef 1;
    };
    if (local _medic
        && {toLowerANSI animationState _medic == "acme_stethoscopework"}
        && {!([_medic] call ACME_fnc_animBlocked)}) then {
        _medic setUnitPos "MIDDLE";
        [_medic,"AmovPknlMstpSnonWnonDnon",1] call ACME_fnc_doAnim;
    };
};

if ((uiNamespace getVariable ["ACM_breathing_Stethoscope_DLG",displayNull]) isEqualTo _display) then {
    uiNamespace setVariable ["ACM_breathing_Stethoscope_DLG",displayNull];
};
[-1] call ace_hearing_fnc_updateHearingProtection;
