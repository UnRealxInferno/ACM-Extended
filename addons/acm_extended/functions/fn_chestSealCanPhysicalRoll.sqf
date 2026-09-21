/* Whether another provider may physically roll/hold this casualty for the chest-seal workspace.
 *
 * A manual prone stance is NEVER permission to seize a conscious player's animation.
 * ACME_CS_ProcedureGrounded is presentation bookkeeping, not clinical authority.
 * Obtundation is an awake state and is not permission either.
 *
 * Physical provider-driven rolling is limited to:
 *   - a genuinely unconscious casualty; or
 *   - a casualty that has just regained consciousness but is still in ACM's logical Lying State
 *     and is still visually in one of the authored lying/unconscious rest states.
 *
 * Everyone else may still use the Flip button as a virtual front/back VIEW switch, but the
 * casualty's actual animation is left completely alone.
 */
params [["_patient", objNull, [objNull]]];
if (isNull _patient || {!alive _patient} || {!isNull objectParent _patient}) exitWith {false};

private _unconscious =
    (_patient getVariable ["ACE_isUnconscious", false])
    || {_patient getVariable ["ace_medical_unconscious", false]};
if (_unconscious) exitWith {true};

private _lyingRaw = _patient getVariable ["ACM_core_Lying_State", false];
private _lying = if (_lyingRaw isEqualType true) then {_lyingRaw} else {_lyingRaw > 0};
if (!_lying) exitWith {false};

// A stale logical flag must not let another provider grab control of a player who has already
// transitioned back into ordinary locomotion. Require a known lying/rest animation too.
private _anim = toLowerANSI animationState _patient;
private _faceUp = toLowerANSI (missionNamespace getVariable ["ACME_uncon_faceUp", "ACM_LyingState"]);
private _faceDown = toLowerANSI (missionNamespace getVariable ["ACME_uncon_faceDown", "ace_medical_engine_uncon_anim_1"]);

if (_anim in ["acm_lyingstate", _faceUp, _faceDown]) exitWith {true};

private _animMap = missionNamespace getVariable ["ace_medical_engine_animations", createHashMap];
private _up = (_animMap getOrDefault ["ace_medical_engine_uncon_anim_faceup", []]) apply {toLowerANSI _x};
private _down = (_animMap getOrDefault ["ace_medical_engine_uncon_anim_facedown", []]) apply {toLowerANSI _x};

(_anim in _up) || {_anim in _down}
