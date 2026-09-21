#include "..\script_component.hpp"
#include "..\TransfusionMenu_defines.hpp"
/*
 * Author: Blue
 * Update selection after changing body part or IV/IO selection.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call ACM_circulation_fnc_TransfusionMenu_UpdateSelection;
 *
 * Public: No
 */

private _display = uiNamespace getVariable [QGVAR(TransfusionMenu_DLG), displayNull];

private _ctrlSelectionText = _display displayCtrl IDC_TRANSFUSIONMENU_SELECTIONTEXT;

private _part = GVAR(TransfusionMenu_Selected_BodyPart);
private _site = GVAR(TransfusionMenu_Selected_AccessSite);
private _valid = if (GVAR(TransfusionMenu_SelectIV)) then {
    _site >= 0 && {[GVAR(TransfusionMenu_Target),_part,0,_site] call FUNC(hasIV)}
} else {
    [GVAR(TransfusionMenu_Target),_part,0] call FUNC(hasIO)
};
if (!_valid) exitWith {_ctrlSelectionText ctrlSetText "No IV / IO access selected";};
private _bodyPartString = [_part] call EFUNC(core,getBodyPartString);
_ctrlSelectionText ctrlSetText ([(format ["%1 - %2", _bodyPartString, LLSTRING(Intraosseous_Short)]), (format ["%1 - %2 (%3)", _bodyPartString, LLSTRING(Intravenous_Short), ([LLSTRING(IV_Upper), LLSTRING(IV_Middle), LLSTRING(IV_Lower)] select _site)])] select GVAR(TransfusionMenu_SelectIV));
