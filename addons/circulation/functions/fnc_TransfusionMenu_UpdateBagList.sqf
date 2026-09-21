#include "..\script_component.hpp"
#include "..\TransfusionMenu_defines.hpp"
/*
 * Author: Blue
 * Handle updating tranfusion bag list.
 *
 * Arguments:
 * 0: Is Update? <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [false] call ACM_circulation_fnc_TransfusionMenu_UpdateBagList;
 *
 * Public: No
 */

params [["_update", false]];

private _display = uiNamespace getVariable [QGVAR(TransfusionMenu_DLG), displayNull];

private _ctrlBagPanel = _display displayCtrl IDC_TRANSFUSIONMENU_LEFTLISTPANEL;

private _IVBagsOnBodyPart = (GVAR(TransfusionMenu_Target) getVariable [QGVAR(IV_Bags), createHashMap]) getOrDefault [GVAR(TransfusionMenu_Selected_BodyPart), []];

// The left list represents one selected IV/IO access, not every bag on the limb.
// Keep the native body-part index beside each filtered row so multiple lines on the
// same arm cannot force a full list rebuild every update.
private _selectedBags = [];
{
    _x params ["", "", "", ["_accessSite", -1], ["_iv", false]];
    if (_accessSite == GVAR(TransfusionMenu_Selected_AccessSite) && {_iv == GVAR(TransfusionMenu_SelectIV)}) then {
        _selectedBags pushBack [_x, _forEachIndex];
    };
} forEach _IVBagsOnBodyPart;

if !(_update) then {
    lbClear _ctrlBagPanel;
    GVAR(TransfusionMenu_Selection_IVBags) = [];

    if (count _selectedBags < 1) exitWith {};

    {
        _x params ["_bag", "_trueIndex"];
        _bag params ["_type", "_remainingVolume", "_accessType", "_accessSite", "_iv", "_bloodType", "_volume", ["_id", -1]];

        private _bagIndex = count GVAR(TransfusionMenu_Selection_IVBags);

        GVAR(TransfusionMenu_Selection_IVBags) pushBack [_type, _remainingVolume, _accessType, _accessSite, _iv, _bloodType, _volume, _id, _trueIndex];

        private _itemClassName = [_type, _volume, _bloodType] call FUNC(formatFluidBagName);

        if (_id > -1) then {
            _itemClassName = format ["%1_%2", _itemClassName, _id];
        };

        private _config = (configFile >> "CfgWeapons" >> _itemClassName);
        private _name = "";

        if ((getNumber (_config >> "uniqueBag")) > 0) then {
            ((configName _config) splitString "_") params ["","","_volume","_id"];

            private _freshEntry = [(parseNumber _id)] call FUNC(getFreshBloodEntry);
            if (_freshEntry isEqualType [] && {count _freshEntry >= 3}) then {
                private _bloodType = _freshEntry param [2, -1];
                private _bloodTypeString = [_bloodType, 1] call FUNC(convertBloodType);
                _name = format [C_LLSTRING(FreshBloodBag_Short), (format ["%1 (%2ml) [%3]", _bloodTypeString, _volume, _id])];
            } else {
                private _shortName = getText (_config >> "shortName");
                _name = if (_shortName != "") then {_shortName} else {getText (_config >> "displayName")};
                if (_name == "") then {_name = _itemClassName;};
            };
        } else {
            private _shortName = getText (_config >> "shortName");
            _name = if (_shortName != "") then {_shortName} else {getText (_config >> "displayName")};
            if (_name == "") then {_name = _itemClassName;};
        };
        private _i = _ctrlBagPanel lbAdd _name;
        _ctrlBagPanel lbSetPicture [_i, getText (_config >> "picture")];
        _ctrlBagPanel lbSetValue [_i, _bagIndex];
        _ctrlBagPanel lbSetTooltip [_i, (format [([(LLSTRING(TransfusionMenu_FluidRemaining)), ("%1ml filled")] select (_type == "FBTK")), round(_remainingVolume)])];
    } forEach _selectedBags;
} else {
    if (count GVAR(TransfusionMenu_Selection_IVBags) != count _selectedBags) exitWith {
        [false] call FUNC(TransfusionMenu_UpdateBagList);
    };

    private _rebuild = false;
    {
        _x params ["_bag", "_trueIndex"];
        _bag params ["_type", "_remainingVolume", "_accessType", "_accessSite", "_iv", "_bloodType", "_volume", ["_id", -1]];
        private _selectionIndex = _forEachIndex;

        if (_selectionIndex >= count GVAR(TransfusionMenu_Selection_IVBags)) exitWith {
            _rebuild = true;
        };

        (GVAR(TransfusionMenu_Selection_IVBags) select _selectionIndex) params ["_cType", "_cRemainingVolume", "_cAccessType", "_cAccessSite", "_cIV", "_cBloodType", "_cVolume", "_cID", "_cIndex"];

        if (_cIndex != _trueIndex || _cType != _type || _cAccessType != _accessType || _cAccessSite != _accessSite || _cIV != _iv || _cBloodType != _bloodType || _cVolume != _volume || _cID != _id) exitWith {
            _rebuild = true;
        };

        if (_cRemainingVolume != _remainingVolume) then {
            GVAR(TransfusionMenu_Selection_IVBags) set [_selectionIndex, [_cType, _remainingVolume, _cAccessType, _cAccessSite, _cIV, _cBloodType, _cVolume, _cID, _trueIndex]];
            _ctrlBagPanel lbSetTooltip [_selectionIndex, (format [([(LLSTRING(TransfusionMenu_FluidRemaining)), ("%1ml filled")] select (_type == "FBTK")), round(_remainingVolume)])];
        };
    } forEach _selectedBags;

    if (_rebuild) then {
        [false] call FUNC(TransfusionMenu_UpdateBagList);
    };
};
