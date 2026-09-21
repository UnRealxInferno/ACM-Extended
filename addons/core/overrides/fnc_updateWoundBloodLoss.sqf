#include "\x\ACM\addons\core\script_component.hpp"
/*
 * Author: Glowbal
 * Update total wound bleeding based on open wounds and tourniquets
 * Wound bleeding = percentage of cardiac output lost
 *
 * Arguments:
 * 0: The Unit <OBJECT>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [player] call ace_medical_status_fnc_updateWoundBloodLoss
 *
 * Public: No
 */

params ["_unit"];
private _acmeBinding = "NA3:updateWoundBloodLoss";

private _tourniquets = GET_TOURNIQUETS(_unit);
private _bodyPartBleeding = [0,0,0,0,0,0];
private _openWounds = GET_OPEN_WOUNDS(_unit);
private _activeBandages = _unit getVariable [QEGVAR(damage,BandageProgress), createHashMap];
if !(_activeBandages isEqualType createHashMap) then {_activeBandages = createHashMap;};

// B134: the junctional overlay is an additional arterial channel layered on a real native wound. Mechanical
// junctional control must affect both channels. Previously packing/XStat/wrapping could make ACME's arterial
// channel read controlled while the native wound continued bleeding underneath it. Bind control to the source
// wound id so unrelated wounds elsewhere on the same limb remain independent.
private _juncNativeFactor = {
    params ["_part", "_woundId"];
    private _state = _unit getVariable [format ["ACME_Junc_%1", _part], ""];
    if (_state == "") exitWith {1};
    private _sourceId = _unit getVariable [format ["ACME_Junc_SourceWound_%1", _part], -1];
    if (_sourceId < 0) then {
        // Backward-compatible inference for an older junctional that predates source binding.
        private _bestScore = -1;
        {
            _x params ["_id", "_amount", "_bleed"];
            private _score = (_amount max 0) * (_bleed max 0);
            if (_score > _bestScore) then {_bestScore = _score; _sourceId = _id;};
        } forEach (_openWounds getOrDefault [_part, []]);
        if (_sourceId >= 0) then {_unit setVariable [format ["ACME_Junc_SourceWound_%1", _part], _sourceId, true];};
    };
    if (_woundId != _sourceId) exitWith {1};

    switch (_state) do {
        case "wrapped": {0};
        case "xstat": {
            private _at = _unit getVariable [format ["ACME_Junc_XStatAt_%1", _part], time];
            private _dwell = (time - _at) max 0;
            private _ramp = missionNamespace getVariable ["ACME_xstatRampTime", 12];
            private _seatRemain = 1 - ((_dwell / (_ramp max 0.01)) min 1);
            private _dwellLimit = missionNamespace getVariable ["ACME_xstatDwellTime", 7200];
            private _rebleedDur = missionNamespace getVariable ["ACME_xstatRebleedTime", 120];
            private _rebleedMax = missionNamespace getVariable ["ACME_xstatRebleedMaxFrac", 0.5];
            private _rebleed = 0;
            if (_dwell > _dwellLimit) then {
                _rebleed = _rebleedMax * (((_dwell - _dwellLimit) / (_rebleedDur max 0.01)) max 0 min 1);
            };
            (_seatRemain max _rebleed) max 0 min 1
        };
        case "packed": {
            private _gauze = missionNamespace getVariable ["ACME_junctionalGauzeControl", 0.50];
            private _provider = _unit getVariable [format ["ACME_DP_press_%1", _part], objNull];
            private _dpHeld = (!isNull _provider && {alive _provider} && {_provider getVariable ["ACME_DP_Active", false]} && {!(_provider getVariable ["ACME_DP_Paused", false])});
            if (_dpHeld) exitWith {0};
            private _wrapProgress = 0;
            {
                _y params ["_bp", "", "_started", "_duration", ["_bandageClass", ""]];
                if (_bandageClass == "ACME_WrapJunctional" && {_bp == _part}) then {
                    private _p = ((serverTime - _started) / (_duration max 0.01)) max 0 min 1;
                    _wrapProgress = _wrapProgress max (_p * _p);
                };
            } forEach _activeBandages;
            (_gauze * (1 - _wrapProgress)) max 0 min 1
        };
        case "open": {
            private _packProgress = 0;
            {
                _y params ["_bp", "", "_started", "_duration", ["_bandageClass", ""]];
                if (_bandageClass == "ACME_PackJunctional" && {_bp == _part}) then {
                    private _p = ((serverTime - _started) / (_duration max 0.01)) max 0 min 1;
                    _packProgress = _packProgress max (_p * _p);
                };
            } forEach _activeBandages;
            private _gauze = missionNamespace getVariable ["ACME_junctionalGauzeControl", 0.50];
            (1 - ((1 - _gauze) * _packProgress)) max 0 min 1
        };
        default {1};
    };
};

