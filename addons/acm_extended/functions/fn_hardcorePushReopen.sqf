/* B121: click target for the one-handed overlay. Opening the Narc Box is presentation only; the persistent PFH
   continues the push without resetting its timer, rate, plunger or batch state. */
private _job = missionNamespace getVariable ["ACME_HCMedPushJob",createHashMap];
if !(_job isEqualType createHashMap && {count _job > 0} && {_job getOrDefault ["flowing",false]}) exitWith {false};
if (!isNull (findDisplay 84000)) exitWith {call ACME_fnc_hardcorePushRestoreUi};
private _patient = _job getOrDefault ["patient",objNull];
private _stable = _job getOrDefault ["stableId",""];
if (isNull _patient || {_stable == ""}) exitWith {false};
private _store = [ACE_player] call ACME_fnc_skStoreEnsureIds;
private _idx = _store findIf {(_x param [11,"",[""]]) == _stable};
if (_idx < 0) exitWith {false};
private _size = (_store select _idx) param [1,10,[0]];
uiNamespace setVariable ["ACME_SK_Patient",_patient];
uiNamespace setVariable ["ACME_SK_BodyPart",_job getOrDefault ["bodyPart","body"]];
uiNamespace setVariable ["ACME_SK_OpenCarouselId",_stable];
uiNamespace setVariable ["ACME_SK_suppressReturn",true];
ace_medical_gui_pendingReopen = false;

// If the clickable syringe is being pressed while the Windows-key ACE cursor menu is open, close that menu and
// neutralize its pending selection first. Otherwise key-up could execute the action that happened to be under the
// cursor after the Narc Box has already opened. The medication PFH is untouched.
private _interaction = findDisplay 91919;
if (!isNull _interaction) then {
    if (!isNil "ace_interact_menu_actionSelected") then {ace_interact_menu_actionSelected = false;};
    if (!isNil "ace_interact_menu_openedMenuType") then {ace_interact_menu_openedMenuType = -1;};
    _interaction closeDisplay 2;
};
private _med = findDisplay 38580;
if (!isNull _med) then {_med closeDisplay 2;};
[_size,_patient,_job getOrDefault ["bodyPart","body"]] call ACME_fnc_skOpenDraw;
[{call ACME_fnc_hardcorePushRestoreUi;},[],0.05] call CBA_fnc_waitAndExecute;
["clear"] call ACME_fnc_hardcorePushOverlay;
true
