// End the chest-seal minigame's temporary casualty state.
// The last viewer restores the side the casualty started on, returns the carrier, then resumes Semi-Fowler if needed.
params [
    ["_patient", objNull, [objNull]],
    ["_token", "", [""]]
];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {
    [_patient, "chestSealPatientEnd", [_patient, _token]] call ACME_fnc_ownerDispatch;
};

private _tokens = +(_patient getVariable ["ACME_CS_ProcedureTokens", []]);
if (_token == "" || {!(_token in _tokens)}) exitWith {};
_tokens = _tokens - [_token];
private _generation = _patient getVariable ["ACME_CS_ProcedureGeneration", 0];
_patient setVariable ["ACME_CS_ProcedureTokens", _tokens, true];
if !(_tokens isEqualTo []) exitWith {};
if !(_patient getVariable ["ACME_CS_ProcedureActive", false]) exitWith {};

private _pre = +(_patient getVariable ["ACME_CS_PreProcedureState", ["front", false, false, false, ""]]);
private _preSide = _pre param [0, "front", [""]];
private _preHeadElev = _pre param [1, false, [false]];
private _preRecovery = _pre param [2, false, [false]];
private _preAnim = _pre param [4, "", [""]];
if !(_preSide in ["front", "back"]) then {_preSide = "front";};
// Defensive migration for a procedure state written by an older build while Semi-Fowler was tilted.
// A head-elevated casualty always returns to anterior-up before the elevation resumes.
if (_preHeadElev) then {_preSide = "front";};

// Finalize the non-roll pieces only after the body is back on its original side.
private _finish = {
    params ["_p", "_wasHeadElev", "_wasRecovery", "_oldAnim", "_generation"];
    if (isNull _p || {!local _p}
        || {(_p getVariable ["ACME_CS_ProcedureGeneration", -1]) != _generation}
        || {!((_p getVariable ["ACME_CS_ProcedureTokens", []]) isEqualTo [])}) exitWith {};

    private _vestEntry = +(_p getVariable ["ACME_CS_vestLoadout", []]);
    if ((count _vestEntry) == 2 && {(vest _p) == ""}) then {
        private _loadout = getUnitLoadout _p;
        if ((count _loadout) > 4) then {
            _loadout set [4, _vestEntry];
            _p setUnitLoadout [_loadout, false];
        };
    };
    private _prop = _p getVariable ["ACME_CS_vestProp", objNull];
    if (!isNull _prop) then {detach _prop; deleteVehicle _prop;};
    _p setVariable ["ACME_CS_vestProp", objNull, true];
    _p setVariable ["ACME_CS_vestLoadout", [], true];
    _p setVariable ["ACME_CS_vestBusy", "", false];
    _p setVariable ["ACME_CS_vestReadyServer", serverTime, true];
    _p setVariable ["ACME_CS_ProcedureActive", false, true];
    _p setVariable ["ACME_CS_ProcedureReadyAt", -1, true];
    _p setVariable ["ACME_CS_ProcedureGrounded", false, true];
    _p setVariable ["ACME_CS_PreProcedureState", [], true];
    _p setVariable ["ACME_CS_rollUntil", -1, false];

    // Semi-Fowler is a suspended logical state, not a new placement. Resume the exact existing elevation only after
    // the roll and carrier cleanup are finished.
    if (_wasHeadElev && {_p getVariable ["ACME_headElevated", false]}
        && {_p getVariable ["ACME_headElev_Suspended", false]}
        && {((_p getVariable ["ACME_lido_seizureState", ""]) in ["", "postictal"])}
    ) then {
        _p setVariable ["ACME_headElev_ResumePending", true, true];
        [{_this call ACME_fnc_headElevTryResume;}, [_p], missionNamespace getVariable ["ACME_headElev_resumeDelay", 0.75]] call CBA_fnc_waitAndExecute;
    } else {
        // Restore the native recovery-position state/worker only after chest access is completely finished.
        if (_wasRecovery && {alive _p}
            && {_p getVariable ["ACE_isUnconscious", false]} && {isNull objectParent _p}) then {
            [_p, _p, true, true] call ACM_airway_fnc_setRecoveryPosition;
        } else {
            if (_wasRecovery && {_oldAnim != ""} && {alive _p} && {isNull objectParent _p}) then {
                [_p, _oldAnim, 2, "chest-seal-restore", objNull, 1.0, 2] call ACME_fnc_patientAnimRequest;
            };
        };
    };
};

private _restoreSide = {
    params ["_p", "_side", "_wasHeadElev", "_wasRecovery", "_oldAnim", "_finishCode", "_generation"];
    if (isNull _p || {!local _p}
        || {(_p getVariable ["ACME_CS_ProcedureGeneration", -1]) != _generation}
        || {!((_p getVariable ["ACME_CS_ProcedureTokens", []]) isEqualTo [])}) exitWith {};
    private _actual = [_p, _p getVariable ["ACME_CS_facing", "front"]] call ACME_fnc_chestSealActualSide;
    private _dead = (!alive _p) || {(lifeState _p) isEqualTo "DEAD"};
    // Closing the workspace cannot restore an old side by force after the casualty has woken,
    // stood up, started crawling, or otherwise left ACM's authored lying/unconscious state.
    private _canRoll = !_dead && {[_p] call ACME_fnc_chestSealCanPhysicalRoll};

    if (_canRoll && {_actual != _side}) then {
        [_p, _side, false, objNull] call ACME_fnc_chestSealRoll;
        private _rollTime = missionNamespace getVariable ["ACME_CS_rollTime", 1.85];
        if (!(_rollTime isEqualType 0) || {_rollTime < 0}) then {_rollTime = 1.85;};
        [{
            params ["_unit", "_head", "_recovery", "_anim", "_fn", "_generation"];
            [_unit, _head, _recovery, _anim, _generation] call _fn;
        }, [_p, _wasHeadElev, _wasRecovery, _oldAnim, _finishCode, _generation], _rollTime + 0.08] call CBA_fnc_waitAndExecute;
    } else {
        [_p, _wasHeadElev, _wasRecovery, _oldAnim, _generation] call _finishCode;
    };
};

// Closing while a Flip is physically in progress is an explicit abort. Do not let the current roll finish and
// do not queue a second full roll back to the procedure's starting side. Cancel the live roll token, snap the
// grounded casualty directly to the original stable side, then finish carrier/posture restoration immediately.
private _rollToken = _patient getVariable ["ACME_CS_rollToken", ""];
private _rollUntil = _patient getVariable ["ACME_CS_rollUntil", -1];
private _rollActive = (_rollToken != "") || {(_rollUntil isEqualType 0) && {_rollUntil > CBA_missionTime}};
if (_rollActive) exitWith {
    [_patient, _preSide] call ACME_fnc_patientRollCancel;
    [_patient, _preHeadElev, _preRecovery, _preAnim, _generation] call _finish;
};

// A completed flip is different from a cancelled one: normal workspace close may still use the authored roll to
// restore the casualty's original side.
[_patient, _preSide, _preHeadElev, _preRecovery, _preAnim, _finish, _generation] call _restoreSide;
