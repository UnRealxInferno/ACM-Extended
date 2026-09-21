// a debug action: toggle polymorphic vt, or torsades, code 102, on the patient.
// Debug induction enters perfusing polymorphic VT directly. If native physiology subsequently arrests the patient,
// the custom overlay releases and ACM owns the resulting pulseless VT/VF/asystole state.
// _this is the ACE callback [_medic, _patient, _bodyPart].
params ["_medic", "_patient"];
[_medic, _patient, 102, "Torsades (polymorphic VT)", (missionNamespace getVariable ["ACME_rhythm_torsadesHR", 210])] call ACME_fnc_rhythmToggle;
