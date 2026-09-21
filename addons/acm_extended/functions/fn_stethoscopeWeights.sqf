// Chest-space coordinates use Stethoscope_Dialog.hpp's GUI grid, independent of aspect ratio.
// Return [right lung, left lung, heart]. No positive floor outside the listening area.
params ["_chestX","_chestY",["_view","front"]];
// Channel identities are anatomical: the patient's right lung is on screen-right in the back view.
private _posterior = _view == "back";
if (_posterior) then {_chestX = 40 - _chestX;};
private _smooth = {
    params ["_a","_b","_value"];
    private _t = linearConversion [_a,_b,_value,0,1,true];
    _t * _t * (3 - 2 * _t)
};
private _upper = [-6,-3.5,_chestY] call _smooth;
private _diaphragm = 1 - ([11.2,13.2,_chestY] call _smooth);
private _outer = ([8,10,_chestX] call _smooth) * (1 - ([30,32,_chestX] call _smooth));
private _leftMix = [18,22,_chestX] call _smooth;
private _sternum = (1 - ([0.8,2.5,abs (_chestX - 20)] call _smooth))
    * ([-2,0,_chestY] call _smooth) * (1 - ([6,8,_chestY] call _smooth));
private _heartFocus = 0;
{
    _x params ["_hx","_hy"];
    private _distance = sqrt ((_chestX - _hx)^2 + ((_chestY - _hy)^2));
    _heartFocus = _heartFocus max (1 - ([0.7,3.0,_distance] call _smooth));
} forEach [[17.6,1.3],[22.5,1.3],[22.7,3.4],[22.9,5.6]];
if (_posterior) then {_heartFocus = 0;};
private _points = if (_posterior) then {
    [[[15,-2.5],[15,1.5],[13.5,6.3],[12.5,11.0]], [[25,-2.5],[25,1.5],[26.5,6.3],[27.5,11.0]]]
} else {
    [[[15.8,-3.7],[15.5,1.3],[13,6.3],[12.1,11.3]], [[24.5,-3.7],[24.5,1.3],[27.7,6.3],[28.9,11.3]]]
};
private _lungGains = [];
{
    private _pointGain = 0;
    {
        _x params ["_lx","_ly"];
        private _distance = sqrt ((_chestX - _lx)^2 + ((_chestY - _ly)^2));
        _pointGain = _pointGain max (1 - ([0.5,4.0,_distance] call _smooth));
    } forEach _x;
    _lungGains pushBack ((0.20 + 0.75 * _pointGain) * _upper * _diaphragm * _outer
        * (1 - 0.80 * _sternum) * (1 - 0.65 * _heartFocus));
} forEach _points;
private _right = (_lungGains select 0) * (1 - _leftMix);
private _left = (_lungGains select 1) * _leftMix;
private _heartDistance = sqrt ((_chestX - 20.5)^2 + (_chestY - 1.5)^2);
private _heart = ((0.5 * (1 - ([1.5,14,_heartDistance] call _smooth))) max (0.95 * _heartFocus))
    * _upper * _outer * (1 - 0.80 * _sternum);
// Below the diaphragm only a narrow centerline window conducts cardiac sound.
// Fade into that window above the boundary so lateral movement never produces a hard edge.
private _centerline = 1 - ([0.15,2.0,abs (_chestX - 20)] call _smooth);
private _lowerHeart = 0.18 * _centerline * (1 - ([13.2,21,_chestY] call _smooth));
private _lowerBlend = [9.5,13.2,_chestY] call _smooth;
_heart = _heart * (1 - _lowerBlend) + _lowerHeart * _lowerBlend;
[_right,_left,if (_posterior) then {0} else {_heart}]
