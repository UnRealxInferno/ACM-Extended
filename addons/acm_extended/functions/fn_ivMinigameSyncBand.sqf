/* Read-only live band refresh. Do not restore the whole partial catheter state here.
   The owner publishes one atomic band snapshot per physical operation, not per frame. */
params [["_force", false, [true]]];
disableSerialization;
private _display = uiNamespace getVariable ["ACME_IV_DLG", displayNull];
if (isNull _display || {!( [] call ACME_fnc_ivUiValid)} || {uiNamespace getVariable ["ACME_IV_EJMode", false]}) exitWith {};
private _patient = uiNamespace getVariable ["ACME_IV_Patient", objNull];
private _bp = toLower (uiNamespace getVariable ["ACME_IV_BodyPart", ""]);
private _index = ["head", "body", "leftarm", "rightarm", "leftleg", "rightleg"] find _bp;
if !(_index in [2,3,4,5]) exitWith {};
private _view = uiNamespace getVariable ["ACME_IV_View", ""];
private _state = _patient getVariable [format ["ACME_IV_BandState_%1", _index], []];
// Compatibility with a previously saved partial view. Reading it never reapplies a band.
if (count _state != 4) then {
    private _key = format ["%1|%2", _bp, _view];
    private _rows = _patient getVariable ["ACME_IV_SiteState", []];
    private _row = _rows findIf {(_x param [0, ""]) == _key};
    private _band = if (_row < 0) then {[false, "middle", [], [], "", ""]} else {+((_rows select _row) select 1)};
    private _on = _patient getVariable [format ["ACME_IV_BandOnPart_%1", _index], _band param [0, false]];
    _state = [0, _on, _view, _band];
};
_state params ["_revision", "_on", "_bandView", "_band"];
private _pending = _display getVariable ["ACME_IV_BandPending", []];
private _waiting = count _pending >= 2 && {_revision <= (_pending select 0)} && {diag_tickTime < (_pending select 1)};
if (_waiting && {count _pending == 2} && {!_force}) exitWith {};
if (_waiting && {count _pending == 6} && {(_pending select 2) == _index}) then {
    _on = _pending select 3;
    _bandView = _pending select 4;
    _band = +(_pending select 5);
    _state = [_revision, _on, _bandView, _band];
} else {
    if (count _pending > 0) then {
        _display setVariable ["ACME_IV_BandPending", []];
        _force = true;
    };
};
private _stamp = [_bp, _view, _state];
if (!_force && {_stamp isEqualTo (_display getVariable ["ACME_IV_BandSeen", []])}) exitWith {};
_display setVariable ["ACME_IV_BandSeen", _stamp];
private _visible = _on && {_bandView == _view} && {count _band == 6};
uiNamespace setVariable ["ACME_IV_BandOn", _visible];
private _ctrl = _display displayCtrl 86502;
if (_visible) then {
    _band params ["", "_site", "_bandUV", "_veinUV", "_label", "_texture"];
    uiNamespace setVariable ["ACME_IV_Site", _site];
    uiNamespace setVariable ["ACME_IV_BandUV", _bandUV];
    uiNamespace setVariable ["ACME_IV_VeinUV", _veinUV];
    uiNamespace setVariable ["ACME_IV_Label", _label];
    uiNamespace setVariable ["ACME_IV_BandTex", _texture];
    (_display displayCtrl 86504) ctrlSetText _label;
    if (count _veinUV == 2) then {
        uiNamespace setVariable ["ACME_IV_VeinSet", [_patient, _bp, _site, _veinUV select 0, _veinUV select 1] call ACME_fnc_ivVeinSet];
    };
    ([_patient, _bp, uiNamespace getVariable ["ACME_IV_Gauge", 16], _site] call ACME_fnc_ivSiteDifficulty) params ["_pat", "_feel", "_hit", "_hot"];
    uiNamespace setVariable ["ACME_IV_Patency", _pat];
    uiNamespace setVariable ["ACME_IV_FeelRadius", _feel];
    uiNamespace setVariable ["ACME_IV_HitRadius", _hit];
    uiNamespace setVariable ["ACME_IV_MaxHot", _hot];
    _ctrl ctrlSetText _texture;
    _ctrl ctrlSetPosition (uiNamespace getVariable ["ACME_IV_BodyRect", [0,0,1,1]]);
    _ctrl ctrlCommit 0;
} else {
    // No BOA is a valid IV state. Do not clear the provider's held mouse input here: that old band-gate behavior
    // made unbanded palpation impossible and could interrupt an unbanded catheter push. The main tick owns the
    // palpation dot and decides whether the cursor is over patient artwork.
};
_ctrl ctrlShow _visible;
// Never cancel another provider's own partially inserted catheter or held needle.
if ((uiNamespace getVariable ["ACME_IV_InsStage", ""]) == "") then {
    uiNamespace setVariable ["ACME_IV_Stage", "ready"];  // band presence changes difficulty, not permission.
};
[] call ACME_fnc_ivMinigameRefreshBandSlot;
