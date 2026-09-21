/*
 * ACM Extended B105 volume semantics.
 *
 * Keep ACM's two volume concepts separate.
 *
 * Total circulating / ACE blood volume is the intravascular sum of the blood,
 * plasma and crystalloid compartments. A fluid bolus contributes to this as
 * soon as the IV/IO pipeline admits it.
 *
 * Effective blood volume remains ACM's native model from script_macros.hpp.
 * Do not override GET_EFF_BLOOD_VOLUME here. In ACM 1.4.5, actual blood counts
 * fully and plasma contributes 30 percent while it remains in the plasma
 * compartment. Plasma and crystalloid then gain additional effective-volume
 * contribution as ACM converts their compartments into Blood_Volume over time.
 * The stock conversion rates are intentionally preserved: plasma converts at
 * 0.003 L/s and saline-class crystalloid at 0.0007 L/s, subject to ACM's native
 * fresh-blood modifier. Fluid overload remains subtracted from effective volume.
 *
 * ACME maps balanced crystalloid, saline medication carriers, HTS, mannitol,
 * magnesium and esmolol carrier volume into ACM's saline-class compartment, so
 * every admitted fluid participates in the same native conversion model. The
 * ACE-facing circulating-volume response remains immediate and separate.
 */
#ifndef ACM_EXTENDED_VOLUME_SEMANTICS_B105
#define ACM_EXTENDED_VOLUME_SEMANTICS_B105

#define ACME_TOTAL_CIRC_VOLUME(unit) (((DEFAULT_BLOOD_VOLUME min ((unit getVariable [QEGVAR(circulation,Blood_Volume), DEFAULT_BLOOD_VOLUME]) + (unit getVariable [QEGVAR(circulation,Plasma_Volume), 0]) + (unit getVariable [QEGVAR(circulation,Saline_Volume), 0]))) max 0))

#endif
