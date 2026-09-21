// Summarize visible contusion burden on one ACE body part for the procedure overlays.
// Returns [weighted score, wound count, 1..10 visual severity].  This is presentation only;
// it never creates, removes or changes a medical wound.
params [
    ["_patient", objNull, [objNull]],
    ["_bodyPart", "body", [""]]
];
if (isNull _patient) exitWith {[0, 0, 0]};
private _bp = toLowerANSI _bodyPart;
private _wounds = _patient getVariable ["ace_medical_openWounds", createHashMap];
if !(_wounds isEqualType createHashMap) exitWith {[0, 0, 0]};
private _score = 0;
private _count = 0;
{
    _x params ["_id", ["_amount", 0]];
    if (_id in [20, 21, 22] && {_amount > 0}) then {
        private _weight = switch (_id) do {case 21: {2}; case 22: {4}; default {1};};
        _score = _score + (_amount * _weight);
        _count = _count + _amount;
    };
} forEach (_wounds getOrDefault [_bp, []]);
if (_score <= 0) exitWith {[0, 0, 0]};
private _severity = round (linearConversion [1, 16, _score, 1, 10, true]);
[_score, _count, (_severity max 1) min 10]
