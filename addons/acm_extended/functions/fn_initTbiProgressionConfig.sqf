/*
 * Phase 21 subsystem initialization: TBI vital coupling, recovery, autoregulation, ventilation and herniation progression tunables.
 *
 * Behavior-preserving extraction from ACME_fnc_postInit. Values and ordering inside
 * this domain are intentionally unchanged.
 */

ACME_tbi_maxDeltaSeconds = 5;
ACME_tbi_defaultMAP = 70;
ACME_tbi_defaultBloodVolume = 6;
ACME_tbi_cushingHR = 45;  // todo[ref] bradycardia target during cushing
ACME_tbi_terminalHR = 35;  // todo[ref] hr target at terminal herniation
ACME_tbi_hrStepPerCall = 1.5;  // todo[ref] max hr nudge per tick

// TBI into vitals coupling: the cushing reflex, decompensation and terminal collapse.
// a raised-ICP brain drives the vitals. fn_tbiapplyvitals reads the ICP, the severity and the stage, then
// writes a coherent pattern the medic can see. while the brain compensates it shows hypertension with a
// widened pulse pressure and reflex bradycardia. as the compensation budget runs out and herniation advances
// it slides into pressure collapse, agonal bradycardia, apnea, and at terminal a cardiac arrest.
ACME_tbi_vitalsCushICP        = 25;  // the ICP at which the vital pattern starts to engage. it equals cushingicp.
ACME_tbi_cushSysPeak          = 205;  // systolic (mmhg) at full cushing surge. malignant htn
ACME_tbi_cushSysBase          = 150;  // systolic at the threshold of the surge
ACME_tbi_cushDiaPeak          = 108;  // diastolic at full surge. it rises far less than systolic, which gives a wide pulse pressure.
ACME_tbi_cushDiaBase          = 92;  // diastolic at threshold
ACME_tbi_collapseSys          = 70;  // systolic at terminal pressure collapse
ACME_tbi_collapseDia          = 44;  // diastolic at terminal collapse (MAP ~53, then arrest)
ACME_tbi_terminalArrestHR     = 26;  // hr target at terminal herniation. it sits below ACM's 40 bpm arrest line on purpose.
ACME_tbi_cushRR               = 11;  // respiratory rate center during cushing. the irregular pattern oscillates around this.
ACME_tbi_terminalRR           = 3;  // respiratory rate at terminal apnea. it drives SpO2 down through ACM's own oxygen sim.
ACME_tbi_bpStepPerSec         = 22;  // max mmhg/s the bp offset eases toward the target, so bp moves visibly rather than instantly.
ACME_tbi_hrWaveAmp            = 7;  // hr oscillation amplitude (bpm). dysautonomic instability
ACME_tbi_bpWaveAmp            = 20;  // systolic oscillation amplitude in mmhg. these are the lundberg plateau-wave swings.
ACME_tbi_rrWaveAmp            = 6;  // rr oscillation amplitude (cheyne-stokes/ataxic irregularity)
ACME_tbi_cheyneStokes         = true;  // wild irregular central or ataxic breathing once the patient is critical.

// vitals rate governor. delta-time smoothing holds any vital from changing fast, even while ACM fights the
// TBI during ICP.
ACME_hrDriveStepPerSec        = 14;  // max bpm/s for custom-rhythm induction only. it stays brisk so a rhythm change reads in quickly.
ACME_hrSmoothStepPerSec       = 6;  // max bpm/s for the TBI, shock and hypothermia hr drive, and for the TBI fallback nudge. this is the gentle cap.
                                       // that holds the ICP heart rate from swinging fast. it stays separate from the rhythm, so it slows ICP and
                                       // shock only.
ACME_rrDriveStepPerSec        = 4;  // max breaths/min per second the rr sole-writer eases the live rate toward. the target is jagged on purpose.
                                       // ataxic and cheyne-stokes TBI drive. this was 8 and is now halved, so the pattern stays irregular and never
                                       // thrashes.
ACME_vitalSmooth_bpMaxPerSec  = 5;  // hard cap in mmhg/s on how fast the returned blood pressure can move. the getbloodpressure path enforces it.
                                       // wrapper, from the real elapsed time between reads. this is the bp, MAP and CPP smoother that always runs.
                                       // 0 disables it.

