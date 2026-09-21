/* Provider-side acknowledgement for owner-authoritative prepared-set hangs. */
params [["_requestId", "", [""]], ["_ok", false, [false]], ["_message", "", [""]]];
private _pending = missionNamespace getVariable ["ACME_preparedHangPending", createHashMap];
private _row = _pending getOrDefault [_requestId, []];
if (_row isEqualTo []) exitWith {};
if (_row param [3, false]) exitWith {};
_row set [3, true];
_pending set [_requestId, _row];
missionNamespace setVariable ["ACME_preparedHangPending", _pending];
_row params ["_patient", "_args"];
_args params ["", "_medic", "", "_setId", "_part", "_iv", "_site"];

if (_ok && {!isNull _medic}) then {
    // Defensive local convergence. The owner already removed this ID publicly; filtering it here prevents a stale
    // local array from redrawing the consumed set for one frame or overwriting the owner's removal later.
    private _sets = +(_medic getVariable ["ACME_preparedIVSets", []]);
    _sets = _sets select {(_x param [0, ""]) != _setId};
    _medic setVariable ["ACME_preparedIVSets", _sets, true];
};
uiNamespace setVariable ["ACME_preparedRowSig", "__force__"];
if (_message != "") then {[_message, 3, ACE_player, 13] call ace_common_fnc_displayTextStructured;};
if (!isNull _patient) then {[[ACE_player, _patient, _part, _iv, _site]] call ACME_fnc_reopenTransfusion;};
