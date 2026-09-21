// Resolve the anatomical IV tier nearest a puncture point on the currently displayed patient artwork.
// [_u,_v] call ACME_fnc_ivSiteAtPoint -> "upper"/"middle"/"lower", or "".
// Optional arguments are [_u,_v,_view,_siteList,_bodyPart].
//
// The puncture coordinates, not the BOA site, own the IV location. Before selecting the nearest catalog vein,
// this function now checks the alpha-derived silhouette for the active arm/leg/EJ artwork. Transparent canvas is
// not patient skin: a catheter pushed there must not start an insertion or silently map to the nearest site.
params ["_u", "_v", ["_view", ""], ["_siteList", []], ["_bodyPart", ""]];
if (!(_u isEqualType 0) || {!(_v isEqualType 0)} || {!finite _u} || {!finite _v}) exitWith {""};
if (_view isEqualTo "") then {_view = uiNamespace getVariable ["ACME_IV_View", ""];};
if (_siteList isEqualTo []) then {_siteList = uiNamespace getVariable ["ACME_IV_SiteList", []];};
if (_bodyPart isEqualTo "") then {_bodyPart = uiNamespace getVariable ["ACME_IV_BodyPart", ""];};
if (_view isEqualTo "" || {_siteList isEqualTo []} || {_bodyPart isEqualTo ""}) exitWith {""};

private _bounds = [_bodyPart, _view, _v] call ACME_fnc_ivLimbBounds;
if (count _bounds != 2) exitWith {""};
_bounds params ["_leftU", "_rightU"];
if (_u < _leftU || {_u > _rightU}) exitWith {""};

private _best = "";
private _bestD = 1e9;
{
    if (_x isEqualType [] && {count _x >= 6}) then {
        _x params ["_sName", "_sView", "", "", "_vU", "_vV"];
        if (_sView isEqualTo _view && {_vU isEqualType 0} && {_vV isEqualType 0}) then {
            private _du = _u - _vU;
            private _dv = _v - _vV;
            private _d = sqrt ((_du * _du) + (_dv * _dv));
            if (_d < _bestD) then {_bestD = _d; _best = toLower _sName;};
        };
    };
} forEach _siteList;
_best
