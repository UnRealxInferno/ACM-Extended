/*
 * Force or clear a shock phenotype for scenarios/training.
 * [_patient, "cardiogenic", 0.8, 300] call ACME_fnc_shockSetPhenotype;
 * Types: auto/none, hemorrhagic, distributive, cardiogenic, obstructive, neurogenic.
 */
params [["_patient",objNull,[objNull]], ["_type","auto",[""]], ["_severity",0.7,[0]], ["_duration",-1,[0]]];
if (isNull _patient) exitWith {false};
_type = toLowerANSI _type;
if !(_type in ["auto","none","hemorrhagic","distributive","cardiogenic","obstructive","neurogenic"]) exitWith {false};
if (_type in ["auto","none"]) exitWith {
    _patient setVariable ["ACME_shock_forced", [], true];
    true
};
private _until = if (_duration > 0) then {CBA_missionTime + _duration} else {-1};
_patient setVariable ["ACME_shock_forced", [_type, (_severity max 0 min 1), _until], true];
true
