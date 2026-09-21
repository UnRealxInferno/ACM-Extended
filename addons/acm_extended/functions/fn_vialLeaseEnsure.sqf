/* Ensure this client owns the short lease for a shared vial source. Returns true only after owner acknowledgement. */
params [["_medic", objNull, [objNull]], ["_holder", objNull, [objNull]]];
if (isNull _medic || {isNull _holder}) exitWith {false};
if (_holder isEqualTo _medic) exitWith {true};
if (!local _medic) exitWith {false};

private _accepted = missionNamespace getVariable ["ACME_vialLeaseAccepted", []];
if (_accepted isEqualType [] && {count _accepted >= 3}) then {
    _accepted params ["_oldHolder","_oldToken","_oldUntil"];
    if (_oldHolder isEqualTo _holder && {_oldToken != ""} && {_oldUntil > serverTime}) then {
        private _nextRenew = missionNamespace getVariable ["ACME_vialLeaseRenewAt", 0];
        if (diag_tickTime >= _nextRenew) then {
            missionNamespace setVariable ["ACME_vialLeaseRenewAt", diag_tickTime + 1.5];
            [_holder,"vialLease",[_medic,"claim",_oldToken]] call ACME_fnc_ownerDispatch;
        };
        true
    } else {
        if (!isNull _oldHolder && {_oldToken != ""}) then {
            [_oldHolder,"vialLease",[_medic,"release",_oldToken]] call ACME_fnc_ownerDispatch;
        };
        missionNamespace setVariable ["ACME_vialLeaseAccepted", []];
        false
    };
} else {
    private _pending = missionNamespace getVariable ["ACME_vialLeasePending", []];
    if (_pending isEqualType [] && {count _pending >= 3}) then {
        _pending params ["_pendingHolder","_pendingToken","_sentAt"];
        if (_pendingHolder isEqualTo _holder && {diag_tickTime - _sentAt < 1.5}) exitWith {false};
        if (!isNull _pendingHolder && {_pendingToken != ""}) then {
            [_pendingHolder,"vialLease",[_medic,"release",_pendingToken]] call ACME_fnc_ownerDispatch;
        };
    };
    private _token = format ["%1:%2:%3", clientOwner, netId _holder, floor (diag_tickTime * 1000)];
    missionNamespace setVariable ["ACME_vialLeasePending", [_holder,_token,diag_tickTime]];
    [_holder,"vialLease",[_medic,"claim",_token]] call ACME_fnc_ownerDispatch;
    false
};
