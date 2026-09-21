// ACM Extended fork-native implementation of ACM_circulation_fnc_recentAEDShock.
// stock ACM treats a patient as recently shocked for 60 s in general and 65 s for the monitor. during that window
// the AED monitor force-draws asystole whatever the real rhythm is, getekgheartrate returns 0 and haspulse
// returns false, so the trace flatlines and the BPM reads nothing for roughly a minute after every shock, even
// after ROSC.
// PILLAR wants the monitor to read the rhythm immediately after a shock and pick up whatever the patient actually
// has, so we collapse that window to a short, tunable value.
// ACME_aed_postShockWindow is the seconds the patient counts as recently shocked. it defaults to 2, giving a brief
// post-shock artifact and then the live trace, against a stock of 60 or 65. set 0 for an instant read, or back to
// 65 for stock behavior.
// the side effect is intended: because this same flag gates getekgheartrate, haspulse and the shockable re-analyze
// check of the AED, shortening it also lets the BPM, the pulse and the re-analyze reflect the real rhythm this
// quickly. raise ACME_aed_postShockWindow if you want the stock 2-minute CPR cadence back before the AED will
// re-arm.
// _this is [_patient, _monitor].
params ["_patient", ["_monitor", false]];

private _window = missionNamespace getVariable ["ACME_aed_postShockWindow", 2];

// a synchronized cardioversion no longer writes ACM's aed_lastshock, because ACM uses that clock to decide whether
// a shock inside 60 seconds should drive the patient to asystole, and a cardioversion must never make the
// defibrillation that follows it lethal. see fn_synccardiovert.
// so it keeps its own timestamp, and this function has to honor both, or the AED would happily re-analyze a
// fraction of a second after a cardioversion.
private _sharedLast = _patient getVariable ["ACME_aed_lastShockServer", -1];
if (_sharedLast >= 0) exitWith {(_sharedLast + _window) > serverTime};

// Compatibility for old serialized states that predate the shared server-time stamp. These owner-clock fields are
// retained for physiology/persistence; new live shocks never depend on them for cross-client presentation timing.
private _last = (_patient getVariable ["ACM_circulation_AED_LastShock", -120])
    max (_patient getVariable ["ACME_sync_lastShock", -120]);
(_last + _window) > CBA_missionTime
