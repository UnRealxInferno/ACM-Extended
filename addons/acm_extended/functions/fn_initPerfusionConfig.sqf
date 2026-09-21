/*
 * Phase 22 subsystem initialization: PPV preload, iatrogenic NCD, oxygen delivery and permissive-hypotension tunables.
 *
 * Behavior-preserving extraction from ACME_fnc_postInit. Runtime event/PFH ownership
 * remains outside this helper and the call stays at the original initialization point.
 */

// ppv against preload, and iatrogenic NCD.
ACME_ppv_maxPreloadPenalty      = 0.35;  // the most stroke volume that positive pressure can cost, at an empty tank.
ACME_ppv_onsetEmptiness         = 0.12;  // a full casualty pays nothing; the penalty starts past this
ACME_ppv_peepMaxMult            = 1.5;  // PEEP 15 vs 5 makes it half again worse
ACME_ncd_iatrogenicTension      = true;  // may an unnecessary needle progress to tension
ACME_ncd_iatrogenicTensionChance = 0.35;  // per unnecessary needle, cumulative
ACME_ncd_iatrogenicTensionDelay = 90;  // seconds before it declares itself

// oxygen delivery, DO2.
// saturation is not delivery. SpO2 reports how much of the hemoglobin a casualty still has is loaded. DO2
// reports how much oxygen reaches tissue, and DO2 is what hemorrhage destroys. see fn_oxygendelivery.
ACME_do2_normalVolume    = 6;  // l of circulating volume taken as normal
ACME_do2_preloadExponent = 1.6;  // stroke volume falls faster than volume does, because frank-starling is steep here.
ACME_do2_preloadCeiling  = 1.1;  // overfilling buys almost nothing
ACME_do2_refHR           = 75;
ACME_do2_hrCompEfficiency = 0.4;  // tachycardia compensates only in part. it buys time and does not restore flow.
ACME_do2_hrCompCeiling   = 1.35;  // and it can never paper over a volume deficit entirely
ACME_do2_tachyKneeHR     = 150;  // past this, diastole is too short to fill and the output falls again.
ACME_do2_refSaO2         = 0.97;  // normalization, so a healthy casualty reads 1.0
ACME_do2_criticalFrac    = 0.5;  // below this, tissue goes anaerobic whatever the blood pressure says.
ACME_do2_clearFrac       = 0.58;  // and must climb back above this to clear. the hysteresis stops it chattering.
ACME_do2_reperfusionWindow = 45;  // s after delivery is restored during which nothing re-accrues, while the debt repays.
ACME_do2_consciousSpO2Floor = -1;  // -1 derives it from the wake floor minus the tolerance below, so the guard and
                                    // so the mercy backstop can never disagree about the same casualty. set a positive number to pin it
                                    // explicitly instead.
ACME_do2_wakeFloorTolerance = 3;  // points below ACME_ko_wakeFloorSpO2 at which the guard still protects.
ACME_do2_crystalloidHalfLife = 1200;  // s for the dilutional effect of crystalloid to halve, as it redistributes out of the
                                    // vascular space. ACM never removes saline except by bleeding, so without this the dilution is permanent. it
                                    // does not touch Saline_Volume itself.
ACME_tbi_do2ClearFrac    = 0.78;
ACME_tbi_do2ReperfusionWindow = 45;
ACME_do2_lethalFrac      = 0.2;
ACME_do2_acidosisPerSec  = 0.0009;
ACME_tbi_do2Threshold    = 0.7;  // an injured brain needs more delivery than surviving tissue does.
ACME_tbi_do2Critical     = 0.35;

// permissive hypotension.
// bleeding scales with the pressure that drives it, in fn_permhypobleedmult, so a medic who resuscitates an
// uncontrolled bleed to a normal pressure now pays in blood. the multiplier is MAP over refmap, so at the
// reference it is exactly 1.0 and the previous balance is unchanged. only running high or low moves
// anything.
ACME_permHypo_refMAP     = 70;  // the MAP at which bleeding is unchanged from before this system existed.
ACME_permHypo_multMin    = 0.55;  // floor: even a nearly pulseless casualty still oozes
ACME_permHypo_multMax    = 2.0;  // ceiling: the linear model stops being honest past this
ACME_clotPop_mapCeiling  = 100;  // MAP at which the clot-pop pressure factor is fully engaged
ACME_clotPop_mapMaxFactor = 1.8;  // and how much it multiplies the pop chance by there
// B119 uses structural-grade MAP floors from fn_initTbiProgressionConfig. Keep the historical universal
// MAP-85 value defined for mission/config compatibility, but it is no longer used as the active injury gate.
ACME_tbi_hypotensionMAPFloor   = 85;
ACME_tbi_hypotensionSevereMAP  = 60;
ACME_tbi_severityPerSecHypotension = 0.012;
