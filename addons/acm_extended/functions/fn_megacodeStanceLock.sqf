// hold a megacode dummy in ACM_LyingState forever: it can never stand, crouch or go prone.
// it runs a light per-unit keeper that re-asserts the lying pose if anything, meaning a treatment, a ragdoll or a
// stray stance, moves it off it, while leaving it alone whenever it is being dragged or carried so medics can
// still move it.
// _this is [_unit].
params ["_unit"];
if (isNull _unit) exitWith {};

private _rest = missionNamespace getVariable ["ACME_megacode_restAnim", "ACM_LyingState"];
if !([_unit] call ACME_fnc_animBlocked) then { ["ace_common_switchMove", [_unit, _rest]] call CBA_fnc_globalEvent; };
_unit setUnitPos "DOWN";

// one keeper per dummy.
if ((_unit getVariable ["ACME_megacode_keeperPFH", -1]) >= 0) exitWith {};
private _pfh = [{
    params ["_args", "_h"];
    _args params ["_u"];
    if (isNull _u || {!alive _u}) exitWith {
        [_h] call CBA_fnc_removePerFrameHandler;
        if (!isNull _u) then { _u setVariable ["ACME_megacode_keeperPFH", -1, true]; };
    };
    // do not fight an active carry or drag, meaning attached, or a vehicle mount.
    if (!isNull objectParent _u || {!isNull attachedTo _u}) exitWith {};

    // Seizure motion owns the body until the episode finishes.
    if ((_u getVariable ["ACME_lido_seizureState", ""]) == "active") exitWith {};

    private _rest = missionNamespace getVariable ["ACME_megacode_restAnim", "ACM_LyingState"];
    private _as = toLowerANSI animationState _u;
    // re-assert only when the unit has drifted to an upright or transitional stance. the lying, unconscious and
    // CPR-on-a-supine-patient animations all read as down already, so we do not stomp on treatment.
    private _isDown = (_as isEqualTo toLowerANSI _rest)
        || {(_as find "ppne") >= 0}
        || {(_as find "lying") >= 0}
        || {(_as find "unconscious") >= 0}
        || {(_as find "ainjppne") >= 0}
        || {(_as find "acm_") >= 0};
    if (!_isDown) then {
        if !([_u] call ACME_fnc_animBlocked) then { ["ace_common_switchMove", [_u, _rest]] call CBA_fnc_globalEvent; };
    };
    _u setUnitPos "DOWN";
}, 0.5, [_unit]] call CBA_fnc_addPerFrameHandler;
_unit setVariable ["ACME_megacode_keeperPFH", _pfh, true];
