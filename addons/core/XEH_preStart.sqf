#include "script_component.hpp"

#include "XEH_PREP.hpp"

// B127 multiplayer override reconciliation. ACE prepares its dragging functions from XEH_preStart as well, and
// heavily modded clients can otherwise finish startup with ACE's native carry-drop function installed after the
// CfgFunctions override below. Rebind the one carry-drop function whose ACM lying-state handoff is required by this
// fork after ace_dragging (a required addon of ACM_core) has completed its own preparation. fn_compatCheck performs
// one late verification/repair as a second line of defense for mods which deliberately recompile it during postInit.
ace_dragging_fnc_dropObject_carry = compile preprocessFileLineNumbers QPATHTOF(overrides\fnc_dropObject_carry.sqf);

// ace/addons/medical_ai/XEH_preStart.sqf
private _itemHash = createHashMap;
// key is Treatment Type (prefix @ represents a group of treatments)
// value is hash of item/treatment pairs
{
    _x params ["_itemType", "_treatments"];

    private _typeHash = createHashMap;
    {
        private _items = getArray (configFile >> "ace_medical_treatment_actions" >> _x >> "items");
        if (_items isEqualTo []) then { ERROR_1("bad action %1",_x); };
        private _itemClassname = configName (configFile >> "CfgWeapons" >> _items # 0);
        private _treatment = ["", _x] select ((count _treatments) > 1);
        _typeHash set [_itemClassname, _treatment];
    } forEach _treatments;
    _itemHash set [_itemType, _typeHash];
} forEach [
    ["@bandage", ["PressureBandage", "EmergencyTraumaDressing", "FieldDressing", "PackingBandage", "ElasticBandage", "QuikClot"]],
    ["@airway", ["InsertNPA", "InsertOPA", "InsertIGel"]],
    ["@suction", ["UseSuctionBag", "UseACCUVAC"]],
    ["chestseal", ["ApplyChestSeal"]],
    ["@iv", ["InsertIV_16_Upper", "InsertIV_16_Middle", "InsertIV_16_Lower"]],
    ["@io", ["InsertIO_FAST1", "InsertIO_EZ"]],
    ["@fluid", ["SalineIV", "SalineIV_500", "SalineIV_250", "PlasmaIV", "PlasmaIV_500", "PlasmaIV_250"]],
    ["tourniquet", ["ApplyTourniquet"]],
    ["splint", ["ApplySAMSplint"]],
    ["morphine", ["morphine"]],
    ["naloxone", ["naloxone"]],
    ["paracetamol", ["paracetamol"]],
    ["penthrox", ["penthrox"]]
];
uiNamespace setVariable [QGVAR(itemHash), compileFinal _itemHash];