// cheyne-stokes respirations. this is standalone, independent of the TBI, and the debug toggle can drive it.
ACME_sys_cheyneStokes = true;  // master enable for the cheyne-stokes driver
ACME_cs_activePatients = [];  // patients currently breathing a cheyne-stokes pattern
ACME_cs_breatheDur = 34;  // seconds of the wax+wane hyperpnea hump
ACME_cs_apneaDur   = 16;  // seconds of the apneic pause
ACME_cs_peakRR     = 30;  // breaths/min at the crest of the hump
ACME_cs_troughRR   = 4;  // breaths/min at the start/end of the hump (not zero)
ACME_cs_apneaRR    = 0;  // breaths/min during the apneic pause
ACME_cs_targetFloor = 6;  // floor for the desired rr target during apnea. ACM divides by it, so it must never be 0.
ACME_tbi_cheyneCompFrac       = 0.9;  // critical threshold to start it, as a fraction of the compensation budget. herniation also triggers it.
ACME_tbi_waveSpeed            = 0.16;  // base oscillation rate (rad/s). slow waves
ACME_tbi_waveDecompAccel      = 0.25;  // how much the oscillation speeds up as the patient decompensates. 0 holds the base ACM cadence at all times and 1 gives the old 2x at terminal.
ACME_hrWrapFreshSecs          = 1.5;  // if the hr sole-writer wrapper eased a unit within this many seconds, the TBI tick skips its own direct hr nudge. that stops the two easers from stacking.
ACME_tbi_terminalArrestSecs   = 20;  // seconds at stage 3 before a forced cardiac arrest. this is the actual damage.
ACME_tbi_nonterminalMinHR    = 42;  // B67: stages 0-2 may cause bradycardia but cannot be the sole ACM fatal-HR trigger.
ACME_tbi_nonterminalMinMAP   = 60;  // B67: stages 0-2 may lower pressure but cannot by themselves cross ACM's MAP<55 arrest line.
ACME_tbi_nonterminalMinRR    = 12;  // B67: stages 0-2 may breathe irregularly/bradypneically, but TBI alone cannot sustain severe hypoventilation that becomes a ROSC/re-arrest driver.
ACME_tbi_cppReperfusionWindow = 45; // seconds after ROSC before low-CPP TBI acid accrual may resume.
ACME_tbi_irreversibleSeverity = 0.85;  // once stage 2, actual herniation, is reached, severity can no longer recover below this. the damage is real and irreversible.

// severity recovery. a treated brain heals.
// severity used to be a pure ratchet that only climbed, so ICP always rebounded to icpmax times severity
// whatever the treatment. osmotherapy pushed the number down and the ceiling dragged it back. now, once the
// insult is genuinely relieved and all the physiology gates are met, severity heals slowly toward a floor set
// by the real damage done. a viable casualty caught before herniation can recover to baseline and go back in
// the fight. one that reached impending herniation carries a permanent light floor. one that herniated, at
// stage 2, keeps the irreversible floor above.
ACME_tbi_recoverPerSec        = 0.0025;  // severity healed per second while the insult is relieved. 0.5 severity to a 0 floor takes about 200 s, near 3.3 min, which matches the 3 to 5 min target window.
ACME_tbi_recoverCPPmin        = 70;  // the CPP the medic is aiming for. it is published to the panel and the aar and no longer gates the heal.
// THE MAP THE MEDIC MUST REACH FOR A TBI TO HEAL. it is a MAP and not a CPP because MAP is the number a medic can
// see, target and treat. a CPP gate of 70 against a live ICP demanded a MAP of 70 plus the ICP, so a casualty
// carrying an ICP of 15 needed a MAP of 85 and nothing on the panel said so.
// it is also the dead band. one predicate, MAP at or above this AND ICP at or below recoverICPmax, drives the
// severity insult, the compensation budget and the recovery, so a casualty held in the band holds instead of
// being damaged and healed by two gates that disagree.
ACME_tbi_recoverMAPmin        = 65;  // mmhg.
ACME_tbi_recoverSpO2min       = 90;  // SpO2 at/above this is a recovery gate
ACME_tbi_recoverICPmax        = 25;  // an ICP at or below this, the cushing threshold, is a recovery gate. the brain is no longer under pressure.
ACME_tbi_recoverVentMinRatio  = 0.9;  // an alveolar-ventilation ratio at or above this, so no CO2 retention, is a recovery gate.

// B119: structural injury is a high-water mark, while severity is the current reversible acute burden.
// Mild and moderate injuries can therefore settle to an inactive acute state when oxygen delivery, ventilation,
// pressure and ICP are stable. Severe/critical structural injury keeps less cerebrovascular/autonomic reserve.
ACME_tbi_structuralMildMax       = 0.35;
ACME_tbi_structuralModerateMax   = 0.60;
ACME_tbi_structuralSevereMax     = 0.80;