{
    private _part = _x;
    private _partIndex = ALL_BODY_PARTS find _part;
    if (_tourniquets select _partIndex == 0 && {!([_unit, _partIndex] call ACME_fnc_aajtOccludes)}) then {
        {
            _x params ["_woundId", "_amountOf", "_bleeding"];
            private _factor = [_part, _woundId] call _juncNativeFactor;
            _bodyPartBleeding set [_partIndex, (_bodyPartBleeding select _partIndex) + (_amountOf * _bleeding * _factor)];
        } forEach _y;
    };
} forEach _openWounds;

// B107: a dressing controls hemorrhage progressively while it is physically being applied.  The start event
// records the bleed reduction that the completed bandage is expected to produce.  Apply a quadratic ease-in so
// control is modest early in the timer and accelerates as the provider gets closer to securing the dressing.
// No wound amount is mutated here.  On interruption the record disappears and the original bleeding returns;
// on success ACE's normal bandage callback performs the permanent wound change.
private _bandageProgress = _activeBandages;
if (_bandageProgress isEqualType createHashMap && {count _bandageProgress > 0}) then {
    private _expiredBandages = [];
    {
        _y params ["_part", "_finalReduction", "_startedAt", "_duration", ["_bandageClass", ""]];
        private _age = serverTime - _startedAt;
        if (_age > (_duration + 2)) then {
            _expiredBandages pushBack _x;
        } else {
            private _partIndex = ALL_BODY_PARTS find _part;
            if (_partIndex >= 0 && {_finalReduction > 0}) then {
                private _progress = (_age / (_duration max 0.01)) max 0 min 1;
                private _control = _progress * _progress;
                private _current = _bodyPartBleeding select _partIndex;
                _bodyPartBleeding set [_partIndex, (_current - (_finalReduction * _control)) max 0];
            };
        };
    } forEach _bandageProgress;

    if (_expiredBandages isNotEqualTo []) then {
        { _bandageProgress deleteAt _x; } forEach _expiredBandages;
        _unit setVariable [QEGVAR(damage,BandageProgress), _bandageProgress, true];
    };
};

// B102: direct pressure gets a modest immediate effect on ordinary external limb bleeding. This is deliberately
// limb-only. Head and torso pressure keep their existing behavior unchanged. The clinical marker is cleared while
// movement or an incompatible maneuver yields pressure, so this multiplier only exists while pressure is actually
// being maintained.
private _dpLimbMult = missionNamespace getVariable ["ACME_DP_limbBleedMult", 0.72];
{
    private _partIndex = _x;
    private _part = ALL_BODY_PARTS select _partIndex;
    private _provider = _unit getVariable [format ["ACME_DP_press_%1", _part], objNull];
    if (!isNull _provider
        && {alive _provider}
        && {_provider getVariable ["ACME_DP_Active", false]}
        && {!(_provider getVariable ["ACME_DP_Paused", false])}) then {
        _bodyPartBleeding set [_partIndex, (_bodyPartBleeding select _partIndex) * _dpLimbMult];
    };
} forEach [2,3,4,5];

