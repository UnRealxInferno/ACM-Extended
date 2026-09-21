/* Provider-side acknowledgement for a shared vial-source lease. */
params [
    ["_holder", objNull, [objNull]],
    ["_token", "", [""]],
    ["_accepted", false, [false]],
    ["_until", 0, [0]],
    ["_reason", "", [""]]
];
if (!hasInterface || {isNull ACE_player} || {_token == ""}) exitWith {};
private _pending = missionNamespace getVariable ["ACME_vialLeasePending", []];
private _current = missionNamespace getVariable ["ACME_vialLeaseAccepted", []];
private _pendingMatch = _pending isEqualType [] && {count _pending >= 2}
    && {(_pending param [0,objNull]) isEqualTo _holder} && {(_pending param [1,""]) == _token};
private _renewMatch = _current isEqualType [] && {count _current >= 2}
    && {(_current param [0,objNull]) isEqualTo _holder} && {(_current param [1,""]) == _token};
if (!_pendingMatch && {!_renewMatch}) exitWith {};
if (_pendingMatch) then {missionNamespace setVariable ["ACME_vialLeasePending", []];};
if (_accepted) then {
    // Renewal acknowledgements extend the same local token. Without this, the owner lease stays live but the client
    // would briefly drop back to an unleased source every four seconds.
    missionNamespace setVariable ["ACME_vialLeaseAccepted", [_holder,_token,_until]];
    missionNamespace setVariable ["ACME_vialLeaseRenewAt", diag_tickTime + 1.5];
} else {
    missionNamespace setVariable ["ACME_vialLeaseAccepted", []];
    private _last = missionNamespace getVariable ["ACME_vialLeaseLastNotice", -100];
    if (_reason != "" && {diag_tickTime - _last > 1.5}) then {
        missionNamespace setVariable ["ACME_vialLeaseLastNotice", diag_tickTime];
        [_reason,2.5,ACE_player,13] call ace_common_fnc_displayTextStructured;
    };
};
if (!isNil "ACM_circulation_fnc_Syringe_UpdateMedicationList" && {!isNull (findDisplay 84000)}) then {
    [] call ACM_circulation_fnc_Syringe_UpdateMedicationList;
};
if (!isNil "ACME_fnc_skListRefresh" && {!isNull (findDisplay 84000)}) then {call ACME_fnc_skListRefresh;};
