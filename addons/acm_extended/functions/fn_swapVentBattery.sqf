params ["_medic", "_patient"];
if (isNull _patient) exitWith {};
if (local _patient) then {
    _patient setVariable ["ACME_vent_battery", 100, true];
    _patient setVariable ["ACME_vent_battWarned", 0, true];
} else {
    [_patient, "ventBattery", []] call ACME_fnc_ownerDispatch;
};
// Battery state belongs to the casualty/ventilator owner. Click/message are provider presentation only.
if (!isNull _medic && {local _medic}) then {
    playSound "ACME_VentClick";
    ["Fresh battery fitted. Ventilator at 100%.", 2, _medic] call ace_common_fnc_displayTextStructured;
};
