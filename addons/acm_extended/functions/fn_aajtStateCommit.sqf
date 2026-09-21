/* Authoritative persistent AAJT-S placement state. Network writes occur only when placement changes. */
params ["_patient", "_op", ["_data", []]];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {
    [_patient, "aajtState", [_patient, _op, _data]] call ACME_fnc_ownerDispatch;
};
private _key = toLowerANSI _op;
switch (_key) do {
    case "inguinal": {
        _data params [["_active", false], ["_at", nil], ["_side", ""]];
        _side = toLowerANSI _side;
        if !(_side in ["leftleg", "rightleg"]) then {_side = "";};
        if (_active && {_side == ""}) then {_active = false;};
        _patient setVariable ["ACME_AAJT_inguinal", _active, true];
        _patient setVariable ["ACME_AAJT_inguinalAt", if (_active) then {_at} else {nil}, true];
        _patient setVariable ["ACME_AAJT_inguinalSide", if (_active) then {_side} else {""}, true];
        _patient setVariable ["ACME_AAJT_legs", if (_active) then {[_side]} else {[]}, true];
    };
    case "zone3": {
        _data params [["_active", false], ["_at", nil]];
        _patient setVariable ["ACME_AAJT_zone3", _active, true];
        _patient setVariable ["ACME_AAJT_zone3At", if (_active) then {_at} else {nil}, true];
    };
    case "leftarm": {
        _data params [["_active", false], ["_at", nil]];
        _patient setVariable ["ACME_AAJT_axillaleft", _active, true];
        _patient setVariable ["ACME_AAJT_axillaleftAt", if (_active) then {_at} else {nil}, true];
    };
    case "rightarm": {
        _data params [["_active", false], ["_at", nil]];
        _patient setVariable ["ACME_AAJT_axillaright", _active, true];
        _patient setVariable ["ACME_AAJT_axillarightAt", if (_active) then {_at} else {nil}, true];
    };
    // Legacy snapshot field. Keep it coherent for old saves/tools, but never use it as authority.
    case "legs": {
        private _legs = _data select {_x in ["leftleg", "rightleg"]};
        _patient setVariable ["ACME_AAJT_legs", _legs arrayIntersect _legs, true];
    };
};

// Persistent pain/posture workers belong to the casualty owner. Starting them here also covers remote providers
// without relying on the provider client to start owner-local PFHs after replication catches up.
if (_patient getVariable ["ACME_AAJT_zone3", false]) then {[_patient] call ACME_fnc_aajtDownedTick;};
if ((_patient getVariable ["ACME_AAJT_zone3", false])
    || {_patient getVariable ["ACME_AAJT_inguinal", false]}
    || {_patient getVariable ["ACME_AAJT_axillaleft", false]}
    || {_patient getVariable ["ACME_AAJT_axillaright", false]}) then {
    [_patient] call ACME_fnc_aajtPainTick;
};
