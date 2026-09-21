// Render the actual closure: a tube when inserted, otherwise a seal when dressed.
// The observer's own permissions never choose the artwork on the patient.
// when placed, the tube art shows at the incision, anchored at the tape and entry corner, and the cut and tract
// opening are occluded, meaning hidden with the data retained.
// when not placed, the tube art is hidden and the cut and opening show normally, so pulling the tube reveals the
// incision again.
disableSerialization;
private _display = uiNamespace getVariable ["ACME_Thora_DLG", displayNull];
if (isNull _display) exitWith {};
private _ctrl = uiNamespace getVariable ["ACME_Thora_TubeCtrl", controlNull];
if (isNull _ctrl) exitWith {};
private _rect = uiNamespace getVariable ["ACME_Thora_BodyRect", []];
if (count _rect != 4) exitWith {};
_rect params ["_bx", "_by", "_bw", "_bh"];
private _side = uiNamespace getVariable ["ACME_Thora_Side", "right"];
private _patient = uiNamespace getVariable ["ACME_Thora_Patient", objNull];
private _placed = (!isNull _patient) && {_patient getVariable [format ["ACME_thora_tube_%1", _side], false]};
private _dressed = (!isNull _patient) && {
    (_patient getVariable [format ["ACME_thora_sealed_%1", _side], false])
    || {_patient getVariable [format ["ACME_thora_closed_%1", _side], false]}
};
private _inc = if (isNull _patient) then { [] } else { _patient getVariable [format ["ACME_thora_incision_%1", _side], []] };
if ((!_placed && {!_dressed}) || {count _inc != 3}) exitWith { _ctrl ctrlShow false; };

{ _x ctrlShow false } forEach (uiNamespace getVariable ["ACME_Thora_IncSegs", []]);
{ _x ctrlShow false } forEach (uiNamespace getVariable ["ACME_Thora_OpenSegs", []]);
(uiNamespace getVariable ["ACME_Thora_OpenCtrl", controlNull]) ctrlShow false;
(uiNamespace getVariable ["ACME_Thora_PleuraCtrl", controlNull]) ctrlShow false;

_inc params ["_ist", "_iang", "_ilenCm"];
_ist params ["_su", "_sv"];
private _ilenUV = (_ilenCm * (missionNamespace getVariable ["ACME_thora_pxPerCm", 60])) / 2048;
private _icU = _su + ((cos _iang) * (_ilenUV / 2));
private _icV = _sv + ((sin _iang) * (_ilenUV / 2));
private _af = uiNamespace getVariable ["ACME_Thora_AspectFix", 0.5625];
([if (_placed) then {"tube"} else {"seal"}, _side] call ACME_fnc_thoraClosureArt) params ["_texture", "_size", "_anchor"];
// Reuse the existing five-frame chest-seal peel artwork at the surgical incision.
private _burp = uiNamespace getVariable ["ACME_Thora_Burp", ["", 0, 0, false]];
if (!_placed && {_dressed} && {(_burp select 0) == _side}) then {
    private _frame = (round (_burp select 1)) max 0 min 5;
    if (_frame > 0) then {
        private _corner = if ((_burp select 2) > 0) then {"left"} else {"right"};
        _texture = format ["\acm_extended\ui\chest_seal\burp_%1\chest_seal_burp_%1_frame_0%2_ca.paa", _corner, _frame];
    };
};
private _h = _bh * _size;
private _w = _h * _af;
_anchor params ["_au", "_av"];
_ctrl ctrlSetText _texture;
_ctrl ctrlSetPosition [(_bx + (_icU * _bw)) - (_au * _w), (_by + (_icV * _bh)) - (_av * _h), _w, _h];
_ctrl ctrlSetTextColor [1, 1, 1, 1];
_ctrl ctrlShow true;
_ctrl ctrlCommit 0;
