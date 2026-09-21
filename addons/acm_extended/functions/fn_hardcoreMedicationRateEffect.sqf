/* B121 Hardcore Medications: bounded acute consequences of delivering selected IV drugs rapidly. Native
   medication history remains the therapeutic source of truth; these short-lived loads only represent the sharper
   hemodynamic/respiratory peak that is absent from a slow push. GAME calibration, not clinical dosing guidance. */
params ["_patient","_class","_amount","_reference",["_context",[],[[]]]];
if (isNull _patient || {!local _patient} || {!alive _patient} || {!(_context isEqualType [])} || {!(missionNamespace getVariable ["ACME_hcEff_medications",false])}) exitWith {};
private _source = _context param [3,"bolus",[""]];
if (_source == "infusion") exitWith {};
private _seconds = (_context param [2,5,[0]]) max 0.05;
private _meta = _context param [5,[],[[]]];
private _rate = if (_meta isEqualType [] && {(_meta param [0,""]) == "hcPush"}) then {_meta param [3,0,[0]]} else {_amount*60/_seconds};
if (_rate <= 0) exitWith {};
private _ref = (_reference max 0.001);
private _equivSec = _ref * 60 / _rate;
private _norm = (_amount/_ref) max 0 min 4;
private _base = (_class splitString "_") select 0;
private _add = {
    params ["_key","_fast","_scale"];
    if (_fast <= 0 || {_scale <= 0}) exitWith {};
    [_patient,_key,((_patient getVariable [_key,0]) + _norm*_fast*_scale) min 2] call ACME_fnc_setVarNet;
};
switch (_base) do {
    case "Propofol": {["ACME_hcMed_rapidPropofol",linearConversion [45,8,_equivSec,0,1,true],1] call _add;};
    case "Midazolam": {["ACME_hcMed_rapidMidazolam",linearConversion [60,10,_equivSec,0,1,true],0.8] call _add;};
    case "Fentanyl": {["ACME_hcMed_rapidOpioid",linearConversion [60,10,_equivSec,0,1,true],0.9] call _add;};
    case "Morphine": {["ACME_hcMed_rapidOpioid",linearConversion [90,15,_equivSec,0,1,true],0.7] call _add;};
    case "Rocuronium": {["ACME_hcMed_rapidRocuronium",linearConversion [60,10,_equivSec,0,1,true],0.6] call _add;};
};