// Severity-specific perfusion floors. The universal MAP 85 injury gate was internally contradictory: a patient
// could satisfy the shared recovery gate at MAP 65 while a second pathway simultaneously injured the brain.
// Mild/moderate TBI now tolerates the normal recovery band; severe/critical injury progressively needs more MAP.
ACME_tbi_hypotensionMAPMild      = 60;
ACME_tbi_hypotensionMAPModerate  = 65;
ACME_tbi_hypotensionMAPSevere    = 75;
ACME_tbi_hypotensionMAPCritical  = 85;
ACME_tbi_perfusionCPPSevereMin   = 55;  // severe structural TBI adds a real CPP floor without imposing it on concussion.
ACME_tbi_perfusionCPPCriticalMin = 60;  // critical structural TBI becomes increasingly pressure-passive/CPP dependent.

// Cerebral autoregulatory integrity, 0 to 1. Structural injury establishes the best recoverable baseline.
// Acute burden, exhausted compensation and herniation can push it lower. Lost autoregulation blunts protective
// low-CPP vasodilation and makes high CPP increasingly pressure-passive, while low-CPP secondary injury worsens.
ACME_tbi_autoregMild              = 1.00;
ACME_tbi_autoregModerate          = 0.95;
ACME_tbi_autoregSevere            = 0.70;
ACME_tbi_autoregCritical          = 0.35;
ACME_tbi_autoregFallPerSec        = 0.018;
ACME_tbi_autoregRecoverPerSec     = 0.0035;
ACME_tbi_autoregLowCPPMultMax     = 2.0;
ACME_tbi_pressurePassiveCPPstart  = 70;
ACME_tbi_pressurePassiveCPPfull   = 100;
ACME_tbi_pressurePassiveICPmax    = 8;

// Systemic autonomic integrity and vasomotor tone. Tone is a signed state: +1 is a strong sympathetic/Cushing
// clamp, 0 is neutral and -1 is profound vasomotor failure. Stable mild/moderate TBI contributes essentially no
// systemic tone. Rising ICP first drives positive tone; exhausted reserve/brainstem failure becomes labile and
// ultimately vasodilated. The junctional transient-spasm model reads integrity but not tone directly, because
// total peripheral resistance already carries the tone effect and applying it twice would double-count it.
ACME_tbi_autonomicMild             = 1.00;
ACME_tbi_autonomicModerate         = 0.97;
ACME_tbi_autonomicSevere           = 0.80;
ACME_tbi_autonomicCritical         = 0.55;
ACME_tbi_autonomicFallPerSec       = 0.022;
ACME_tbi_autonomicRecoverPerSec    = 0.004;
ACME_tbi_autonomicToneSlewPerSec   = 0.35;
ACME_tbi_autonomicChaosStart       = 0.35;
ACME_tbi_autonomicChaosAmp         = 0.55;
ACME_tbi_autonomicVasoGain         = 0.30;  // max fractional resistance rise from a resistance-only positive autonomic swing.
ACME_tbi_autonomicVasodilGain      = 0.45;  // max fractional resistance loss from resistance-only vasomotor failure.
ACME_tbi_autonomicJuncMinAbility   = 0.25;
ACME_tbi_osmoRecoverBonus     = 2.0;  // multiplier on the recovery rate for a short window after HTS or mannitol. osmotherapy treats actively and does not only move the number.
ACME_tbi_osmoRecoverWindow    = 120;  // seconds after an osmotherapy bolus that the recovery bonus applies.

