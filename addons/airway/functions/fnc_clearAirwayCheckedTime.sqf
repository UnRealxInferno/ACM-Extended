#include "..\script_component.hpp"
/* Author: ACM Extended Fork. Airway-owned invalidation of the cached airway-assessment timestamp. */
params [["_patient", objNull, [objNull]], ["_public", true, [true]]];
if (isNull _patient) exitWith {false};
_patient setVariable [QGVAR(AirwayChecked_Time), nil, _public];
_patient setVariable ["ACME_airwayCheckedServer", nil, _public];
true
