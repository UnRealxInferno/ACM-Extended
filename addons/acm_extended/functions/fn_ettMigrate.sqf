// an unsecured tube works its way out.
// call it as [_patient, _severity] call ACME_fnc_ettMigrate, on one handling event.
// tubes do not fall out because a clock ran. they come loose because the casualty gets handled, which in the field
// is constant: dragged, carried, loaded, unloaded and rolled. so this is driven entirely by those events. stand
// still and nothing happens, and move them across a field with a loose tube and you will pay for it.
// it is silent, and nothing announces it. the tube simply sits a little further out each time, and the medic who
// looks will see it and the medic who does not will find out later. that is the whole point of the unsecured icon
// on the body diagram: the information is there to act on.
// a secured tube still moves, and far less. tubes migrate even when they are tied, and a flat zero would teach that
// securing makes the problem disappear rather than shrink it.
params ["_patient", ["_sev", 1]];
if (isNull _patient) exitWith {};
if (!local _patient) exitWith {[_patient, "ettMigrate", [_sev]] call ACME_fnc_ownerDispatch;};
if (!(_patient getVariable ["ACME_ETT_Inserted", false])) exitWith {};

private _secured = _patient getVariable ["ACME_ETT_Secured", false];
private _step = (missionNamespace getVariable ["ACME_ettMigrateStep", 0.11]) * _sev
    * (if (_secured) then { missionNamespace getVariable ["ACME_ettSecuredMult", 0.18] } else { 1 });

private _depth = (_patient getVariable ["ACME_ETT_Depth", 1]) - _step;
if (_depth < 0) then { _depth = 0; };
[_patient, "placement", [_depth]] call ACME_fnc_ettMigrationStateCommit;

// nearly out. the cuff is sitting at the cords now, which is worse than no tube at all: it is a balloon wedged in
// the one place air has to pass. the airway obstructs and the casualty answers the way an irritated airway
// answers, and it keeps answering for about a minute.
if (_depth <= (missionNamespace getVariable ["ACME_ettCuffAtCords", 0.25])) then {
    if (!(_patient getVariable ["ACME_ETT_Obstructing", false])) then {
        [_patient, "obstruction", [true, CBA_missionTime + (missionNamespace getVariable ["ACME_ettObstructSec", 60])]] call ACME_fnc_ettMigrationStateCommit;
        // bloody if the cords have already been through something, and otherwise it is stomach contents.
        private _kind = if (_patient getVariable ["ACME_laryngo_bloody", false]) then {"Blood"} else {"Vomit"};
        private _v = format ["ACM_airway_AirwayObstruction%1_State", _kind];
        _patient setVariable [_v, ((_patient getVariable [_v, 0]) max 2), true];
        _patient setVariable ["ACME_laryngo_fluidPersist", true, true];
    };
};
