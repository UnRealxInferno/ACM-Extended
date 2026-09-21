/* B115 IO pain contract. Runs on the patient owner.
 *
 * placement: an IO insertion always establishes at least moderate pain.
 *
 * fluid: admitted fluid through an IO drives raw pain to maximum severity. The old per-tick explicit injured sound
 * was removed because a hanging bag retriggered it every circulation update. Fluid flow instead schedules the
 * configured delayed IO syncope once; repeated flow ticks share that one pending syncope token.
 *
 * medication: an IV/IO medication bolus still produces the severe pain response but does not independently schedule
 * the fluid-pressure syncope. A saline flush uses mode "fluid" and therefore follows the fluid rule.
 */
params ["_patient", ["_bodyPart", "body"], ["_mode", "fluid"]];
if (isNull _patient || {!alive _patient} || {!local _patient}) exitWith {};
_mode = toLowerANSI _mode;

private _isUncon = (_patient getVariable ["ACE_isUnconscious", false])
    || {_patient getVariable ["ace_medical_unconscious", false]};

if (_mode == "placement") exitWith {
    private _floor = missionNamespace getVariable ["ACME_ioInsertionMinPain", 0.35];
    private _current = (_patient getVariable ["ace_medical_pain", 0]) max 0;
    private _delta = (_floor - _current) max 0;
    if (_delta > 0.001 && {!isNil "ace_medical_fnc_adjustPainLevel"}) then {
        [_patient, _delta] call ace_medical_fnc_adjustPainLevel;
    };
    // Native ACM already plays the insertion reaction. Only add a second reaction when suppression forced a
    // meaningful top-up to the minimum placement-pain floor.
    if (_delta > 0.05 && {!_isUncon} && {!isNil "ace_medical_feedback_fnc_playInjuredSound"}) then {
        [_patient, "hit"] call ace_medical_feedback_fnc_playInjuredSound;
    };
};

// Actual IO flow is intentionally not suppressed by local lidocaine or systemic analgesia.
private _rawPain = (_patient getVariable ["ace_medical_pain", 0]) max 0;
if (_rawPain < 0.999) then {
    if (!isNil "ace_medical_fnc_adjustPainLevel") then {[_patient, 1] call ace_medical_fnc_adjustPainLevel;};
    if ((_patient getVariable ["ace_medical_pain", 0]) < 0.999) then {
        [_patient, [["pain", 1, true]]] call ACM_core_fnc_setAceMedicalState;
    };
};

// Do NOT call ace_medical_feedback_fnc_playInjuredSound here. A hanging IO bag reaches this function every
// circulation update, so explicit playback here created an uninterrupted injury-sound loop. ACE pain feedback can
// still react naturally to the max pain state.

if (_mode == "fluid" && {!_isUncon}) then {
    private _token = _patient getVariable ["ACME_ioSyncopeToken", -1];
    if (_token < 0) then {
        private _serial = (_patient getVariable ["ACME_ioSyncopeSerial", 0]) + 1;
        _patient setVariable ["ACME_ioSyncopeSerial", _serial, false];
        _patient setVariable ["ACME_ioSyncopeToken", _serial, false];
        private _delay = (missionNamespace getVariable ["ACME_ioFluidSyncopeDelay", 3]) max 0.1;
        [{
            params ["_patient", "_token"];
            if (isNull _patient || {!local _patient} || {!alive _patient}) exitWith {};
            if ((_patient getVariable ["ACME_ioSyncopeToken", -1]) != _token) exitWith {};
            _patient setVariable ["ACME_ioSyncopeToken", -1, false];
            private _alreadyUncon = (_patient getVariable ["ACE_isUnconscious", false])
                || {_patient getVariable ["ace_medical_unconscious", false]};
            if (!_alreadyUncon && {!isNil "ace_medical_status_fnc_setUnconsciousState"}) then {
                [_patient, true] call ace_medical_status_fnc_setUnconsciousState;
            };
        }, [_patient, _serial], _delay] call CBA_fnc_waitAndExecute;
    };
};
