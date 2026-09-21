// head injuries trigger or worsen a TBI. it is fired off ace_medical_woundReceived. there are two mechanisms, and
// it takes the worse.
// 1. a penetrating head wound, meaning a VelocityWound or PunctureWound, the pneumothorax-class wounds. the
// severity scales with the largest such wound, from small giving mild to large giving severe. any penetrating
// head wound qualifies.
// 2. blunt head trauma: significant head body-part damage of any mechanism, such as a hard impact, a blast or a
// fall, above a threshold, with the severity scaling with the damage. minor and superficial damage does not
// qualify.
// so both a gsw to the head and a hard blunt impact seed a TBI, and a graze or trivial damage does not. a hard hit
// arrives already herniation-prone, so the ICP, CPP and pupil cascade in fn_tbihandle takes over.
// _this, from ace_medical_woundReceived, is [_unit, _allDamages, _source, _projectile].
// the wound id maps to class and size: classindex is floor(id/10) and size is id mod 10, where 0 is small, 1
// medium and 2 large.
params ["_unit", ["_newWounds", createHashMap], ["_headDelta", 0]];
if (isNull _unit || {!local _unit} || {!alive _unit}) exitWith {};

// 1. a penetrating head wound gives a severity from the largest velocity or puncture wound size.
private _penSev = -1;
private _names = missionNamespace getVariable ["ace_medical_damage_woundClassNames", []];
if !(_names isEqualTo []) then {
    private _headWounds = _newWounds getOrDefault ["head", []];
    private _maxSize = -1;
    {
        _x params ["_id", "_amountOf"];
        if (_amountOf <= 0) then { continue };
        private _ci = floor (_id / 10);
        private _sz = _id % 10;
        private _cn = if (_ci >= 0 && {_ci < count _names}) then { _names select _ci } else { "" };
        if (_cn in ["VelocityWound", "PunctureWound"] && {_sz > _maxSize}) then { _maxSize = _sz };
    } forEach _headWounds;
    if (_maxSize >= 0) then {
        _penSev = (missionNamespace getVariable ["ACME_tbi_penSizeSeverity", [0.35, 0.62, 0.95]]) param [_maxSize, 0.95];
    };
};

// 2. blunt head trauma gives a severity from the head body-part damage above a meaningful threshold.
private _bluntSev = -1;
private _head = (_unit getVariable ["ace_medical_bodyPartDamage", [0,0,0,0,0,0]]) param [0, 0];
private _bluntTrigger = missionNamespace getVariable ["ACME_tbi_bluntTriggerDamage", 0.40];
if (_headDelta > 0 && {_head >= _bluntTrigger}) then {
    _bluntSev = linearConversion [_bluntTrigger, 0.9, _head, 0.30, 0.97, true];
};

private _sev = _penSev max _bluntSev;
if (_sev < 0) exitWith {};  // neither a penetrating head wound nor significant blunt head trauma.

private _state = _unit getVariable ["ACME_tbi_State", createHashMap];
if (count _state == 0) then {
    [_unit, _sev, false] call ACME_fnc_tbiInit;
} else {
    private _cur = _state getOrDefault ["severity", 0];
    private _struct = _state getOrDefault ["structuralSeverity", _cur];
    _state set ["structuralSeverity", _struct max _sev];
    if (_sev > _cur) then {
        _state set ["severity", _sev];
        private _bump = missionNamespace getVariable ["ACME_tbi_reinjuryICPBump", 1];
        _state set ["icp", ((_state getOrDefault ["icp", 10]) + _bump) min (missionNamespace getVariable ["ACME_tbi_icpMax", 40])];
    };
    [_unit, _state] call ACME_fnc_tbiStateCommit;
};
