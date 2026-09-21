# PEA morphology update

Public/debug build tag: **1.2.1-rc1**. HEMTT version: **1.4.5.0**.

## Changes

- Default PEA now uses the same narrow P-QRS-T template as sinus rhythm. This includes obstructive PEA without a severe uncovered transfusion burden.
- The existing wide PEA complex and its beat variation are reserved for PEA patients with a severe transfusion burden not covered by calcium.
- Giving calcium can narrow the displayed complex while the patient remains in PEA from another cause. The open monitor detects this change and uses its existing waveform transition path; reopening the monitor also re-evaluates the selection.
- Both forms remain native rhythm 5: pulseless and nonshockable. Electrical beat timing, heart-rate selection, arrest entry and ROSC logic are unchanged.

## Cause selection

ACME currently has no measured potassium state. The wide complex is a gameplay proxy for the requested transfusion-related, hyperkalemic-style appearance, using existing current transfusion burden and calcium reserve. It does not diagnose hyperkalemia or add potassium physiology.

The selector subtracts unspent native calcium reserve from current native transfusion burden, clamping at zero. These quantities are consumed together by the existing transfusion code, so this avoids counting calcium twice or using lifetime dose totals.

Severity uses the existing native burden penalty of 0.05 L per BPM and the existing fatal heart-rate boundary below 40 BPM, relative to the patient's resting baseline. At an 80 BPM baseline, more than 2 L of uncovered burden selects wide PEA; at exactly 2 L, PEA remains narrow. This is a game threshold derived from existing mechanics, not a clinical potassium or transfusion threshold.

Only a living patient already in native PEA and cardiac arrest can select the wide form. The selector is read-only. It does not turn a perfusing rhythm, VF or PVT into PEA and does not create a new arrest pathway.

## Validation

Completed source and numerical checks:

- Changed SQF/config delimiters balance; the new function is registered once; config has no duplicate concrete classes.
- Sixteen selector-model cases cover obstructive PEA, threshold boundaries, calcium coverage, other rhythms, death and malformed numeric values.
- Equal consumption of native calcium reserve and transfusion burden preserves the calculated uncovered burden.
- Checks against the actual waveform sample arrays confirm narrow versus wide complexes and R-peak alignment. Default PEA retains separate P, QRS and T components.
- A focused pytest file was added at `addons/acm_extended/tools/test_pea_waveform_morphology.py`.

The source/numerical checks ran in JavaScript. Pytest, HEMTT and Arma were not run because the command runner was unavailable. Source checks do not establish engine behavior.

## In-game checks still required

1. Induce obstructive PEA without transfusion burden. Confirm a sinus-like tracing, no pulse and no shock advised.
2. In an existing PEA patient with an 80 BPM resting baseline, compare 0.5 L, 2 L and 2.5 L uncovered burden. Only 2.5 L should select the wide tracing.
3. In that PEA patient, administer calcium through the normal treatment path. Confirm narrowing when coverage drops the uncovered burden below the cutoff; unresolved obstruction must still prevent a pulse.
4. Observe the change with the monitor open, then close and reopen it. Check sweep continuity and beep alignment.
5. Check CPR/post-shock visual precedence, VF/PVT, full heal and a remote-owned patient.

Local verification commands:

```powershell
python -m pytest addons/acm_extended/tools/test_pea_waveform_morphology.py
hemtt build
```

## Reference

Littmann, Bustin and Haley, *A Simplified and Structured Teaching Tool for the Evaluation and Management of Pulseless Electrical Activity* (2014): https://karger.com/mpp/article/23/1/1/202979/A-Simplified-and-Structured-Teaching-Tool-for-the

The paper's narrow/mechanical versus wide/metabolic distinction informs the visual mapping. It is a teaching framework with exceptions, not an assertion that ECG width uniquely identifies a cause.
