// Owner-authoritative casualty animation arbiter.
// Every request is serialized on the patient owner, which prevents two providers from repeatedly overwriting the
// same casualty with competing roll/special animations on a dedicated server. A short lease is enough for ordinary
// treatment transitions; modal procedures such as auscultation can hold a longer lease and release it explicitly.
params [
    ["_patient", objNull, [objNull]],
    ["_animation", "", [""]],
    ["_animPriority", 1, [0]],
    ["_source", "treatment", [""]],
    ["_provider", objNull, [objNull]],
    ["_leaseSeconds", 2.5, [0]],
    ["_lockPriority", 1, [0]],
    ["_token", "", [""]]
];
if (isNull _patient) exitWith {""};
if (_token == "") then {
    private _serial = (missionNamespace getVariable ["ACME_patientAnimSerial", 0]) + 1;
    missionNamespace setVariable ["ACME_patientAnimSerial", _serial];
    _token = format ["%1:%2:%3:%4", clientOwner, netId _patient, _serial, floor (diag_tickTime * 1000)];
};

if (!local _patient) exitWith {
    [_patient, "patientAnimRequest", [_patient, _animation, _animPriority, _source, _provider, _leaseSeconds, _lockPriority, _token]] call ACME_fnc_ownerDispatch;
    _token
};
if (!alive _patient || {!isNull objectParent _patient}) exitWith {""};

private _now = serverTime;
private _providerId = if (isNull _provider) then {""} else {netId _provider};
private _lock = _patient getVariable ["ACME_patientAnimLock", []];
private _active = (count _lock) >= 5 && {(_lock param [4, -1]) > _now};
private _rejected = false;
if (_active) then {
    private _oldToken = _lock param [0, ""];
    private _oldSource = _lock param [1, ""];
    private _oldProvider = _lock param [2, ""];
    private _oldPriority = _lock param [3, 0];
    private _sameOwner = (_oldToken == _token) || {(_oldSource == _source) && {_oldProvider == _providerId}};
    _rejected = !_sameOwner && {_oldPriority >= _lockPriority};
};
if (_rejected) exitWith {""};

_leaseSeconds = _leaseSeconds max 0.15;
private _expires = _now + _leaseSeconds;
_patient setVariable ["ACME_patientAnimLock", [_token, _source, _providerId, _lockPriority, _expires], true];

if (_animation != "") then {
    [_patient, _animation, _animPriority] call ACME_fnc_doAnim;
};

// Expiry is token-checked. A newer owner can replace this lease without an old timer clearing the new state.
[{
    params ["_p", "_tok"];
    if (isNull _p || {!local _p}) exitWith {};
    private _cur = _p getVariable ["ACME_patientAnimLock", []];
    if ((_cur param [0, ""]) == _tok && {(_cur param [4, -1]) <= serverTime}) then {
        _p setVariable ["ACME_patientAnimLock", [], true];
    };
}, [_patient, _token], _leaseSeconds + 0.05] call CBA_fnc_waitAndExecute;

_token
