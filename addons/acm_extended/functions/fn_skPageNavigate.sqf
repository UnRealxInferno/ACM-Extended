/* Three-page navigation: Transfuse <-> Narc Box <-> Body Map. */
disableSerialization;
params [["_dir","right",[""]]];
private _draw = findDisplay 84000;
private _tx = findDisplay 86000;
private _patient = objNull;
private _part = "leftarm";
private _current = "transfuse";

if (!isNull _draw) then {
    _patient = uiNamespace getVariable ["ACME_SK_Patient",objNull];
    if (isNull _patient) then {_patient = _draw getVariable ["ACME_SK_ReturnPatient",objNull];};
    _part = uiNamespace getVariable ["ACME_SK_BodyPart","leftarm"];
    if (_part == "") then {_part = "leftarm";};
    _current = if ((uiNamespace getVariable ["ACME_SK_View","syringe"]) == "body") then {"body"} else {"syringe"};
} else {
    if (!isNull _tx) then {
        _patient = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Target",objNull];
        _part = missionNamespace getVariable ["ACM_circulation_TransfusionMenu_Selected_BodyPart","leftarm"];
    };
};
if (isNull _patient) then {_patient = ACE_player;};

private _target = switch (_current) do {
    case "syringe": {if (_dir == "left") then {"transfuse"} else {"body"}};
    case "body": {if (_dir == "left") then {"syringe"} else {"transfuse"}};
    default {if (_dir == "left") then {"body"} else {"syringe"}};
};

// Narc Box <-> Body Map is a true in-place page switch.
if (!isNull _draw && {_target in ["syringe","body"]}) exitWith {
    uiNamespace setVariable ["ACME_SK_View",_target];
    if (_target == "body") then {
        private _store = [ACE_player] call ACME_fnc_skStoreEnsureIds;
        if !(_store isEqualTo []) then {[_store] call ACME_fnc_skSelectedIndex;};
        uiNamespace setVariable ["ACME_SK_CarouselExpanded",false];
        uiNamespace setVariable ["ACME_SK_CarouselCollapseAt",0];
    };
    call ACME_fnc_skSetView;
};

if (_target == "transfuse") exitWith {
    uiNamespace setVariable ["ACME_SK_suppressReturn",true];
    closeDialog 0;
    [{params ["_p","_part"]; [ACE_player,_p,_part] call ACM_circulation_fnc_openTransfusionMenu;},[_patient,_part]] call CBA_fnc_execNextFrame;
};

// Coming from Transfuse: this is explicitly a NORMAL Narc Box / Body Map open, never an infusion-prep reopen.
// A prepared infusion is already stored in its prepared-set record; ACME_infusion_pendingContext is only the
// temporary syringe-into-bag editor context. If that context survives the close/reopen race, fn_skInject marks
// the new display as ACME_SK_Return and fn_skSetView immediately forces the bag-injection page back on screen.
uiNamespace setVariable ["ACME_SK_RequestedView",_target];
ACME_infusion_pendingContext = nil;
missionNamespace setVariable ["ACME_infusion_bagTally", []];
closeDialog 0;
[{
    params ["_p","_part"];
    // Clear again on the next frame so an unload handler from the previous dialog cannot restore stale prep state
    // between the button click and creation of the normal Narc Box.
    ACME_infusion_pendingContext = nil;
    missionNamespace setVariable ["ACME_infusion_bagTally", []];
    [uiNamespace getVariable ["ACME_SK_CurSize",10],_p,_part] call ACME_fnc_skOpenDraw;
},[_patient,_part]] call CBA_fnc_execNextFrame;
