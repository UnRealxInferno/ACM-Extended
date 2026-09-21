/* Release only Extended contributions. Never overwrite a native deterioration or revive an arrest. */
params ["_patient"];
if (isNull _patient || {!local _patient}) exitWith {};
[_patient, 0, true, true] call ACME_fnc_rhythmActiveCommit;
{[_patient, _x, 0] call ACME_fnc_setVarNet;} forEach ["ACME_rhythm_targetHR", "ACME_rhythm_bpOffset", "ACME_rhythm_painContribution"];
[_patient, "ACME_rhythm_savedTargetHR", nil] call ACME_fnc_setVarNet;
[_patient, "ACME_rhythm_torsadesStart", nil] call ACME_fnc_setVarNet;
[_patient, "ACME_rhythm_torsadesNonPerfusing", nil] call ACME_fnc_setVarNet;
[_patient, "ACME_rhythm_torsadesPerfusion", nil] call ACME_fnc_setVarNet;
_patient setVariable ["ACME_rhythm_torsadesArrestRequestAt", nil, false];
if ((_patient getVariable ["ACME_rhythm_obtundUntil", -1]) > 0) then {
    [_patient, "ACME_rhythm_obtundUntil", -1] call ACME_fnc_setVarNet;
    if (_patient getVariable ["ACME_obtunded", false]) then {[_patient, false, false] call ACME_fnc_obtundedSet;};
};
