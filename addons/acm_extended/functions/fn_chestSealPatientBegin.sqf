// Begin the temporary casualty state used by the chest-seal minigame.
// The first viewer owns preparation. Additional viewers share the same state and do not strip gear twice.
params [
    ["_patient", objNull, [objNull]],
    ["_token", "", [""]],
    ["_medic", objNull, [objNull]]
];
if (isNull _patient || {_token == ""}) exitWith {};
if (!local _patient) exitWith {
    [_patient, "chestSealPatientBegin", [_patient, _token, _medic]] call ACME_fnc_ownerDispatch;
};

private _tokens = +(_patient getVariable ["ACME_CS_ProcedureTokens", []]);
if (_token in _tokens) exitWith {};
private _first = !(_patient getVariable ["ACME_CS_ProcedureActive", false]);
_patient setVariable ["ACME_CS_ProcedureGeneration", 1 + (_patient getVariable ["ACME_CS_ProcedureGeneration", 0])];
_tokens pushBack _token;
_patient setVariable ["ACME_CS_ProcedureTokens", _tokens, true];
_patient setVariable ["ACME_CS_ProcedureActive", true, true];

// A second medic joins the already prepared workspace. The existing ready time is authoritative.
if (!_first) exitWith {};

private _preHeadElev = _patient getVariable ["ACME_headElevated", false];
// Semi-Fowler is an anterior-up/supine posture.  Do not infer a back-facing state from the tilted
// model geometry or Done can perform a spurious roll before the elevation is resumed.
private _preSide = if (_preHeadElev) then {
    "front"
} else {
    [_patient, _patient getVariable ["ACME_CS_facing", "front"]] call ACME_fnc_chestSealActualSide
};
private _preRecovery = _patient getVariable ["ACM_airway_RecoveryPosition_State", false];
private _preLying = _patient getVariable ["ACM_core_Lying_State", false];
private _preAnim = animationState _patient;
// This flag records whether physical rolling was legitimately permitted when the workspace opened.
// Manual prone, obtundation and ordinary conscious posture are not roll permission.
private _preGrounded = [_patient] call ACME_fnc_chestSealCanPhysicalRoll;
_patient setVariable ["ACME_CS_PreProcedureState", [_preSide, _preHeadElev, _preRecovery, _preLying, _preAnim], true];
_patient setVariable ["ACME_CS_ProcedureGrounded", _preGrounded, true];
_patient setVariable ["ACME_CS_facing", _preSide, true];
_patient setVariable ["ACME_CS_rollUntil", -1, false];

private _readyDelay = 0.12;

// Recovery position is suspended for the procedure just like Semi-Fowler. The existing worker notices the false
// state and retires; the exact pre-procedure state is restored only when the last viewer presses Done/closes.
if (_preRecovery) then {
    _patient setVariable ["ACM_airway_RecoveryPosition_State", false, true];
    _patient setVariable ["ACM_airway_HeadTilt_State", false, true];
};

// A Semi-Fowler casualty is laid flat once, before the minigame. Keep the support carrier out of the chest
// workspace instead of putting it back on the patient while flat.
if (_preHeadElev) then {
    _patient setVariable ["ACME_headElev_ResumePending", false, true];
    [_patient, true] call ACME_fnc_headElevSuspend;
    private _headReady = _patient getVariable ["ACME_headElev_suspendReadyAt", -1];
    if (_headReady > CBA_missionTime) then {
        _readyDelay = _readyDelay max ((_headReady - CBA_missionTime) + 0.08);
    };
};

// If a carrier is still worn, chest access now uses the same patient lift/release theatre as Semi-Fowler.
// The provider simultaneously performs the normal medic4 body-handling animation. Removal happens only while the
// casualty is visibly lifted, then the casualty is laid flat again before any front/back normalization begins.
_patient setVariable ["ACME_CS_vestLoadout", [], true];
_patient setVariable ["ACME_CS_vestProp", objNull, true];
_patient setVariable ["ACME_CS_vestReadyServer", serverTime, true];
private _hadVest = (vest _patient) != "" && {count ((getUnitLoadout _patient) param [4, [], [[]]]) == 2};
if (_hadVest) then {
    [_patient, _medic, "chestseal"] call ACME_fnc_chestAccessVestAcquire;
    private _vestReady = _patient getVariable ["ACME_CS_vestReadyServer", serverTime];
    if (_vestReady > serverTime) then {
        _readyDelay = _readyDelay max ((_vestReady - serverTime) + 0.02);
    };
};

// Normalize a live, grounded casualty to the anterior/supine workspace only AFTER the temporary lift/removal
// sequence has settled. This prevents the Semi-Fowler Grab/Release and a front/back roll from fighting over the
// casualty skeleton.
private _canNormalize = alive _patient && {isNull objectParent _patient} && {_preGrounded};
private _actualNow = [_patient, _preSide] call ACME_fnc_chestSealActualSide;
if (_canNormalize && {_actualNow != "front"}) then {
    private _rollTime = missionNamespace getVariable ["ACME_CS_rollTime", 1.85];
    if (!(_rollTime isEqualType 0) || {_rollTime < 0}) then {_rollTime = 1.85;};
    private _rollDelay = _readyDelay;
    [{
        params ["_p","_m"];
        if (isNull _p || {!local _p} || {!alive _p}) exitWith {};
        if (!isNull _m) then {[_m, "chestAccessVestProvider", [_m, _p]] call ACME_fnc_ownerDispatch;};
        [_p, "front", false, _m] call ACME_fnc_chestSealRoll;
    }, [_patient,_medic], _rollDelay] call CBA_fnc_waitAndExecute;
    private _providerRollTime = (missionNamespace getVariable ["ACME_rollProviderDuration", 2.2]) + 0.35;
    _readyDelay = _readyDelay + ((_rollTime + 0.08) max _providerRollTime);
};

_patient setVariable ["ACME_CS_ProcedureReadyAt", serverTime + _readyDelay, true];
