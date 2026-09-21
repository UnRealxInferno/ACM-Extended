#include "..\script_component.hpp"
#include "..\TransfusionMenu_defines.hpp"
/*
 * Author: Blue
 * Handle selecting body part in transfusion menu.
 *
 * Arguments:
 * 0: Body Part <STRING>
 * 1: Access Site <NUMBER>
 * 2: Force Route (-1 = automatic, 0 = IO, 1 = IV) <NUMBER> (optional)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["leftarm", 0, 1] call ACM_circulation_fnc_TransfusionMenu_SelectBodyPart;
 *
 * Public: No
 */

params [["_bodyPart", ""], "_accessSite", ["_forceRoute", -1]];

private _initialBodyPart = GVAR(TransfusionMenu_Selected_BodyPart);
private _initialSelectIV = GVAR(TransfusionMenu_SelectIV);
private _initialAccessSite = GVAR(TransfusionMenu_Selected_AccessSite);

if (_bodyPart == "") then {
    _bodyPart = _initialBodyPart;
};

private _targetPartIndex = GET_BODYPART_INDEX(_bodyPart);
private _forcedSelection = false;

// ACME body-map site buttons pass an explicit route. This prevents ACM's legacy route state from swallowing a
// click when a limb has both an IO and one or more IVs: clicking a catheter always selects that exact catheter.
if (_forceRoute == 1 && {[GVAR(TransfusionMenu_Target), _bodyPart, 0, _accessSite] call FUNC(hasIV)}) then {
    GVAR(TransfusionMenu_SelectIV) = true;
    GVAR(TransfusionMenu_Selected_BodyPart) = _bodyPart;
    GVAR(TransfusionMenu_Selected_AccessSite) = _accessSite;
    _forcedSelection = true;
};
if (_forceRoute == 0 && {[GVAR(TransfusionMenu_Target), _bodyPart, 0] call FUNC(hasIO)}) then {
    GVAR(TransfusionMenu_SelectIV) = false;
    GVAR(TransfusionMenu_Selected_BodyPart) = _bodyPart;
    GVAR(TransfusionMenu_Selected_AccessSite) = 0;
    _forcedSelection = true;
};

if (!_forcedSelection) then {
    if (GVAR(TransfusionMenu_SelectIV)) then {
        if ([GVAR(TransfusionMenu_Target), _bodyPart, 0, _accessSite] call FUNC(hasIV)) then {
            GVAR(TransfusionMenu_Selected_BodyPart) = _bodyPart;
            GVAR(TransfusionMenu_Selected_AccessSite) = _accessSite;
        } else {
            if ([GVAR(TransfusionMenu_Target), _bodyPart, 0] call FUNC(hasIV)) then {
                GVAR(TransfusionMenu_Selected_BodyPart) = _bodyPart;
                GVAR(TransfusionMenu_Selected_AccessSite) = (GET_IV(GVAR(TransfusionMenu_Target)) select _targetPartIndex) findIf {_x > 0};
            } else {
                if ([GVAR(TransfusionMenu_Target), _bodyPart, 0] call FUNC(hasIO)) then {
                    GVAR(TransfusionMenu_SelectIV) = false;
                    GVAR(TransfusionMenu_Selected_BodyPart) = _bodyPart;
                    GVAR(TransfusionMenu_Selected_AccessSite) = 0;
                };
            };
        };
    } else {
        if ([GVAR(TransfusionMenu_Target), _bodyPart, 0] call FUNC(hasIO)) then {
            GVAR(TransfusionMenu_Selected_BodyPart) = _bodyPart;
            GVAR(TransfusionMenu_Selected_AccessSite) = 0;
        } else {
            if ([GVAR(TransfusionMenu_Target), _bodyPart, 0] call FUNC(hasIV)) then {
                GVAR(TransfusionMenu_SelectIV) = true;
                GVAR(TransfusionMenu_Selected_BodyPart) = _bodyPart;
                GVAR(TransfusionMenu_Selected_AccessSite) = (GET_IV(GVAR(TransfusionMenu_Target)) select _targetPartIndex) findIf {_x > 0};
            };
        };
    };
};

if (_initialBodyPart != GVAR(TransfusionMenu_Selected_BodyPart) || _initialAccessSite != GVAR(TransfusionMenu_Selected_AccessSite) || _initialSelectIV != GVAR(TransfusionMenu_SelectIV)) then {
    call FUNC(TransfusionMenu_UpdateSelection);
    [false] call FUNC(TransfusionMenu_UpdateBagList);
};
