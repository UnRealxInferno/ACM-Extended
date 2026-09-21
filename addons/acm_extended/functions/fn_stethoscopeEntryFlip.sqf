// Roll a prone casualty supine before opening the auscultation minigame.
// Uses the same provider theatre and patient roll primitive as chest-seal Flip.
params [
    ["_medic", objNull, [objNull]],
    ["_patient", objNull, [objNull]],
    ["_bodyPart", "Body", [""]]
];
if (isNull _medic || {isNull _patient} || {!local _medic} || {!alive _medic} || {!alive _patient}) exitWith {};

private _actual = [_patient, _patient getVariable ["ACME_CS_facing", "front"]] call ACME_fnc_chestSealActualSide;
if (_actual != "back" || {!([_patient] call ACME_fnc_chestSealCanPhysicalRoll)}) exitWith {
    [_medic, _patient, _bodyPart, true] call ACM_breathing_fnc_useStethoscope;
};

// Reserve the continuous-action generation BEFORE the asynchronous roll. Without this, the UseStethoscope
// treatment-success lifecycle can reopen the medical menu while the casualty is still rolling. When the roll
// finishes, that deferred menu wins one frame after the scope appears and immediately triggers "Stopped using
// Stethoscope." The final scope adopts this exact epoch instead of creating a second generation.
if (missionNamespace getVariable ["ACM_core_ContinuousAction_Active", false]) exitWith {};
private _entryEpoch = (missionNamespace getVariable ["ACM_core_ContinuousAction_Epoch", 0]) + 1;
missionNamespace setVariable ["ACM_core_ContinuousAction_Epoch", _entryEpoch];
missionNamespace setVariable ["ACM_core_ContinuousAction_IsDialog", true];
missionNamespace setVariable ["ACM_core_ContinuousAction_Active", true];
missionNamespace setVariable ["ACM_core_ContinuousAction_ShouldReopen", false];
ace_medical_gui_pendingReopen = false;
_medic setVariable ["ACM_core_ContinuousAction_Session", [_patient, _entryEpoch], true];
_medic setVariable ["ACM_core_ContinuousAction_LastSeen", CBA_missionTime, true];
_medic setVariable ["ACME_stethEntryEpoch", _entryEpoch, false];

private _started = [_medic, "stethoscopeEntry", _patient] call ACME_fnc_rollProviderStart;
if (!_started) exitWith {
    if ((missionNamespace getVariable ["ACM_core_ContinuousAction_Epoch", -2]) == _entryEpoch) then {
        missionNamespace setVariable ["ACM_core_ContinuousAction_Active", false];
        missionNamespace setVariable ["ACM_core_ContinuousAction_IsDialog", false];
    };
    if ((_medic getVariable ["ACM_core_ContinuousAction_Session", []]) isEqualTo [_patient, _entryEpoch]) then {
        _medic setVariable ["ACM_core_ContinuousAction_Session", [], true];
    };
    _medic setVariable ["ACME_stethEntryEpoch", -1, false];
    ["Unable to reposition patient for auscultation.", 2, _medic] call ace_common_fnc_displayTextStructured;
    ["ace_treatmentFailed", [_medic, _patient, _bodyPart, "ACM_ContinuousAction", "", "", false]] call CBA_fnc_localEvent;
    ["ACM_core_openMedicalMenu", _patient] call CBA_fnc_localEvent;
};

private _pose = _medic getVariable ["ACME_treatmentPoseState", []];
private _epoch = _pose param [0, -1];
private _rollToken = _medic getVariable ["ACME_rollProviderToken", ""];
if (_epoch < 0 || {_rollToken == ""}) exitWith {
    if ((missionNamespace getVariable ["ACM_core_ContinuousAction_Epoch", -2]) == _entryEpoch) then {
        missionNamespace setVariable ["ACM_core_ContinuousAction_Active", false];
        missionNamespace setVariable ["ACM_core_ContinuousAction_IsDialog", false];
    };
    if ((_medic getVariable ["ACM_core_ContinuousAction_Session", []]) isEqualTo [_patient, _entryEpoch]) then {
        _medic setVariable ["ACM_core_ContinuousAction_Session", [], true];
    };
    _medic setVariable ["ACME_stethEntryEpoch", -1, false];
    ["ace_treatmentFailed", [_medic, _patient, _bodyPart, "ACM_ContinuousAction", "", "", false]] call CBA_fnc_localEvent;
};

private _rollTime = missionNamespace getVariable ["ACME_CS_rollTime", 1.85];
if !(_rollTime isEqualType 0 && {finite _rollTime}) then {_rollTime = 1.85;};
_rollTime = (_rollTime max 0.1) min 5;

private _args = [_medic, _patient, _bodyPart, _epoch, _rollToken, _rollTime, -1, diag_tickTime + 5.5, _entryEpoch];
[{_this call ACME_fnc_stethoscopeEntryFlipTick;}, 0, _args] call CBA_fnc_addPerFrameHandler;
