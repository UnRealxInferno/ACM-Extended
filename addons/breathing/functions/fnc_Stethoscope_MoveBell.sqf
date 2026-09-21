// Compatibility entry point: pressure is explicit, never click-to-toggle.
params [["_pressed",false,[true]]];
private _display = findDisplay 81000;
if (!isNull _display) then {_display setVariable ["ACME_stethPressed",_pressed];};
