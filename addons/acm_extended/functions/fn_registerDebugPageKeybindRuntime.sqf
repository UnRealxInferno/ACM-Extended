// Rebindable debug-page navigation. It consumes the keys only while the ACME debug overlay is enabled.
if (missionNamespace getVariable ["ACME_debugPageKeysRegistered", false]) exitWith {};
missionNamespace setVariable ["ACME_debugPageKeysRegistered", true];

private _changePage = {
    params ["_delta"];
    if (!(call ACME_fnc_debugEnabled)) exitWith {false};
    private _p = uiNamespace getVariable ["ACME_debug_page", 0];
    _p = (_p + _delta) mod 2;
    if (_p < 0) then {_p = _p + 2;};
    uiNamespace setVariable ["ACME_debug_page", _p];
    call ACME_fnc_debugMenu;
    true
};

missionNamespace setVariable ["ACME_debug_changePage", _changePage];

[
    "ACM Extended", "ACME_debug_pagePrev", "Debug Menu: Previous Page",
    {[-1] call (missionNamespace getVariable ["ACME_debug_changePage", {false}])},
    {false},
    [0xC9, [false, true, false]],  // Ctrl + Page Up
    false
] call CBA_fnc_addKeybind;
[
    "ACM Extended", "ACME_debug_pageNext", "Debug Menu: Next Page",
    {[1] call (missionNamespace getVariable ["ACME_debug_changePage", {false}])},
    {false},
    [0xD1, [false, true, false]],  // Ctrl + Page Down
    false
] call CBA_fnc_addKeybind;
