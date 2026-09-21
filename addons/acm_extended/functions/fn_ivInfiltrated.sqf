// the catheter is in the skin but not in the vein. the hub seats, the line looks placed, and everything that goes
// down it goes into the tissue.
// call it as [_u, _v, _gauge, _bodyPart, _site] call ACME_fnc_ivInfiltrated.
// it is used by a stick that missed the vessel and by a cannula that split the vessel it entered. the outcome is
// the same in both cases, so the consequence lives here once.
// there is no puncture hole, because the catheter did not come back out. the hub is sitting in it.
params ["_u", "_v", ["_gauge", 16], ["_bodyPart", "leftarm"], ["_site", "middle"]];

// bruise containment.
// the blood collects under the hub, so the bruise goes there. it has to stay on the limb.
// each site has a safe radius, being the half-width of the limb segment at that vein, measured off the body art.
// the bruise is shrunk to fit rather than moved, so a stick near the edge of a limb marks a smaller bruise in the
// right place instead of a full one in the wrong place.
private _safeMap = createHashMapFromArray [
    ["leftarm#lower", 0.0116], ["leftarm#middle", 0.0273], ["leftarm#upper", 0.0484],
    ["rightarm#lower", 0.0114], ["rightarm#middle", 0.0242], ["rightarm#upper", 0.0416],
    ["leftleg#lower", 0.0275], ["leftleg#middle", 0.0362], ["leftleg#upper", 0.0608],
    ["rightleg#lower", 0.0278], ["rightleg#middle", 0.0355], ["rightleg#upper", 0.0616]
];
// CAUTION: Do not use str on a value that is already a string. str adds quotation marks.
// This line read toLower (str _bodyPart) and toLower (str _site), so the key was
// """leftarm"""#"""lower""" and it matched no row of the map above.
// Every site therefore used the default safe radius, and the bruise containment was wrong everywhere.
// _site arrives as a name from the mini game and as an index from the treatment actions. Take both.
private _bpKeyPart = if (_bodyPart isEqualType "") then { toLower _bodyPart } else { toLower (str _bodyPart) };
private _siteKeyPart = if (_site isEqualType "") then {
    toLower _site
} else {
    ["upper", "middle", "lower"] param [(((round _site) max 0) min 2), "middle"]
};
private _key = format ["%1#%2", _bpKeyPart, _siteKeyPart];
private _safeR = 0 max ((_safeMap getOrDefault [_key, 0.020]) - 0.003);  // a small inset, so it never touches the edge.
// the measured content radius of each bruise texture, as a fraction of the body rect.
// the 14g was reading no bigger than the others in game, because these radii are close together relative to the
// safe-radius clamp below: on a narrow site the clamp flattened all three to the same value. the gauge boost
// widens the spread BEFORE the clamp, so a 14g reads as a bigger bruise wherever the limb has room for it and
// still gets contained where it does not.
private _bruiseR = switch (_gauge) do { case 14: {0.0413}; case 18: {0.0214}; case 20: {0.0168}; default {0.0294} };
private _gBoost = switch (_gauge) do {
    case 14: { missionNamespace getVariable ["ACME_iv_bruiseBoost14", 1.45] };
    case 16: { missionNamespace getVariable ["ACME_iv_bruiseBoost16", 1.12] };
    default { 1 };
};
if (!(_gBoost isEqualType 0) || {!finite _gBoost}) then { _gBoost = 1 };
_bruiseR = _bruiseR * (_gBoost max 0.1);
private _scale = if (_bruiseR > 0) then { (_bruiseR min _safeR) / _bruiseR } else { 1 };

// the natural variance of a real bruise, so two of them never look stamped.
private _jit = 0.85 + (random 0.30);
_scale = _scale * _jit;

// keep the whole footprint on the limb picture as well as on the limb.
// the bruise control is the body rect times the scale, and the painted content is about 6.5 percent of that
// canvas, so this is the radius that is actually visible. without this clamp a stick near the top or the edge of
// the picture drew a bruise that ran off it.
private _visR = _scale * 0.0325;
private _cu = _u max _visR min (1 - _visR);
private _cv = _v max _visR min (1 - _visR);

// the bruise carries no hole texture. rendermarks only draws a puncture when one is given, so a seated hub
// leaves a bruise and nothing else.
// Bruise age is presentation shared by every provider, so use the engine's shared serverTime rather than either
// diag_tickTime or client-local CBA_missionTime.
[_cu, _cv, "miss", "", "", _gauge, serverTime, _scale, random 360, 0.72] call ACME_fnc_ivMinigameAddMark;

// flag the access as compromised. this is the same flag the extravasation model already reads, so a drug pushed
// through this line infiltrates instead of circulating, and everything downstream behaves with nothing new to
// maintain.
private _patient = uiNamespace getVariable ["ACME_IV_Patient", objNull];
if (!isNull _patient) then {
    private _siteIdx = [_site] call ACME_fnc_ivSiteIndex;
    // the key is the lowercase body part name, and the ej is filed under the head. it is NOT an index. the reader
    // in fn_postinit builds it as format ["ACME_ivCompromised_%1_%2", tolower bodypart, site], so anything else
    // here writes a variable nothing ever reads and the bad line silently behaves like a good one.
    // CAUTION: Do not use str here either. The comment above states the required name and the old
    // line then broke it, so this flag was written under a name nothing reads and a bad line behaved
    // like a good one.
    private _bpKey = _bpKeyPart;
    if (_bpKey == "ej") then { _bpKey = "head"; };
    [_patient, "ivCompromised", [_bpKey, _siteIdx, "set"]] call ACME_fnc_ownerDispatch;
};



// NO LOG LINE HERE. it was removed at v0.9.999r-42, and the reason it existed still holds.
// this function used to write "IV sited, <vein>" so that an infiltrated line still left a normal-looking record,
// because a medic who did not know they were in tissue did not write down that they were in tissue.
// fn_ivMinigameRegister now writes that record for EVERY placement, and fn_ivMinigameStickSuccess calls it
// before it calls this function, on a good stick and on a bad one alike. so the record still exists, it still
// says nothing about the miss, and there is only one of it.
// before r-42 both lines fired and the medic read two entries for one cannula.
