// Temporarily remove a worn plate carrier for chest access.
//
// Presentation contract:
//   1. Lift the casualty with the same patient Grab/Hold animation used by Semi-Fowler.
//   2. While lifted, remove and park the carrier.
//   3. Lay the casualty back down with the matching Release animation.
//   4. The provider simultaneously uses the same medic4 body-handling animation as patient Flip.
//
// _context selects which existing custody fields own the removed carrier:
//   "access"    -> ACME_chestAccess_* (auscultation/check-breathing/inspect/CPR/thoracostomy)
//   "chestseal" -> ACME_CS_vest*       (chest-seal workspace)
params [
    ["_patient", objNull, [objNull]],
    ["_medic", objNull, [objNull]],
    ["_context", "access", [""]]
];
if (isNull _patient || {!local _patient}) exitWith {false};
_context = toLowerANSI _context;
if !(_context in ["access","chestseal"]) then {_context = "access";};

private _savedVar = ["ACME_chestAccess_vestLoadout","ACME_CS_vestLoadout"] select (_context == "chestseal");
private _propVar = ["ACME_chestAccess_vestProp","ACME_CS_vestProp"] select (_context == "chestseal");
private _readyVar = ["ACME_chestAccess_readyServer","ACME_CS_vestReadyServer"] select (_context == "chestseal");
private _busyVar = ["ACME_chestAccess_vestBusy","ACME_CS_vestBusy"] select (_context == "chestseal");

// Existing custody means another chest-access action already removed the carrier. Keep it parked and report ready.
private _saved = +(_patient getVariable [_savedVar, []]);
if ((count _saved) == 2) exitWith {
    if (_context == "chestseal") then {[_patient] call ACME_fnc_chestSealParkCarrier}
    else {[_patient] call ACME_fnc_chestAccessVestPark};
    _patient setVariable [_readyVar, serverTime, true];
    true
};

// Never schedule a second lift/removal sequence over one already in progress.
private _busy = _patient getVariable [_busyVar, ""];
if (_busy != "") exitWith {true};

private _vestClass = vest _patient;
private _vestEntry = (getUnitLoadout _patient) param [4, [], [[]]];
if (_vestClass == "" || {(count _vestEntry) != 2}) exitWith {
    _patient setVariable [_readyVar, serverTime, true];
    false
};

private _commitRemoval = {
    params ["_p","_ctx","_savedVar","_propVar"];
    if (isNull _p || {!local _p}) exitWith {false};
    if ((count (_p getVariable [_savedVar, []])) == 2) exitWith {true};

    private _class = vest _p;
    private _entry = (getUnitLoadout _p) param [4, [], [[]]];
    if (_class == "" || {(count _entry) != 2}) exitWith {false};

    removeVest _p;
    if ((vest _p) != "") exitWith {false};

    private _model = getText (configFile >> "CfgWeapons" >> _class >> "model");
    private _prop = objNull;
    if (_model != "") then {_prop = createSimpleObject [_model, [0,0,0], false];};
    if (isNull _prop) then {
        _prop = createVehicle ["GroundWeaponHolder", getPosATL _p, [], 0, "CAN_COLLIDE"];
        _prop addItemCargoGlobal [_class, 1];
    };

    _p setVariable [_savedVar, +_entry, true];
    _p setVariable [_propVar, _prop, true];
    if (_ctx == "chestseal") then {
        [_p] call ACME_fnc_chestSealParkCarrier;
    } else {
        [_p] call ACME_fnc_chestAccessVestPark;

        // Preserve the original long-action custody watchdog. It keeps the prop beyond the head and retires
        // abandoned provider leases on disconnect/death so an interrupted chest treatment cannot strand gear.
        private _oldPFH = _p getVariable ["ACME_chestAccess_vestPFH", -1];
        if (_oldPFH isEqualType 0 && {_oldPFH >= 0}) then {[_oldPFH] call CBA_fnc_removePerFrameHandler;};
        private _pfh = [{
            params ["_args","_handle"];
            _args params ["_patient"];
            if (isNull _patient || {!local _patient}
                || {(count (_patient getVariable ["ACME_chestAccess_vestLoadout", []])) != 2}) exitWith {
                [_handle] call CBA_fnc_removePerFrameHandler;
                if (!isNull _patient) then {_patient setVariable ["ACME_chestAccess_vestPFH", -1, false];};
            };

            private _leases = _patient getVariable ["ACME_chestAccess_leases", createHashMap];
            private _dirty = false;
            {
                private _lease = _leases get _x;
                private _provider = _lease param [0,objNull,[objNull]];
                private _at = _lease param [1,CBA_missionTime,[0]];
                if (isNull _provider || {!alive _provider} || {CBA_missionTime - _at > 900}) then {
                    _leases deleteAt _x;
                    _dirty = true;
                };
            } forEach keys _leases;

            if (_dirty) then {
                _patient setVariable ["ACME_chestAccess_leases", _leases, true];
                private _thora = false;
                {
                    if (((_leases get _x) param [2,"",[""]]) == "thoracostomy") exitWith {_thora = true;};
                } forEach keys _leases;
                _patient setVariable ["ACME_Thora_ChestAccessActive", _thora, true];
            };

            if ((count _leases) == 0) exitWith {[_patient] call ACME_fnc_chestAccessVestRestore;};
            [_patient] call ACME_fnc_chestAccessVestPark;
        }, 0.20, [_p]] call CBA_fnc_addPerFrameHandler;
        _p setVariable ["ACME_chestAccess_vestPFH", _pfh, false];
    };
    true
};

