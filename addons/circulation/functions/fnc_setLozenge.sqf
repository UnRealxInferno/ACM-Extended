#include "..\script_component.hpp"
/*
 * Author: Blue
 * Handle setting lozenge for patient.
 *
 * Arguments:
 * 0: Medic <OBJECT>
 * 1: Patient <OBJECT>
 * 2: Type <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, cursorTarget, "Fentanyl"] call ACM_circulation_fnc_setLozenge;
 *
 * Public: No
 */

params ["_medic", "_patient", ["_type", ""]];

if (_type == "") then {
    // Capture age before owner-side removal clears the timestamp. serverTime is shared across clients.
    private _insertServer = _patient getVariable ["ACME_lozengeInsertServer", -1];
    private _woreOff = _insertServer >= 0 && {(serverTime - _insertServer) > 180};

    if (!isNull _medic) then {
        if (_woreOff) then {
            [LLSTRING(FentanylLozenge_Remove_WoreOff_Hint), 2, _medic] call ACEFUNC(common,displayTextStructured);
        } else {
            [LLSTRING(FentanylLozenge_Remove_Complete), 1.5, _medic] call ACEFUNC(common,displayTextStructured);
            [QACEGVAR(common,displayTextStructured), [(format [LLSTRING(FentanylLozenge_Remove_Hint), _medic]), 1.5, _patient], _patient] call CBA_fnc_targetEvent;
        };
    };
    [QGVAR(setLozengeLocal), [_medic, _patient, ""], _patient] call CBA_fnc_targetEvent;
} else {
    if ((_patient getVariable [QGVAR(LozengeItem), ""]) != "") exitWith {
        [LLSTRING(FentanylLozenge_Already), 2, _medic] call ACEFUNC(common,displayTextStructured);
    };

    if ((_patient getVariable [QEGVAR(airway,AirwayItem_Oral), ""]) != "") exitWith {
        [LLSTRING(FentanylLozenge_Blocked), 2, _medic] call ACEFUNC(common,displayTextStructured);
    };

    [_patient, LLSTRING(FentanylLozenge)] call ACEFUNC(medical_treatment,addToTriageCard);

    [_patient, "activity", LLSTRING(FentanylLozenge_Give_ActionLog), [[_medic, false, true] call ACEFUNC(common,getName)]] call ACEFUNC(medical_treatment,addToLog);
    [LLSTRING(FentanylLozenge_Give_Complete), 1.5, _medic] call ACEFUNC(common,displayTextStructured);
    [QACEGVAR(common,displayTextStructured), [(format [LLSTRING(FentanylLozenge_Give_Hint), _medic]), 2, _patient], _patient] call CBA_fnc_targetEvent;

    [QACEGVAR(medical_treatment,medicationLocal), [_patient, "head", (format ["%1_BUC", _type]), 1, false], _patient] call CBA_fnc_targetEvent;

    [QGVAR(setLozengeLocal), [_medic, _patient, _type], _patient] call CBA_fnc_targetEvent;
};
