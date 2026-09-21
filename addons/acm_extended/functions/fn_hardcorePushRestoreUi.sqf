/* B121: reconstruct the exact Body Map context around an already-running push. It never changes flow state. */
disableSerialization;
private _job = missionNamespace getVariable ["ACME_HCMedPushJob",createHashMap];
private _d = findDisplay 84000;
if (isNull _d || {!(_job isEqualType createHashMap)} || {count _job == 0}) exitWith {false};
private _patient = _job getOrDefault ["patient",objNull];
private _stable = _job getOrDefault ["stableId",""];
if (isNull _patient || {_stable == ""}) exitWith {false};
uiNamespace setVariable ["ACME_SK_Patient",_patient];
_d setVariable ["ACME_SK_ReturnPatient",_patient];
uiNamespace setVariable ["ACME_SK_BodyPart",_job getOrDefault ["bodyPart","body"]];
private _store = [ACE_player] call ACME_fnc_skStoreEnsureIds;
if (([_stable,_store] call ACME_fnc_skSelectStored) < 0) exitWith {false};
uiNamespace setVariable ["ACME_SK_View","body"];
uiNamespace setVariable ["ACME_SK_Route","vascular"];
uiNamespace setVariable ["ACME_SK_SiteIdx",_job getOrDefault ["site",-2]];
uiNamespace setVariable ["ACME_SK_PendingInjection",[_job getOrDefault ["bodyPart","body"],_job getOrDefault ["site",-2],"vascular"]];
uiNamespace setVariable ["ACME_SK_CarouselExpanded",true];
uiNamespace setVariable ["ACME_SK_CarouselCollapseAt",0];
uiNamespace setVariable ["ACME_SK_InjectionBusy",true];
uiNamespace setVariable ["ACME_SK_CarouselBusy",true];
call ACME_fnc_skSetView;
call ACME_fnc_skBuildHotspots;
{private _c=_d displayCtrl _x; if (!isNull _c) then {_c ctrlEnable false;};} forEach [84150,84151,84154,84470,84831];
call ACME_fnc_skBodyActionRender;
["clear"] call ACME_fnc_hardcorePushOverlay;
true
