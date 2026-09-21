/*
 * Integrated clot-strength model.  Existing ACME calcium/hypothermia/acidosis coagulopathy remains the base.
 * This layer adds dilution/platelet reserve and TXA stabilization, publishes a 0..1.15 clot-strength state and
 * folds the extra multiplier back into ACME_ca_coagMult, which the canonical blood-volume transaction already reads.
 */
{
    private _u = _x;
    if (isNull _u || {!local _u} || {!alive _u}) then {continue};

    private _current = _u getVariable ["ACME_ca_coagMult",1];
    private _lastPublished = _u getVariable ["ACME_coag_lastPublished",-1];
    private _base = _u getVariable ["ACME_coag_lastBase",_current];
    // If circulation has written a fresh value since our previous pass, capture it as the new lethal-triad base.
    if (_lastPublished < 0 || {abs (_current - _lastPublished) > 0.001}) then {_base = _current max 1;};
    _u setVariable ["ACME_coag_lastBase",_base,false];

    private _platelets = (_u getVariable ["ACM_circulation_Platelet_Count",3]) max 0;
    private _plateletStrength = linearConversion [0,3,_platelets,0.18,1,true];

    // Saline and plasma-like crystalloid volume is the dilutional burden.  Cumulative saline delivery is included
    // because rapidly redistributed crystalloid can still dilute clotting factors after the bag itself is gone.
    private _saline = (_u getVariable ["ACM_circulation_Saline_Volume",0]) max 0;
    private _plasmaVol = (_u getVariable ["ACM_circulation_Plasma_Volume",0]) max 0;
    private _givenMl = (_u getVariable ["ACME_circ_salineGivenMl",0]) max 0;
    private _dilutionLoad = (_saline + (_givenMl / 1000 * 0.35)) max 0;
    private _dilutionSeverity = linearConversion [0.5,2.5,_dilutionLoad,0,1,true];
    private _dilutionMult = 1 + (0.70 * _dilutionSeverity);

    private _txa = if (!isNil "ace_medical_status_fnc_getMedicationCount") then {
        ([_u,"TXA_IV",false] call ace_medical_status_fnc_getMedicationCount) max 0 min 2
    } else {0};
    private _txaBenefit = linearConversion [0,1.5,_txa,0,0.18,true];
    // True plasma carries clotting factors rather than behaving like crystalloid dilution.
    private _factorBenefit = linearConversion [0,1.5,_plasmaVol,0,0.22,true];

    private _combinedBurden = (_base max 1) * _dilutionMult;
    private _strength = ((_plateletStrength / _combinedBurden) + _txaBenefit + _factorBenefit) max 0.08 min 1.15;
    private _extraMult = (1 / (_strength max 0.10)) max 1 min 3.0;

    private _published = (_base * _extraMult) max 1 min 5;
    // The 5 Hz physiology remains exact on the patient owner. Observers only need
    // clinically meaningful changes, plus a periodic refresh for locality/JIP safety.
    [_u,"ACME_coag_clotStrength",_strength,0.002,3] call ACME_fnc_setVarNetApprox;
    [_u,"ACME_coag_dilutionSeverity",_dilutionSeverity,0.002,3] call ACME_fnc_setVarNetApprox;
    [_u,"ACME_coag_extraMult",_extraMult,0.005,3] call ACME_fnc_setVarNetApprox;
    [_u,"ACME_ca_coagMult",_published,0.005,3] call ACME_fnc_setVarNetApprox;
    _u setVariable ["ACME_coag_lastPublished",_published,false];
} forEach allUnits;
