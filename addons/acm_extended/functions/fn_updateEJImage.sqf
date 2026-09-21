// the ej, external jugular, iv marker on the medical-menu body diagram.
// ACM's body-image iv loop draws icons for the arms and legs only. it does _ivarray select (_forEachIndex + 2),
// which skips the head, index 0, and the torso, index 1. in this mod a head iv is always an external jugular, so
// an established ej otherwise shows no icon on the body diagram, unlike every limb iv and the AED pads. this adds
// one.
// the iv_ej_left_ca.paa and iv_ej_right_ca.paa icons are full-canvas overlays: the neck catheter is pre-painted at
// the correct spot in the same canvas ACM's body image uses. so, exactly like the junctional, HPMK and AAJT
// overlays, we clone the full body-image rect, idc 70113, and let the texture place the catheter, with no manual
// neck positioning needed.
// there is one control per jugular, where head access-site 0 is left and 1 is right, each shown only when that side
// is cannulated, so both can display at once. the close-up 3d hub is the establish-iv mini-game marker and this
// flat art is the body-diagram counterpart, which is the same split as every other intervention overlay.

params ["_ctrlGroup", "_target"];
if (isNull _ctrlGroup) exitWith {};

private _ref = _ctrlGroup controlsGroupCtrl 70113;  // idc_body_torso_io, the full body-image rect all the icons clone.
if (isNull _ref) exitWith {};
private _refPos = ctrlPosition _ref;

// which jugulars are cannulated? ACM stores the placement per body part as [site0, site1, site2], and index 0 is
// the head, where the two jugulars live on access-sites 0, left, and 1, right. read it directly, because the ACM
// get_iv macro is not in the macro scope of this addon.
private _leftEJ = false;
private _rightEJ = false;
if (!isNull _target) then {
    private _ivArr = _target getVariable ["ACM_circulation_IV_Placement", []];
    if ((_ivArr isEqualType []) && {count _ivArr > 0}) then {
        private _head = _ivArr select 0;
        if (_head isEqualType []) then {
            private _l = _head param [0, 0];
            private _r = _head param [1, 0];
            _leftEJ  = (_l isEqualType 0) && {_l > 0};
            _rightEJ = (_r isEqualType 0) && {_r > 0};
        };
    };
};

// one full-canvas overlay control per side, created on demand by cloning the full rect, and then only the
// visibility is toggled.
{
    _x params ["_idc", "_tex", "_show"];
    private _c = _ctrlGroup controlsGroupCtrl _idc;
    if (isNull _c) then {
        _c = (ctrlParent _ctrlGroup) ctrlCreate ["RscPicture", _idc, _ctrlGroup];
        _c ctrlSetText _tex;
        // tint it green to match every other iv placement icon. ACM's torso_io base uses color_circulation, which is
        // {0.2,0.65,0.2,1}.
        _c ctrlSetTextColor (["success2", 1] call ACME_fnc_a11yColor);
        // the position is the full body-image rect, a full-canvas clone. the .paa is already scaled to the body background,
        // so do not apply any width or height scaling here, because cloning _refPos keeps it pixel-aligned to the
        // diagram.
        _c ctrlSetPosition _refPos;
        _c ctrlCommit 0;
    };
    _c ctrlShow _show;
} forEach [
    [7290020, [0] call ACME_fnc_ejTexturePath, _leftEJ],
    [7290021, [1] call ACME_fnc_ejTexturePath, _rightEJ]
];
