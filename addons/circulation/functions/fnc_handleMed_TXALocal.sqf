#include "..\script_component.hpp"
/*
 * Author: Blue
 * Handle TXA effects (LOCAL)
 *
 * Arguments:
 * 0: Patient <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call ACM_circulation_fnc_handleMed_TXALocal;
 *
 * Public: No
 */

params ["_patient"];

[QGVAR(handleCoagulationPFH), [_patient, true], _patient] call CBA_fnc_targetEvent;
[QGVAR(handleIBCoagulationPFH), [_patient, true], _patient] call CBA_fnc_targetEvent;

// Hemothorax has its own native ACM clot process. Normal chest-injury creation starts that PFH and the PFH reads
// TXA_IV directly on every clot attempt. ACME delivery routes, including syringe pushes and bag infusions, still
// produce TXA_IV, so preserve that exact model. This is only a lifecycle guard: if an active hemothorax somehow
// lost its PFH, TXA re-arms it without incrementing Hemothorax_State or otherwise changing ACM's clot odds/timing.
if ((_patient getVariable [QEGVAR(breathing,Hemothorax_State), 0]) > 0
    && {(_patient getVariable [QEGVAR(breathing,Hemothorax_PFH), -1]) == -1}) then {
    [_patient, true] call EFUNC(breathing,handleHemothorax);
};
