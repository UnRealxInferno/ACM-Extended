/*
 * Phase 20 subsystem initialization: IV/EJ procedure presentation, prep and catheter-flow tunables.
 *
 * This is a behavior-preserving extraction from ACME_fnc_postInit. Keep runtime
 * event/PFH ownership in postInit or the owning subsystem; this helper only establishes
 * startup state and tunables in the same order as before.
 */

// 18g catheter flow, as a fraction of the 16g base. a real 18g runs about half of a 16g, where 16g is about
// 200 ml/min and 18g about 100 ml/min on gravity. the getIVFlowRate override reads this for a type-5 line, the
// ACME 18g, placed through the establish iv mini-game.
// The fixed authored 15-degree catheter owns the resting orientation on both arms and legs.
// Rigid rotation adds at most 15 degrees, including hand motion, toward nominal 30 at the edge.
// EJ uses the same fixed 15-degree baseline and up to 15 degrees extra. Limb edges define the lateral reference.
ACME_iv_tiltRefU = 0.5;  // fallback limb midline, as a fraction of the body rect width.
ACME_iv_armEdgeStart       = 0.60; // B32: begin rigid outward rotation a little earlier.
ACME_iv_armEdgeFull        = 0.90; // reach nominal 30 before the measured edge.
ACME_iv_armEdgeExtraTiltDeg = 15;  // 15 base sprite + 15 runtime = 30 near the edge.
ACME_iv_legTiltStart       = 0.10; // no extra rotation in the centre; fixed 15-degree art then biases outward.
ACME_iv_legTiltFull        = 0.74; // B32: reach the same maximum slightly sooner.
ACME_iv_legTiltDeg         = 15;
ACME_iv_ejTiltDeg          = 15;
ACME_iv_needleMotionTiltDeg = 4;   // inertial hand-lean only. no size change.
ACME_iv_needleMotionTiltSpan = 0.020;

// the alcohol pad. it lags the hand and squashes under the press. both are position and size only.
ACME_iv_padLag        = 16;   // higher follows the hand more closely.
ACME_iv_padPressRate  = 12;   // how fast it squashes and springs back.
ACME_iv_padPressScale = 0.78; // the size it squashes to while the button is down. 1 is no squash.
// THE LEAN IS BACK ON at mavis's call. it is the same ctrlSetAngle that skewed the catheter, so it is a skew
// here too, but the swab is a small round sprite with no long axis for a skew to read against, and it looks
// like weight rather than like a fault. set it to 0 to keep the pad upright and keep the lag and the squash.
ACME_iv_padTiltDeg    = 22;
ACME_iv_padTiltSpan   = 0.030;

// Uniform prep coverage uses the CBA opacity/footprint settings. The painter's
// bounded grid avoids randomized dabs and overlapping pass-dependent dark spots.
ACME_iv_prepSpacing     = 0.011;  // body fractions of travel before the next dab lands.

// THE LIFE OF A MISS BRUISE. a puncture HOLE is permanent for the life of the body. a bruise resolves.
// it darkens over the configured fade-in, holds, then fades out across the last stretch and is gone at the life.
ACME_iv_bruiseLifeSec       = 1200;  // twenty minutes of mission time from the stick to fully gone.
ACME_iv_bruiseFadeOutSec    = 300;   // the last five minutes of that life are the fade.
ACME_iv_bruiseFadeInSec     = 5.0;   // the larger immediate IV-site haematoma develops over a few seconds instead of popping in.
ACME_iv_newBruiseFadeInSec  = 2.5;   // newer scattered contusions/track marks are smaller and surface faster.
ACME_iv_extravasationFadeInSec = 4.0; // first visible infiltration/extravasation is broader, so it develops a little more slowly.
// THE BRUISE. keep working one patch and the red stops being antiseptic and becomes a mark in the skin. the
// trigger is the MEAN passes per cell, so a long single-pass scrub over a wide area never bruises and a hard
// scrub over one small patch does. the SIZE comes from the wiped area, as the cell count times the cell area.
ACME_iv_prepBruiseMeanOn   = 4;    // mean passes per cell at which the bruise starts to show.
ACME_iv_prepBruiseMeanFull = 12;   // and at which it reaches its full strength.
ACME_iv_prepBruiseAlphaMax = 0.30; // full strength. it is a LIGHT bruise and not a haematoma.
ACME_iv_prepBruiseSpread   = 2.2;  // how far past the exact wiped edge the bruise spreads.
ACME_iv18gFlowFactor = 0.5;
ACME_iv20gFlowFactor = 0.35;  // the 20g, smaller again. it is the slowest line on the tray.
