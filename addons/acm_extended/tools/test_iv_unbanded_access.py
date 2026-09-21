"""Static contracts for unbanded IV access and consequence-only bruising."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
F = ROOT / 'functions'

def read(name):
    return (F / name).read_text(encoding='utf-8-sig')

class IVUnbandedContracts(unittest.TestCase):
    def test_ready_without_boa_and_palpation_not_band_gated(self):
        self.assertIn('["ACME_IV_Stage", "ready"]', read('fn_ivMinigameInit.sqf'))
        sync = read('fn_ivMinigameSyncBand.sqf')
        self.assertNotIn('["ACME_IV_Stage", "needband"]', sync)
        tick = read('fn_ivMinigameTick.sqf')
        self.assertIn('if (!_drag || {!_onPatientArt}) exitWith', tick)
        self.assertNotIn('if (!(_bandOn && _drag))', tick)

    def test_puncture_must_land_on_authored_patient_art(self):
        click = read('fn_ivMinigameClick.sqf')
        self.assertIn('call ACME_fnc_ivLimbBounds', click)
        self.assertIn('if (!_onArt) exitWith {};', click)
        site = read('fn_ivSiteAtPoint.sqf')
        self.assertIn('call ACME_fnc_ivLimbBounds', site)
        self.assertIn('if (_u < _leftU || {_u > _rightU}) exitWith {""};', site)

    def test_pressure_is_dominant_and_boa_can_help_distal_sites(self):
        diff = read('fn_ivSiteDifficulty.sqf')
        self.assertIn('private _map =', diff)
        self.assertIn('private _pressure =', diff)
        self.assertIn('private _patency = _pressure ^ 1.60;', diff)
        self.assertIn('case 0: {0.22};', diff)
        self.assertIn('case 1: {0.13};', diff)
        self.assertIn('case 2: {0.08};', diff)
        self.assertNotIn('exitWith {[0, 0, 0, 0]}', diff)

    def test_success_keeps_exact_puncture_uv_and_prep_does_not_bruise(self):
        click = read('fn_ivMinigameClick.sqf')
        self.assertIn('ACME_IV_NeedleTipUV', click)
        insert = read('fn_ivMinigameInsertStart.sqf')
        self.assertIn('ACME_IV_InsU', insert)
        self.assertIn('ACME_IV_InsV', insert)
        retract = read('fn_ivMinigameRetract.sqf')
        self.assertIn('ACME_IV_InsU', retract)
        self.assertIn('ACME_IV_InsV', retract)
        success = read('fn_ivMinigameStickSuccess.sqf')
        self.assertIn('ACME_IV_StickU', success)
        self.assertIn('ACME_IV_StickV', success)
        prep = read('fn_ivPrepPaint.sqf')
        self.assertIn('Bruising is reserved for a missed/blown stick', prep)
        self.assertIn('infiltration or extravasation', prep)
        self.assertNotIn('ACME_IV_PrepBruiseAt', prep)

if __name__ == '__main__':
    unittest.main()
