// Owner-only junctional hemorrhage rate worker.
// B102 keeps the intended extra junctional severity, but it no longer writes blood volume in a second PFH.
// This worker publishes one L/s contribution which the normal ACM circulation tick consumes in its single
// blood-volume update. That removes the junctional-only double update while preserving the existing pressure,
// packing, wrap, AAJT and XStat controls. Native ACE wounds remain separate injuries.
// Reference-rate stroke flow, temporary compensation, resistance and the mission's
// bleeding coefficient still affect loss. This is gameplay tuning, not a clinical model.
params ["_unit"];
if (isNull _unit || {!alive _unit}) exitWith {};
if (!local _unit) exitWith { [_unit, "junctional", [_unit, [_unit] call ACME_fnc_clinicalEpoch]] call ACME_fnc_ownerDispatch; };
private _epoch = [_unit] call ACME_fnc_clinicalEpoch;
if ((_unit getVariable ["ACME_juncWorker", []]) isEqualTo [clientOwner, _epoch] && {(_unit getVariable ["ACME_juncPFH", -1]) >= 0}) exitWith {};
private _old = _unit getVariable ["ACME_juncPFH", -1];
if (_old >= 0) then {[_old] call CBA_fnc_removePerFrameHandler;};
_unit setVariable ["ACME_juncWorker", [clientOwner, _epoch]];
_unit setVariable ["ACME_JuncBleedActive", true];

