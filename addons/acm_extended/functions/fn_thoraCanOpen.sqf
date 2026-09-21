// Can the thoracostomy mini-game be opened? _existingOnly is used by Adjust and must never create a fresh option.
params ["_medic", "_patient", ["_existingOnly", false, [false]]];
if (isNull _patient || {!(_patient isKindOf "CAManBase")}) exitWith {false};
private _completed = (_patient getVariable ["ACM_breathing_Thoracostomy_State", 0]) > 0
    || {(["left", "right"] findIf {
        (_patient getVariable [format ["ACME_thora_open_%1", _x], ""]) in ["finger", "sealed"]
            || {_patient getVariable [format ["ACME_thora_tube_%1", _x], false]}
    }) >= 0};
// A saved incision can resume an unfinished Perform Thoracostomy minigame, but it is NOT an "Adjust" procedure.
// Completed per-side tracts remain adjustable even if ACM's aggregate state has since changed.
private _partial = count (_patient getVariable ["ACME_thora_incision_left", []]) == 3
    || {count (_patient getVariable ["ACME_thora_incision_right", []]) == 3};
private _existing = _completed || _partial;
if (_existingOnly && {!_completed}) exitWith {false};
if (_existing && {([_medic, "thoracostomySeal", true] call ACME_fnc_procedureAllowed)
    || {[_medic, "thoracostomy", true] call ACME_fnc_procedureAllowed}
    || {[_medic, "chestTube", true] call ACME_fnc_procedureAllowed}}) exitWith {true};
if (_existingOnly) exitWith {false};
([_medic, "thoracostomy"] call ACME_fnc_procedureAllowed)
    && {([_medic, _patient] call ACME_fnc_thoraKitItem) != ""}
