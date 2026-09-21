// Pure PEA morphology lookup. Native rhythm 5 still owns pulselessness, AED advice and ROSC.
// ACME has no measured potassium state. Use its existing transfusion/calcium burden as the
// gameplay proxy for the requested hyperkalemic-style wide complex, not as a potassium diagnosis.
params [["_patient",objNull,[objNull]]];
if (isNull _patient || {!alive _patient}
    || {!(_patient getVariable ["ace_medical_inCardiacArrest",false])}
    || {(_patient getVariable ["ACM_circulation_Cardiac_RhythmState",0]) != 5}) exitWith {false};

private _blood = _patient getVariable ["ACM_circulation_TransfusedBlood_Volume",0];
private _calcium = _patient getVariable ["ACM_circulation_Calcium_Count",0];
private _restingHR = _patient getVariable ["ACME_hrRestBaseline",
    _patient getVariable ["ACM_core_TargetVitals_HeartRate",80]];
if (!(_blood isEqualType 0) || {!finite _blood}) exitWith {false};
if (!(_calcium isEqualType 0) || {!finite _calcium}) exitWith {false};
if (!(_restingHR isEqualType 0) || {!finite _restingHR} || {_restingHR <= 0}) then {_restingHR = 80;};

// Native transfused-blood burden and calcium reserve are consumed together, in equal quantities.
// Subtract the unspent reserve once: as both are consumed, the uncovered burden stays consistent.
// Do not use bag size, lifetime calcium doses, or the mere presence of a blood bag.
private _uncovered = ((_blood max 0) - (_calcium max 0)) max 0;

// Reuse ACM's 0.05 L per BPM penalty and fatal <40 BPM boundary to distinguish a severe substrate
// from a small transfusion during an unrelated obstructive PEA. At an 80 BPM baseline this requires
// more than 2 L of uncovered burden. This selects a tracing only; it cannot itself induce an arrest.
(_uncovered > 0.05) && {((_restingHR max 40) - (_uncovered / 0.05)) < 40}
