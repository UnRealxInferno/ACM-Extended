from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def src(rel):
    return (ROOT / rel).read_text(encoding='utf-8')


def test_provider_stance_owner_covers_cross_system_controllers():
    text = src('functions/fn_providerStanceOwned.sqf')
    for token in [
        'ACME_treatmentPoseState', 'ACME_treatmentPreflightActive',
        'ace_medical_treatment_endInAnim', 'ACME_rollProviderActive',
        'ACME_headElev_seqActive', 'ACME_menuPose', 'ACME_hang_Raising',
        'ACME_hang_Active', 'ACME_DP_InPose', 'ACME_DP_TreatmentBusy',
        'ACM_circulation_isPerformingCPR', 'ACM_core_ContinuousAction_Active',
    ]:
        assert token in text


def test_provider_stance_owner_is_registered():
    assert 'class providerStanceOwned {};' in src('config.cpp')


def test_all_delayed_provider_stance_releases_respect_new_owner():
    paths = [
        'functions/fn_treatmentPoseStop.sqf',
        'functions/fn_registerProviderStanceReleaseRuntime.sqf',
        'functions/fn_hangBagStop.sqf',
        'functions/fn_headElevMedicSeq.sqf',
        'functions/fn_headElevCancelSeq.sqf',
        'functions/fn_headElevateCancelSeq.sqf',
        'functions/fn_megacodeClosePanel.sqf',
    ]
    for path in paths:
        assert 'ACME_fnc_providerStanceOwned' in src(path), path


def test_megacode_exit_does_not_switchmove_over_new_medical_owner():
    text = src('functions/fn_megacodeClosePanel.sqf')
    guard = text.index('if ([_u] call ACME_fnc_providerStanceOwned) exitWith {};')
    switch = text.index('_u switchMove "";', guard)
    auto = text.index('_u setUnitPos "AUTO";', switch)
    assert guard < switch < auto


def test_treatment_delayed_auto_keeps_epoch_and_new_owner_guards():
    text = src('functions/fn_treatmentPoseStop.sqf')
    epoch = text.index('ACME_treatmentPoseEpoch')
    owner = text.index('ACME_fnc_providerStanceOwned', epoch)
    auto = text.index('setUnitPos "AUTO"', owner)
    assert epoch < owner < auto
