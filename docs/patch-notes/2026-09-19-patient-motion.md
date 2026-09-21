# ACM Extended 1.2.1-rc1: patient motion follow-up

## Changes
- Induce Seizure (debug) now executes directly through the patient owner. It remains head-only and requires the provider's debug setting, but no longer runs weapon/stance preflight or a 0.01-second treatment timer.
- The seizure state is published before collapse. Active seizures prevent spontaneous wake-up, generic treatment settling yields to the actual seizure state, and the gesture driver waits for ragdoll/transport to release the skeleton.
- Megacode manikins retain animation capability with autonomous AI disabled. Their resting-pose keeper yields during seizures and drag-handle transport.
- Drag-handle collapse explicitly exits the locked lying/unconscious animation while staying prone. The unconscious-animation handler yields to the replicated drag session instead of pinning the body again.
- The drag controller wakes a settled body before applying force, including when the provider is stationary. Short startup/interpolation stretches get bounded grace; sustained overextension and teleports still release.
- Drag tether drawing is wider. Patient movement remains owner-driven physics, with the existing weight, fatigue, speed cap, and vehicle/procedure handoffs.
- Deferred ragdoll work checks locality, clinical epoch, consciousness, vehicle entry, and drag-session identity before acting.
- Ketamine water-displacement amplitudes are 25% lower at every dose/debug tier. Frequency, easing, blur and chromatic response are unchanged.
- Semi-Fowler's rejects standing and crouching patients even if a stale lying flag remains. The menu checks live eligibility, and the patient owner rechecks before changing equipment or starting the pose.

## Validation
Source delimiter, reference, ordering and displacement-ratio checks were performed. Eleven focused regression checks were added and the existing visual-profile expectations were updated.
The local command runner was unavailable. Pytest, HEMTT compilation and Arma runtime behavior have not been verified for this patch.

## Required in-game checks
1. Spawn an ACM training patient. With debug enabled, use Head > Debug > Induce Seizure. Try with the provider standing with a weapon and already crouched. Confirm the notice, active seizure entry, visible convulsions, and eventual postictal transition.
2. Repeat on a casualty owned by a dedicated server. Check that a normal treatment completing during the episode does not cancel the seizure animation.
3. Attach a drag handle to a settled unconscious training patient. Wait briefly, walk, turn, stop and resume. Confirm ragdoll movement follows the tether, sprint is blocked and weight affects pace.
4. Release and reattach, start a conflicting procedure, load into a vehicle, and heal/wake the patient. Confirm cleanup and no stale collapse or provider speed restriction.
5. With a conscious patient standing, then crouching, confirm no Semi-Fowler's option appears. Confirm an awake ACM lying patient and an unconscious patient on the ground can still be positioned. Stand up during the action timer to check the completion guard.
6. Compare ketamine Mild/Moderate/Severe and real medication effects. Water movement should be weaker, with the same onset and wave timing.

If seizure or drag motion still fails, capture the RPT and the existing debug dump along with whether the casualty is a normal ACM training patient or Megacode manikin. Source checks cannot establish Arma PhysX or gesture behavior.
