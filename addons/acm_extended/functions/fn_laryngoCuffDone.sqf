// cuff up. the airway is now definitive.
// call it as [] call ACME_fnc_laryngoCuffDone.
// this is the moment the tube becomes worth what it cost. ACME_ETT_CuffInflated is what fn_ettairwayprotect gates
// on, so from here the casualty is protected from vomit, blood and soft-tissue collapse exactly the way an i-gel
// protects them, no better and no worse. the only price of a tube over a supraglottic is everything that had to
// happen to get here: sedation or paralysis, the laryngoscopy, holding the view, feeding the tube and inflating
// the cuff. once it is in, it is in.
disableSerialization;
private _dlg     = uiNamespace getVariable ["ACME_laryngo_dlg", displayNull];
private _patient = uiNamespace getVariable ["ACME_laryngo_patient", objNull];
private _medic   = uiNamespace getVariable ["ACME_laryngo_medic", ACE_player];
if (isNull _patient) exitWith { closeDialog 0; };
// Once a tube has passed the cords, finishing its cuff remains aftercare even if
// the mission disables new intubations while the panel is open.
private _existingTube = (_patient getVariable ["ACME_ETT_Inserted", false])
    || {uiNamespace getVariable ["ACME_laryngo_tubePassed", false]};
if !([_medic, "intubation", _existingTube] call ACME_fnc_procedureAllowed) exitWith {};
if (uiNamespace getVariable ["ACME_laryngo_done", false]) exitWith {};
// it is not done in the sense of closing. the screen stays open, and this simply stops the cuff step running again.
// cuff up: the airway is definitive from here. the collar is the last step, and it is mechanical rather than
// clinical.
private _tubeCommittedB39 = (uiNamespace getVariable ["ACME_laryngo_tubePassed", false])
    || {_patient getVariable ["ACME_ETT_Inserted", false]};
uiNamespace setVariable ["ACME_laryngo_state", if (_tubeCommittedB39) then {"collar"} else {"tube"}];

// consume the tube and secure the airway.
// it is not consumed here, because it came off the count the moment it went through the cords.
// The cuff can be inflated before seating. That is a valid mechanical state, but it is NOT
// a definitive airway until the tube has actually passed the cords. Preserve the inflated cuff
// while allowing further tube manipulation/insertion.
private _rammed = _tubeCommittedB39 && {uiNamespace getVariable ["ACME_laryngo_tubeRammed", false]};
private _timeToTube = uiNamespace getVariable ["ACME_laryngo_attemptClock", 0];
[_patient, "ettCuffDone", [_medic, _tubeCommittedB39, _rammed, _timeToTube]] call ACME_fnc_ownerDispatch;

if (_tubeCommittedB39) then {
    // rammed in. advancing the tube faster than the cords will tolerate scrapes them, and that shows up after the tube
    // is in rather than as a failure at the time, because that is when a scraped airway announces itself. the
    // consequence is deliberately mild and recoverable: the airway bleeds around the tube. the tube itself still
    // works, the casualty is still combat-recoverable, and suction handles it.
    if (_rammed) then {
        [_patient, "trauma"] call ACME_fnc_laryngoBleed;
    };

    if (!isNil "ace_medical_treatment_fnc_addToLog") then {
        [_patient, "airway", "Orotracheal intubation: ET tube placed, cuff inflated", []] call ace_medical_treatment_fnc_addToLog;
    };
    if (!isNil "ace_medical_treatment_fnc_addToTriageCard") then {
        [_patient, "Endotracheal tube placed"] call ace_medical_treatment_fnc_addToTriageCard;
    };

    // the attempt record, for the aar. first-pass success and time to tube are the two numbers the airway world
    // actually cares about, so they are worth having on the casualty rather than only in a hint.
};

if (!isNull _dlg) then {
    { (_dlg displayCtrl _x) ctrlSetTextColor [1,1,1,0]; } forEach [87814,87817,87818];
    // used. the syringe is empty now, so it leaves the hand and comes off the tray count. it is not stowed for you when
    // you go to inflate, only once the act is finished.
    uiNamespace setVariable ["ACME_laryngo_held", ""];
    // B39: this is the reusable cuff syringe from the tray. Emptying it returns it to the tray;
    // it is not a consumed medication syringe and remains available if the cuff is later deflated.
    uiNamespace setVariable ["ACME_laryngo_syringeUsed", false];
    {(_dlg displayCtrl _x) ctrlSetTextColor [1,1,1,0];} forEach [87814,87817,87818];
    uiNamespace setVariable ["ACME_laryngo_cuffDone", true];
    // give the cursor tracker its normal area back, now the syringe is finished with.
    (_dlg displayCtrl 87830) ctrlSetPosition (uiNamespace getVariable ["ACME_laryngo_viewRect", [0,0,0.5,0.5]]);
    (_dlg displayCtrl 87830) ctrlCommit 0;
    (_dlg displayCtrl 87810) ctrlSetText "";
    (_dlg displayCtrl 87816) ctrlSetText "";
};
playSound "ACME_VentClick";

// there is no automatic exit. the operator presses done when they are ready to leave.
[] call ACME_fnc_laryngoRefreshSlots;
