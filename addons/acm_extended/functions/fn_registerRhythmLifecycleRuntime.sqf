// custom cardiac rhythms.
// the three ACM waveform generators are overridden at compile time through CfgFunctions, because ACM compiles
// its functions final and a runtime reassignment is ignored silently. the ekg override delegates codes of 100
// and above to ACME_fnc_genRhythmEKG. the pleth and capno overrides render a custom code as sinus. there is
// nothing to install here at runtime.

// sustain the active custom rhythms. this holds the display rhythm and drives hr to the target.
[{call ACME_fnc_rhythmTick}, 0.5, []] call CBA_fnc_addPerFrameHandler;
// physical awake-but-lying state change. it runs where the patient is local.
["ACME_obtundedApply", {_this call ACME_fnc_obtundedApply}] call CBA_fnc_addEventHandler;

// reset our per-life patient state on respawn. these vars live on the unit and otherwise bleed into the next
// life, so an obtunded or arrhythmic prior life carries over. this clears both units and force-removes the
// client-side obtundation screen effects on the fresh life.
// the mission-level handler is "EntityRespawned", with params [newentity, oldentity]. the "Respawn" enum exists
// only as a unit event handler. EntityRespawned fires for every entity, so we guard to humans only.
addMissionEventHandler ["EntityRespawned", {
    params ["_newUnit", "_oldUnit"];
    if !(_newUnit isKindOf "CAManBase") exitWith {};

    // The old body remains a corpse snapshot. Stop any residual local workers without deleting its injuries,
    // airway devices, vascular access, chest interventions, AAJT-S, dressings or other treatment evidence.
    if (!isNull _oldUnit && {local _oldUnit}) then {[_oldUnit] call ACME_fnc_deathFreeze;};

    // Only the freshly spawned life is scrubbed back to baseline.
    if (!isNull _newUnit && {local _newUnit}) then {[_newUnit] call ACME_fnc_clearAllAilments;};
    if (!isNull _newUnit) then {
        [_newUnit, false, false, "", -1, local _newUnit] call ACME_fnc_obtundedStateCommit;
        _newUnit setVariable ["ACME_obtunded_forcedBack", false, local _newUnit];
        [_newUnit, 0, local _newUnit, false] call ACME_fnc_rhythmActiveCommit;
        _newUnit setVariable ["ACME_rhythm_targetHR", 0, local _newUnit];
        _newUnit setVariable ["ACME_rhythm_bpOffset", 0, local _newUnit];
        _newUnit setVariable ["ACME_rhythm_savedTargetHR", nil, local _newUnit];
        _newUnit setVariable ["ACME_rhythm_obtundUntil", -1, local _newUnit];
        _newUnit setVariable ["ACME_rhythm_torsadesNonPerfusing", nil, local _newUnit];
        _newUnit setVariable ["ACME_rhythm_torsadesPerfusion", nil, local _newUnit];
        _newUnit setVariable ["ACME_rhythm_torsadesArrestRequestAt", nil, false];
        [_newUnit, "", -1, local _newUnit, false] call ACME_fnc_rhythmNativeHoldCommit;
        [_newUnit, 0, false, false, false] call ACME_fnc_rhythmNativeHighHRFloorCommit;
        [_newUnit, 0, false, false] call ACME_fnc_rhythmNativeShockGraceCommit;
        [_newUnit, [["cardiacRhythmState", 0]], local _newUnit] call ACM_circulation_fnc_setRuntimeState;
        [_newUnit, false, false, false, local _newUnit, false] call ACME_fnc_nrbStateCommit;
        [_newUnit, "", local _newUnit, false] call ACME_fnc_hpmkStateCommit;
        _newUnit setVariable ["ACME_emma_bvmAttached", false, local _newUnit];
        _newUnit setVariable ["ACME_emma_lastPatient", objNull];
        _newUnit setVariable ["ACME_emma_lastBag", -1e9];
    };

    // Ownership of the new player can settle a moment after EntityRespawned. Re-run the NEW-life reset on whichever
    // machine actually owns it; never touch the old corpse here.
    [{
        params ["_u"];
        if (isNull _u || {!alive _u}) exitWith {};
        if (local _u) then {[_u] call ACME_fnc_clearAllAilments;};
    }, [_newUnit], 2.0] call CBA_fnc_waitAndExecute;

    [_newUnit, false] call ACME_fnc_obtundedApply;
    if (!isNil "ACME_hpmk_activePatients") then {ACME_hpmk_activePatients = ACME_hpmk_activePatients - [_oldUnit, _newUnit];};
}];


// clear the native rhythm persistence after a confirmed ROSC. vt, vf and PVT must not self-clear from an hr
// wobble, but ACM's successful resuscitation pathway must be able to restore an organized rhythm.
["ace_medical_CPRSucceeded", {
    params ["_patient"];
    if (isNull _patient) exitWith {};
    [_patient, CBA_missionTime + (missionNamespace getVariable ["ACME_rhythmNativeShockGraceSec", 10]), true, false] call ACME_fnc_rhythmNativeShockGraceCommit;
    [_patient, "", -1, true, false] call ACME_fnc_rhythmNativeHoldCommit;
    [_patient, 0, false, false, false] call ACME_fnc_rhythmNativeHighHRFloorCommit;
    if (local _patient) then {
        _patient setVariable ["ACME_peaElectricalHR", nil, true];
        _patient setVariable ["ACME_peaElectricalState", nil, true];
    };
}] call CBA_fnc_addEventHandler;
