params ["_medic","_patient",["_kind","hypoxia"]];
if (!hasInterface) exitWith {};
_kind = toLowerANSI _kind;
if !(_kind in ["hypoxia","hypotension","hypercapnia","ketamine","syncope"]) exitWith {};

// Visual post-processing is local to the person looking through the screen.  Keep instructor/test overrides
// client-local as well: putting them on the casualty made old debug state survive respawn and made an action on
// somebody else's Head change a variable that the local PP mixer never read.  The provider who clicks the debug
// action now owns the test profile regardless of which casualty's medical menu is open.
private _key = format ["ACME_VFX_Debug_%1",_kind];
private _cur = uiNamespace getVariable [_key,0];
if !(_cur isEqualType 0) then {_cur = 0;};
private _next = ((_cur max 0 min 3) + 1) mod 4;
uiNamespace setVariable [_key,_next];
uiNamespace setVariable ["ACME_VFX_ForceRefresh",true];
if (_kind isEqualTo "ketamine") then {uiNamespace setVariable ["ACME_VFX_WetForceRefresh",true];};
// Apply the selected test tier immediately instead of waiting for the next PFH tick. The PFH continues to own and
// reassert the effect afterward, so the profile persists across Mild -> Moderate -> Severe.
if (!isNil "ACME_fnc_visualFxTick") then {call ACME_fnc_visualFxTick;};

private _label = switch (_kind) do {
    case "hypoxia": {"Hypoxia"};
    case "hypotension": {"Hypotension / shock"};
    case "hypercapnia": {"Hypercapnia"};
    case "ketamine": {"Ketamine / dissociation"};
    case "syncope": {"Near-syncope"};
    default {_kind};
};
private _sev = ["OFF","MILD","MODERATE","SEVERE"] select _next;
if (!isNull _medic) then {[format ["Visual FX %1: %2",_label,_sev],1.5,_medic] call ace_common_fnc_displayTextStructured;};
