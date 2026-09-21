// remove an 18g iv from a patient. Gauge type 5 is ACME's 18g.
// Durable access state, compromise state and persistent IV art all commit on the casualty owner.
// _this is the ACE callback [_medic, _patient, _bodyPart, _args].
params ["_medic", "_patient", "_bodyPart", "_args"];
_args params [["_accessSite", 2]];
if (isNull _patient) exitWith {};
if (_accessSite < 0 || {_accessSite > 2}) exitWith {};

private _bpFlag = toLowerANSI _bodyPart;
if (_bpFlag == "ej") then {_bpFlag = "head";};
private _siteName = ["upper", "middle", "lower"] param [_accessSite, "lower"];

// Match the owner-safe removal used by the IV minigame. setIVLocal treats type 0 as removal and avoids a second
// native activity-log entry; the provider-side message/log below remains the single human-readable record.
[_patient, "ivSite", [_medic, _patient, _bpFlag, 0, _accessSite,
    [_patient] call ACME_fnc_clinicalEpoch]] call ACME_fnc_ownerDispatch;
[_patient, "ivCompromised", [_bpFlag, _accessSite, "clear"]] call ACME_fnc_ownerDispatch;

[format ["18G IV removed: %1 %2.", _siteName, ([_bodyPart, "display"] call ACME_fnc_bodyPartName)], 2, _medic]
    call ace_common_fnc_displayTextStructured;
[_patient, "activity",
 "%1 removed an 18G IV (%2 %3)",
 "18g IV removed, %2 %3, %1",
 [[_medic, false, true] call ace_common_fnc_getName, _siteName, [_bodyPart, "short"] call ACME_fnc_bodyPartName]]
    call ACME_fnc_medLog;

// Convert the exact hub for this access site on the casualty owner. If old builds left extra hub art behind, the
// owner-side commit sweeps those legacy hubs only after native circulation confirms the whole body part is empty.
private _bpL = toLowerANSI _bodyPart;
private _markPart = if (_bpL == "head") then {"ej"} else {_bpL};
private _hole = format ["\acm_extended\ui\holes\hole%1_ca.paa", (floor random 8) + 1];
[_patient, "ivMarks", ["removeSite", [_markPart, _bpFlag, _siteName, 18, _hole],
    [_patient] call ACME_fnc_clinicalEpoch]] call ACME_fnc_ownerDispatch;
