// add a plate carrier to casualties created by the training patient spawner of ACM.
// this is intentionally post-spawn rather than a full ACM spawner override, because ACM strips gear during
// generatepatient and spawncustompatient. so this runs after the unit exists and only touches members of
// ACM_mission_TrainingCasualtyGroup.
params ["_patient"];

if (!(missionNamespace getVariable ["ACME_acmSpawnerPlateCarrierEnabled", true])) exitWith {};
if (isNull _patient) exitWith {};
if (!alive _patient) exitWith {};
if (isPlayer _patient) exitWith {};
if (!local _patient) exitWith {
    ["ACME_acmSpawnerArmorLocal", [_patient], _patient] call CBA_fnc_targetEvent;
};

private _grp = missionNamespace getVariable ["ACM_mission_TrainingCasualtyGroup", grpNull];
if (isNull _grp) exitWith {};
if ((group _patient) != _grp) exitWith {};

private _vestClass = missionNamespace getVariable ["ACME_acmSpawnerPlateCarrierClass", "V_PlateCarrier1_rgr"];
if !(isClass (configFile >> "CfgWeapons" >> _vestClass)) exitWith {
    if !(_patient getVariable ["ACME_acmSpawnerPlateCarrierBadClassLogged", false]) then {
        _patient setVariable ["ACME_acmSpawnerPlateCarrierBadClassLogged", true, false];
    };
};

// if another script intentionally gave the patient a vest already, preserve it.
if ((vest _patient) isEqualTo "") then {
    _patient addVest _vestClass;
};

_patient setVariable ["ACME_acmSpawnerPlateCarrierDone", true, true];
