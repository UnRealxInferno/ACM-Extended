#include "\x\ACM\addons\circulation\script_component.hpp"
// Build the current site-specific infiltration/extravasation visual state for one IV limb.
// Output is [[siteIndex,severity], ...], aggregated to the worst active finding at each site.
// Severity is 1..10. It combines medication extravasation, native ACM IV leakage and live carrier-fluid
// infiltration from a compromised line. All presentation ages use shared serverTime so every observer agrees.
params [
    ["_patient", objNull, [objNull]],
    ["_bodyPart", "", [""]]
];
if (isNull _patient || {_bodyPart == ""}) exitWith {[]};
private _bp = toLowerANSI _bodyPart;
if !(_bp in ["leftarm", "rightarm", "leftleg", "rightleg"]) exitWith {[]};
private _bySite = createHashMap;

// Medication extravasation / tissue injury.
private _records = _patient getVariable ["ACME_vesicant_records", []];
{
    _x params [["_key", ""], ["_recBP", ""]];
    if (toLowerANSI _recBP == _bp && {_key != ""}) then {
        private _cur = _patient getVariable [_key, []];
        if !(_cur isEqualTo []) then {
            private _stage = _cur param [2, -1];
            if (_stage >= 0) then {
                private _site = -1;
                { if ((_key find format ["_site%1", _x]) >= 0) exitWith {_site = _x;}; } forEach [0, 1, 2];
                if (_site < 0) then {_site = 1;};
                private _severity = 1;
                if ((count _cur) > 10) then {
                    private _pos = _cur param [10, _stage];
                    if !(_pos isEqualType 0 && {finite _pos}) then {_pos = _stage;};
                    _severity = round (linearConversion [-0.35, 3, _pos, 1, 10, true]);
                } else {
                    private _total = _cur param [0, 0];
                    private _threshold = _cur param [6, 1];
                    if !(_threshold isEqualType 0 && {finite _threshold} && {_threshold > 0}) then {_threshold = 1;};
                    private _ratio = _total / _threshold;
                    _severity = ceil (linearConversion [1, 2, _ratio, 1, 10, true]);
                    private _stageFloor = [1, 4, 7, 9] param [_stage, 1];
                    _severity = _severity max _stageFloor;
                };
                _severity = (_severity max 1) min 10;
                _bySite set [_site, _severity max (_bySite getOrDefault [_site, 0])];
            };
        };
    };
} forEach _records;

// Native ACM IV leakage is already networked by ACM. A flow state of 2 is actual leakage rather than only
// pain/slow flow, so make it visible even before any medication exposure record exists.
private _partIndex = ALL_BODY_PARTS find _bp;
if (_partIndex >= 0 && {missionNamespace getVariable ["ACM_circulation_IVComplications", false]}) then {
    {
        private _nativeFlow = (GET_IV_COMPLICATIONS_FLOW_X(_patient,_partIndex,_x)) max 0 min 2;
        if (_nativeFlow >= 2) then {
            _bySite set [_x, 2 max (_bySite getOrDefault [_x, 0])];
        };
    } forEach [0, 1, 2];
};

// Live infiltrated carrier volume. The patient owner records only a compact visual severity/last-flow timestamp
// while fluid is actually lost at an IV site. Repeated publication is rate-limited at the writers; this reader
// simply turns that shared state into a bruise that develops for every medic currently looking at the limb.
private _life = missionNamespace getVariable ["ACME_iv_bruiseLifeSec", 1200];
private _fadeOut = missionNamespace getVariable ["ACME_iv_bruiseFadeOutSec", 300];
if !(_life isEqualType 0 && {finite _life} && {_life > 1}) then {_life = 1200;};
if !(_fadeOut isEqualType 0 && {finite _fadeOut} && {_fadeOut >= 0}) then {_fadeOut = 300;};
_fadeOut = _fadeOut min (_life - 1);
{
    private _row = _patient getVariable [format ["ACME_ivInfiltrationVisual_%1_%2", _bp, _x], []];
    if (_row isEqualType [] && {count _row >= 2}) then {
        private _sev = _row param [0, 0];
        private _at = _row param [1, -1];
        if (_sev isEqualType 0 && {finite _sev} && {_sev > 0} && {_at isEqualType 0} && {finite _at} && {_at >= 0}) then {
            private _age = serverTime - _at;
            if (_age < 0) then {_age = 0;};
            if (_age < _life) then {
                if (_age > (_life - _fadeOut) && {_fadeOut > 0}) then {
                    _sev = ceil (_sev * (((_life - _age) / _fadeOut) max 0 min 1));
                };
                _sev = (_sev max 1) min 10;
                _bySite set [_x, _sev max (_bySite getOrDefault [_x, 0])];
            };
        };
    };
} forEach [0, 1, 2];

private _out = [];
{ private _sev = _bySite getOrDefault [_x, 0]; if (_sev > 0) then {_out pushBack [_x, _sev];}; } forEach [0, 1, 2];
_out
