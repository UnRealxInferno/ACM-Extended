// B120: dilutional coagulopathy can destabilize a recently controlled wound, but it is an occasional event.
// One server roll is made every configured interval, a successful patient enters a cooldown, and one wound is
// selected by the owner-side pop function.  ACE's own long-timescale bandage reopening remains separate.
if (!isServer) exitWith {};
if !(missionNamespace getVariable ["ACME_clotPop_enabled", true]) exitWith {};

private _bvThresh = missionNamespace getVariable ["ACME_clotPop_bvThreshold", 5.1];
private _base = missionNamespace getVariable ["ACME_clotPop_chance", 0.08];
private _frac = missionNamespace getVariable ["ACME_clotPop_fraction", 0.20];
private _types = missionNamespace getVariable ["ACME_clotPop_fluidTypes", ["Saline", "PlasmaLyte"]];
private _cooldown = missionNamespace getVariable ["ACME_clotPop_cooldown", 120];
private _now = CBA_missionTime;

{
    private _u = _x;
    if (_now < (_u getVariable ["ACME_clotPop_nextAt", -1])) then {continue};
    private _bv = _u getVariable ["ACM_circulation_Blood_Volume", 6];
    if (_bv >= _bvThresh) then {continue};

    private _bags = _u getVariable ["ACM_circulation_IV_Bags", createHashMap];
    private _infusing = false;
    {
        {
            _x params ["_t", "_vol"];
            if (_vol > 1 && {_t in _types}) exitWith {_infusing = true;};
        } forEach _y;
        if (_infusing) exitWith {};
    } forEach _bags;
    if (!_infusing) then {continue};

    private _load = (_u getVariable ["ACM_circulation_Saline_Volume", 0]) + (_u getVariable ["ACM_circulation_Plasma_Volume", 0]);
    private _loadF = linearConversion [0.1, 1.5, _load, 0.4, 1.6, true];
    private _shockF = linearConversion [_bvThresh, 3.5, _bv, 1, 2, true];
    private _mapF = 1;
    if (missionNamespace getVariable ["ACME_sys_permHypo", true]) then {
        private _pm = [_u] call ACME_fnc_tbiGetMAP;
        if (_pm isEqualType 0 && {finite _pm} && {_pm > 0}) then {
            _mapF = linearConversion [
                missionNamespace getVariable ["ACME_permHypo_refMAP", 70],
                missionNamespace getVariable ["ACME_clotPop_mapCeiling", 100],
                _pm, 1, missionNamespace getVariable ["ACME_clotPop_mapMaxFactor", 1.8], true
            ];
        };
    };
    private _pop = (_base * _loadF * _shockF * _mapF) min (missionNamespace getVariable ["ACME_clotPop_maxChance", 0.15]);
    if (random 1 < _pop) then {
        _u setVariable ["ACME_clotPop_nextAt", _now + _cooldown, false];
        ["ACME_popClots", [_u, _frac], _u] call CBA_fnc_targetEvent;
    };
} forEach (allUnits select {alive _x && {_x getVariable ["ACM_circulation_IV_Bags_Active", false]}});
