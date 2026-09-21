/* B121 admitted exposure only. Hardcore Medications gates manual push-rate consequences; infusion-rate models
   remain active because their physical flow rate is part of the infusion system itself. */
params ["_patient","_class","_amount","_iv","_reference",["_context",[]]];
if (isNull _patient || {!local _patient} || {!alive _patient} || {_amount <= 0}) exitWith {};
private _source = _context param [3,if (missionNamespace getVariable ["ACME_vesicant_infusionDelivery",false]) then {"infusion"} else {"bolus"}];
private _hcMed = missionNamespace getVariable ["ACME_hcEff_medications",false];
private _totals = _patient getVariable ["ACME_medicationAdmitted",createHashMap];
_totals set [_class,(_totals getOrDefault [_class,0]) + _amount];
_patient setVariable ["ACME_medicationAdmitted",_totals,true];
private _families = _patient getVariable ["ACME_medicationGenerations",createHashMap];
private _family = switch (true) do {
    case (_class in ["Fentanyl","Fentanyl_IV","Fentanyl_BUC","Morphine","Morphine_IV"]): {"opioid"};
    case (_class in ["Ketamine","Ketamine_IV","Esketamine"]): {"ketamine"};
    default {_class};
};
_families set [_family,(_families getOrDefault [_family,0]) + 1];
_patient setVariable ["ACME_medicationGenerations",_families,true];
if (_class == "Naloxone") then {[_patient,"mark","opioid",_families getOrDefault ["opioid",0],createHashMap,true] call ACME_fnc_medicationToxicityFiredCommit;};
private _seconds = _context param [2,5];
if !(_seconds isEqualType 0 && {finite _seconds}) then {_seconds=5;};
_seconds = _seconds max 0.25;
private _rateMeta = _context param [5,[]];
private _hcPushRate = if (_rateMeta isEqualType [] && {(_rateMeta param [0,""]) == "hcPush"}) then {_rateMeta param [3,0,[0]]} else {0};
if (_class == "Adenosine_IV") then {
    private _episodes = _patient getVariable ["ACME_adenosineEpisodes",[]];
    private _speed = 1;
    if (_source == "infusion") then {_speed=0.1;} else {
        if (_hcMed) then {
            private _equivSec = if (_hcPushRate > 0) then {360/_hcPushRate} else {_seconds};
            _speed = linearConversion [5,30,_equivSec,1,0.1,true];
        };
    };
    _episodes pushBack [(_amount/6)*_speed,0,false];
    _patient setVariable ["ACME_adenosineEpisodes",_episodes,true];
};
if (_source != "infusion") then {[_patient,_class,_amount,if (_iv) then {_seconds} else {120}] call ACME_fnc_medicationDriveAdd;};
if (_class == "Ketamine_IV" && {_source != "infusion"} && {_hcMed}) then {
    private _inductionLoad = (_amount / (_reference max 0.001)) * 0.8 / ((missionNamespace getVariable ["ACME_ket_induceThreshold",7]) max 0.1);
    private _equivSec = if (_hcPushRate > 0) then {(_reference max 0.001)*60/_hcPushRate} else {_seconds};
    private _speed = linearConversion [30,5,_equivSec,0,1,true];
    [_patient,"ACME_ketRapidLoad",(_patient getVariable ["ACME_ketRapidLoad",0]) + _inductionLoad*_speed] call ACME_fnc_setVarNet;
};
if (_hcMed && {_iv} && {_source != "infusion"}) then {[_patient,_class,_amount,_reference,_context] call ACME_fnc_hardcoreMedicationRateEffect;};
