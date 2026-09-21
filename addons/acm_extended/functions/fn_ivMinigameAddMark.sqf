// append a persistent iv mark to the patient, so it survives re-opening the limb, and re-render.
// call it as [_u, _v, _kind, _holeTex, _frame, _gauge, _missTime, _scale] call ACME_fnc_ivMinigameAddMark.
// _kind is "hub", "removed" or "miss". _gauge colors the hub art and sizes the miss bruise.
// _rot and _alpha are miss bruises only. they carry the per-bruise variance so a repaint reproduces the same
// mark rather than rolling a new one, which would make every bruise twitch on every render.
params ["_u", "_v", "_kind", ["_holeTex", ""], ["_frame", ""], ["_gauge", 0], ["_missTime", -1], ["_scale", 1], ["_rot", 0], ["_alpha", 1]];
if !([] call ACME_fnc_ivUiValid) exitWith {};
private _patient = uiNamespace getVariable ["ACME_IV_Patient", objNull];
private _bp = uiNamespace getVariable ["ACME_IV_BodyPart", "leftarm"];
private _view = uiNamespace getVariable ["ACME_IV_View", ""];
// The tier is upper, middle or lower, from proximal to distal. The EJ uses left or right.
// This value is the site of the PUNCTURE. It is not the site of the band.
// Element 10 below holds this value.
// fn_ivMinigamePullStop reads element 10. It selects the ACM access site to remove.
// CAUTION: A mark with the band site lets a medic pull one catheter and remove a different IV.
// The two callers of this function run immediately after a puncture.
// Therefore ACME_IV_InsSite is correct for both callers.
// The EJ stores "" in ACME_IV_InsSite. The EJ keeps its locked side in ACME_IV_Site.
private _site = toLower (uiNamespace getVariable ["ACME_IV_InsSite", ""]);
if (_site isEqualTo "") then { _site = toLower (uiNamespace getVariable ["ACME_IV_Site", ""]); };
if (!isNull _patient) then {
    private _mark = [_bp, _view, _u, _v, _kind, _holeTex, _frame, _gauge, _missTime, _scale, _site, _rot, _alpha,
        if (_kind == "hub") then {uiNamespace getVariable ["ACME_IV_InsAngle", 0]} else {0}];
    [_patient, "ivMarks", ["add", [_mark], [_patient] call ACME_fnc_clinicalEpoch]] call ACME_fnc_ownerDispatch;
};
[] call ACME_fnc_ivMinigameRenderMarks;
