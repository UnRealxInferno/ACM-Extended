// stage 1 complete: the combat gauze is packed, taking the state from open to packed.
// combat gauze is the first-stage control: a finished packing holds the junction at 50 percent bleed control and
// stays there, and it does not work loose. holding direct pressure on top of the gauze brings it to 100 percent
// control while held. the pressure bandage, the wrap, is the definitive step that makes hemorrhage control
// permanent.
// on a conscious patient the packing hurts, moderately.
params ["_medic", "_patient", "_bodyPart"];
// the packing loop ends with the action rather than running on past it.
[_medic] call ACME_fnc_junctionalPackSfxStop;
private _p = toLower _bodyPart;
// The casualty owner owns junctional state and pain. Provider-local completion keeps only UI/SFX/log presentation.
[_patient, "junctionalPackDone", [_medic, _p]] call ACME_fnc_ownerDispatch;

["Combat gauze packed.", 4] call ace_common_fnc_displayTextStructured;

// record the completed intervention in the activity log of the patient.
[_patient, "activity",
 "%1 packed a junctional wound (%2) with combat gauze",
 "Wound packed, combat gauze, %2, %1",
 [[_medic, false, true] call ace_common_fnc_getName, [_p, "short"] call ACME_fnc_bodyPartName]] call ACME_fnc_medLog;
