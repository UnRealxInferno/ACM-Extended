// the server-side keeper for one megacode dummy. it runs at about 1 hz where the dummy is local.
// it enforces the plot armor so the manikin can never actually die, through per-unit ai-unconsciousness,
// instant-death immunity, a pinned arrest timer and a blood floor, and it runs an instructor-meaningful fatal
// clock: while the patient is pulseless and not receiving CPR, time accrues, and once it passes the death time
// without ROSC the manikin is declared dead. that is handled by ACME_fnc_megacodeDie, which announces, drops them
// unconscious to mimic death, and runs a full auto-reset.
// the pfh args are [_d].
params ["_args", "_pfhId"];
_args params ["_d"];

if (isNull _d) exitWith { [_pfhId] call CBA_fnc_removePerFrameHandler; };
if (!local _d) exitWith {};  // managed only where the manikin is local, which is the server.

// re-assert the immortality each pass. it is cheap and survives anything that clears it. the state machine of the
// manikin runs server-side, where it is local, so these only need to be correct locally and there is no broadcast
// each tick.
[_d, [["aiUnconsciousness", true, false]]] call ACM_core_fnc_setAceMedicalState;
[_d, [["instantDeathImmune", true, false]]] call ACM_core_fnc_setAceMedicalState;
[_d, [["deathBlocked", true, false]]] call ACM_core_fnc_setAceMedicalState;

// a backstop: the plot armor should make this impossible, and if the manikin is somehow dead, route to the death
// handler, which latches and resets the state, rather than leaving a corpse.
if (!alive _d) exitWith { [_d] call ACME_fnc_megacodeDie; };

if (_d getVariable ["ACME_MC_dying", false]) exitWith {};  // the death sequence is already running.

// ease the panel vitals toward their slider targets. a press ramps the value over, LifePak-style.
private _rampNow = CBA_missionTime;
private _rampDt = ((_rampNow - (_d getVariable ["ACME_MC_rampLast", _rampNow])) max 0) min 3;
_d setVariable ["ACME_MC_rampLast", _rampNow, false];
{
    _x params ["_liveKey", "_tgtKey", "_rate"];
    private _tgt = _d getVariable [_tgtKey, -9999];
    if (_tgt > -9999) then {
        private _cur = _d getVariable [_liveKey, _tgt];
        private _step = _rate * _rampDt;
        private _next = if ((abs (_tgt - _cur)) <= _step) then { _tgt } else { _cur + (_step * ([1, -1] select (_tgt < _cur))) };
        if (_next != _cur) then { _d setVariable [_liveKey, _next, true]; };
    };
} forEach [
    ["ACME_MC_HR",    "ACME_MC_HRTgt",    7],
    ["ACME_MC_SpO2",  "ACME_MC_SpO2Tgt",  4],
    ["ACME_MC_SBP",   "ACME_MC_SBPTgt",   9],
    ["ACME_MC_DBP",   "ACME_MC_DBPTgt",   6],
    ["ACME_MC_RR",    "ACME_MC_RRTgt",    3],
    ["ACME_MC_EtCO2", "ACME_MC_EtCO2Tgt", 4]
];

private _rhythm = _d getVariable ["ACM_circulation_Cardiac_RhythmState", 0];
private _pulseless = (_rhythm in [1, 2, 3, 5]) || {_d getVariable ["ace_medical_inCardiacArrest", false]};
private _now = CBA_missionTime;

if (_pulseless) then {
    // pin the arrest timeout of ACM and ACE and hold a blood floor, so the engine cannot kill first. our clock owns
    // it.
    [_d, [["cardiacArrestTimeLeft", 1e9, false]]] call ACM_core_fnc_setAceMedicalState;
    if ((_d getVariable ["ace_medical_bloodVolume", 6]) < 4.0) then {
        [_d, [["bloodVolume", 4.0, true]]] call ACM_core_fnc_setAceMedicalState;
    };
    private _last = _d getVariable ["ACME_MC_arrestLast", _now];
    private _elapsed = _d getVariable ["ACME_MC_arrestElapsed", 0];
    private _cpr = alive (_d getVariable ["ace_medical_CPR_provider", objNull]);
    // Scheduler bookkeeping is server-local. Publishing it once per second was
    // pure traffic; only the final scenario state needs replication.
    _d setVariable ["ACME_MC_arrestLast", _now, false];
    if (!_cpr) then { _elapsed = _elapsed + (_now - _last); };
    _d setVariable ["ACME_MC_arrestElapsed", _elapsed, false];

    private _limit = missionNamespace getVariable ["ACME_megacode_deathTime", 240];
    if (_limit > 0 && {_elapsed >= _limit}) then { [_d] call ACME_fnc_megacodeDie; };
} else {
    // perfusing again, so clear the clock.
    _d setVariable ["ACME_MC_arrestElapsed", 0, false];
    // Scheduler bookkeeping is server-local. Publishing it once per second was
    // pure traffic; only the final scenario state needs replication.
    _d setVariable ["ACME_MC_arrestLast", _now, false];
};
