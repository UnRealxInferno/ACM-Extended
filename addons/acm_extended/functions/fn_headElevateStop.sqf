// B71 lower Semi-Fowler to flat using the authored patient release in tandem with the provider sequence.
params [["_medic", objNull, [objNull]], ["_patient", objNull, [objNull]], ["_quiet", false, [false]]];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {[_patient, "headElevStop", [_medic, _patient, _quiet]] call ACME_fnc_ownerDispatch;};
if (canSuspend) exitWith {isNil {[_medic, _patient, _quiet] call ACME_fnc_headElevateStop;};};
[_patient] call ACME_fnc_headElevHoldClear;
_patient setVariable ["ACME_headElev_treatments", createHashMap, true];
if (!alive _patient) exitWith {[_patient] call ACME_fnc_headElevDeathRelease;};
if !(_patient getVariable ["ACME_headElevated", false]) exitWith {
    [_patient] call ACME_fnc_headElevVestRestore;
    [_patient] call ACME_fnc_chestAccessVestRestore;
};
_patient setVariable ["ACME_headElev_poseToken", "", true];
_patient setVariable ["ACME_headElevated", false, true];
_patient setVariable ["ACME_headElev_Suspended", false, true];
_patient setVariable ["ACME_headElev_ResumePending", false, true];
_patient setVariable ["ACME_headElev_visualActive", false, true];
_patient setVariable ["ACME_headElev_suspendVestLoadout", [], false];
_patient setVariable ["ACME_headElev_suspendReadyAt", -1, false];
_patient setVariable ["ACME_headElev_suspendKeepVestOut", false, true];
if (!_quiet && {!isNil "ace_medical_treatment_fnc_addToLog"}) then {
    private _providerName = if (isNull _medic) then {"Provider"} else {[_medic, false, true] call ace_common_fnc_getName};
    [_patient, "activity", "%1 laid head flat", "%1 laid them supine", [_providerName]] call ACME_fnc_medLog;
};
private _pfh = _patient getVariable ["ACME_headElev_pfh", -1];
if (_pfh isEqualType 0 && {_pfh >= 0}) then {[_pfh] call CBA_fnc_removePerFrameHandler; _patient setVariable ["ACME_headElev_pfh", -1];};

// Clean any helper left from an older build, but never restore a cached world position.
private _helper = _patient getVariable ["ACME_headElev_helper", objNull];
[_patient, _helper] call ACME_fnc_releasePatient;
if (!isNull _helper) then {deleteVehicle _helper;};
_patient setVariable ["ACME_headElev_helper", objNull, true];
private _mass = _patient getVariable ["ACME_headElev_mass", -1];
if (_mass > 0) then {_patient setMass _mass; _patient setVariable ["ACME_headElev_mass", nil, true];};


private _visibleLower = !_quiet && {isNull objectParent _patient};
if (_visibleLower) then {
    // Patient and provider start together. The carrier stays as the physical bolster until the authored release has
    // finished, then it returns to the chest. That prevents a loadout change from cutting the lay-flat animation short.
    [_patient, false] call ACME_fnc_headElevCollision;
    [_patient, "ACME_HeadElevPatientRelease", 2] call ACME_fnc_doAnim;
    private _lowerTime = missionNamespace getVariable ["ACME_headElev_lowerAnimTime", 1.4];
    [_patient, _lowerTime] call ACME_fnc_headElevPinPose;
    if (!isNull _medic) then {[_medic, "lower"] call ACME_fnc_headElevMedicSeq;};
    private _rest = [_patient] call ACME_fnc_headElevRestAnim;
    [{
        params ["_patient", "_rest"];
        if (isNull _patient || {!local _patient} || {!alive _patient}) exitWith {};
        [_patient, true] call ACME_fnc_headElevCollision;
        if (_patient getVariable ["ACME_headElevated", false]) exitWith {};
        // This is a true Lower Head action: the support carrier may finally return to the body. A separate
        // backpack-supported chest-access carrier still waits for its own action lease to end.
        [_patient] call ACME_fnc_headElevVestRestore;
        [_patient] call ACME_fnc_chestAccessVestRestore;
        private _propObj = _patient getVariable ["ACME_headElev_propObj", objNull];
        if (!isNull _propObj) then {detach _propObj; deleteVehicle _propObj;};
        _patient setVariable ["ACME_headElev_propObj", objNull, true];
        if (isNull objectParent _patient && {_rest != ""}) then {[_patient, _rest, 2] call ACME_fnc_doAnim;};
    }, [_patient, _rest], _lowerTime] call CBA_fnc_waitAndExecute;
} else {
    [_patient, true] call ACME_fnc_headElevCollision;
    [_patient] call ACME_fnc_headElevVestRestore;
    [_patient] call ACME_fnc_chestAccessVestRestore;
    private _propObj = _patient getVariable ["ACME_headElev_propObj", objNull];
    if (!isNull _propObj) then {detach _propObj; deleteVehicle _propObj;};
    _patient setVariable ["ACME_headElev_propObj", objNull, true];
};
_patient setVariable ["ACME_headElev_preserveFaceDown", nil, true];
_patient setVariable ["ACME_headElev_baseAnim", nil, true];
