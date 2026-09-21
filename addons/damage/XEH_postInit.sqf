#include "script_component.hpp"

[QGVAR(wrapBruisesLocal), LINKFUNC(wrapBruisesLocal)] call CBA_fnc_addEventHandler;
[QGVAR(wrapBodyPartLocal), LINKFUNC(wrapBodyPartLocal)] call CBA_fnc_addEventHandler;

[QGVAR(handleCoagulationPFH), LINKFUNC(handleCoagulationPFH)] call CBA_fnc_addEventHandler;
[QGVAR(handleIBCoagulationPFH), LINKFUNC(handleIBCoagulationPFH)] call CBA_fnc_addEventHandler;

// B107: bandages provide progressive hemostasis while their treatment timer is running.  State lives on the
// patient owner so the circulation/wound calculations never depend on the provider's locality.
[QGVAR(bandageProgressStart), LINKFUNC(bandageProgressStart)] call CBA_fnc_addEventHandler;
[QGVAR(bandageProgressStop), LINKFUNC(bandageProgressStop)] call CBA_fnc_addEventHandler;

GVAR(BandageProgressClasses) = [
    "BasicBandage",
    "FieldDressing",
    "PackingBandage",
    "ElasticBandage",
    "QuikClot",
    "PressureBandage",
    "EmergencyTraumaDressing",
    "ACME_PackJunctional",
    "ACME_WrapJunctional"
];

{
    [_x, {
        params ["_medic", "_patient", "", "_classname"];
        if !(_classname in GVAR(BandageProgressClasses)) exitWith {};
        private _token = _medic getVariable ["ACME_BandageProgressToken", ""];
        if (_token isEqualTo "") exitWith {};
        [QGVAR(bandageProgressStop), [_patient, _token], _patient] call CBA_fnc_targetEvent;
        _medic setVariable ["ACME_BandageProgressToken", nil];
    }] call CBA_fnc_addEventHandler;
} forEach ["ace_treatmentSucceded", "ace_treatmentFailed"];
