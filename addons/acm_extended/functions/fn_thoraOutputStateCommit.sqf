/* Phase 85: authoritative writer for thoracostomy drainage/output metrics.
 * _public is preserved per caller because live totals are networked while high-frequency history/fluid cursors are local.
 * An omitted/nil value means clear the variable; do not bind an undefined local and then pass it to setVariable.
 */
params ["_patient", "_field"];
if (isNull _patient) exitWith {};
private _hasValue = (count _this > 2) && {!isNil {_this select 2}};
private _public = _this param [3, true];
private _key = toLower _field;
private _name = switch (_key) do {
    case "ml": {"ACME_thora_outputMl"};
    case "perhour": {"ACME_thora_outputPerHour"};
    case "start": {"ACME_thora_outputStart"};
    case "hist": {"ACME_thora_outputHist"};
    case "fluidseen": {"ACME_thora_fluidSeen"};
    default {""};
};
if (_name isEqualTo "") exitWith {};
if (_hasValue) then {
    _patient setVariable [_name, _this select 2, _public];
} else {
    _patient setVariable [_name, nil, _public];
};
