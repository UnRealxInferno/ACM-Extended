/* Authoritative custom-rhythm writer. Perfusing torsades remains custom until native physiology actually arrests the patient. */
params ["_unit", ["_code", 0], ["_epoch", -1]];
if (isNull _unit || {!(_code isEqualType 0)}) exitWith {};
if (_epoch < 0) then {_epoch = [_unit] call ACME_fnc_clinicalEpoch;};
if (!local _unit) exitWith {[_unit, "rhythmSet", [_unit, _code, _epoch]] call ACME_fnc_ownerDispatch;};
if (_epoch != ([_unit] call ACME_fnc_clinicalEpoch)) exitWith {};
// B67: invalidate ACM's monitor rhythm cache at the authoritative rhythm write. Native ACM already splices a
// rhythm change into the remainder of the active sweep; this guarantees custom ACME rhythm changes enter that
// path on the very next monitor update instead of waiting for a completed sweep.
private _forceMonitorRefresh = {
    params ["_u"];
    [_u, [["aedPadsLastSync", -1]], true] call ACM_circulation_fnc_setRuntimeState;
    [_u, [["aedEkgRhythm", -99]], true] call ACM_circulation_fnc_setRuntimeState;
};
if (_code in [100,101,102,103,104] && {(_unit getVariable ["ACME_rhythm_targetHR",0]) <= 0}) then {
    private _fallbackHR = switch (_code) do {
        case 100: {missionNamespace getVariable ["ACME_rhythm_afibHR",165]};
        case 101: {missionNamespace getVariable ["ACME_rhythm_atHR",185]};
        case 102: {missionNamespace getVariable ["ACME_rhythm_torsadesHR",210]};
        case 103: {missionNamespace getVariable ["ACME_rhythm_afibControlledHR",80]};
        case 104: {missionNamespace getVariable ["ACME_rhythm_svtHR",190]};
        default {80};
    };
    [_unit,"ACME_rhythm_targetHR",_fallbackHR] call ACME_fnc_setVarNet;
};
if (_code == 102) exitWith {
    if (!alive _unit || {_unit getVariable ["ace_medical_inCardiacArrest", false]}) exitWith {};
    if ((_unit getVariable ["ACME_rhythm_active", 0]) != 102) then {
        [_unit, "ACME_rhythm_torsadesStart", CBA_missionTime] call ACME_fnc_setVarNet;
        [_unit, "ACME_rhythm_torsadesNonPerfusing", false] call ACME_fnc_setVarNet;
        [_unit, "ACME_rhythm_torsadesPerfusion", 1] call ACME_fnc_setVarNet;
        _unit setVariable ["ACME_rhythm_torsadesArrestRequestAt", -1, false];
    };
    [_unit, "", -1, true, true] call ACME_fnc_rhythmNativeHoldCommit;
    [_unit, 0, true, true, false] call ACME_fnc_rhythmNativeHighHRFloorCommit;
    [_unit, 102, true, true] call ACME_fnc_rhythmActiveCommit;
    [_unit, [["cardiacRhythmState", 0]], true] call ACM_circulation_fnc_setRuntimeState;
    [_unit] call _forceMonitorRefresh;
};
if (_code in [100,101,103,104]) exitWith {
    if (!alive _unit || {_unit getVariable ["ace_medical_inCardiacArrest", false]}) exitWith {};
    // An explicit induction replaces the previous perfusing rhythm. Clear its old ventricular hold here,
    // at the owner-authoritative transition, so the next threshold tick cannot resurrect a stale VT.
    // Observation/ticking never uses this path to clear an actual native deterioration or an arrest.
    [_unit, "", -1, true, true] call ACME_fnc_rhythmNativeHoldCommit;
    [_unit, 0, true, true, false] call ACME_fnc_rhythmNativeHighHRFloorCommit;
    {
        _x params ["_key", "_value"];
        if (_key isEqualTo "ACM_circulation_CardiacArrest_TargetRhythm") then {
            [_unit, _value] call ACM_circulation_fnc_setCardiacArrestTargetRhythm;
        } else {
            [_unit, _key, _value] call ACME_fnc_setVarNet;
        };
    } forEach [
        ["ACME_rhythmNativeHoldSince", -1],
        ["ACME_rhythmNativeLastSeen", -1],
        ["ACME_rhythmNativeClearStart", -1],
        ["ACME_rhythmThresholdForced", ""],
        ["ACME_rhythmThresholdKind", ""],
        ["ACME_rhythmThresholdStart", -1],
        ["ACM_circulation_CardiacArrest_TargetRhythm", 0]
    ];
    [_unit, "ACME_rhythm_torsadesStart", nil] call ACME_fnc_setVarNet;
    [_unit, "ACME_rhythm_torsadesNonPerfusing", nil] call ACME_fnc_setVarNet;
    [_unit, "ACME_rhythm_torsadesPerfusion", nil] call ACME_fnc_setVarNet;
    _unit setVariable ["ACME_rhythm_torsadesArrestRequestAt", nil, false];
    [_unit, _code, true, true] call ACME_fnc_rhythmActiveCommit;
    [_unit, [["cardiacRhythmState", 0]], true] call ACM_circulation_fnc_setRuntimeState;
    [_unit] call _forceMonitorRefresh;
};
if (_code >= -1 && {_code <= 5}) then {
    [_unit, "ACME_rhythm_torsadesStart", nil] call ACME_fnc_setVarNet;
    [_unit, "ACME_rhythm_torsadesNonPerfusing", nil] call ACME_fnc_setVarNet;
    [_unit, "ACME_rhythm_torsadesPerfusion", nil] call ACME_fnc_setVarNet;
    _unit setVariable ["ACME_rhythm_torsadesArrestRequestAt", nil, false];
    [_unit] call ACME_fnc_rhythmRelease;
    if (_code == 5) then {
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
        [_unit, "ACME_peaElectricalHR", _peaHR] call ACME_fnc_setVarNet;
        [_unit, "ACME_peaElectricalStart", CBA_missionTime] call ACME_fnc_setVarNet;
    } else {
        [_unit, "ACME_peaElectricalHR", nil] call ACME_fnc_setVarNet;
        [_unit, "ACME_peaElectricalStart", nil] call ACME_fnc_setVarNet;
    };
    [_unit, [["cardiacRhythmState", _code]], true] call ACM_circulation_fnc_setRuntimeState;
    [_unit] call _forceMonitorRefresh;
};
