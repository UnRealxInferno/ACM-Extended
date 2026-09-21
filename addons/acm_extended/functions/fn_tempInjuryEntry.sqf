// append the last-measured core temperature to the general vitals section of the medical menu, the same persistent
// way a measured blood pressure reads.
// it shows only after a manual check temperature, so a never-measured patient shows nothing, exactly like an
// unchecked bp. it is a frozen value plus how long ago it was taken, color-coded by the reading so hypothermia and
// fever stand out at a glance.
// _this is [_ctrl, _target, _selectionN, _entries], from ace_medical_gui_updateInjuryListGeneral.
// _entries is passed by reference, so pushing onto it adds a rendered row with no override needed.
params ["_ctrl", "_target", "_selectionN", "_entries"];
if (isNull _target) exitWith {};

private _at = _target getVariable ["ACME_tempReadingAt", -1];
if (_at < 0) exitWith {};  // never measured -> show nothing

private _t = _target getVariable ["ACME_tempReading", 37];
private _ageS = (serverTime - _at) max 0;
private _age = if (_ageS < 60) then {"just now"} else {format ["%1m ago", floor (_ageS / 60)]};

// the color bands by the reading: a cold-blue family for hypothermia, deeper being colder, warm for fever and
// white for normal.
private _col = switch (true) do {
    case (_t < 32):   {["info", 1] call ACME_fnc_a11yColor};  // severe hypothermia
    case (_t < 35):   {["cool", 1] call ACME_fnc_a11yColor};  // moderate hypothermia
    case (_t < 36):   {["cyan", 1] call ACME_fnc_a11yColor};  // mild hypothermia
    case (_t > 38.5): {["danger", 1] call ACME_fnc_a11yColor};  // high fever
    case (_t > 37.8): {["warm", 1] call ACME_fnc_a11yColor};  // fever
    default           {[1, 1, 1, 1]};  // normal
};

_entries pushBack [format ["Temperature: %1%2C (%3)", (_t toFixed 1), (toString [176]), _age], _col];
