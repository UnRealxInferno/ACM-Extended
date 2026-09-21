// this runs on ace_medical_FullHeal, raised locally on the patient by ace_medical_treatment_fnc_fullheallocal. the
// zeus heal path, the ACM full-heal facility and any ACE full-heal all funnel through it.
// a full heal resolves everything, so clear the custom junctional state of the extension too, including taking out
// an XStat, which is otherwise permanent, and lifting its leg impairment. before this, junctional state could
// persist through a full heal, and this also closes that gap.
// _this is the patient. ace_medical_FullHeal raises it as a bare object, and an array form is tolerated too.
private _patient = if (_this isEqualType []) then { _this param [0, objNull] } else { _this };
if (isNull _patient) exitWith {};

{
    _patient setVariable [format ["ACME_Junc_%1", _x], "", true];
    _patient setVariable [format ["ACME_Junc_Packing_%1", _x], false, true];
    _patient setVariable [format ["ACME_Junc_PackedAt_%1", _x], -1, true];
    _patient setVariable [format ["ACME_Junc_PackStamp_%1", _x], -1, true];
    _patient setVariable [format ["ACME_Junc_XStatAt_%1", _x], nil, true];
    _patient setVariable [format ["ACME_Junc_XStatRebled_%1", _x], false, true];
} forEach ["leftarm", "rightarm", "leftleg", "rightleg"];

// XStat: lift the surgical flag and the leg impairment, because a full heal is a surgical removal.
_patient setVariable ["ACME_XStat_needsSurgery", false, true];
if (_patient getVariable ["ACME_XStat_impaired", false]) then {
    _patient setVariable ["ACME_XStat_impaired", false, true];
    if (local _patient) then { _patient forceWalk false } else { [_patient, false] remoteExec ["ACME_fnc_forceWalkLocal", _patient] };
};

// AAJT-s devices come off too. the full-heal of ACE already reset the tourniquet array, so simply clear our
// flags.
[_patient, "inguinal", [false]] call ACME_fnc_aajtStateCommit;
[_patient, "zone3", [false]] call ACME_fnc_aajtStateCommit;
[_patient, "leftarm", [false]] call ACME_fnc_aajtStateCommit;
[_patient, "rightarm", [false]] call ACME_fnc_aajtStateCommit;
[_patient] call ACME_fnc_aajtDownedStop;
private _aajtPain = _patient getVariable ["ACME_AAJT_painPFH", -1];
if (_aajtPain >= 0) then {[_aajtPain] call CBA_fnc_removePerFrameHandler;};
_patient setVariable ["ACME_AAJT_painPFH", -1, false];

// silence any lingering leak sound source. the bleed pfh will tear itself down next tick, because no junction is
// left.
if (local _patient) then {
    private _leakSrc = _patient getVariable ["ACME_JuncLeakSfxSrc", objNull];
    if (!isNull _leakSrc) then { deleteVehicle _leakSrc; };
    _patient setVariable ["ACME_JuncLeakSfxSrc", objNull, true];
    _patient setVariable ["ACME_JuncLeakNext", -1, true];
    _patient setVariable ["ACME_junctionalBleedLPS", 0, false];
};
