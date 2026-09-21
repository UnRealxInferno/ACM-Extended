// add a "SEIZING (active)" or "Postictal" row to the medical-menu overview injury list while a patient is in the
// shared ACME generalized-seizure arc, regardless of whether the source is lidocaine toxicity, TBI or severe Sarin.
// a generalized seizure is a whole-body neuro finding, so it reads on the head and torso, the parts a medic checks
// for it, rather than a single limb. it mirrors the AAJT-s injury-entry pattern and hooks the same
// ace_medical_gui_updateInjuryListWounds event, which passes _woundEntries by reference.
// _this is [_ctrl, _target, _selectionN, _woundEntries, _bodyPartName].
params ["_ctrl", "_target", "_selectionN", "_woundEntries"];
if (isNull _target || {_selectionN < 0}) exitWith {};

private _state = _target getVariable ["ACME_lido_seizureState", ""];
if (_state == "") exitWith {};

// a whole-body neuro finding: show it on the head, 0, and the body, 1, only.
if !(_selectionN in [0, 1]) exitWith {};

switch (_state) do {
    case "active": {
        _woundEntries pushBack ["SEIZING (active)", (["danger", 1] call ACME_fnc_a11yColor)];
    };
    case "postictal": {
        _woundEntries pushBack ["Postictal", (["warning", 1] call ACME_fnc_a11yColor)];
    };
    default {};
};
