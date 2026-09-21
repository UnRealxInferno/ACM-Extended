/* True only when the selected transfusion route points at a currently established IV/IO. */
params [['_patient',objNull,[objNull]], ['_bodyPart','',[""]], ['_iv',true,[true]], ['_site',-1,[0]]];
if (isNull _patient || {_bodyPart == ''}) exitWith {false};
_bodyPart = toLowerANSI _bodyPart;
if (_iv) exitWith {
    _site >= 0 && {[_patient,_bodyPart,0,_site] call ACM_circulation_fnc_hasIV}
};
[_patient,_bodyPart,0] call ACM_circulation_fnc_hasIO
