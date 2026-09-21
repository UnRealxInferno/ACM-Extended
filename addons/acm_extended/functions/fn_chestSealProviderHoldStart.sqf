// Hold the provider in the chest-seal hands-on-chest workspace pose for the lifetime of the minigame.
// Flip temporarily replaces this pose and fn_chestSealFlipTick restores it directly after the roll.
params [
    ["_medic", objNull, [objNull]],
    ["_patient", objNull, [objNull]]
];
if (isNull _medic || {!alive _medic} || {_medic isEqualTo _patient}) exitWith {-1};
if (!local _medic) exitWith {
    [_medic, "chestSealProviderHold", [_medic, _patient]] call ACME_fnc_ownerDispatch;
    -1
};
if (_medic getVariable ["ACE_isUnconscious", false] || {[_medic] call ACME_fnc_animBlocked}) exitWith {-1};

private _state = _medic getVariable ["ACME_treatmentPoseState", []];
if ((_state param [1, ""]) == "chestSealWorkspace") exitWith {_state param [0, -1]};

private _epoch = [_medic, "chestSealWorkspace", -1, _patient] call ACME_fnc_treatmentPoseStart;
if (_epoch >= 0) then {
    _medic setVariable ["ACME_CS_providerHoldEpoch", _epoch, false];
};
_epoch
