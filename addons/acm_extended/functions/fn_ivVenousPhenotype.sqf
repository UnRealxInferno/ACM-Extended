// the venous phenotype of a casualty: how the veins of the antecubital fossa are arranged.
// call it as [_patient] call ACME_fnc_ivVenousPhenotype, which returns one of "n", "m", "separate" or
// "dominant" and caches it on the unit.
//
// the fossa is the one place on the arm where the arrangement genuinely varies between people, and it varies
// enough to change which vein you should go for. the four patterns modelled:
//
//   "n"         a single median cubital running obliquely from the cephalic up to the basilic. the commonest
//               arrangement and the one every textbook picture shows.
//   "m"         the median antebrachial splits into a median cephalic and a median basilic, so there are two
//               shorter oblique veins instead of one long one.
//   "separate"  no communicating vein at all. the cephalic and the basilic run parallel and never meet, so the
//               middle of the fossa is empty and a medic who stabs the center out of habit finds nothing.
//   "dominant"  one side is fat and the other is thready. either way round.
//
// exact prevalence figures are not used here on purpose. published series disagree with each other by a lot
// and the populations differ, so a hard-coded percentage would be false precision. what is solid is that "n"
// is the commonest and the other three are each common enough to be worth meeting, so the weighting below is
// deliberately coarse and is tunable.
//
// STABILITY. this mirrors ACM's own blood type derivation exactly, at
// circulation/functions/fnc_generateBloodType.sqf:40 to 51, so a player's veins are as consistent as their
// blood type and for the same reasons:
//   a player in multiplayer   the Steam UID, so it is the same every session on every server
//   an AI in multiplayer      the network identity, so every medic sees the same anatomy for that mission
//   singleplayer              one local random draw, because there is only one authority
// the derived value is cached locally; multiplayer does not need a public anatomy variable.
params [["_patient", objNull]];
if (isNull _patient) exitWith { "n" };

private _cached = _patient getVariable ["ACME_iv_phenotype", ""];
if (_cached isNotEqualTo "") exitWith { _cached };

private _patterns = ["n", "m", "separate", "dominant"];

// The singleplayer override is deliberately ignored in multiplayer. The cache is CLIENT-LOCAL: multiplayer
// anatomy is derived deterministically below, so every medic gets the same answer without a public first-writer
// race or a network variable just to describe anatomy.
private _forced = missionNamespace getVariable ["ACME_iv_phenotypeForce", 0];
if (!(_forced isEqualType 0)) then { _forced = 0 };
if (_forced > 0 && {!isMultiplayer}) exitWith {
    private _p = _patterns param [(_forced - 1) max 0 min 3, "n"];
    _patient setVariable ["ACME_iv_phenotype", _p, false];
    _p
};

private _id = 0;
if (isMultiplayer) then {
    // Players keep stable anatomy across sessions from their UID. AI use their network identity, which is stable
    // for this mission on every client. No random draw is allowed in multiplayer because whichever medic opened
    // the IV panel first must not decide the casualty's anatomy for everyone else.
    private _key = if (isPlayer _patient) then {getPlayerUID _patient} else {netId _patient};
    if (_key == "") then {_key = netId _patient;};
    if (_key == "") then {_key = format ["%1:%2:%3", typeOf _patient, vehicleVarName _patient, str _patient];};
    private _h = 0;
    {
        _h = ((_h * 131) + _x + ((_forEachIndex + 1) * 17)) % 9973;
    } forEach (toArray _key);
    _id = _h % 100;
} else {
    // Singleplayer has only one authority, so a local random phenotype remains appropriate and is cached below.
    _id = floor (random 100);
};

// coarse weighting. n is the commonest, the rest are all worth meeting.
private _p = switch (true) do {
    case (_id < 45): { "n" };
    case (_id < 70): { "m" };
    case (_id < 85): { "dominant" };
    default         { "separate" };
};

_patient setVariable ["ACME_iv_phenotype", _p, false];
_p
