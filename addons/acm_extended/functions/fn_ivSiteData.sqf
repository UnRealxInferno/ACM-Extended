// the iv mini-game site catalog. given a body part and access site, it returns everything the dialog needs: the
// limb silhouette to show, front or rear, the BOA constricting-band overlay, where the band sits, proximally, and
// where the vein and stick target sits, distal to the band toward the wrist or ankle, plus the vein name.
// call it as [_bodyPart, _site] call ACME_fnc_ivSiteData, which returns [_view, _bandTex, _bandU, _bandV, _veinU,
// _veinV, _label], or [].
// _bodyPart is "leftarm", "rightarm", "leftleg" or "rightleg".
// _site is "upper", "middle" or "lower".
// _bandU and _bandV are the BOA band center as a 0 to 1 fraction of the 2048 art canvas, where the band is applied,
// proximally.
// _veinU and _veinV are the stick target as a 0 to 1 fraction, distal to the band, which is the vein you actually
// cannulate.
// the band art is baked at the band position, and the vein is offset distally, down the limb toward the wrist or
// ankle, from there. it returns [] for an unknown combination.
params ["_bodyPart", "_site"];
private _bp = toLower _bodyPart;
private _s  = toLower _site;

#define IVUI(f) ("\acm_extended\ui\iv\" + (f) + ".paa")

// [viewfile, bandfile, bandu, bandv, veinu, veinv, midu, edgeLeftU, edgeRightU, label].
// _midU is the MEASURED horizontal midline of the limb at that site, as a fraction of the same canvas. it is the
// reference the catheter tilt pivots on, in fn_ivMinigameTick.
// it is a per-site number because the limb is not in the same place on every canvas. every value below is
// measured off the alpha of the art with tools/paa.py, over a band of rows centred on the vein, taking the run of
// limb that contains the vein. none of them is written by hand.
// the previous code used one constant, ACME_iv_tiltRefU at 0.5, for all twelve. the real midlines run from 0.456
// to 0.615, so the tilt pivoted off the arm on most sites. the worst were rightarm#middle at 0.578 and
// leftarm#upper at 0.615, both about three tilt thresholds out, which pinned the catheter at 30 degrees across
// the whole limb and never let it straighten over the vein.
private _map = createHashMapFromArray [
    // the left arm of the patient.
    ["leftarm#lower",  ["iv_left_arm_ca",       "iv_boa_left_arm_lower_ca",       0.557, 0.622, 0.557, 0.682, 0.573, 0.5359, 0.6028]],
    ["leftarm#middle", ["iv_left_arm_ca",       "iv_boa_left_arm_middle_ca",      0.477, 0.328, 0.477, 0.403, 0.491, 0.4402, 0.5511]],
    ["leftarm#upper",  ["iv_left_arm_rear_ca",  "iv_boa_left_arm_rear_upper_ca",  0.623, 0.178, 0.623, 0.253, 0.615, 0.5427, 0.6844]],
    // the right arm of the patient.
    ["rightarm#lower",  ["iv_right_arm_ca",      "iv_boa_right_arm_lower_ca",      0.512, 0.621, 0.512, 0.681, 0.498, 0.4680, 0.5344]],
    ["rightarm#middle", ["iv_right_arm_ca",      "iv_boa_right_arm_middle_ca",     0.594, 0.327, 0.594, 0.402, 0.578, 0.5237, 0.6297]],
    ["rightarm#upper",  ["iv_right_arm_rear_ca", "iv_boa_right_arm_rear_upper_ca", 0.442, 0.180, 0.442, 0.255, 0.456, 0.3835, 0.5261]],
    // the left leg of the patient.
    ["leftleg#lower",  ["iv_left_leg_ca",        "iv_left_leg_lower_ca",        0.528, 0.695, 0.528, 0.740, 0.529, 0.4929, 0.5638]],
    ["leftleg#middle", ["iv_left_leg_rear_ca",   "iv_left_leg_rear_middle_ca",  0.519, 0.421, 0.519, 0.496, 0.509, 0.4602, 0.5628]],
    ["leftleg#upper",  ["iv_left_leg_ca",        "iv_left_leg_upper_ca",        0.510, 0.180, 0.510, 0.260, 0.516, 0.4421, 0.5872]],
    // the right leg of the patient.
    ["rightleg#lower",  ["iv_right_leg_ca",      "iv_right_leg_lower_ca",       0.520, 0.702, 0.520, 0.747, 0.520, 0.4861, 0.5554]],
    ["rightleg#middle", ["iv_right_leg_rear_ca", "iv_right_leg_rear_middle_ca", 0.534, 0.431, 0.534, 0.506, 0.543, 0.4885, 0.5906]],
    ["rightleg#upper",  ["iv_right_leg_ca",      "iv_right_leg_upper_ca",       0.540, 0.167, 0.540, 0.247, 0.533, 0.4607, 0.6092]],
    // the external jugular, at the neck. there is no constricting band, because the patient must be supine or prone
    // instead. there is one vein each side of the throat, below the chin and above the clavicles. a band file of ""
    // signals no band to the dialog. the veinu and veinv are estimates on body_background_ej_view, where screen-right
    // is the patient's left, so tune them in game.
    // the ej takes no midline, because the ej tilt is one fixed frame toward the worked side and reads no reference.
    ["ej#left",  ["body_background_ej_view", "", 0.560, 0.505, 0.560, 0.505, 0.500]],
    ["ej#right", ["body_background_ej_view", "", 0.440, 0.505, 0.440, 0.505, 0.500]]
];

private _entry = _map getOrDefault [format ["%1#%2", _bp, _s], []];
if (_entry isEqualTo []) exitWith {[]};
_entry params ["_viewF", "_bandF", "_bandU", "_bandV", "_veinU", "_veinV", "_midU", ["_edgeLeftU", -1], ["_edgeRightU", -1]];
private _bandPath = if (_bandF == "") then { "" } else { IVUI(_bandF) };

// the label is DERIVED from the vein catalog rather than stored here. it used to be a literal on each row,
// and it drifted: these rows still read basilic, antecubital fossa, cephalic down the arm after the catalog
// had been rewritten to something else entirely, so the geometry and the name disagreed with nothing to
// catch it. one source of truth means that cannot happen again.
private _vein = [_bp, _s] call ACME_fnc_ivVeinCatalog;
private _label = _vein getOrDefault ["name", ""];
if (_bp == "ej" && {_label != ""}) then {
    private _side = if (_s == "right") then { "R" } else { "L" };
    _label = format ["%1 (%2)", _label, _side];
};

// the midline rides at index 7, past the label. every existing consumer reads indexes 0 to 6 by params or by
// select, so appending cannot shift anything under them.
[IVUI(_viewF), _bandPath, _bandU, _bandV, _veinU, _veinV, _label, _midU, _edgeLeftU, _edgeRightU]