// Dead/vehicle/animation-blocked casualties still need functional chest access, but cannot safely play the lift.
private _canAnimate = alive _patient
    && {isNull objectParent _patient}
    && {!([_patient] call ACME_fnc_animBlocked)}
    && {[_patient] call ACME_fnc_chestSealCanPhysicalRoll
        || {_patient getVariable ["ACME_headElevated", false]}
        || {_patient getVariable ["ACME_headElev_Suspended", false]}};
if (!_canAnimate) exitWith {
    [_patient,_context,_savedVar,_propVar] call _commitRemoval;
    _patient setVariable [_readyVar, serverTime, true];
    true
};

private _liftTime = missionNamespace getVariable ["ACME_headElev_liftAnimTime", 1.2];
if (!(_liftTime isEqualType 0) || {_liftTime <= 0}) then {_liftTime = 1.2;};
private _lowerTime = missionNamespace getVariable ["ACME_headElev_lowerAnimTime", 1.4];
if (!(_lowerTime isEqualType 0) || {_lowerTime <= 0}) then {_lowerTime = 1.4;};
private _holdTime = missionNamespace getVariable ["ACME_chestAccess_vestLiftHold", 0.18];
if (!(_holdTime isEqualType 0) || {_holdTime < 0}) then {_holdTime = 0.18;};

// If Semi-Fowler is active, laying the casualty flat remains the first operation. Do not start the temporary
// vest-removal lift until the existing authored Release has reached its ready time.
private _preDelay = 0;
if (_patient getVariable ["ACME_headElevated", false]) then {
    if !(_patient getVariable ["ACME_headElev_Suspended", false]) then {
        _patient setVariable ["ACME_headElev_ResumePending", false, true];
        [_patient, true] call ACME_fnc_headElevSuspend;
    };
    private _suspendReady = _patient getVariable ["ACME_headElev_suspendReadyAt", -1];
    if (_suspendReady > CBA_missionTime) then {
        _preDelay = (_suspendReady - CBA_missionTime) + 0.05;
    };
};

private _sequenceTime = _liftTime + _holdTime + _lowerTime + 0.08;
private _total = _preDelay + _sequenceTime;

private _serial = (_patient getVariable ["ACME_chestAccess_vestSerial", 0]) + 1;
_patient setVariable ["ACME_chestAccess_vestSerial", _serial, false];
private _token = format ["vest:%1:%2:%3:%4", _context, netId _patient, _serial, round (serverTime * 1000)];
_patient setVariable [_busyVar, _token, false];
_patient setVariable [_readyVar, serverTime + _total, true];

// Start the lift only after any preceding lay-flat operation is finished. Provider and casualty begin together.
[{
    params ["_p","_medic","_busyVar","_token","_total","_liftWindow"];
    if (isNull _p || {!local _p} || {(_p getVariable [_busyVar,""]) != _token}) exitWith {};

    if (!isNull _medic && {!(_medic isEqualTo _p)}) then {
        [_medic, "chestAccessVestProvider", [_medic, _p]] call ACME_fnc_ownerDispatch;
    };

    [_p, false] call ACME_fnc_headElevCollision;
    [_p, "ACME_HeadElevPatientGrab", 2, "chest-access-vest", _medic, _total + 0.5, 4, _token] call ACME_fnc_patientAnimRequest;
    [_p, _liftWindow] call ACME_fnc_headElevPinPose;
}, [_patient,_medic,_busyVar,_token,_sequenceTime,_liftTime + _holdTime + 0.25], _preDelay] call CBA_fnc_waitAndExecute;

// Remove the carrier only once the casualty has actually been lifted, then immediately begin the authored lay-flat
// Release. The same token owns both requests, so no unrelated treatment can splice into the middle of the sequence.
[{
    params ["_p","_medic","_ctx","_savedVar","_propVar","_busyVar","_token","_commit","_lowerTime"];
    if (isNull _p || {!local _p} || {(_p getVariable [_busyVar,""]) != _token}) exitWith {};

    [_p,_ctx,_savedVar,_propVar] call _commit;

    if (alive _p && {isNull objectParent _p}) then {
        [_p, "ACME_HeadElevPatientRelease", 2, "chest-access-vest", _medic, _lowerTime + 0.4, 4, _token] call ACME_fnc_patientAnimRequest;
        [_p, _lowerTime + 0.2] call ACME_fnc_headElevPinPose;
    };
}, [_patient,_medic,_context,_savedVar,_propVar,_busyVar,_token,_commitRemoval,_lowerTime], _preDelay + _liftTime + _holdTime] call CBA_fnc_waitAndExecute;

// Settle flat and release collision/ownership. Do not invent a roll or change the casualty's logical lying state.
[{
    params ["_p","_medic","_ctx","_busyVar","_readyVar","_token"];
    if (isNull _p || {!local _p} || {(_p getVariable [_busyVar,""]) != _token}) exitWith {};
    _p setVariable [_busyVar, "", false];

    if (alive _p && {isNull objectParent _p}) then {
        private _uncon = (_p getVariable ["ACE_isUnconscious", false]) || {_p getVariable ["ace_medical_unconscious", false]};
        private _side = [_p, _p getVariable ["ACME_CS_facing","front"]] call ACME_fnc_chestSealActualSide;
        private _rest = if (_side == "back") then {
            missionNamespace getVariable ["ACME_uncon_faceDown", "ace_medical_engine_uncon_anim_1"]
        } else {
            if (_uncon) then {missionNamespace getVariable ["ACME_uncon_faceUp", "ACM_LyingState"]} else {"ACM_LyingState"}
        };
        [_p, _rest, 2, "chest-access-vest", _medic, 0.8, 3, _token] call ACME_fnc_patientAnimRequest;
    };
    [_p, true] call ACME_fnc_headElevCollision;
    _p setVariable [_readyVar, serverTime, true];
}, [_patient,_medic,_context,_busyVar,_readyVar,_token], _total] call CBA_fnc_waitAndExecute;

true
