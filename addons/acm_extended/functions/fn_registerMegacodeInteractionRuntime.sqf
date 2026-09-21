/* Register the Megacode laptop interaction on clients/JIP. */
if (!hasInterface) exitWith {};
if (isNil "ace_interact_menu_fnc_createAction") exitWith {};
private _act=[
    "ACME_MegacodeControl","Megacode Control Panel","\a3\ui_f\data\IGUI\Cfg\Actions\heal_ca.paa",
    {private _d=_target getVariable ["ACME_megacodeDummy",objNull]; [_d,_player] call ACME_fnc_megacodeOpenPanel;},
    {private _d=_target getVariable ["ACME_megacodeDummy",objNull]; (_target getVariable ["ACME_isMegacodeLaptop",false]) && {!isNull _d} && {_d getVariable ["ACME_isMegacode",false]}}
] call ace_interact_menu_fnc_createAction;
["Land_Laptop_03_olive_F",0,["ACE_MainActions"],_act] call ace_interact_menu_fnc_addActionToClass;

private _actCable=[
    "ACME_MegacodeTuneCable","Tune Cable","\a3\ui_f\data\IGUI\Cfg\Actions\heal_ca.paa",
    {[_target] call ACME_fnc_megacodeCableTunerOpen},
    {(missionNamespace getVariable ["ACME_debug_enabled",false]) && {_target getVariable ["ACME_isMegacodeLaptop",false]}}
] call ace_interact_menu_fnc_createAction;
["Land_Laptop_03_olive_F",0,["ACE_MainActions"],_actCable] call ace_interact_menu_fnc_addActionToClass;
