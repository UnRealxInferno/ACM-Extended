// ACM mission spawner casualty armor.
// ACM's generatepatient and spawncustompatient create b_survivor_f and strip the gear. a full function override
// breaks across ACM versions, so this addon applies the carrier after the spawn and watches ACM's own
// trainingcasualtygroup. this affects ACM training casualties only. players and normal ai stay untouched.
ACME_acmSpawnerPlateCarrierEnabled = missionNamespace getVariable ["ACME_acmSpawnerPlateCarrierEnabled", true];
ACME_acmSpawnerPlateCarrierClass   = missionNamespace getVariable ["ACME_acmSpawnerPlateCarrierClass", "V_PlateCarrier1_rgr"];

// A training casualty spawned by a non-host client can be local to that client even though the
// server owns the training-group watcher. Route armor work to the casualty owner instead of
// silently failing the local-only addVest command.
if (isNil "ACME_acmSpawnerPlateCarrierEventInstalled") then {
    ACME_acmSpawnerPlateCarrierEventInstalled = true;
    ["ACME_acmSpawnerArmorLocal", {
        params [["_patient", objNull, [objNull]]];
        if (!isNull _patient && {local _patient}) then {
            [_patient] call ACME_fnc_acmSpawnerArmor;
        };
    }] call CBA_fnc_addEventHandler;
};

if (isServer && {isNil "ACME_acmSpawnerPlateCarrierPFH"}) then {
    ACME_acmSpawnerPlateCarrierPFH = [{
        if !(missionNamespace getVariable ["ACME_acmSpawnerPlateCarrierEnabled", true]) exitWith {};
        private _grp = missionNamespace getVariable ["ACM_mission_TrainingCasualtyGroup", grpNull];
        if (isNull _grp) exitWith {};
        {
            if !(_x getVariable ["ACME_acmSpawnerPlateCarrierDone", false]) then {
                [_x] call ACME_fnc_acmSpawnerArmor;
            };
        } forEach (units _grp);
    }, 2, []] call CBA_fnc_addPerFrameHandler;
};
