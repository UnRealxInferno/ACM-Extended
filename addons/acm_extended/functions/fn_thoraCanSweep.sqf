/* Existing finger tracts can be rechecked without another disposable kit. */
params ["_medic", "_patient", "_side"];
if (isNull _patient || {!(_side in ["left", "right"])}) exitWith {false};
([_medic, "thoracostomy", true] call ACME_fnc_procedureAllowed)
    && {count (_patient getVariable [format ["ACME_thora_incision_%1", _side], []]) == 3}
    && {(_patient getVariable [format ["ACME_thora_open_%1", _side], ""]) == "finger"}
    && {!(_patient getVariable [format ["ACME_thora_tube_%1", _side], false])}
    && {!(_patient getVariable [format ["ACME_thora_sealed_%1", _side], false])}
    && {!(_patient getVariable [format ["ACME_thora_closed_%1", _side], false])}
