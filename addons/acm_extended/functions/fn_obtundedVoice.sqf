// a best-effort TFAR radio and voice mute for the obtunded state. it runs locally on the machine of the affected
// player, which is where TFAR wants voice calls made. the exact API differs by version, so every call here is
// guarded and every setVariable is harmless if TFAR is not loaded.
// _this is [_unit, _mute], where a _mute of true silences and false restores.
params ["_unit", ["_mute", true]];

// Manual/debug obtundation may still exercise the TFAR mute path.
private _effectiveMute = _mute
    && {(missionNamespace getVariable ["ACME_sys_obtunded", false]) || {_unit getVariable ["ACME_obtunded_manual", false]}}
    && {!isNull _unit}
    && {alive _unit}
    && {_unit getVariable ["ACME_obtunded", false]}
    && {!(_unit getVariable ["ACE_isUnconscious", false])};

// tfar, the beta "TFAR_fnc_*" api.
_unit setVariable ["tf_unable_to_use_radio", _effectiveMute, true];
_unit setVariable ["tf_voiceVolume", ([1, 0] select _effectiveMute), true];
if (!isNil "TFAR_fnc_setForbiddenToSpeak") then {
    [_unit, _effectiveMute] call TFAR_fnc_setForbiddenToSpeak;
};

// tfar, the legacy "task_force_radio" api.
_unit setVariable ["tf_unconscious_analog_radio", _effectiveMute, true];
