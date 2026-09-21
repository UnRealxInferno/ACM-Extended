// install one persistent MouseButtonDown handler on the mission display, 46, that swallows the right mouse button,
// button 1, while any ACME cancelable hold state is active, so RMB cancels the action without the engine also
// processing it as aim-down-sights.
// returning true from a display-46 MouseButtonDown handler is the reliable way to block the RMB into ads path,
// because CBA mouse keyhandlers do not consistently consume it.
// the covered states, each canceling its own way, are hang iv bag, ACME_hang_Active, which lowers the bag, and
// direct pressure, ACME_DP_Active, which stops holding pressure.
// lmb and MMB always pass through. the cancel is fired one frame later, so this handler returns cleanly first.
if (!hasInterface) exitWith {};

private _disp = findDisplay 46;
if (isNull _disp) exitWith {
    // the mission display is not up yet, so retry shortly.
    [{ call ACME_fnc_installRmbCancelGuard }, [], 1] call CBA_fnc_waitAndExecute;
};

// do not double-install.
if (uiNamespace getVariable ["ACME_RmbGuard_Installed", false]) exitWith {};
uiNamespace setVariable ["ACME_RmbGuard_Installed", true];

private _eh = _disp displayAddEventHandler ["MouseButtonDown", {
    params ["_d", "_button"];
    if !(_button isEqualTo 1) exitWith { false };  // only RMB; lmb/MMB pass through
    private _u = ACE_player;
    if (isNull _u || {!alive _u}) exitWith { false };

    private _hang = _u getVariable ["ACME_hang_Active", false];
    private _dp   = _u getVariable ["ACME_DP_Active", false];
    if !(_hang || _dp) exitWith { false };  // no cancelable hold -> let RMB do its normal thing

    // B127: capture the exact hold episode before deferring. Without this, an RMB from an ending hold could execute
    // one frame later after a new hold started and cancel the new episode instead.
    private _hangStart = _u getVariable ["ACME_hang_Start", -1];
    private _dpToken = _u getVariable ["ACME_DP_PoseToken", -1];

    // fire the matching cancel next frame, so this handler returns, and swallows the RMB, cleanly first.
    [{
        params ["_hangStart", "_dpToken"];
        private _u = ACE_player;
        if (isNull _u) exitWith {};
        if (_u getVariable ["ACME_hang_Active", false]
            && {(_u getVariable ["ACME_hang_Start", -2]) == _hangStart}) exitWith {
            [false] call ACME_fnc_hangBagStop;
        };
        if (_u getVariable ["ACME_DP_Active", false]
            && {(_u getVariable ["ACME_DP_PoseToken", -2]) == _dpToken}) exitWith {
            private _reopen = (_u getVariable ["ACME_DP_Mode", ""]) == "torso";
            [false, _u, _reopen] call ACME_fnc_directPressureStop;
        };
    }, [_hangStart, _dpToken]] call CBA_fnc_execNextFrame;

    true  // swallow RMB -> the weapon does not aim
}];

uiNamespace setVariable ["ACME_RmbGuard_EH", _eh];
