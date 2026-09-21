// the outward skin signs, from the perfusion and the core temperature. it returns a brief label, for the always-on
// medical-menu row, a one-line descriptor, for the "Feel Skin" assessment, a color, and its hex.
// _this is _patient, and it returns [_short, _desc, _colorrgba, _hex].
// the "looks", meaning the pallor, keys off the perfusion, the MAP and blood volume. the "feels [temp]" keys off the
// peripheral perfusion, because shock gives cool, vasoconstricted skin, and the core temp, because hypothermia
// gives cold. the "and [moisture]" is clammy in shock and dry otherwise.
// the color is the worse of the perfusion and the temperature, so hypothermia shows up in the color even when the
// pallor still looks pink. it mirrors how cyanosis is color-graded.
params ["_patient"];

private _green = [0.50, 0.85, 0.45, 1];  private _gHex = "#7fd97f";
private _yellw = [1.00, 0.82, 0.30, 1];  private _yHex = "#ffd24d";
private _orang = [1.00, 0.55, 0.20, 1];  private _oHex = "#ff8c33";
private _red   = [1.00, 0.33, 0.33, 1];  private _rHex = "#ff5555";
private _gray  = [0.55, 0.60, 0.72, 1];  private _kHex = "#8c99b8";

if (isNull _patient) exitWith { ["Skin: unknown", "Can't assess the skin.", _gray, _kHex] };
if (!alive _patient) exitWith { ["Skin: ashen, cold", "Skin is ashen and mottled, cold to the touch.", _gray, _kHex] };

private _bp = [_patient] call ace_medical_status_fnc_getBloodPressure;
_bp params [["_dia", 80], ["_sys", 120]];
private _map = _dia + ((_sys - _dia) / 3);
private _bv = _patient getVariable ["ACM_circulation_Blood_Volume", 6];
private _temp = _patient getVariable ["ACME_hypo_temp", 37];
private _arrest = _patient getVariable ["ace_medical_inCardiacArrest", false];
private _shockType = toLowerANSI (_patient getVariable ["ACME_shock_phenotype", "none"]);
private _shockSev = (_patient getVariable ["ACME_shock_severity", 0]) max 0 min 1;
private _warmShock = (_shockType in ["distributive","neurogenic"]) && {_shockSev >= 0.25} && {_temp >= 36};

// the perfusion tier: 1 is severe or near-arrest, 2 is shock, 3 is mild or compensating and 4 is healthy.
private _tier = switch (true) do {
    case (_arrest || {_map < 50} || {_bv < 3.5}): {1};
    case (_map < 65 || {_bv < 4.5}):              {2};
    case (_map < 75 || {_bv < 5.4}):              {3};
    default {4};
};

private _pallor = if (_warmShock && {_shockType == "distributive"}) then {
    "flushed"
} else {
    switch (_tier) do {
        case 4: {"pink"};
        case 3: {"slightly pale"};
        case 2: {"pale"};
        default {"mottled and gray"};
    }
};

// the skin temperature you would feel: cold from hypothermia, then cool from shock vasoconstriction or mild cold,
// then warm.
private _feels = switch (true) do {
    case (_temp < 34): {"cold"};
    case (_warmShock): {"warm"};
    case (_tier <= 2 || {_temp < 36}): {"cool"};
    default {"warm"};
};

private _hcDesc = ((missionNamespace getVariable ["ACME_hc_descriptors", false]) isEqualTo true);
private _moisture = if (_warmShock && {_shockType == "neurogenic"}) then {
    "dry"
} else {
    if (_tier <= 2) then {if (_hcDesc) then {"diaphoretic"} else {"clammy"}} else {"dry"}
};

// the color is the worse of the perfusion tier and the temperature band.
private _tempScore = switch (true) do {
    case (_temp < 32): {1};
    case (_temp < 34): {2};
    case (_temp < 36): {3};
    default {4};
};
private _overall = _tier min _tempScore;
private _pick = switch (_overall) do {
    case 4: {[_green, _gHex]};
    case 3: {[_yellw, _yHex]};
    case 2: {[_orang, _oHex]};
    default {[_red, _rHex]};
};
_pick params ["_rgba", "_hex"];

private _short = format ["Skin: %1, %2", _pallor, _feels];
private _desc  = format ["Skin looks %1, feels %2 and %3.", _pallor, _feels, _moisture];

[_short, _desc, _rgba, _hex]
