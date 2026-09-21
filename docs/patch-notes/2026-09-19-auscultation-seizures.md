# ACM Extended 1.2.1-rc1: auscultation and seizure corrections

## Changes

- Reduced all 21 stethoscope sound variants by another 6 dB, from db+16 to db+10, including cardiac, normal/shallow/dull breathing and crackles.
- Added a Front/Back listening-view button using ACM's existing front texture and ACME's existing back texture. Both use the original square body canvas, chest crop and scale. Anatomical right/left lung identity reverses on screen when viewing the back. The button changes the listening diagram; it does not physically roll the casualty.
- Kept the held bell, drag resistance, pressed-size feedback and continuous audio mixing. The view button retains normal button input and sound. Changing views lifts the bell.
- Added a separate basal crackle channel for each lung. Above 0.3 L of hemothorax fluid, crackles progressively replace the affected lung's lower-node sound; they reach full contribution at 1.1 L. Upper-node and opposite-lung findings remain. The blend uses current fluid, so draining the chest reduces the finding.
- ACM has pooled pleural fluid and a native affected-lung finding, not separate left/right fluid volumes. This change uses that existing model. Lung findings refresh on the patient owner while the scope is open, with rate limiting, clinical-episode checks and broadcasts only on a changed finding.
- Posterior listening uses lung fields without anterior cardiac listening points. Lung sound still fades out at the diaphragm. The front view retains only the narrow centerline cardiac field below it.
- Clinical descriptor mode now says "Severe Ecchymosis" in chest inspection and injury-list bruising rows. The injury list now resolves the clinical mapping rather than always displaying the plain localized wording.

## Seizure correction

The earlier patch incorrectly treated positive CfgGestures speed as a multiplier. It is clip cycles per second. A shared value of 1.05 compressed every clip to about 0.95 seconds.

The ACME aliases now multiply each native BI value by 1.05:

| Clip | Native speed | ACME speed | Approximate duration |
| --- | ---: | ---: | ---: |
| GestureSpasm3 | 0.238 | 0.2499 | 4.00 s |
| GestureSpasm4 | 0.2325 | 0.244125 | 4.10 s |
| GestureSpasm5 | 0.2069 | 0.217245 | 4.60 s |
| GestureSpasm6 | 0.1287 | 0.135135 | 7.40 s |

Native values were checked against the [exported BI gesture configuration](https://github.com/alexgibbs606/arma3configParser/blob/main/AiO.1.92.145639_CUP.json). The existing speed regression test now checks the ratio and clip duration.

- Start the spasm through switchGesture, bypassing the underlying ACM_LyingState action graph that could swallow playActionNow.
- After the onset settling period, a stationary ragdoll receives one animation handoff preserving its actual supine/prone surface or elevated hold. The driver no longer waits forever for another procedure to wake the skeleton.
- Continue yielding to vehicles, drag/carry, CPR and an active roll. Do not change heading, position, consciousness or global animation speed to start the gesture.
- Give each visual episode a unique session and clinical epoch. Delayed onset, retry, handoff and GestureDone callbacks cannot restart an old episode after a full heal or replacement.
- Repeating the debug action also recovers an interrupted visual driver without repeating the collapse.
- Clear the gesture with GestureEmpty on stop. GestureNo is a head-shake gesture, not an empty layer.

## Validation

Ten focused source checks passed: changed-source delimiter balance, duplicate concrete classes, speed ratios/durations, 21 sound gains, gated descriptors, view registration/geometry, channel lifecycle, owner-routed lung refresh, seizure startup path and stale-callback guards.

A numerical model of the listening formulas checked 13,122 spatial samples for bounded gains, side mapping and silence below the lateral diaphragm. Fluid checks covered no basal crackles through 0.3 L, preserved upper/opposite fields and increasing basal contribution through 1.1 L. The existing 128-pixel texture mipmaps were decoded and visually checked; both source textures are 2048x2048 and use matching body placement.

The command runner was unavailable. Pytest, HEMTT compilation and Arma runtime tests were not run here. These checks do not verify rendered gesture timing, ragdoll handoff, button behavior or audible mixing in the engine.

## In-game verification

1. Induce a debug seizure on an untouched training casualty, an already-supine casualty, a prone casualty, an elevated casualty and an awake patient. Seizing should start after the onset settling period without CPR or a manual roll. Already-down patients must not be reset face-down.
2. Time Spasm3-6 against the durations above. Compare the loaded alias speed to its BI parent in the config viewer to confirm the 1.05 ratio.
3. Full-heal during onset, a retry and an active gesture; induce a new episode immediately. No previous callback should restart or double-advance it. Repeat with a remote-owned patient.
4. Open the scope at 16:9 and ultrawide resolutions. Change Front/Back, hold and release the bell, and check that the diagram remains at the same chest scale and the correct anatomical side remains affected.
5. Test hemothorax at 0, 0.2, 0.3, 0.5 and 1.1 L. Compare upper/lower nodes and both lungs on both views. Drain fluid while listening and confirm the basal finding fades away. Also check existing diffuse edema/aspiration crackles.
6. Confirm the lower sound level, silence with the bell lifted, lower-lateral silence, and no lingering sound after ESC, focus loss or replacement of the dialog.
7. Toggle clinical descriptors. Chest inspection and injury rows should show Severe Ecchymosis only in clinical mode.

```powershell
py -m pytest addons/acm_extended/tools/test_seizure_gesture_unification.py addons/acm_extended/tools/test_debug_seizure_action.py addons/acm_extended/tools/test_patient_motion_hotfix.py addons/acm_extended/tools/test_chest_interaction_followup.py addons/acm_extended/tools/test_config_compile.py
hemtt build
```
