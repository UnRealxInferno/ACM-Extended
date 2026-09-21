params ["_args", "_id", "_epoch"];
_args params ["_medic", "_patient", "_target", "_item", "_action", "_vehicle", "_part", "_iv", "_site", "_volume", "_prepared", "_index", "_label", ["_staged", []]];
if (!local _patient) exitWith {[_patient, "preparedAttach", _this] call ACME_fnc_ownerDispatch;};
private _results = _patient getVariable ["ACME_preparedResults", createHashMap];
private _previous = _results getOrDefault [_id, []];
if !(_previous isEqualTo []) exitWith {["ACME_preparedAck", [_id, _previous select 0, _previous select 1], _medic] call CBA_fnc_targetEvent;};
private _ok = !isNull _medic && {alive _medic} && {_medic distance _patient <= 5 || {!isNull objectParent _medic && {objectParent _medic == objectParent _patient}}} && {_epoch == ([_patient] call ACME_fnc_clinicalEpoch)} && {!([_patient, _part, _iv, _site] call ACME_fnc_isYLineAccess)};
private _pi = ACME_infusion_bodyParts find toLowerANSI _part;
private _access = if (_pi >= 0) then {[_patient, _iv, _pi, _site] call ACM_circulation_fnc_getAccessType} else {0};
_ok = _ok && {_access > 0};
private _components = [_prepared] call ACME_fnc_preparedComponents;
private _customStaged = (_prepared param [15, ""]) != "";
_ok = _ok && {!(_components isEqualTo [])};
if (_customStaged) then {
    private _sets = _medic getVariable ["ACME_preparedIVSets", []];
    private _preparedLive = _medic getVariable ["ACME_infusion_PreparedBags", []];
    _ok = _ok && {(_sets findIf {(_x select 0) == (_prepared select 0)}) >= 0} &&
        {(_preparedLive findIf {_x isEqualTo _prepared}) >= 0};
};
if !(_staged isEqualTo []) then {
    private _sets = _medic getVariable ["ACME_preparedIVSets", []];
    _ok = _ok && {(toLowerANSI (getText (configFile >> "ace_medical_treatment" >> "IV" >> _action >> "type"))) in keys (missionNamespace getVariable ["ACME_infusion_premixedByType", createHashMap])} && {(_sets findIf {(_x select 0) == (_staged select 0)}) >= 0};
};
// A single fresh infusion cannot silently replace another provider's bag on this access.
private _occupied = ((_patient getVariable ["ACM_circulation_IV_Bags", createHashMap]) getOrDefault [_part, []]) findIf {
    (_x param [3, -1]) == _site && {(_x param [4, true]) == _iv} && {(_x param [1, 0]) > 0.01}
};
_ok = _ok && {_occupied < 0} && {
    (_components findIf {
        private _class = (missionNamespace getVariable ["ACME_infusion_deliveryClassOverride", createHashMap]) getOrDefault [_x select 0, format ["%1_IV", _x select 0]];
        !((_x select 1) > 0) || {!finite (_x select 1)} || {!(isClass (configFile >> "ACM_Medication" >> "Medications" >> _class) || {(_x select 0) in (missionNamespace getVariable ["ACME_infusion_osmoticAgents", []])})}
    }) < 0
};
private _doseId = "";
if (_ok) then {
    private _bagId = [_patient, _part, _action, _access, _iv, _site, false, true] call ace_medical_treatment_fnc_ivBagLocal;
    private _bags = (_patient getVariable ["ACM_circulation_IV_Bags", createHashMap]) getOrDefault [_part, []];
    private _bi = _bags findIf {(_x param [8, ""]) == _bagId};
    if (_bi >= 0) then {
        private _b = _bags select _bi;
        private _exact = if (_customStaged) then {_prepared select 10} else {_staged param [9, 0]};
        if (_exact > 0) then {
            _b set [1, _exact];
            if (_customStaged) then {_b set [6, _exact];};
            private _map = _patient getVariable ["ACM_circulation_IV_Bags", createHashMap];
            _bags set [_bi, _b]; _map set [_part, _bags];
            [_patient, _map] call ACME_fnc_ivBagsCommit;
        };
        private _ctx = [_patient, _part, _bi, _b select 0, _access, _site, _iv, _b select 5, _b select 6, _b select 7, _b select 1, _bagId];
        private _accepted = true;
        {
            _x params ["_med", "_dose"];
            private _partId = format ["%1:%2", _id, _forEachIndex];
            private _registered = [_ctx, _med, _dose, _prepared param [5,600], _prepared param [6,20], 0, 0, _partId, _bagId, _epoch, [], 0] call ACME_fnc_infusionRegisterLocal;
            if (_registered == "") exitWith {_accepted = false;};
            if (_doseId == "") then {_doseId = _registered;};
        } forEach _components;
        if (!_accepted) then {_doseId = "";};
        if (_doseId == "") then {
            // Roll back the just-created bag before any vitals callback can run; no delivery happened.
            private _remaining = (_patient getVariable ["ACME_infusion_BagMedications", []]) select {(_x param [23, ""]) != _bagId};
            [_patient, _remaining] call ACME_fnc_infusionMedicationStateCommit;
            private _map = _patient getVariable ["ACM_circulation_IV_Bags", createHashMap];
            _bags deleteAt _bi; _map set [_part, _bags]; [_patient, _map] call ACME_fnc_ivBagsCommit;
            [_patient, _part] call ACM_circulation_fnc_updateActiveFluidBags;
        };
    };
    _ok = _doseId != "";
    if (_ok) then {
        // ivBagLocal can attach to an IV whose native site gate was left at zero by an earlier stop or by the
        // infusion-prep pause. IO usually remained at its default 1, which is why the same prepared infusion
        // appeared to work on IO but not on IV. Starting a newly attached infusion explicitly starts this site.
        [_patient, _part, _iv, _site] call ACME_fnc_resumeSiteFlow;
    };
};
_results set [_id, [_ok, _doseId]];
if (count _results > 128) then {_results deleteAt ((keys _results) select 0);};
_patient setVariable ["ACME_preparedResults", _results, true];
["ACME_preparedAck", [_id, _ok, _doseId], _medic] call CBA_fnc_targetEvent;
