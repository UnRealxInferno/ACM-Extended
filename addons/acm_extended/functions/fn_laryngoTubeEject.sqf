// throw the ET tube out of an airway that is not holding it.
// call it as [_reason] call ACME_fnc_laryngoTubeEject.
//
// a casualty who vomits around a tube that is not yet secured expels it. the only tube that survives is one that
// is fully seated with the cuff up, because that is the point at which it is physically held in the trachea.
// anything short of both, a tube part way down, or fully down with a flat cuff, comes straight back out.
// it comes out fast. the insertion frames are played in reverse rather than the tube being deleted, so the medic
// sees it ejected rather than finding it gone.
params [["_reason", "vomit"], ["_force", false, [false]]];
private _dlg = uiNamespace getVariable ["ACME_laryngo_dlg", displayNull];
if (isNull _dlg) exitWith { false };

private _depth = uiNamespace getVariable ["ACME_laryngo_tubeDepth", 0];
private _cuffUp = (uiNamespace getVariable ["ACME_laryngo_cuffDone", false])
    || {(uiNamespace getVariable ["ACME_laryngo_cuffAmt", 0]) >= (missionNamespace getVariable ["ACME_laryngo_cuffSecure", 0.9])};
private _seated = _depth >= (missionNamespace getVariable ["ACME_laryngo_tubeSeatedDepth", 0.98]);

// seated and cuffed. it stays where it is.
if (_seated && _cuffUp && {!_force}) exitWith { false };

// nothing in the airway to throw out.
if (_depth <= 0 && {!(uiNamespace getVariable ["ACME_laryngo_tubeIn", false])}) exitWith { false };

uiNamespace setVariable ["ACME_laryngo_ejecting", true];
private _patient0 = uiNamespace getVariable ["ACME_laryngo_patient", objNull];
private _wasCommitted = (uiNamespace getVariable ["ACME_laryngo_tubePassed", false])
    || {!isNull _patient0 && {_patient0 getVariable ["ACME_ETT_Inserted", false]}};

// run the depth back to zero over a short window. the tube pose is driven from the depth, so reversing the depth
// plays the insertion frames backwards without a second animation to keep in step.
private _from = _depth;
private _dur = missionNamespace getVariable ["ACME_laryngo_ejectTime", 0.35];
[{
    params ["_args", "_h"];
    _args params ["_t0", "_from", "_dur", "_wasCommitted"];
    private _dlg = uiNamespace getVariable ["ACME_laryngo_dlg", displayNull];
    if (isNull _dlg) exitWith {
        [_h] call CBA_fnc_removePerFrameHandler;
        uiNamespace setVariable ["ACME_laryngo_ejecting", false];
    };
    private _f = ((diag_tickTime - _t0) / (_dur max 0.01)) min 1;
    uiNamespace setVariable ["ACME_laryngo_tubeDepth", (_from * (1 - _f))];
    if (_f >= 1) exitWith {
        [_h] call CBA_fnc_removePerFrameHandler;
        // out. the tube is back in the tray, the cuff is flat and nothing is held.
        uiNamespace setVariable ["ACME_laryngo_tubeDepth", 0];
        uiNamespace setVariable ["ACME_laryngo_tubeIn", false];
        uiNamespace setVariable ["ACME_laryngo_cuffAmt", 0];
        uiNamespace setVariable ["ACME_laryngo_cuffDone", false];
        uiNamespace setVariable ["ACME_laryngo_held", ""];
        uiNamespace setVariable ["ACME_laryngo_ejecting", false];
        private _pat = uiNamespace getVariable ["ACME_laryngo_patient", objNull];
        if (!isNull _pat) then {
            [_pat, false, false, false, false, true, false] call ACME_fnc_ettAirwayStateCommit;
            [_pat, "placement", [0, 0, false]] call ACME_fnc_ettMigrationStateCommit;
            [_pat, "tip", [[]]] call ACME_fnc_ettMigrationStateCommit;
            if (_wasCommitted) then {
                private _medic = uiNamespace getVariable ["ACME_laryngo_medic", objNull];
                if (!isNull _medic) then {["ACME_ettReturnTube", [_medic], _medic] call CBA_fnc_targetEvent;};
            };
        };
        uiNamespace setVariable ["ACME_laryngo_tubePassed", false];
        uiNamespace setVariable ["ACME_laryngo_tubeAnchored", false];
        uiNamespace setVariable ["ACME_laryngo_tubeInHand", false];
        uiNamespace setVariable ["ACME_laryngo_tubeGrip", false];
        uiNamespace setVariable ["ACME_laryngo_state", "idle"];
        [] call ACME_fnc_laryngoRefreshSlots;
    };
}, 0, [diag_tickTime, _from, _dur, _wasCommitted]] call CBA_fnc_addPerFrameHandler;

true
