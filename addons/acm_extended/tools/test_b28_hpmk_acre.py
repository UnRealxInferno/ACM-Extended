import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
def src(name): return (ROOT/'functions'/f'fn_{name}.sqf').read_text(errors='ignore')
class B28Regression(unittest.TestCase):
    def test_version(self):
        self.assertIn('1.0.100-r7',(ROOT/'config.cpp').read_text())
        self.assertIn('CfgPatches',src('postInit'))
        self.assertIn('ACME_buildBatch = "B43"',src('postInit'))
    def test_no_network_blanket_attached_to_wrapped_patient(self):
        t=src('hpmkBlanketTick')
        self.assertNotIn('attachTo [_p',t)
        self.assertIn('networked anchor',t)
        self.assertIn('ACME_hpmk_dropped',t)
    def test_wrapped_blanket_is_local_simple_object(self):
        t=src('postInit')
        self.assertIn('ACME_hpmk_wrappedVisuals',t)
        self.assertIn('createSimpleObject [_class',t)
        self.assertNotIn('_vis attachTo [_patient',t)
        self.assertIn('getPosWorldVisual _patient',t)
    def test_obtunded_default_fallback_is_off(self):
        for n in ('obtundedTick','obtundedAuto','consciousnessBudget'):
            self.assertNotIn('getVariable ["ACME_sys_obtunded", true]',src(n))
            self.assertIn('getVariable ["ACME_sys_obtunded", false]',src(n))
    def test_obtunded_tick_can_cleanup_when_master_off(self):
        t=src('obtundedTick')
        self.assertNotIn('ACME_sys_obtunded", true]) exitWith',t)
        self.assertIn('private _active = _systemOn',t)
        self.assertIn('ACME_ObtundedActive',t)
        self.assertIn('ACME_ObtundedVoiceGuardAt',t)
    def test_voice_true_request_is_clamped_to_actual_state(self):
        t=src('obtundedVoice')
        self.assertIn('private _effectiveMute = _mute',t)
        self.assertIn('ACME_sys_obtunded", false',t)
        self.assertIn('ACME_obtunded", false',t)
        self.assertIn('TFAR_fnc_setForbiddenToSpeak',t)

if __name__=='__main__': unittest.main()
