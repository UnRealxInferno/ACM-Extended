// Compute IV palpability and puncture precision for this casualty, site and gauge.
// Pressure is deliberately the dominant input. A normal-pressure vein is broad and easy to feel; falling MAP/SBP
// collapses the palpable ridge and the usable hit core quickly. A NAR BOA is helpful but is not a permission gate:
// an unbanded vein can still be found, and a band also distends sites distal to where it is applied with a smaller
// benefit. This lets an AC-fossa band improve wrist veins without making them as obvious as the fossa itself.
// Call as [_patient,_bodyPart,_gauge,_site] call ACME_fnc_ivSiteDifficulty.
// Returns [_patency,_feelRadius,_hitRadius,_maxHot].
params ["_patient", "_bodyPart", ["_gauge", 16], ["_site", 1]];
private _bp = toLower _bodyPart;
private _siteName = if (_site isEqualType "") then {toLower _site} else {
    ["upper", "middle", "lower"] param [(((round _site) max 0) min 2), "middle"]
};

// ACE returns [diastolic,systolic]. Use both SBP and MAP: either one falling makes a peripheral vein harder to
// palpate. The nonlinear curve is intentional; mild hypotension is noticeable, while profound shock produces a
// genuinely thready/flat target rather than a slightly smaller green zone.
private _dia = 80;
private _sys = 120;
private _bp2 = if (!isNil "ace_medical_status_fnc_getBloodPressure" && {!isNull _patient}) then {
    [_patient] call ace_medical_status_fnc_getBloodPressure
} else {[80,120]};
if (_bp2 isEqualType [] && {count _bp2 >= 2}) then {
    private _d = _bp2 select 0;
    private _s = _bp2 select 1;
    if (_d isEqualType 0 && {finite _d}) then {_dia = _d max 0;};
    if (_s isEqualType 0 && {finite _s}) then {_sys = _s max 0;};
};
private _map = _dia + ((_sys - _dia) / 3);
private _sysScore = linearConversion [55, 105, _sys, 0, 1, true];
private _mapScore = linearConversion [40, 80, _map, 0, 1, true];
private _pressure = ((_sysScore * 0.45) + (_mapScore * 0.55)) max 0 min 1;
private _patency = _pressure ^ 1.60;

// Read the physical BOA state, not merely whether its texture is visible on this face. A circumferential band
// continues to distend distal veins after the provider flips from front to rear. The local UI state wins while a
// just-placed band is waiting for the owner snapshot.
private _bandOn = uiNamespace getVariable ["ACME_IV_BandOn", false];
private _bandSite = toLower (uiNamespace getVariable ["ACME_IV_Site", ""]);
if (!_bandOn && {!isNull _patient} && {_bp in ["leftarm","rightarm","leftleg","rightleg"]}) then {
    private _index = ["head","body","leftarm","rightarm","leftleg","rightleg"] find _bp;
    if (_index >= 2) then {
        private _state = _patient getVariable [format ["ACME_IV_BandState_%1", _index], []];
        if (_state isEqualType [] && {count _state == 4} && {_state select 1}) then {
            private _band = _state select 3;
            if (_band isEqualType [] && {count _band >= 2}) then {
                _bandOn = true;
                _bandSite = toLower (_band select 1);
            };
        };
    };
};

if (_bandOn && {_siteName in ["upper","middle","lower"]} && {_bandSite in ["upper","middle","lower"]}) then {
    private _targetIndex = ["upper","middle","lower"] find _siteName;
    private _bandIndex = ["upper","middle","lower"] find _bandSite;
    private _distalSteps = _targetIndex - _bandIndex;
    // Same level receives the strongest venous distension. One/two tiers distal remain palpably improved but
    // deliberately weaker, so an AC band exposes the wrist at slightly slower sensitivity rather than making it
    // identical to the AC target. A band distal to the target provides no proximal benefit.
    private _bonus = switch (_distalSteps) do {
        case 0: {0.22};
        case 1: {0.13};
        case 2: {0.08};
        default {0};
    };
    if (_bonus > 0) then {
        // A BOA amplifies venous filling; it cannot create it when perfusion has collapsed. Scaling the benefit by
        // the same pressure term keeps MAP/SBP dominant even at the exact tier under the band.
        _patency = _patency + ((1 - _patency) * _bonus * _pressure);
    };
};
_patency = _patency max 0 min 1;

// EJ remains the larger superficial target, but it is no longer immune to shock. Pressure still changes how
// strongly it can be felt; the floor simply keeps it more accessible than a collapsed hand vein.
if (_bp == "ej") exitWith {
    private _ejPerf = (0.20 + (0.80 * _patency)) max 0 min 1;
    private _hitEJ = linearConversion [14, 20, _gauge,
        (missionNamespace getVariable ["ACME_iv_ejHitMin", 0.0045]),
        (missionNamespace getVariable ["ACME_iv_ejHitMax", 0.0075]), true];
    _hitEJ = _hitEJ * linearConversion [0,1,_ejPerf,0.35,1.0,true];
    private _feelEJ = (missionNamespace getVariable ["ACME_iv_ejFeel", 0.014])
        * linearConversion [0,1,_ejPerf,0.35,1.0,true];
    [_ejPerf, _feelEJ, _hitEJ, linearConversion [0,1,_ejPerf,0.20,1.0,true]]
};

// Base palpable radius and puncture core. The low-pressure end is intentionally tiny rather than zero: a skilled
// provider can still attempt a collapsed vein, but the finger gives very little information and the placement must
// be extremely accurate.
private _feelRadius = linearConversion [0, 1, _patency, 0.0018, 0.0080, true];
private _hitRadius  = linearConversion [0, 1, _patency, 0.0009, 0.0040, true];
private _maxHot     = linearConversion [0, 1, _patency, 0.18, 1.0, true];

// Gauge scales puncture precision.
private _gaugeMult = switch (_gauge) do {
    case 14: {0.65};
    case 16: {0.85};
    case 18: {1.15};
    case 20: {1.35};
    default {1.0};
};
_hitRadius = _hitRadius * _gaugeMult;

// Site anatomy modifies the pressure-derived target without replacing it.
private _vein = [_bodyPart, _siteName] call ACME_fnc_ivVeinCatalog;
if ((count _vein) > 0) then {
    _hitRadius = _hitRadius * (linearConversion [0.3, 1.0, (_vein getOrDefault ["caliber", 0.7]), 0.72, 1.25, true]);
    _feelRadius = _feelRadius * (linearConversion [0, 1, (_vein getOrDefault ["depth", 0.3]), 1.15, 0.65, true]);
    _hitRadius = _hitRadius * (linearConversion [0, 1, (_vein getOrDefault ["roll", 0.3]), 1.10, 0.70, true]);
    private _maxG = _vein getOrDefault ["maxG", 16];
    if (_gauge < _maxG) then {
        private _over = (_maxG - _gauge) / 2;
        _hitRadius = _hitRadius * ((1 - (0.28 * _over)) max 0.25);
    };
};

[_patency, _feelRadius, _hitRadius, _maxHot]
