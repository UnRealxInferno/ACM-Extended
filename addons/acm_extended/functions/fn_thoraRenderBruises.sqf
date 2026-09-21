// Paint persistent-looking chest contusions underneath prep/incision/intervention art.
// The medical state remains ACE wounds; these controls are only a visualization of that state.
disableSerialization;
private _display = uiNamespace getVariable ["ACME_Thora_DLG", displayNull];
if (isNull _display) exitWith {};
private _ctrls = uiNamespace getVariable ["ACME_Thora_BruiseCtrls", []];
{if (!isNull _x) then {_x ctrlShow false;};} forEach _ctrls;
private _patient = uiNamespace getVariable ["ACME_Thora_Patient", objNull];
if (isNull _patient || {_ctrls isEqualTo []}) exitWith {};
private _state = [_patient, "body"] call ACME_fnc_visualBruiseState;
_state params ["_score", "_woundCount", "_severity"];
if (_score <= 0 || {_severity <= 0}) exitWith {};
private _rect = uiNamespace getVariable ["ACME_Thora_BodyRect", []];
if (count _rect != 4) exitWith {};
_rect params ["_bx", "_by", "_bw", "_bh"];
private _side = uiNamespace getVariable ["ACME_Thora_Side", "right"];
private _n = ((ceil (_score / 4)) max 1) min (count _ctrls);
private _layouts = _display getVariable ["ACME_Thora_BruiseLayouts", createHashMap];
private _signature = format ["%1:%2", round (_score * 10), _n];
private _cached = _layouts getOrDefault [_side, []];
private _points = [];
if ((_cached param [0, ""]) == _signature) then {_points = +(_cached param [1, []]);};
if ((count _points) != _n) then {
    _points = [];
    // Keep marks within the chest/torso run.  Left/right images are mirrored and the arm overlay masks crossings.
    private _baseU = if (_side == "left") then {0.54} else {0.46};
    for "_i" from 0 to (_n - 1) do {
        private _u = (_baseU + (random 0.24) - 0.12) max 0.28 min 0.72;
        private _v = (0.30 + random 0.38) max 0.24 min 0.72;
        private _sev = ((_severity + (floor (random 3)) - 1) max 1) min 10;
        private _scale = 0.18 * (0.86 + random 0.30);
        _points pushBack [_u, _v, _sev, _scale];
    };
    _layouts set [_side, [_signature, _points]];
    _display setVariable ["ACME_Thora_BruiseLayouts", _layouts];
};
{
    if (_forEachIndex >= count _ctrls) exitWith {};
    _x params ["_u", "_v", "_sev", "_scale"];
    private _c = _ctrls select _forEachIndex;
    if (!isNull _c) then {
        _c ctrlSetText format ["\acm_extended\ui\bruises\chest_torso_bruises_sev%1_ca.paa", if (_sev < 10) then {format ["0%1", _sev]} else {"10"}];
        private _w = _bw * _scale; private _h = _bh * _scale;
        _c ctrlSetPosition [_bx + (_bw * _u) - (_w * 0.5), _by + (_bh * _v) - (_h * 0.5), _w, _h];
        _c ctrlSetTextColor [1,1,1,0.72];
        _c ctrlCommit 0;
        _c ctrlShow true;
    };
} forEach _points;
