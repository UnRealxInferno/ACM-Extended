// end a catheter pull.
// call it as [_done] call ACME_fnc_ivMinigamePullStop.
// _done true means the catheter came all the way out. _done false means the medic let go part way, and the
// catheter stays where it is.
params [["_done", false]];
private _idx = uiNamespace getVariable ["ACME_IV_PullIdx", -1];

private _clear = {
    uiNamespace setVariable ["ACME_IV_PullIdx", -1];
    uiNamespace setVariable ["ACME_IV_PullProg", 0];
    uiNamespace setVariable ["ACME_IV_PullPin", []];
    uiNamespace setVariable ["ACME_IV_PullBroke", false];
    uiNamespace setVariable ["ACME_IV_PullCtrl", controlNull];
};

if !([] call ACME_fnc_ivUiValid) exitWith {call _clear;};
if (_idx < 0) exitWith { call _clear; };
if (!_done) exitWith {
    // part way out is not a state the model keeps. the catheter goes back to seated and the marks are redrawn.
    call _clear;
    [] call ACME_fnc_ivMinigameRenderMarks;
};

private _patient = uiNamespace getVariable ["ACME_IV_Patient", objNull];
if (isNull _patient) exitWith { call _clear; };
private _marks = _patient getVariable ["ACME_IV_Marks", []];
if (_idx >= count _marks) exitWith { call _clear; };

private _mark = _marks select _idx;
_mark params ["_mbp", "_mview", "_mu", "_mv", "_mkind", ["_mtex", ""], ["_mframe", ""], ["_mgauge", 16],
              ["_mmiss", -1], ["_mscale", 1], ["_msite", "middle"]];

// The site becomes a puncture. Identify the exact hub semantically; a stale local array index can never mutate
// a different provider's mark after concurrent IV work.
private _hole = format ["\acm_extended\ui\holes\hole%1_ca.paa", (floor random 8) + 1];
private _sig = [_mbp, _mview, _mu, _mv, _msite, _mgauge];
[_patient, "ivMarks", ["remove", [_sig, _hole], [_patient] call ACME_fnc_clinicalEpoch]] call ACME_fnc_ownerDispatch;

// tell ACM the line is gone. the old Remove IV button only changed the picture, so the casualty kept an access
// site that no longer existed on the body image and fluids still ran through it.
private _siteIdx = [_msite] call ACME_fnc_ivSiteIndex;
private _type = switch (_mgauge) do {
    case 14: { 2 };
    case 18: { 5 };
    case 20: { 6 };
    default { 1 };
};
private _medic = ACE_player;
// EJ is only a close-up/minigame body-part name. ACM stores both jugulars on the native head row,
// access sites 0 and 1. Sending "ej" to ACM's setter is rejected as an invalid body part and leaves
// the real line registered after the hub is physically pulled. Normalize before the owner-safe removal.
private _nativePart = if ((toLowerANSI _mbp) == "ej") then {"head"} else {_mbp};
// drive ACM's LOCAL setter, not ACM_circulation_fnc_setIV.
// setIV writes its own removal line into the activity log at circulation/functions/fnc_setIV.sqf:179, and this
// function writes the line below, so the medic read two entries for one removal. the local setter does the same
// state work and no logging.
// setIVLocal takes [_medic, _patient, _bodyPart, _type, _iv, _accessSite] and a type of 0 IS the removal. that
// is exactly what setIV hands it: on a removal setIV sets _setState to 0 and passes that through. every check
// setIV runs before that point is a placement check, guarded by its _state argument, which is false here.
[_patient, "ivSite", [_medic, _patient, _nativePart, 0, _siteIdx, [_patient] call ACME_fnc_clinicalEpoch]] call ACME_fnc_ownerDispatch;
// the compromise flag belongs to the line, so it goes with it.
// CAUTION: Do not use str on a value that is already a string. str adds quotation marks.
// This line read toLower (str _mbp). The name became ACME_ivCompromised_"leftarm"_2 with real quotes.
// The reader in fn_postInit builds the plain name, so it never found this variable.
// A pulled IV therefore never cleared its compromise flag, and the ej test below never matched either.
private _bpFlagRaw = if (_mbp isEqualType "") then { toLower _mbp } else { toLower (str _mbp) };
private _bpFlag = _bpFlagRaw;
if (_bpFlag == "ej") then { _bpFlag = "head"; };
[_patient, "ivCompromised", [_bpFlag, _siteIdx, "clear"]] call ACME_fnc_ownerDispatch;

// a bag hung on this limb was running into a line that no longer exists. take it down with the line.
// ACM clears its own IV_Bags for the site through setIV above, so this is only the physically hung bag, which
// is tracked on the medic rather than on the casualty and would otherwise keep flowing.
if (_medic getVariable ["ACME_hang_Active", false]) then {
    private _hp = _medic getVariable ["ACME_hang_Patient", objNull];
    // Both sides carried str before, so they matched each other and this test worked.
    // They are normalised the same way now, so the test still works and the values are clean.
    private _hangPart = _medic getVariable ["ACME_hang_Part", ""];
    private _hbp = if (_hangPart isEqualType "") then { toLower _hangPart } else { toLower (str _hangPart) };
    if (_hp == _patient && {_hbp in [_bpFlagRaw, toLowerANSI _nativePart]}) then {
        [true] call ACME_fnc_hangBagStop;
    };
};

if (!isNil "ace_medical_treatment_fnc_addToLog") then {
    // it mirrors the placement line, which reads "M. Harlow established IV, L GSV". the site text comes from
    // ACME_fnc_ivLogSite, the same function the placement uses, so the two entries name the same site.
    private _siteText = [_mbp, _msite] call ACME_fnc_ivLogSite;
    private _who = [_medic, false, true] call ace_common_fnc_getName;
    if (_who isEqualTo "") then {
        if (_siteText isEqualTo "") then {
            [_patient, "activity", "Removed the %1g IV", [_mgauge]] call ace_medical_treatment_fnc_addToLog;
        } else {
            [_patient, "activity", "Removed IV, %1", [_siteText]] call ace_medical_treatment_fnc_addToLog;
        };
    } else {
        if (_siteText isEqualTo "") then {
            [_patient, "activity", "%1 removed IV", [_who]] call ace_medical_treatment_fnc_addToLog;
        } else {
            [_patient, "activity", "%1 removed IV, %2", [_who, _siteText]] call ace_medical_treatment_fnc_addToLog;
        };
    };
};

call _clear;
[] call ACME_fnc_ivMinigameRenderMarks;
[] call ACME_fnc_ivMinigameSaveState;
playSound "ACE_Sound_Click";
