# ACM Extended 1.2.1-rc1: chest interactions and patient motion

## Changes

- Dress Junctional Wound uses the same medical-menu icon as Pressure Bandage.
- Seizure spasm aliases now play at 1.05x. Already-unconscious patients retain their existing supine, prone or elevated posture at onset, including debug-induced episodes. Awake patients still become unconscious.
- Drag handles use a real native rope with the helper endpoints used by ACE fast-roping. The patient owner creates one replicated rope per session. Stop, deletion and locality handoff clean up the objects. ACE fast-roping is now an explicit addon dependency.
- Dragging enters ragdoll with Arma's native addForce command. Removed the prone switchMove and one-frame consciousness toggle. Pulling no longer waits for that animation transition. Existing weight, fatigue, pace and overstretch limits remain.
- Traumatic and thoracostomy chest-seal burps share a patient-owner cooldown of 10 seconds, including between providers. Rejected repeats do not repeat the treatment, activity entry or provider animation. The lifted corner can still be laid flat during cooldown.
- Accepted burps request the chest-seal treatment animation on the provider's machine.
- Chest-seal Flip waits for the exact provider roll animation and matching pose/session ownership before sending one physical patient-roll request. Weapon and crouch transitions do not trigger a flip. Closing the panel, cancellation or timeout retires pending work.
- Auscultation opens with the bell at the cursor, 19% larger. Hold left mouse to listen and drag with resistance. The bell shrinks by 12% while pressed; release lifts it.
- Right lung, left lung and cardiac sounds play on separate local emitters with continuous distance attenuation while dragging. Samples keep their phase during movement. Existing respiratory rate, heart rate and pathology sound selection remain.
- Lung sound fades out at the diaphragm. Below it, only a narrow centerline cardiac field remains, fading laterally and downward. There is no universal audible heart-sound floor.
- Closing or replacing the scope panel removes all local sound objects and restores hearing attenuation.

## Current open finger-thoracostomy behavior

An unsealed finger tract continues to vent air. There is no additional penalty based solely on time left open, and no spontaneous tract-closure timer in the current PTX model. Continuous passive blood drainage belongs to chest tubes. Inadequate preparation sets the incision's infection flag when cutting; that is separate from leaving the tract open. This patch does not add new clinical penalties.

## Validation

Checked delimiters in all 24 changed SQF files and the changed configuration/dialog. Checked function registration, duplicate concrete config classes and ACE dependency identities. Thirteen focused source-level interaction and lifecycle checks passed. Existing regression expectations were updated and a focused pytest module was added.

The local command runner was unavailable. Pytest, HEMTT compilation and Arma runtime behavior were not run here. Source checks do not establish PhysX movement, animation playback or the audible crossfade.

## In-game verification

1. Induce a debug seizure on a supine unconscious patient and on an awake patient. Confirm 1.05x spasms, no prone reset for the former, and normal collapse/physiology for the latter.
2. Attach the drag rope to supine and prone casualties, including training manikins. Walk, turn, stop and resume with light and heavy equipment. Verify physical movement, a native rope, and no position snap.
3. Release, delete, heal/wake, change patient locality, enter a vehicle and start a conflicting procedure. Verify rope cleanup and restored provider movement.
4. Burp traumatic and surgical seals repeatedly, including with two providers. Expect at most one accepted burp per casualty every 10 seconds, one log entry per accepted burp and a provider animation. Check that the seal can still be laid flat.
5. Flip with empty hands from standing, crouching and prone, then with a selected weapon. The patient must wait for the provider's medic4 roll state. Close or cancel during entry; no delayed flip should occur.
6. Hold and drag the bell across normal, unilateral pathological and crackling lungs; across the heart; and below the diaphragm. Listen for uninterrupted phase and smooth transitions. Check sound level in first/third person and indoors because mixing uses local positional sound attenuation.
7. Release left mouse, lose focus, press ESC and replace the dialog. Confirm silence, no stuck press and no lingering sound objects.

For source checks, run:
```powershell
py -m pytest addons/acm_extended/tools/test_chest_interaction_followup.py addons/acm_extended/tools/test_patient_motion_hotfix.py addons/acm_extended/tools/test_drag_handle_ragdoll.py addons/acm_extended/tools/test_seizure_gesture_unification.py
hemtt build
```
