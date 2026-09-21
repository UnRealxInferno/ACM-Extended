/* B121: provider-facing default for Hardcore Medications. These are GAME defaults that select a useful
   syringe-push duration for ACME's rate model. They are not real-patient dosing instructions. A compound uses
   the slowest component's default so one fast component cannot silently force the entire mixture faster. */
params [["_row",[],[[]]]];
if (_row isEqualTo []) exitWith {3};
private _meds = [];
private _components = _row param [5,[],[[]]];
if (_components isEqualType [] && {!(_components isEqualTo [])}) then {
    {private _m = _x param [0,"",[""]]; if (_m != "") then {_meds pushBackUnique _m;};} forEach _components;
} else {
    private _m = _row param [0,"",[""]];
    if (_m != "") then {_meds pushBack _m;};
};
private _seconds = 3;
{
    private _base = (_x splitString "_") select 0;
    private _s = switch (_base) do {
        case "Adenosine": {3};
        case "Ketamine": {30};
        case "CalciumChloride": {300};
        case "CalciumGluconate": {120};
        case "Amiodarone": {300};
        case "Norepinephrine": {60};
        case "Esmolol": {60};
        case "Lidocaine": {60};
        case "Magnesium": {300};
        case "Propofol": {30};
        case "Midazolam": {60};
        case "Fentanyl": {30};
        case "Morphine": {60};
        case "Rocuronium": {30};
        default {3};
    };
    _seconds = _seconds max _s;
} forEach _meds;
(_seconds max 1) min 300
