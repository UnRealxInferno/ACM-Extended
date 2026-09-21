// atrial-rhythm pain and obtundation episodes.
// these rhythms cause pain while the patient is awake, and it decays to none while they are unconscious. they
// can also drop the patient into a syncope-like obtundation episode. Rhythm-generated discomfort does not
// feed back into its own HR target; independent native pain and other physiological adjustments still do.
ACME_rhythm_painRVR            = 0.50;  // AFib-RVR: moderate pain while conscious
ACME_rhythm_painAtrialTach     = 0.35;  // atrial tach: mild-moderate
ACME_rhythm_painAFib           = 0.35;  // controlled AFib: mild-moderate
ACME_rhythm_painSVT            = 0.45;  // SVT: moderate (palpitations)
ACME_rhythm_painStepPerSec     = 0.12;  // pain ramp/decay rate (per second)
ACME_rhythm_obtundChancePerTick = 0.015;  // per 0.5 s tick chance to enter an obtundation episode
ACME_rhythm_obtundMinSec       = 12;  // episode duration floor
ACME_rhythm_obtundMaxSec       = 30;  // episode duration ceiling
// per-rhythm hemodynamic instability, as a MAP drop in mmhg, where a negative value is hypotension. it cascades
// into NIBP, capillary refill, the obtunded band and CPP through the getbloodpressure offset.
ACME_rhythm_bpDropRVR          = -28;  // AFib-RVR: hemodynamically unstable, poorly perfusing
ACME_rhythm_bpDropAtrialTach   = -12;  // atrial tach: mildly unstable
ACME_rhythm_bpDropTorsades     = -30;  // torsades: near-arrest perfusion
ACME_rhythm_bpDropAFib         = 0;  // controlled AFib: rate-controlled, perfuses fine
ACME_rhythm_bpDropSVT          = -18;  // SVT: symptomatic / cardiovertible

// Custom rhythms that are perfusing for their full lifetime. Torsades (102) is transitional: it perfuses only
// while its entry morphology converts, then deliberately enters native PVT arrest while retaining the 102 waveform.
ACME_rhythm_perfusingCustom = [100, 101, 103, 104];

// Custom rhythms no longer masquerade as a native arrest rhythm while they still perfuse. Native ACM takes over
// only after a real critical/arrest transition, at which point the custom overlay is released.
ACME_rhythm_acmProxy = [];

// Electrical monitor-rate contract. PEA is an unstable organized electrical rhythm from 60-100 BPM. One seed and
// one start timestamp are networked on entry; every machine derives the same low-frequency variation from mission
// time, so PEA moves continuously without broadcasting a new HR every second. Legacy brady/normal keys remain for
// old entry code, but brady selection is disabled and the seed itself is always inside the 60-100 range.
ACME_peaBradyChance        = 0;
ACME_peaNormalMinHR        = 60;
ACME_peaNormalModeHR       = 80;
ACME_peaNormalMaxHR        = 100;
ACME_peaBradyMinHR         = 60;
ACME_peaBradyModeHR        = 72;
ACME_peaBradyMaxHR         = 86;
ACME_peaVariationHz        = 4;
ACME_rhythm_vfElectricalHR  = 170;
ACME_rhythm_pvtElectricalHR = 220;
