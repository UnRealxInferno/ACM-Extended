/* Compile cumulative Batch 3 expansion functions without disturbing the mature CfgFunctions table. */
{
    _x params ["_name","_file"];
    missionNamespace setVariable [format ["ACME_fnc_%1",_name], compileFinal preprocessFileLineNumbers _file];
} forEach [
    ["pulsePerfusionProfile", "\acm_extended\functions\fn_pulsePerfusionProfile.sqf"],
    ["preoxygenationTick", "\acm_extended\functions\fn_preoxygenationTick.sqf"],
    ["shockSetPhenotype", "\acm_extended\functions\fn_shockSetPhenotype.sqf"],
    ["shockPhenotypeTick", "\acm_extended\functions\fn_shockPhenotypeTick.sqf"],
    ["coagulationTick", "\acm_extended\functions\fn_coagulationTick.sqf"],
    ["aspirationTick", "\acm_extended\functions\fn_aspirationTick.sqf"],
    ["megacodeAARRecord", "\acm_extended\functions\fn_megacodeAARRecord.sqf"],
    ["megacodeAARReset", "\acm_extended\functions\fn_megacodeAARReset.sqf"],
    ["megacodeAARTick", "\acm_extended\functions\fn_megacodeAARTick.sqf"],
    ["megacodeAARShow", "\acm_extended\functions\fn_megacodeAARShow.sqf"],
    ["expansionRegisterRuntime", "\acm_extended\functions\fn_expansionRegisterRuntime.sqf"]
];
[{ call ACME_fnc_expansionRegisterRuntime; }, [], 0.75] call CBA_fnc_waitAndExecute;
