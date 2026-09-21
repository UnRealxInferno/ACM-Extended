// unwrap a fully-wrapped HPMK back to the prepped state, taking the state from wrapped to prepped.
// rewarming stops, because the ground blanket despawns, the wrapped body overlay hides and the unwrapped cutout
// returns, and the canTreatCached gate clears so all body treatments are available again.
// the kit is not returned here, because it is still prepped and out. use remove from the prepped state to stow it.
// _this is the ACE callback [_medic, _patient, _bodyPart].
params ["_medic", "_patient"];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {
    ["ACME_ownerCommand", [_patient, "hpmkUnwrap", [_medic, _patient]], _patient] call CBA_fnc_targetEvent;
};
if (!((_patient getVariable ["ACME_hpmk_state", ""]) in ["wrapped", "exposed"])) exitWith {};

[_patient, "prepped", true, false] call ACME_fnc_hpmkStateCommit;
if (!isNil "ACME_hpmk_activePatients") then { ACME_hpmk_activePatients = ACME_hpmk_activePatients - [_patient]; };

["HPMK unwrapped.", 3, _medic] call ace_common_fnc_displayTextStructured;
if (!isNil "ace_medical_treatment_fnc_addToLog") then {
    [_patient, "activity", "NAR HPMK unwrapped", []] call ace_medical_treatment_fnc_addToLog;
};
