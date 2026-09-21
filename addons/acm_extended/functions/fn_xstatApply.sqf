// apply an XStat 30 hemostatic sponge bolus to an axillary or inguinal junctional wound. it is an extreme-case
// device: far faster than gauze packing, at a 3 s insert against a 15 s pack plus a 15 s wrap, and the bleed ramps
// to fully controlled over about _xRamp s, defaulting to 12.
// the wound never resolves on its own. it is held by the bolus and is permanent until surgery or a full heal.
// the junctional state becomes "xstat": the wound icon stays and the injury row goes green with "[XStat]".
// the casualty is silently flagged as needing surgical care to remove it.
// an inguinal placement impairs gait, on forcewalk with no sprint, until a full heal; axillary placement does not impair gait.
// a 2-hour dwell limit is watched by the bleed pfh: if there is no surgery by then, it rebleeds.
// it cannot be removed, replaced, reapplied or stacked, because the apply action only offers it on a fresh open
// junctional wound with no occluding AAJT in place, and no XStat remove action exists.
// _this is [_medic, _patient, _bodyPart].
params ["_medic", "_patient", "_bodyPart"];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {
    [_patient, "xstatApply", [_medic, _bodyPart]] call ACME_fnc_ownerDispatch;
    if (hasInterface && {!isNull _medic} && {_medic isEqualTo ACE_player}) then {
        ["XStat inserted.", 3.5, _medic] call ace_common_fnc_displayTextStructured;
    };
};
private _p = toLowerANSI _bodyPart;
if !(_p in ["leftarm", "rightarm", "leftleg", "rightleg"]) exitWith {
    ["XStat may only be used on an axillary or inguinal junctional wound.", 2.5] call ace_common_fnc_displayTextStructured;
};

// seat the bolus. record the seat time, which drives the ramp and the dwell timer, and clear any stale pack
// flags.
_patient setVariable [format ["ACME_Junc_%1", _p], "xstat", true];
_patient setVariable [format ["ACME_Junc_XStatAt_%1", _p], time, true];
_patient setVariable [format ["ACME_Junc_XStatRebled_%1", _p], false, true];
_patient setVariable [format ["ACME_Junc_Packing_%1", _p], false, true];
_patient setVariable [format ["ACME_Junc_PackedAt_%1", _p], -1, true];

// the silent surgical flag. only a hospital or a full heal can take the XStat out.
_patient setVariable ["ACME_XStat_needsSurgery", true, true];

// XStat anywhere remains a surgical problem. Only an inguinal XStat impairs gait. Derive the gait flag from
// the actual leg device states so adding/removing an axillary XStat can never accidentally clear a leg impairment.
private _legXStat = (["leftleg", "rightleg"] findIf {
    toLowerANSI (_patient getVariable [format ["ACME_Junc_%1", _x], ""]) isEqualTo "xstat"
}) >= 0;
_patient setVariable ["ACME_XStat_impaired", _legXStat, true];
if (local _patient) then { _patient forceWalk _legXStat } else { [_patient, _legXStat] remoteExec ["ACME_fnc_forceWalkLocal", _patient] };

// the wound was an open bleeder, so the pfh is already running. this simply guarantees it, and the ramp.
[_patient] call ACME_fnc_junctionalStartBleed;

if (hasInterface && {!isNull _medic} && {_medic isEqualTo ACE_player}) then {
    ["XStat inserted.", 3.5, _medic] call ace_common_fnc_displayTextStructured;
};