// impending and actual herniation floors. stage 1 is recoverable.
// stage 1 is impending herniation, a warning that a medic can correct. a casualty who reached it and was then
// treated keeps a permanent light severity floor, scaled by how deep into the stage 1 clock they went. they
// can be combat-effective again, but their vitals never fully normalize and repeat trauma is far more
// dangerous. stage 2 is actual, irreversible, herniation and keeps the 0.85 floor above.
ACME_tbi_stage1FloorMin       = 0.01;  // lightest permanent floor after a barely reached impending herniation.
ACME_tbi_stage1FloorMax       = 0.30;  // heaviest permanent floor after a fully developed impending herniation. it is still recoverable and costly.
ACME_tbi_severityRiseCapPerSec = 0.02;  // max net severity rise per second whatever number of insults stack. it is above any single insult rate, near 0.01, so one insult is unthrottled and three at once cannot tank the patient.
ACME_tbi_resistStepPerSec     = 40;  // how fast, in resistance units per second, the TBI SVR add eases toward its target. it matches the visible rate of the bp tells, so the cuff and the HUD move together.
// fluid overload into ICP, which is over-resuscitation cerebral edema.
// fluid added while the patient is still hypovolemic carries no penalty. the moment they go over the limit,
// where ACM_circulation_Overload_Volume is above 0, every excess unit drives ICP up hard. a small overload has
// a large effect, because the injured brain has no compliance left to absorb it.
ACME_tbi_overloadICPperVol    = 5;  // resuscitation must not worsen ICP tenfold the moment the volume turns positive.
ACME_tbi_overloadICPmax       = 10;  // cap on the overload ICP add. it is enough to matter and not enough to kill at once.
ACME_tbi_overloadRisePerSec   = 0.035;  // overload edema accrues slowly, like a real accumulating secondary insult.

// compensation budget. this is how long a raised-ICP brain can defend perfusion before it decompensates.
ACME_tbi_compBudgetSeconds = 600;  // seconds of compensated time, where ICP is at or above cushing or CPP is under target, before the decline starts. the brain now defends perfusion for about 10 min before it tips over.
ACME_tbi_compRecoverMult   = 0.4;  // reserve recovery rate, times dt, once the insult is relieved, with CPP restored or ICP controlled.
ACME_tbi_decompSeverityPerSec = 0.012;  // extra severity per second once past the budget. it accelerates the ICP cascade and the vitals decline.
ACME_tbi_herniationStageSeconds = 360;  // per-stage herniation time once ICP is at or above the trigger. about 6 min per stage, and about 18 min from trigger to terminal, so herniation is a late event you have time to prevent or evac.
// per-stage decompensation floor from herniation, indexed by stage 0 to 3. the lethal cardiovascular collapse
// concentrates at stage 3. stages 1 and 2 are neuro warning signs, a fixed pupil or pupils and a dropping
// GCS-m, set in fn_tbihandle, and carry a light vital penalty only. stage 3 drives full decompensation, with
// agonal bradycardia and bp collapse, on top of the forced arrest that already fires there. set this to
// [0,0.33,0.67,1.0] to restore the old linear stage/3.
ACME_tbi_herniationStageDecomp = [0, 0.15, 0.30, 1.0];
ACME_tbi_evacInVehicle = true;  // true means a load of a herniated casualty into any vehicle counts as the casevac.
                                       // handoff, which freezes the cascade and satisfies requires-evac. set it false to need an explicit
                                       // ACME_evacuated flag from the mission or zeus instead, such as a real evac zone.

// cerebral autoregulation and the vasodilatory cascade, which is CPP-driven ICP.
// a CPP between autoreglower and autoregupper dilates the cerebral vessels progressively and adds ICP, capped
// at vasoicpmax. above autoregupper the brain holds normal tone and adds nothing. a restored CPP relaxes the
// add away at vasorelaxpersec, which is the therapeutic vasoconstriction a norepi drip buys. vasorisepersec is
// the active dilation push while CPP is low. the targets are a CPP of 60 to 70, with autoregupper at the top
// of that band, and a MAP of 80 to 90.
// the autoregulation band moves down with the MAP gate, or the two fight.
// a casualty at the target MAP of 65 with a controlled ICP of 15 sits at a CPP of 50. with the band at 70 to 40
// that is a vasodilation fraction of 0.67, so rosner's spiral engaged at the very MAP the medic was told to
// reach, drove ICP past the recovery ceiling of 25 and re-opened the damage gate. the target was unreachable.
// the band keeps its 20 point ramp and shifts down, so a controlled ICP at a MAP of 65 is normal tone and no
// spiral runs. a casualty at the same MAP whose ICP has climbed to 25 sits at a CPP of 40, half dilated, and the
// spiral engages again, which is correct: the sicker brain needs more MAP than 65, and that is the lesson.
// revert to 70 and 40 to restore the old band.
ACME_tbi_autoregUpperCPP = 50;  // the CPP in mmhg at or above which cerebral tone is normal, with no vasodilatory add.
ACME_tbi_autoregLowerCPP = 30;  // CPP (mmhg) at/below which reflex vasodilation is maximal
ACME_tbi_vasoICPmax = 12;  // max ICP in mmhg that the vasodilatory cascade stacks on the structural ceiling.
                                       // tuned with the 70 to 40 band so the loop is breakable. untreated, at a MAP near 70, it spirals about +12
                                       // into herniation. a MAP of 80 controls a milder TBI, near a CPP in the mid 60s, and partly controls a severe
                                       // one. a MAP of 90 clears it, at a CPP near 70. that is why the rule is MAP 80 or 90 by baseline.
