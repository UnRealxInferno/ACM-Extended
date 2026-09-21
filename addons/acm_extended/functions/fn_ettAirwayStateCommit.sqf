/*
 * Phase 64: authoritative writer for the durable ETT airway-state quartet.
 *
 * Pass -1 for a bool that should retain its current value. The mutation boundary repairs impossible combinations:
 * no inserted tube => no secured/unsecured collar marker;
 * cuff inflation may exist before seating/passage and therefore does not itself imply insertion;
 * secured/unsecured collar state implies insertion, and secured/unsecured are mutually exclusive.
 */
params [
    ["_patient", objNull, [objNull]],
    ["_inserted", -1],
    ["_cuffInflated", -1],
    ["_secured", -1],
    ["_unsecured", -1],
    ["_public", true, [true]],
    ["_deduplicate", false, [true]]
];
if (isNull _patient) exitWith {[false, false, false, false]};
if (!local _patient) exitWith {
    [_patient, "ettAirwayState", [_inserted, _cuffInflated, _secured, _unsecured, _public, _deduplicate]] call ACME_fnc_ownerDispatch;
    [
        _patient getVariable ["ACME_ETT_Inserted", false],
        _patient getVariable ["ACME_ETT_CuffInflated", false],
        _patient getVariable ["ACME_ETT_Secured", false],
        _patient getVariable ["ACME_ETT_Unsecured", false]
    ]
};
private _writeInserted = _inserted isEqualType true;
private _writeCuff = _cuffInflated isEqualType true;
private _writeSecured = _secured isEqualType true;
private _writeUnsecured = _unsecured isEqualType true;
private _newInserted = if (_writeInserted) then {_inserted} else {_patient getVariable ["ACME_ETT_Inserted", false]};
private _newCuff = if (_writeCuff) then {_cuffInflated} else {_patient getVariable ["ACME_ETT_CuffInflated", false]};
private _newSecured = if (_writeSecured) then {_secured} else {_patient getVariable ["ACME_ETT_Secured", false]};
private _newUnsecured = if (_writeUnsecured) then {_unsecured} else {_patient getVariable ["ACME_ETT_Unsecured", false]};

// A cuff may be inflated before the tube has actually passed the cords; that pre-seating mechanical state is
// deliberately allowed. A secured/unsecured collar marker, however, only makes sense for an inserted tube.
if (_newSecured || {_newUnsecured}) then {
    _newInserted = true;
    _writeInserted = true;
};
if (_newSecured) then {
    _newUnsecured = false;
    _writeUnsecured = true;
};
if (_newUnsecured) then {
    _newSecured = false;
    _writeSecured = true;
};
if (_writeInserted && {!_newInserted}) then {
    _newSecured = false;
    _newUnsecured = false;
    _writeSecured = true;
    _writeUnsecured = true;
};

private _publish = {
    params ["_name", "_value"];
    if (_public && {_deduplicate}) then {
        [_patient, _name, _value] call ACME_fnc_setVarNet;
    } else {
        _patient setVariable [_name, _value, _public];
    };
};
if (_writeInserted) then {["ACME_ETT_Inserted", _newInserted] call _publish;};
if (_writeCuff) then {["ACME_ETT_CuffInflated", _newCuff] call _publish;};
if (_writeSecured) then {["ACME_ETT_Secured", _newSecured] call _publish;};
if (_writeUnsecured) then {["ACME_ETT_Unsecured", _newUnsecured] call _publish;};
[_newInserted, _newCuff, _newSecured, _newUnsecured]
