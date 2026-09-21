/* Centralized local perception model. Debug variables and rendering stay client-local. */
ACME_visualFx_enabled = true;
ACME_visualFx_updateSec = 0.05;  // 20 Hz so HR-synchronous tunnel pulses remain legible even during tachycardia
ACME_visualFx_commitSec = 0.30;
ACME_visualFx_hypoxiaStart = 95;
ACME_visualFx_hypoxiaSevere = 72;
ACME_visualFx_mapStart = 70;
ACME_visualFx_mapSevere = 35;
ACME_visualFx_co2Start = 48;
ACME_visualFx_co2Severe = 85;
// Ketamine visual thresholds are fractions of ACME's induction-equivalent ketamine load, NOT raw ACM medication
// count.  The real-dose curve is intentionally bottom-heavy: a ~0.25 mg/kg analgesic dose should be barely visible,
// a moderate exposure rises only to the previous low-dose look, and the high/induction endpoint remains unchanged.
ACME_visualFx_ketamineStart = 0.08;
ACME_visualFx_ketamineFull = 0.82;
ACME_visualFx_ketamineDoseLowPoint = 0.16;
ACME_visualFx_ketamineDoseModeratePoint = 0.45;
ACME_visualFx_ketamineLowGeneralOut = 0.010;
ACME_visualFx_ketamineModerateGeneralOut = 0.060;
// The water cue begins slightly earlier than chromatic/blur. Low analgesic exposure stays subtle, but the
// low/mid curve is raised enough that the slow swimming motion remains perceptible before high dissociative doses.
ACME_visualFx_ketamineWetStart = 0.05;
ACME_visualFx_ketamineWetFull = 0.82;
ACME_visualFx_ketamineLowWetOut = 0.065;
ACME_visualFx_ketamineModerateWetOut = 0.215;
// Analgesic/sub-dissociative perception is intentionally transient. New ketamine medication events refresh the
// five-minute window. Mild blur now falls close to clear vision between slow crests instead of sitting at a constant floor.
ACME_visualFx_ketamineAnalgesicMax = 0.22;
ACME_visualFx_ketamineAnalgesicWindowSec = 300;
ACME_visualFx_ketamineAnalgesicWaveSec = 34;
ACME_visualFx_ketamineWetRiseSec = 7.0;   // slower onset so low-dose waves develop instead of appearing abruptly
ACME_visualFx_ketamineWetFallSec = 6.0;   // gentle recovery/washout
ACME_visualFx_ketamineGeneralRiseSec = 8.5; // chromatic/blur lag behind drug arrival instead of snapping on
ACME_visualFx_ketamineGeneralFallSec = 7.0;
ACME_visualFx_tunnelStart = 0.50; // same severe-range onset used by the ACM-style radial tunnel profile

// Ketamine perceptual layering is intentionally dose-banded in fn_visualFxTick: sub-dissociative exposure favors
// mild blur/diplopia + subtle vividness and motion-lag; stronger depth/zoom and chromatic separation arrive later.
// ACME reproduces the magnitude of ACM's former ketamine chromatic pulse inside ONE PP handle. 0.86 comes close
// to the old stacked ACM+ACME look without actually running two competing ChromAberration effects.
ACME_visualFx_ketamineLegacyChromEquivalentScale = 1.00;

