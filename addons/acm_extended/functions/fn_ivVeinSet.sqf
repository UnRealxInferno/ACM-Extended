// the veins you can actually feel at a site, as a list of candidates rather than one strip.
// call it as [_patient, _bodyPart, _site, _baseU, _baseV] call ACME_fnc_ivVeinSet.
// _site is "upper", "middle" or "lower". _baseU and _baseV are the site's vein anchor from
// ACME_fnc_ivSiteData, which stays the reference point every candidate is offset from.
//
// it returns an array of [_u, _v, _halfLen, _quality, _name], where
//   _u, _v      the center of the vein in body fractions
//   _halfLen    half the palpable run, so a vein is a short strip rather than a point
//   _quality    0.35 to 1.15, scaling how big and how stickable it is. a thready vein is a smaller target and
//               never goes fully green.
//   _name       what it is, for the caption and the log
//
// SCOPE. only the antecubital fossa carries three veins. every other site returns the single strip it always
// had, at quality 1, so nothing outside the fossa changes behavior at all. the fossa is where the anatomy
// genuinely varies and where the choice of vein actually matters; the wrist and the upper arm do not need
// three candidates to teach anything.
//
// LATERALITY. _sgn flips the medial and lateral offsets between arms. the cephalic is on the thumb side and
// the basilic on the little finger side, and which of those is screen-left depends on the limb and the view.
// if the cephalic and basilic come out swapped in game this is a ONE LINE fix: negate _sgn. that is the same
// class of thing as the catheter tilt direction, which was also flipped once after a look in game.
params [["_patient", objNull], ["_bodyPart", ""], ["_site", "middle"], ["_baseU", 0.5], ["_baseV", 0.5]];
private _bp = toLower _bodyPart;
private _s = toLower _site;

// every site except the fossa keeps exactly its old single strip.
private _defHalf = uiNamespace getVariable ["ACME_IV_StripHalf", 0.045];
if (!(_bp in ["leftarm", "rightarm"]) || {_s isNotEqualTo "middle"}) exitWith {
    [[_baseU, _baseV, _defHalf, 1, ([_bp, _s, false] call ACME_fnc_skSiteName)]]
};

private _pheno = [_patient] call ACME_fnc_ivVenousPhenotype;
private _sgn = if (_bp isEqualTo "rightarm") then { -1 } else { 1 };

// the spread of the fossa across the limb, in body fractions. the cephalic and basilic sit either side of the
// midline and the median cubital crosses between them.
private _off = missionNamespace getVariable ["ACME_iv_fossaSpread", 0.030];
if (!(_off isEqualType 0) || {!finite _off}) then { _off = 0.030 };

// the median cubital runs OBLIQUELY, low on the cephalic side and high on the basilic side, which is what
// makes it a diagonal across the fossa rather than a horizontal bar. the vertical stagger below is what gives
// it that run.
private _rise = _off * 0.55;

private _cephU = _baseU - (_off * _sgn);   // lateral, thumb side
private _basiU = _baseU + (_off * _sgn);   // medial, little finger side. the artery and nerve are under this one.
private _out = [];

switch (_pheno) do {
    // one long oblique median cubital linking the two. the classic picture, and the middle of the fossa is a
    // real target.
    case "n": {
        _out = [
            [_baseU, _baseV, _defHalf * 0.85, 1.10, "Median Cubital"],
            [_cephU, _baseV + _rise, _defHalf, 0.90, "Cephalic"],
            [_basiU, _baseV - _rise, _defHalf, 0.95, "Basilic"]
        ];
    };
    // the median antebrachial forks, so there are two shorter obliques instead of one long one. each is a
    // smaller target than the single median cubital of an n.
    case "m": {
        _out = [
            [_baseU - (_off * 0.5 * _sgn), _baseV + (_rise * 0.5), _defHalf * 0.55, 0.85, "Median Cephalic"],
            [_baseU + (_off * 0.5 * _sgn), _baseV - (_rise * 0.5), _defHalf * 0.55, 0.85, "Median Basilic"],
            [_cephU, _baseV + _rise, _defHalf, 0.90, "Cephalic"],
            [_basiU, _baseV - _rise, _defHalf, 0.95, "Basilic"]
        ];
    };
    // no communicating vein. the center of the fossa is EMPTY, so a medic who goes for the middle out of habit
    // finds nothing at all. this is the pattern that teaches palpating before committing.
    case "separate": {
        _out = [
            [_cephU, _baseV, _defHalf * 1.15, 0.95, "Cephalic"],
            [_basiU, _baseV, _defHalf * 1.15, 1.00, "Basilic"]
        ];
    };
    // one side fat, the other thready. which side is decided off the same cached phenotype draw so it is
    // stable for the casualty rather than rerolling per palpation.
    default {
        private _side = _patient getVariable ["ACME_iv_phenotypeSide", -1];
        if (_side < 0) then {
            if (isMultiplayer) then {
                private _key = if (isPlayer _patient) then {getPlayerUID _patient} else {netId _patient};
                if (_key == "") then {_key = netId _patient;};
                if (_key == "") then {_key = format ["%1:%2:%3", typeOf _patient, vehicleVarName _patient, str _patient];};
                private _h = 37;
                { _h = ((_h * 137) + _x + ((_forEachIndex + 3) * 19)) % 9973; } forEach (toArray (_key + ":dominant"));
                _side = _h % 2;
            } else {
                _side = floor (random 2);
            };
            // Derived multiplayer state is local-only. Every client computes the same value; broadcasting it just
            // creates a first-client-wins anatomy race and unnecessary traffic.
            _patient setVariable ["ACME_iv_phenotypeSide", _side, false];
        };
        private _cephDom = _side == 1;
        _out = [
            [_baseU, _baseV, _defHalf * 0.70, 0.75, "Median Cubital"],
            [_cephU, _baseV + _rise, _defHalf, ([0.45, 1.15] select _cephDom), "Cephalic"],
            [_basiU, _baseV - _rise, _defHalf, ([1.15, 0.45] select _cephDom), "Basilic"]
        ];
    };
};

_out
