// Reuse ACM's square full-body canvas and chest crop for both existing 2048x2048 textures.
// This selects the listening diagram. It does not acquire a second patient animation lease.
disableSerialization;
params ["_display", ["_view","front"]];
if (isNull _display || {!(_view in ["front","back"])}) exitWith {};
_display setVariable ["ACME_stethView",_view];
_display setVariable ["ACME_stethPressed",false];
(_display displayCtrl 81005) ctrlSetText (if (_view == "front") then {
    "\x\acm\addons\gui\ui\body_background.paa"
} else {
    "\acm_extended\ui\body_background_back.paa"
});
if !(_display getVariable ["ACME_stethFlipActive",false]) then {
    (_display displayCtrl 81006) ctrlSetText "Flip Side";
};
(_display displayCtrl 81007) ctrlSetText (if (_view == "front") then {"Anterior (front)"} else {"Posterior (back)"});
