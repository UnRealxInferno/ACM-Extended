// junctional wounds: the auto-spawn and the bleed and pain tuning.
// the chance is high off a medium or large velocity wound, and low off a large avulsion on the chest, arms or
// legs.
ACME_junctionalChanceVelocity = 0.60;  // medium-large VelocityWound -> junctional (high)
ACME_junctionalChanceAvulsion = 0.15;  // large avulsion -> junctional (low)
ACME_junctionalBleedBaseNorm  = 0.10;  // canonical normal baseline; native wounds still bleed separately.
ACME_junctionalBleedHardcoreNorm = 0.15; // hardcore baseline before the user bleed-rate multiplier.
ACME_junctionalBleedNorm      = ACME_junctionalBleedBaseNorm;
ACME_junctionalDPControl      = 0.10;  // B102: direct pressure controls about 90 percent of the extra junctional channel in normal mode.
ACME_junctionalPackControl    = 0.50;  // legacy fallback for Combat Gauze packing. B108 uses treatment progress to ramp from 1.00 (open) toward the completed packed multiplier below instead of applying instant full tamponade.
ACME_junctionalGauzeControl   = 0.50;  // finished combat-gauze packing, not yet wrapped. the bleed multiplier is 0.50, which is 50 percent control. it holds at this level until a pressure bandage wraps it, with no work-loose falloff.
ACME_junctionalGauzeDPControl = 0.00;  // combat gauze plus direct pressure held on top. 0.00 adds the other 50 percent of control, so the bleed stops fully while held. a lift of the dp returns it to the 50 percent gauze level.
ACME_junctionalPackedOoze     = 0.10;  // legacy, retained for back-compat. ACME_junctionalGauzeControl supersedes it for the packed state.
ACME_junctionalPackFalloff    = 75;  // legacy work-loose timer. it no longer applies to packed gauze, because the gauze holds at 50 percent until a wrap.
ACME_junctionalPackPain       = 0.10;  // packing remains painful without adding a second large consciousness penalty.
ACME_junctionalWrapPain       = 0.10;  // wrap pain is modest; hemorrhage physiology, not the button press, should drive LOC.

// XStat rebleed. see fn_junctionalstartbleed.
ACME_xstatRampTime       = 12;  // seating: bleed ramps full -> 0 over this many seconds
ACME_xstatDwellTime      = 7200;  // the bolus holds for this long (2 h) before it starts to fail
ACME_xstatRebleedTime    = 120;  // once it fails, the rebleed grows from a trickle to full across 2 min.
ACME_xstatRebleedMaxFrac = 0.5;  // ...and full = at most half the original bleed. never more.

// Large junctional wound/device body-map art develops more slowly than the smaller IV/contusion overlays.
ACME_junctionalImageFadeInSec = 4.5;
