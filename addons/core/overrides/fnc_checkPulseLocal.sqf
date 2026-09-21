// ACME override of ace_medical_treatment_fnc_checkPulseLocal.
// Manual pulse checks report the mechanically palpable rate, not merely the electrical monitor rate.  AFib-RVR
// and severe low-output tachycardia may therefore have a pulse deficit.  Site thresholds still permit a carotid
// pulse after radial/femoral palpability is lost.
params ["_medic", "_patient", "_bodyPart"];

private _heartRate = 0;
private _pulseCharacter = "absent";
private _cprProvider = _patient getVariable ["ace_medical_CPR_provider", objNull];
private _compressionsActive = alive _cprProvider;

if (_compressionsActive) then {
    _heartRate = random [100,110,120];
    _pulseCharacter = "bounding";
} else {
    private _profile = [_patient, _bodyPart] call ACME_fnc_pulsePerfusionProfile;
    _profile params ["_palpable","_electricalHR","_mechanicalHR","_strength","_character"];
    if (_palpable) then {
        _heartRate = _mechanicalHR;
        _pulseCharacter = _character;
    };
};

// Hardcore clinical wording. Resolve here before the generic text/log wrappers.
private _lz = {
    params ["_k"];
    private _c = [_k] call ACME_fnc_clinTerm;
    if (_c isNotEqualTo "") exitWith {_c};
    localize _k
};

private _heartRateOutput = ["STR_ACE_medical_treatment_Check_Pulse_Output_5"] call _lz;
private _logOutput = ["STR_ACE_medical_treatment_Check_Pulse_None"] call _lz;

if (_heartRate > 1) then {
    if (_medic call ace_medical_treatment_fnc_isMedic) then {
        _heartRateOutput = ["STR_ACE_medical_treatment_Check_Pulse_Output_1"] call _lz;
        _logOutput = str round _heartRate;
    } else {
        // Weak/normal/strong follows actual pulse character rather than heart rate.
        switch (_pulseCharacter) do {
            case "thready": {
                _heartRateOutput = ["STR_ACE_medical_treatment_Check_Pulse_Output_2"] call _lz;
                _logOutput = ["STR_ACE_medical_treatment_Check_Pulse_Weak"] call _lz;
            };
            case "bounding": {
                _heartRateOutput = ["STR_ACE_medical_treatment_Check_Pulse_Output_3"] call _lz;
                _logOutput = ["STR_ACE_medical_treatment_Check_Pulse_Strong"] call _lz;
            };
            default {
                _heartRateOutput = ["STR_ACE_medical_treatment_Check_Pulse_Output_4"] call _lz;
                _logOutput = ["STR_ACE_medical_treatment_Check_Pulse_Normal"] call _lz;
            };
        };
    };
};

[_patient, "quick_view", localize "STR_ACE_medical_treatment_Check_Pulse_Log", [_medic call ace_common_fnc_getName, _logOutput]] call ace_medical_treatment_fnc_addToLog;
["ace_common_displayTextStructured", [[_heartRateOutput, _patient call ace_common_fnc_getName, round _heartRate], 1.5, _medic], _medic] call CBA_fnc_targetEvent;