// Internal bleeding
private _bodyPartInternalBleeding = [0,0,0,0,0,0];
{
    private _partIndex = ALL_BODY_PARTS find _x;
    if (_tourniquets select _partIndex == 0 && {!([_unit, _partIndex] call ACME_fnc_aajtOccludes)}) then {
        {
            _x params ["", "_woundCount", "_bleedRate"];

            _bodyPartInternalBleeding set [_partIndex, (_bodyPartInternalBleeding select _partIndex) + (_woundCount * _bleedRate)];
        } forEach _y;
    };
} forEach GET_INTERNAL_WOUNDS(_unit);

/*if (GVAR(Hardcore_InternalBleeding)) then {
    [_unit] call EFUNC(damage,handleHardcoreInternalBleeding);
};*/

if (_bodyPartInternalBleeding isEqualTo [0,0,0,0,0,0]) then {
    _unit setVariable [VAR_INTERNAL_BLEEDING, 0, true];
} else {
    _bodyPartInternalBleeding params ["_headB", "_bodyB", "_leftArmB", "_rightArmB", "_leftLegB", "_rightLegB"];

    private _bodyBleedingRate = ((_headB min 0.9) + (_bodyB min 1.0)) min 1.0;
    private _limbBleedingRate = ((_leftArmB min 0.3) + (_rightArmB min 0.3) + (_leftLegB min 0.5) + (_rightLegB min 0.5)) min 1.0;

    _limbBleedingRate = _limbBleedingRate * (1 - _bodyBleedingRate);

    _unit setVariable [VAR_INTERNAL_BLEEDING, (_bodyBleedingRate + _limbBleedingRate), true];

    if !(_unit getVariable [QGVAR(IBCoagulation_Active), false]) then {
        [QEGVAR(damage,handleIBCoagulationPFH), [_unit], _unit] call CBA_fnc_targetEvent;
    };
};

if (_bodyPartBleeding isEqualTo [0,0,0,0,0,0]) then {
    TRACE_1("updateWoundBloodLoss-none",_unit);
    _unit setVariable [VAR_WOUND_BLEEDING, 0, true];
} else {
    _bodyPartBleeding params ["_headB", "_bodyB", "_leftArmB", "_rightArmB", "_leftLegB", "_rightLegB"];

    private _bodyBleedingRate = 0;
    private _limbBleedingRate = 0;

    if (GET_INTERNAL_BLEEDING(_unit) > 0.3) then { // Severe internal bleeding slows external bleeding
        _bodyPartInternalBleeding params ["_headIB", "_bodyIB", "_leftArmIB", "_rightArmIB", "_leftLegIB", "_rightLegIB"];

        _bodyBleedingRate = ((((_headB - _headIB) max 0) min 0.9) + (((_bodyB - _bodyIB) max 0) min 1.0)) min 1.0;
        _limbBleedingRate = ((((_leftArmB - _leftArmIB) max 0) min 0.3) + (((_rightArmB - _rightArmIB) max 0) min 0.3) + (((_leftLegB - _leftLegIB) max 0) min 0.5) + (((_rightLegB - _rightLegIB) max 0) min 0.5)) min 1.0;
    } else {
        _bodyBleedingRate = ((_headB min 0.9) + (_bodyB min 1.0)) min 1.0;
        _limbBleedingRate = ((_leftArmB min 0.3) + (_rightArmB min 0.3) + (_leftLegB min 0.5) + (_rightLegB min 0.5)) min 1.0;
    };

    // limb bleeding is scaled down based on the amount of body bleeding
    _limbBleedingRate = _limbBleedingRate * (1 - _bodyBleedingRate);

    TRACE_3("updateWoundBloodLoss-bleeding",_unit,_bodyBleedingRate,_limbBleedingRate);
    _unit setVariable [VAR_WOUND_BLEEDING, _bodyBleedingRate + _limbBleedingRate, true];

    if (EGVAR(circulation,coagulationClotting) && (EGVAR(circulation,coagulationClottingAffectAI) || (!(EGVAR(circulation,coagulationClottingAffectAI)) && isPlayer _unit))) then {
        if !(_unit getVariable [QGVAR(Coagulation_Active), false]) then {
            [QEGVAR(damage,handleCoagulationPFH), [_unit], _unit] call CBA_fnc_targetEvent;
        };
    };
};
