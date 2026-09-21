// B120 deliberate extubation action.  This is the supported removal path for now: the 4-second treatment includes
// releasing securement and the cuff rather than hiding/refusing Extubate until the operator separately manipulates the airway view.
params ["_medic", "_patient"];
if (isNull _patient) exitWith {};
if !([_medic, "intubation", true] call ACME_fnc_procedureAllowed) exitWith {};
if !(_patient getVariable ["ACME_ETT_Inserted", false]) exitWith {};

// Clear the complete durable airway state on the casualty owner. The returned tube is granted only after the
// owner accepts this extubation, preventing a remote UI race from duplicating equipment.
[_patient, "ettExtubate", [_medic]] call ACME_fnc_ownerDispatch;
