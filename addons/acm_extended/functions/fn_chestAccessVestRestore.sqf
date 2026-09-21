// Restore the temporary backpack-supported chest-access vest after the final chest-access action ends.
// A normal release refuses to restore while another lease or chest-seal/thoracostomy workspace still owns the
// chest. Hard reset/death may pass true to force cleanup.
params [["_patient", objNull, [objNull]], ["_force", false, [false]]];
if (isNull _patient || {!local _patient}) exitWith {false};

if (!_force) then {
    private _leases = _patient getVariable ["ACME_chestAccess_leases", createHashMap];
    if ((count _leases) > 0
        || {_patient getVariable ["ACME_CS_ProcedureActive", false]}
        || {_patient getVariable ["ACME_Thora_ChestAccessActive", false]}) exitWith {false};
};

private _saved = +(_patient getVariable ["ACME_chestAccess_vestLoadout", []]);
private _prop = _patient getVariable ["ACME_chestAccess_vestProp", objNull];
private _restored = (count _saved) != 2;
if ((count _saved) == 2) then {
    private _vestClass = _saved param [0, "", [""]];
    if ((vest _patient) != "") then {
        // Another system already put a carrier on the casualty. Never overwrite current gear just to satisfy an
        // old visual lease; retire our saved prop instead.
        _restored = true;
    } else {
        if (_vestClass != "") then {
            private _loadout = getUnitLoadout _patient;
            if ((count _loadout) > 4) then {
                _loadout set [4, +_saved];
                _patient setUnitLoadout [_loadout, false];
                _restored = (vest _patient) == _vestClass;
            };
        };
    };
};

if (_restored || {_force}) then {
    if (_force) then {
        _patient setVariable ["ACME_chestAccess_leases", createHashMap, true];
        _patient setVariable ["ACME_Thora_ChestAccessActive", false, true];
    };
    private _pfh = _patient getVariable ["ACME_chestAccess_vestPFH", -1];
    if (_pfh isEqualType 0 && {_pfh >= 0}) then {[_pfh] call CBA_fnc_removePerFrameHandler;};
    _patient setVariable ["ACME_chestAccess_vestPFH", -1, false];
    if (!isNull _prop) then {detach _prop; deleteVehicle _prop;};
    _patient setVariable ["ACME_chestAccess_vestProp", objNull, true];
    _patient setVariable ["ACME_chestAccess_vestLoadout", [], true];
    _patient setVariable ["ACME_chestAccess_vestBusy", "", false];
    _patient setVariable ["ACME_chestAccess_readyServer", serverTime, true];
};
_restored