ACME_tbi_vasoRisePerSec = 0.035;  // slow active vasodilatory-cascade push. an old duplicate at 0.2 was killing patients.
ACME_tbi_vasoRelaxPerSec = 0.04;  // ICP fall per second as a restored CPP drives vasoconstriction. it is slow enough to avoid a sawtooth oscillation.
// CO2 cerebral vasoreactivity, the chemical limb. hypercapnia from hypoventilation raises ICP and
// hyperventilation lowers it.
// the mechanical limb is intrathoracic pressure, which obstructs cerebral venous outflow and raises ICP. it is
// a peer of the CO2 limb.
// a medic who bags a head injury must be able to make ICP progress. see the CO2 limb in fn_tbihandle. a
// provider who must bag, in arrest or at an rr under 8, is doing the indicated thing and must not be charged
// with hypoventilation.
ACME_tbi_bvmFreshSec = 12;  // a BVM rate older than this stops counting (bag was set down)
ACME_tbi_bvmTargetRR = 10;  // adequate manual ventilation rate. meet this and the CO2 ceiling clears.
ACME_tbi_bvmThrottleFloor = 0.6;  // a reasonably managed airway always lets bagging make some progress.

ACME_tbi_peepICPmax = 6;  // max ICP in mmhg from PEEP alone, at 20 cmH2O. it is small, because PEEP is the gentle part.
ACME_tbi_dyssynchronyICPmax = 14;  // max ICP in mmhg from a spontaneously breathing patient who fights the vent.
                                    // vanishes once they are sedated or unconscious enough to stop fighting. that is the teaching point: sedate
                                    // the head injury before you ventilate it.
ACME_tbi_mechRisePerSec = 0.10;  // how fast mechanical ICP climbs. it is fast, because it is a plumbing problem and not a chemical one.

ACME_tbi_co2VasoICPmax = 18;  // max ICP in mmhg added at full hypercapnia, in apnea or a full obstruction.
ACME_tbi_co2RisePerSec = 0.12;  // CO2 retention still matters and cannot spike ICP in seconds.
ACME_tbi_co2HyperventICPdrop = 12;  // max ICP in mmhg the ceiling drops at twice-target hyperventilation. it is temporising.
ACME_tbi_co2IschemiaRatio = 1.8;  // the vent ratio, effvent over target, above which over-hyperventilation causes ischemia.
ACME_tbi_co2IschemiaPerSec = 0.008;  // TBI severity, 0 to 1, added per second while over-hyperventilating. this is a secondary injury.
ACME_tbi_mapTargetLow = 80;  // MAP (mmhg) titration goal. normal-baseline patient
ACME_tbi_mapTargetHigh = 90;  // MAP in mmhg as the titration goal, for a higher baseline or a chronically hypertensive patient.

// final ICP safety rails. these sit after every TBI tuning block on purpose, so no older duplicate assignment
// can undo them. they force ICP to behave like a long accumulation problem. even when several ceilings stack,
// from low CPP, CO2 and overload together, ICP cannot climb to herniation in seconds.
ACME_tbi_icpRisePerSec = 0.015;  // structural creep floor; final value after duplicate cleanup
ACME_tbi_vasoRisePerSec = 0.035;  // final active dilation rate. an old late duplicate at 0.2 is killed on purpose.
ACME_tbi_co2RisePerSec = 0.12;  // final CO2 limb rate. it is still clinically important and no longer instant.
ACME_tbi_globalRiseCapPerSec = 0.025;  // hard cap: ~15 mmhg / 10 min, so 15->30 takes at least 10 min
ACME_tbi_globalFallCapPerSec = 0.04;  // hard cap on the ICP fall as well, which prevents a rapid rise and fall sawtooth.
ACME_tbi_herniationMinSeconds = 600;  // ICP must stay at or above the herniation threshold this long before the cascade starts.
ACME_tbi_herniationStageSeconds = 360;  // each actual herniation stage still takes about 6 minutes once the gate opens.
ACME_tbi_reinjuryICPBump = 1;  // repeated head hits add slow pressure and severity, not an instant spike of +5.
