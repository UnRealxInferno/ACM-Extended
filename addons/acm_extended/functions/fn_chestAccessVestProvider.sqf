// Provider theatre for temporary plate-carrier removal.
// The user asked for the same medic4 body-handling animation used by front/back Flip while the casualty is lifted.
params [
    ["_medic", objNull, [objNull]],
    ["_patient", objNull, [objNull]]
];
if (isNull _medic || {!alive _medic}) exitWith {false};
if (!local _medic) exitWith {
    [_medic, "chestAccessVestProvider", [_medic, _patient]] call ACME_fnc_ownerDispatch;
    true
};
if ([_medic] call ACME_fnc_animBlocked) exitWith {false};

[_medic, "chestAccessVest", _patient] call ACME_fnc_rollProviderStart
