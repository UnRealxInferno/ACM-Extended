/* Hit-test the visible surgical seal, using the same UI coordinates as its artwork. */
disableSerialization;
private _patient = uiNamespace getVariable ["ACME_Thora_Patient", objNull];
private _side = uiNamespace getVariable ["ACME_Thora_Side", "right"];
if (isNull _patient || {(uiNamespace getVariable ["ACME_Thora_Held", ""]) != ""}
    || {_patient getVariable [format ["ACME_thora_tube_%1", _side], false]}
    || {!(_patient getVariable [format ["ACME_thora_sealed_%1", _side], false])}) exitWith {false};
private _seal = uiNamespace getVariable ["ACME_Thora_TubeCtrl", controlNull];
if (isNull _seal || {!ctrlShown _seal}) exitWith {false};
private _mouse = [] call ACME_fnc_chestSealMouseCoords;
if (count _mouse != 2) exitWith {false};
_mouse params ["_mx", "_my"];
(ctrlPosition _seal) params ["_left", "_top", "_width", "_height"];
(_mx >= _left) && {_mx <= (_left + _width)} && {_my >= _top} && {_my <= (_top + _height)}
