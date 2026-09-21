params [["_patient",objNull,[objNull]],["_requestId","",[""]],["_accepted",false,[false]],["_usedId","",[""]],["_record",[],[[]]],["_part","",[""]],["_reason","",[""]],["_bagUid","",[""]]];
if (!hasInterface || {isNull ACE_player}) exitWith {};
private _pending=uiNamespace getVariable ["ACME_usedRehangPending",createHashMap]; private _saved=_pending getOrDefault [_requestId,_record];
if (_requestId in _pending) then {_pending deleteAt _requestId; uiNamespace setVariable ["ACME_usedRehangPending",_pending];};
private _seen=uiNamespace getVariable ["ACME_usedRehangSeen",createHashMap]; if (_requestId in _seen) exitWith {};
_seen set [_requestId,true]; private _ks=keys _seen; while {count _ks>48} do {_seen deleteAt (_ks deleteAt 0);}; uiNamespace setVariable ["ACME_usedRehangSeen",_seen];
if (!_accepted) exitWith {
    if !(_saved isEqualTo []) then {private _used=ACE_player getVariable ["ACME_usedBags",[]]; if ((_used findIf {(_x param [0,""])==_usedId})<0) then {_used pushBack _saved; ACE_player setVariable ["ACME_usedBags",_used,true];};};
    if (_reason!="") then {[_reason,2.5,ACE_player,13] call ace_common_fnc_displayTextStructured;}; uiNamespace setVariable ["ACME_usedRowSig","__force__"];
};
if (count _saved>=7) then {_saved params ["",["_type",""],["_rem",0],"","","",["_name",""]]; [format ["Re-hung %1 (%2 mL).",_name,round _rem],2.5,ACE_player] call ace_common_fnc_displayTextStructured;};
uiNamespace setVariable ["ACME_usedRowSig","__force__"]; uiNamespace setVariable ["ACME_coolerRowSig","__force__"]; if (!isNil "ACM_circulation_fnc_TransfusionMenu_UpdateBagList") then {[false] call ACM_circulation_fnc_TransfusionMenu_UpdateBagList;}; call ACME_fnc_updateTransfusionControls;