private _handle = [{
    params ["_args", "_h"];
    _args params ["_unit", "_epoch"];
    if (isNull _unit || {!local _unit} || {_epoch != ([_unit] call ACME_fnc_clinicalEpoch)}) exitWith {
        [_h] call CBA_fnc_removePerFrameHandler;
        if (!isNull _unit && {(_unit getVariable ["ACME_juncPFH", -1]) == _h}) then {
            _unit setVariable ["ACME_juncPFH", -1];
            _unit setVariable ["ACME_JuncBleedActive", false];
            _unit setVariable ["ACME_junctionalBleedLPS", 0, false];
        };
    };
    private _parts = ["leftarm", "rightarm", "leftleg", "rightleg"];
    private _norm  = missionNamespace getVariable ["ACME_junctionalBleedNorm", 0.10];
    private _dpCtl = missionNamespace getVariable ["ACME_junctionalDPControl", 0.10];
    // XStat 30, the hemostatic sponge bolus. it seats fast, with the bleed ramping from full to 0 over _xRamp
    // seconds, then holds until the dwell limit, after which the bolus fails and the junction rebleeds. it is
    // permanent until surgery or a full heal.
    private _xRamp  = missionNamespace getVariable ["ACME_xstatRampTime", 12];

    private _juncNorm = 0;
    private _anyXStat = false;

    // AAJT-S application tamponades only the anatomical territory being compressed. Legacy numeric stamps are
    // accepted as a conservative all-junction pause for old in-progress saves and self-heal after 25 seconds.
    private _applyRaw = _unit getVariable ["ACME_Junc_AAJTApplying", []];
    private _applyActive = false;
    private _applyPart = "";
    if (_applyRaw isEqualType []) then {
        if ((count _applyRaw) >= 2) then {
            private _stamp = _applyRaw param [0, -1];
            _applyPart = toLowerANSI (_applyRaw param [1, ""]);
            if (_stamp >= 0 && {serverTime - _stamp < 25}) then {_applyActive = true;} else {
                _unit setVariable ["ACME_Junc_AAJTApplying", [], true];
            };
        };
    } else {
        if (_applyRaw isEqualType 0 && {_applyRaw >= 0}) then {
            if (time - _applyRaw < 25) then {_applyActive = true; _applyPart = "legacy";} else {
                _unit setVariable ["ACME_Junc_AAJTApplying", [], true];
            };
        };
    };

    {
        private _state = _unit getVariable [format ["ACME_Junc_%1", _x], ""];
        // Device occlusion is centralized so native wounds, junctional wounds, IV/IO flow and medication delivery
        // all agree about which limb is actually compressed. During the 20 s application, only that same territory
        // is temporarily tamponaded. Zone 3 (body) covers both legs.
        private _partIndex = ["head","body","leftarm","rightarm","leftleg","rightleg"] find _x;
        private _applyingCtl = _applyActive && {
            _applyPart == "legacy" || {_applyPart == _x} || {_applyPart == "body" && {_x in ["leftleg","rightleg"]}}
        };
        private _aajtCtl = _applyingCtl || {[_unit, _partIndex] call ACME_fnc_aajtOccludes};
        // XStat 30, the inguinal-only sponge bolus. while seated, the bleed ramps from full to 0 over _xRamp seconds and
        // holds at zero. after a long dwell, defaulting to 2 h, the bolus slowly fails and the junction rebleeds, gently
        // and bounded: the rebleed grows from a trickle up to at most half the original bleed, over 2 minutes, and never
        // past that.
        // it is a smooth monotonic ramp driven purely by the elapsed time since the dwell mark, so it cannot oscillate the
        // way the old on-off failure did. that flipped the wound fully open, treatment re-seated it, and the blood volume
        // jumped through drop, recover and drop again. the wound stays xstat throughout, and surgery or a full heal
        // still ends it.
        if (_state == "xstat") then {
            _anyXStat = true;
            private _at = _unit getVariable [format ["ACME_Junc_XStatAt_%1", _x], time];
            private _dwell = time - _at;
            private _ramp = 1 - (_dwell / (_xRamp max 0.001));  // seating: full down to 0 over _xRamp.
            private _seated = _norm * (0 max (_ramp min 1));

            private _dwellLimit = missionNamespace getVariable ["ACME_xstatDwellTime", 7200];  // 2 h to failure.
            private _rebleedDur = missionNamespace getVariable ["ACME_xstatRebleedTime", 120];  // 2 min to a full rebleed.
            private _rebleedMax = missionNamespace getVariable ["ACME_xstatRebleedMaxFrac", 0.5];  // at most half the original.
            private _rebleed = 0;
            private _rebled = _dwell > _dwellLimit;
            if ((_unit getVariable [format ["ACME_Junc_XStatRebled_%1", _x], false]) isNotEqualTo _rebled) then {
                _unit setVariable [format ["ACME_Junc_XStatRebled_%1", _x], _rebled, true];
            };
            if (_rebled) then {
                // the fraction of the way through the 2-minute rebleed ramp, 0 to 1. it starts at a trickle and climbs.
                private _rf = ((_dwell - _dwellLimit) / (_rebleedDur max 0.001)) max 0 min 1;
                _rebleed = _norm * _rebleedMax * _rf;
            };
            // the seating contribution decays to 0 and the rebleed grows later. taking the max keeps the transition smooth,
            // and they never overlap in practice, because the rebleed only begins hours after the seating completes.
            // AAJT occludes actual loss, not XStat seating/dwell age. Removal exposes
            // the existing wound state; do not reset its clock.
            if (!_aajtCtl) then {_juncNorm = _juncNorm + (_seated max _rebleed);};
        };
        if ((_state in ["open", "packed"]) && {!_aajtCtl}) then {
            private _partNorm = _norm;

            // when this part started bleeding. it is stamped here rather than at every place a junctional can be
            // created, so the zeus module, the spawner and the automatic roll all get one without being edited.
            private _atKey = format ["ACME_Junc_At_%1", _x];
            private _woundAt = _unit getVariable [_atKey, -1];
            if (_woundAt < 0) then {
                _woundAt = time;
                _unit setVariable [_atKey, _woundAt, true];
            };

            // the compensation curve.
            // a fresh arterial junctional bleeds at full rate. within seconds the sympathetic response arrives,
            // the vessel clamps down and a plug forms, and the flow drops well below where it started. that
            // compensation is not durable: the vessel cannot hold the spasm, the plug is disturbed by movement and
            // handling, and over the next minute or two the bleeding climbs back to where it began.
            // this is the reason a junctional casualty looks like they are settling and then is not.
            // the depth of the dip follows what the casualty can actually mount. one who is already empty, or who
            // is on something that stops them clamping down, barely dips at all. vasoconstriction runs 0 to 50 in
            // ACM and is read directly.
            private _tw = time - _woundAt;
            private _onset = missionNamespace getVariable ["ACME_junctionalCompOnset", 12];
            private _hold  = missionNamespace getVariable ["ACME_junctionalCompHold", 45];
            private _recov = missionNamespace getVariable ["ACME_junctionalCompRecover", 105];
            private _shape = switch (true) do {
                case (_tw < 0): { 0 };
                case (_tw < _onset): { _tw / (_onset max 0.01) };
                case (_tw < (_onset + _hold)): { 1 };
                case (_tw < (_onset + _hold + _recov)): { 1 - ((_tw - _onset - _hold) / (_recov max 0.01)) };
                default { 0 };
            };
            private _vaso = _unit getVariable ["ACM_circulation_Vasoconstriction_State", 0];
            if !(_vaso isEqualType 0) then { _vaso = 0 };
            private _able = (missionNamespace getVariable ["ACME_junctionalCompFloorFrac", 0.4])
                + ((1 - (missionNamespace getVariable ["ACME_junctionalCompFloorFrac", 0.4])) * ((_vaso / 50) max 0 min 1));
            // Severe TBI/brainstem autonomic failure reduces the separate transient spasm/plug response. Signed TBI
            // tone is intentionally not applied here because total peripheral resistance below already contains it.
            if (_unit getVariable ["ACME_tbi_HasTBI", false]) then {
                private _tbiState = _unit getVariable ["ACME_tbi_State", createHashMap];
                if ((count _tbiState) > 0) then {
                    private _autoInt = (_tbiState getOrDefault ["autonomicIntegrity", 1]) max 0 min 1;
                    private _minAbility = missionNamespace getVariable ["ACME_tbi_autonomicJuncMinAbility", 0.25];
                    _able = _able * (_minAbility + ((1 - _minAbility) * _autoInt));
                };
            };
            private _depth = (missionNamespace getVariable ["ACME_junctionalCompDepth", 0.55]) * _shape * _able;
            _partNorm = _partNorm * ((1 - _depth) max 0.05);

            // is combat gauze being actively packed on this part right now? the callbackstart of the pack action sets it, and
            // success or failure clears it. it self-heals: if the flag has lingered past the pack timer plus a margin, such
            // as a medic disconnecting mid-pack, it is force-cleared so the wound cannot stay subsided forever.
            private _packing = _unit getVariable [format ["ACME_Junc_Packing_%1", _x], false];
            if (_packing) then {
                private _stamp = _unit getVariable [format ["ACME_Junc_PackStamp_%1", _x], -1];
                if (_stamp < 0) then {
                    _stamp = time;
                    _unit setVariable [format ["ACME_Junc_PackStamp_%1", _x], _stamp];
                };
                if (time - _stamp > (missionNamespace getVariable ["ACME_junctionalPackTime", 10]) + 2) then {
                    _packing = false;
                    _unit setVariable [format ["ACME_Junc_Packing_%1", _x], false, true];
                    _unit setVariable [format ["ACME_Junc_PackStamp_%1", _x], -1];
                };
            } else {
                if ((_unit getVariable [format ["ACME_Junc_PackStamp_%1", _x], -1]) >= 0) then {
                    _unit setVariable [format ["ACME_Junc_PackStamp_%1", _x], -1];
                };
            };

            // is direct pressure actively held on this part?
            private _m = _unit getVariable [format ["ACME_DP_press_%1", _x], objNull];
            private _dpHeld = (!isNull _m
                && {alive _m}
                && {_m getVariable ["ACME_DP_Active", false]}
                && {!(_m getVariable ["ACME_DP_Paused", false])});

            if (_packing) then {
                // B108: Combat Gauze follows the same progressive-hemostasis rule as every other bandage.
                // Start at the wound's open bleed rate and ease toward the completed packed-gauze state
                // (ACME_junctionalGauzeControl, normally 0.50) using B107's quadratic treatment-progress curve.
                // If the action is interrupted, the progress record disappears and the wound immediately returns
                // to its true open-state bleed rate. No permanent partial packing is written before success.
                private _gauze = missionNamespace getVariable ["ACME_junctionalGauzeControl", 0.50];
                private _packProgress = 0;
                private _activeBandages = _unit getVariable ["ACM_damage_BandageProgress", createHashMap];
                if (_activeBandages isEqualType createHashMap) then {
                    {
                        _y params ["_bp", "", "_started", "_duration", ["_bandageClass", ""]];
                        if (_bandageClass == "ACME_PackJunctional" && {_bp == _x}) then {
                            private _p = ((serverTime - _started) / (_duration max 0.01)) max 0 min 1;
                            _packProgress = _packProgress max (_p * _p);
                        };
                    } forEach _activeBandages;
                };
                private _packRemaining = 1 - ((1 - _gauze) * _packProgress);
                _partNorm = _partNorm * _packRemaining;
            } else {
                if (_state == "packed") then {
                    // combat gauze packing is the first-stage control. a finished packing holds the junction at 50 percent control,
                    // where ACME_junctionalGauzeControl is 0.50, and stays there until a pressure bandage wraps it. it does not work
                    // loose. holding direct pressure on top of the gauze adds the other 50 percent, where
                    // ACME_junctionalGauzeDPControl is 0.00, so the bleed is fully stopped at 100 percent control, for as long as it
                    // is held. lifting dp drops back to the 50 percent gauze level. the pressure bandage, the wrap, is the
                    // definitive step that makes control permanent, because the wrapped state excludes the part.
                    private _gauze   = missionNamespace getVariable ["ACME_junctionalGauzeControl", 0.50];
                    private _gauzeDP = missionNamespace getVariable ["ACME_junctionalGauzeDPControl", 0.00];

                    // B107: while the pressure dressing is being secured, progressively move the packed wound
                    // from gauze-only control toward the wrapped state.  This uses the same quadratic curve as
                    // ordinary bandages.  Direct Pressure still wins while it is actively held.
                    private _wrapProgress = 0;
                    private _juncPart = _x;
                    private _activeBandages = _unit getVariable ["ACM_damage_BandageProgress", createHashMap];
                    if (_activeBandages isEqualType createHashMap) then {
                        {
                            _y params ["_bp", "", "_started", "_duration", ["_bandageClass", ""]];
                            if (_bandageClass == "ACME_WrapJunctional" && {_bp == _juncPart}) then {
                                private _p = ((serverTime - _started) / (_duration max 0.01)) max 0 min 1;
                                _wrapProgress = _wrapProgress max (_p * _p);
                            };
                        } forEach _activeBandages;
                    };
                    private _wrapRemaining = _gauze * (1 - _wrapProgress);
                    _partNorm = _partNorm * (if (_dpHeld) then { _gauzeDP } else { _wrapRemaining });
                } else {
                    // an open bleeder: direct pressure partially controls it. this is the most dangerous wound on the limb, so dp
                    // prioritizes it, and holding pressure here is the first-line control.
                    if (_dpHeld) then { _partNorm = _partNorm * _dpCtl; };
                };
            };
            _juncNorm = _juncNorm + _partNorm;
        };
    } forEach _parts;

    // Keep the worker alive during an active AAJT application even when that application's local tamponade makes
    // the current junctional contribution zero. The per-part logic above already handled which territory pauses.
    private _treatPause = _applyActive;

    // stay alive while an XStat is seated even at zero bleed, because the loop is what watches the dwell timer and
    // resumes bleeding when it expires. also stay alive while an AAJT-s is being applied, meaning paused rather than
    // done. only fully tear down when the casualty is dead, or when nothing junctional remains.
    private _injuryPersists = (_parts findIf {(_unit getVariable [format ["ACME_Junc_%1", _x], ""]) in ["open", "packed", "xstat"]}) >= 0;
    if (!alive _unit || {!_injuryPersists && {!_treatPause}}) exitWith {
        [_h] call CBA_fnc_removePerFrameHandler;
        private _leakSrc = _unit getVariable ["ACME_JuncLeakSfxSrc", objNull];
        if (!isNull _leakSrc) then { deleteVehicle _leakSrc; };
        _unit setVariable ["ACME_JuncLeakSfxSrc", objNull, true];
        _unit setVariable ["ACME_JuncBleedActive", false];
        _unit setVariable ["ACME_juncPFH", -1];
        _unit setVariable ["ACME_junctionalBleedLPS", 0, false];
        _unit setVariable ["ACME_JuncLeakNext", -1, true];  // reset, so the next bleed re-inits the leak timer.
    };

    // fully controlled, such as an XStat seated and holding, and kept alive to watch the dwell. silence the leak and
    // do not drain. only run the leak sfx and the blood drain when there is actual bleeding to express.
    if (_juncNorm <= 0) exitWith {
        _unit setVariable ["ACME_junctionalBleedLPS", 0, false];
        private _leakSrc = _unit getVariable ["ACME_JuncLeakSfxSrc", objNull];
        if (!isNull _leakSrc) then { deleteVehicle _leakSrc; _unit setVariable ["ACME_JuncLeakSfxSrc", objNull, true]; };
        _unit setVariable ["ACME_JuncLeakNext", -1, true];
    };

    // past the exit gate, a junctional wound is still bleeding. the ambient leak is a deletable sound-source object
    // rather than a say3d, so an important action can stop it immediately instead of queueing.
    // Leak scheduling is public because important treatment sounds may reserve the same patient from another
    // client or the server. serverTime is therefore the only valid clock domain for this small audio scheduler.
    private _audioNow = serverTime;
    private _leakNext = _unit getVariable ["ACME_JuncLeakNext", -1];
    if (_leakNext < 0) then { _leakNext = _audioNow; };
    private _busyUntil = _unit getVariable ["ACME_SfxBusyUntil", -1];

    if (_audioNow >= _leakNext && {_audioNow >= _busyUntil}) then {
        private _oldLeak = _unit getVariable ["ACME_JuncLeakSfxSrc", objNull];
        if (!isNull _oldLeak) then { deleteVehicle _oldLeak; };

        private _leakSrc = createSoundSource ["ACME_JunctionalLeak_SoundSource", getPosATL _unit, [], 0];
        _leakSrc attachTo [_unit, [0, 0, 0]];
        _unit setVariable ["ACME_JuncLeakSfxSrc", _leakSrc, true];

        [{
            params ["_unit", "_src"];
            if (!isNull _src) then { deleteVehicle _src; };
            if (!isNull _unit && {local _unit} && {(_unit getVariable ["ACME_JuncLeakSfxSrc", objNull]) isEqualTo _src}) then {
                _unit setVariable ["ACME_JuncLeakSfxSrc", objNull, true];
            };
        }, [_unit, _leakSrc], 2.38] call CBA_fnc_waitAndExecute;

        _leakNext = _audioNow + 5 + random 5;
    };
    if (_audioNow < _busyUntil) then {
        _leakNext = _leakNext max (_busyUntil + 0.5 + random 2);
    };
    _unit setVariable ["ACME_JuncLeakNext", _leakNext, true];

    // a junctional bleed is arterial, so it is driven by what the ventricle actually ejects each beat rather than
    // by the minute output of the heart.
    // ACE builds its cardiac output as (entering * 95 ml) * hr / 60, where "entering" is the filling of the
    // ventricle and therefore the stroke volume term. ordinary wounds use the whole product, so a casualty who
    // compensates by going tachycardic bleeds faster the harder the heart works. that is what emptied these
    // patients in under a minute.
    // this uses the stroke volume alone, held at the reference rate of 80 bpm. the numbers are ACE's own, so the
    // existing per-part calibration is unchanged for a casualty at rest with a full tank.
    // the consequence is that the bleed falls away as the tank empties, because a ventricle that is not filling
    // cannot eject, and tachycardia no longer multiplies it. an arterial junctional bleed is self limiting in
    // exactly that way, and it buys the time to pack and wrap.
    // systemic vascular resistance. ACM folds its vasoconstriction state, 0 to 50, straight into this variable,
    // so a clamped-down casualty already bleeds less here and a vasodilated one bleeds more. it is not applied a
    // second time anywhere, because that would count the same response twice.
    private _res     = _unit getVariable ["ace_medical_peripheralResistance", 100];
    private _coeff   = missionNamespace getVariable ["ace_medical_bleedingCoefficient", 1];
    // ventricle_stroke_vol is 95e-3 liters and default_blood_volume is 6, both from ACE.
    private _bvAce   = _unit getVariable ["ace_medical_bloodVolume", 6];
    private _entering = linearConversion [0.5, 1, (_bvAce / 6), 0, 1, true];
    private _refHR   = missionNamespace getVariable ["ACME_junctionalRefHR", 80];
    private _svTerm  = (0.095 * _refHR / 60) * _entering;
    // the floor is passive drainage, meaning what leaks out under gravity with no pressure behind it. it is not
    // ACM's cardiac arrest rate, because that is calibrated for the whole wound model and would swallow the
    // stroke volume curve well before the casualty was in any real trouble.
    private _passive = missionNamespace getVariable ["ACME_junctionalPassiveBleed", 0.02];
    private _lps = _juncNorm * (_svTerm max _passive) * (100 / (_res max 1)) * _coeff;

    // Do not mutate blood volume here. ACM's circulation integration consumes this rate in the same write as
    // ordinary external wound loss, so a junctional casualty produces one coherent blood-volume update per tick.
    _unit setVariable ["ACME_junctionalBleedLPS", _lps max 0, false];
}, 1, [_unit, _epoch]] call CBA_fnc_addPerFrameHandler;
_unit setVariable ["ACME_juncPFH", _handle];
_unit setVariable ["ACME_junctionalBleedLPS", 0, false];
