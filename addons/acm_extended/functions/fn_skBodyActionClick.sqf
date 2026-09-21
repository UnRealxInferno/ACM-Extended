/* B76: contextual Body Map action button. A staged site means administer; otherwise arm/confirm discard. */
disableSerialization;
private _d = findDisplay 84000;
if (isNull _d || {(uiNamespace getVariable ["ACME_SK_View","syringe"]) != "body"}) exitWith {};
private _hcJob = missionNamespace getVariable ["ACME_HCMedPushJob",createHashMap];
if (_hcJob isEqualType createHashMap && {count _hcJob > 0} && {_hcJob getOrDefault ["flowing",false]}) exitWith {["manual"] call ACME_fnc_hardcorePushStop;};
if (uiNamespace getVariable ["ACME_SK_InjectionBusy",false]) exitWith {};
private _pending = uiNamespace getVariable ["ACME_SK_PendingInjection",[]];
if (_pending isEqualType [] && {count _pending >= 3}) exitWith {call ACME_fnc_skConfirmInjection;};

private _store = [ACE_player] call ACME_fnc_skStoreEnsureIds;
private _idx = [_store,false] call ACME_fnc_skSelectedIndex;
if (_idx < 0 || {_idx >= count _store}) exitWith {};
private _id = (_store select _idx) param [11,"",[""]];
if (_id == "") exitWith {};
private _armed = uiNamespace getVariable ["ACME_SK_DiscardArmedId",""];
if (_armed != _id) exitWith {
    uiNamespace setVariable ["ACME_SK_DiscardArmedId",_id];
    call ACME_fnc_skBodyActionRender;
};
call ACME_fnc_skDiscardSelected;
