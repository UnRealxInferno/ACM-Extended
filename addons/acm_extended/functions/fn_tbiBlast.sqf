// apply a blast traumatic brain injury at a severity the blast solver has already decided.
// call it as [_unit, _severity] call ACME_fnc_tbiBlast, where _severity is 0 to 1.
// this used to take the raw engine explosion damage, roll its own chance against it and derive its own severity.
// it does not any more. fn_blastsolve works out one pressure dose for the casualty and fn_blastapply turns that
// into a severity, so the brain, the lungs and the hearing all follow from the same wave rather than from three
// separate rolls off the same number. two casualties standing together now get consistent injuries, and one
// standing behind a wall gets a smaller dose rather than a separate coin flip.
// it escalates an existing TBI rather than replacing it, which is what makes repeated exposure worse than one
// large one.
params ["_unit", ["_severity", 0]];
if (isNull _unit || {!local _unit} || {!alive _unit}) exitWith {};
if (_severity <= 0) exitWith {};
private _sev = (_severity max 0.05) min 1;

private _state = _unit getVariable ["ACME_tbi_State", createHashMap];
if (count _state == 0) then {
    [_unit, _sev, false] call ACME_fnc_tbiInit;
    // the activity-log line is removed, because it revealed the condition of the patient.
} else {
    private _cur = _state getOrDefault ["severity", 0];
    private _struct = _state getOrDefault ["structuralSeverity", _cur];
    _state set ["structuralSeverity", _struct max _sev];
    if (_sev > _cur) then {
        _state set ["severity", _sev];
        _state set ["icp", ((_state getOrDefault ["icp", 10]) + 5) min (missionNamespace getVariable ["ACME_tbi_icpMax", 40])];
    };
    [_unit, _state] call ACME_fnc_tbiStateCommit;
};
