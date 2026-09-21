// Flip the auscultation side using the same provider/patient roll theatre as the chest-seal minigame.
disableSerialization;
private _display = findDisplay 81000;
if (isNull _display || {_display getVariable ["ACME_stethFlipActive",false]}) exitWith {};

private _patient = _display getVariable ["ACME_stethPatient",objNull];
private _provider = _display getVariable ["ACME_stethMedic",objNull];
if (isNull _patient || {isNull _provider} || {!local _provider} || {!alive _provider}) exitWith {};

private _current = _display getVariable ["ACME_stethView","front"];
private _target = if (_current == "front") then {"back"} else {"front"};
_display setVariable ["ACME_stethPressed",false];

// Match chest-seal behavior: a conscious/mobile patient gets a view-only side change. Physical animation is only
// permitted when chestSealCanPhysicalRoll says the casualty is legitimately under the authored lying state.
if !([_patient] call ACME_fnc_chestSealCanPhysicalRoll) exitWith {
    [_display,_target] call ACME_fnc_stethoscopeSetView;
};

private _started = [_provider,"stethoscopeFlip",_patient] call ACME_fnc_rollProviderStart;
if (!_started) exitWith {};

private _pose = _provider getVariable ["ACME_treatmentPoseState",[]];
private _epoch = _pose param [0,-1];
private _rollToken = _provider getVariable ["ACME_rollProviderToken",""];
if (_epoch < 0 || {_rollToken == ""}) exitWith {};

// The stethoscope casualty lease is intentionally stronger than the roll lease. Release only our exact token
// before dispatching the roll, then reacquire the final side after the roll has settled.
private _lease = _provider getVariable ["ACME_stethPatientAnimLease",[]];
if ((count _lease) >= 2) then {
    private _leasePatient = _lease param [0,objNull];
    private _leaseToken = _lease param [1,""];
    if (!isNull _leasePatient && {_leasePatient isEqualTo _patient} && {_leaseToken != ""}) then {
        [_leasePatient,_leaseToken] call ACME_fnc_patientAnimRelease;
    };
};
_provider setVariable ["ACME_stethPatientAnimLease",[],false];

private _serial = (_display getVariable ["ACME_stethFlipSerial",0]) + 1;
_display setVariable ["ACME_stethFlipSerial",_serial];
private _token = format ["stethflip:%1:%2:%3",clientOwner,_serial,diag_tickTime];
_display setVariable ["ACME_stethFlipToken",_token];
_display setVariable ["ACME_stethFlipActive",true];
_display setVariable ["ACME_stethFlipTarget",_target];

private _button = _display displayCtrl 81006;
_button ctrlEnable false;
_button ctrlSetText "Flipping...";

private _rollTime = missionNamespace getVariable ["ACME_CS_rollTime",1.85];
if !(_rollTime isEqualType 0 && {finite _rollTime}) then {_rollTime = 1.85;};
_rollTime = (_rollTime max 0.1) min 5;
private _args = [_patient,_provider,_display,_token,_epoch,_rollToken,_target,_rollTime,-1,diag_tickTime + 5.5,false];
private _flipPFH = [{_this call ACME_fnc_stethoscopeFlipTick;},0,_args] call CBA_fnc_addPerFrameHandler;
_display setVariable ["ACME_stethFlipPFH", _flipPFH];
