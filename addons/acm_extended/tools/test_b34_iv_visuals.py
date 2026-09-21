"""B34 geometric invariants and source contracts; does not execute Arma UI code."""
from pathlib import Path
import math
import unittest

ROOT = Path(__file__).resolve().parents[1]
def src(name):
    return (ROOT / 'functions' / f'fn_{name}.sqf').read_text(encoding='utf-8-sig')


def swept_coverage(start, end, cell=.008, radius=.016):
    """Independent union raster model: covered cells are max-composited once."""
    samples = max(1, math.ceil(math.dist(start,end)/(cell*.5)))
    coverage = {}
    for sample in range(samples+1):
        f = sample/samples
        u, v = (a+(b-a)*f for a,b in zip(start,end))
        for gx in range(math.floor((u-radius)/cell),math.floor((u+radius)/cell)+1):
            for gy in range(math.floor((v-radius)/cell),math.floor((v+radius)/cell)+1):
                d = math.dist(((gx+.5)*cell,(gy+.5)*cell),(u,v))
                value = max(0,min(1,(radius-d)/(cell*.75)))
                if value:coverage[gx,gy] = max(value,coverage.get((gx,gy),0))
    return coverage


class IVPanelGeometry(unittest.TestCase):
    def test_physical_endpoints_and_monotonic_zoom_without_old_clamp(self):
        minimum = .66/.925
        heights = [.925*(minimum+(1.5-minimum)*i/100) for i in range(101)]
        self.assertAlmostEqual(heights[0],.66)
        self.assertAlmostEqual(.925,.97-.045)
        self.assertAlmostEqual(heights[-1],(.97-.045)*1.5)
        self.assertTrue(all(a<b for a,b in zip(heights,heights[1:])))
        init=src('ivMinigameInit')
        self.assertIn('getVariable ["ACME_iv_uiScaleV3", 1]',init)
        self.assertNotIn('getVariable ["ACME_iv_uiScaleV2",',init)
        self.assertIn('private _zoom = _zoomSetting * 1.10;',init)
        self.assertIn('private _bodyH = _szH * 0.925 * _zoom;',init)
        self.assertNotIn('_bodyH = _botLimit - _bodyY',init)

    def test_every_canvas_point_reachable_by_vertical_pan(self):
        for height in (.925,1.11,1.3875):
            pan_range=(.97-height,.045)
            for v in [i/100 for i in range(101)]:
                y=min(pan_range[1],max(pan_range[0],.5075-height*v))
                self.assertGreaterEqual(y+height*v,.045-1e-9)
                self.assertLessEqual(y+height*v,.97+1e-9)

    def test_translation_keeps_hits_marks_and_prep_registered(self):
        for width,height in ((1920,1080),(2560,1440),(5120,1440)):
            for scale in (.66/.925,1,1.5):
                bh=.925*scale;bw=bh*height/width
                self.assertAlmostEqual(bw*width,bh*height)
                for u,v in ((.557,.682),(.623,.253),(.560,.470),(.520,.747)):
                    x,y=.5-bw/2+bw*u,.5075-bh/2+bh*v
                    for dy in (-.2,.045,.2):
                        self.assertAlmostEqual((x-(.5-bw/2))/bw,u)
                        self.assertAlmostEqual((y+dy-(.5075-bh/2+dy))/bh,v)
        pan=src('ivMinigamePan')
        for term in ('ACME_IV_MarkCtrls','ACME_IV_PrepViews','ACME_IV_CathCtrl','ACME_IV_BodyRectBase','ACME_IV_Dragging','ACME_IV_InsPin", []','ACME_IV_LastNeedleState", []'):
            self.assertIn(term,pan)
        self.assertNotIn('ACME_IV_InsU",',pan)
        self.assertNotIn('ACME_IV_InsV",',pan)
        self.assertNotIn('remoteExec',pan)

    def test_neck_motion_is_mirrored_and_opposite_old_limb_convention(self):
        tick=src('ivMinigameTick')
        self.assertIn('_displayAngle = _span * (missionNamespace getVariable ["ACME_iv_ejTiltDeg", 15]);',tick)
        self.assertIn('if (_isEJ) then {_motionTilt = -_motionTilt;};',tick)
        for span in (-1,-.5,0,.5,1):
            left_angle=span*15;right_angle=-span*15
            self.assertAlmostEqual(left_angle,-right_angle)
            self.assertLessEqual(abs(left_angle),15)
            for a,b in ((.228,.9737),(-.2301,.9732)):
                c,s=math.cos(math.radians(left_angle)),math.sin(math.radians(left_angle))
                self.assertAlmostEqual((a*c-b*s)**2+(a*s+b*c)**2,a*a+b*b)


class UniformPrep(unittest.TestCase):
    def test_swept_diagonal_is_connected_without_random_dabs(self):
        remaining=set(swept_coverage((.45,.45),(.57,.57)))
        todo=[remaining.pop()]
        while todo:
            x,y=todo.pop()
            for p in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                if p in remaining:remaining.remove(p);todo.append(p)
        self.assertFalse(remaining)
        paint=src('ivPrepPaint')
        self.assertNotRegex(paint,r'\brandom\s*\(')
        self.assertIn('_coverage max (_known param [4,0])',paint)
        self.assertIn('ctrlSetText "#(argb,8,8,3)color(1,1,1,1)"',paint)

    def test_repeated_crossing_refreshes_without_opacity_stacking(self):
        coverage={}
        paths=(((.46,.50),(.54,.50)),((.50,.46),(.50,.54)))
        for _ in range(100):
            for start,end in paths:
                for key,value in swept_coverage(start,end).items():
                    coverage[key]=max(value,coverage.get(key,0))
        self.assertTrue(all(0<opacity<=1 for opacity in coverage.values()))
        self.assertEqual(coverage[62,62],1)
        paint=src('ivPrepPaint')
        self.assertIn('private _cap = 768;',paint)
        self.assertIn('_cells deleteAt _oldest',paint)
        self.assertNotIn('prepPassAlphaStep',paint)
        self.assertNotIn('prepSpeedFast',paint)

    def test_redness_is_below_band_and_every_dynamic_mark(self):
        config=(ROOT/'config.cpp').read_text(encoding='utf-8-sig')
        dialog=config.split('class ACME_IVMinigame_Dialog',1)[1]
        self.assertLess(dialog.index('class IV_Limb'),dialog.index('class IV_PrepLayer'))
        self.assertLess(dialog.index('class IV_PrepLayer'),dialog.index('class IV_Band'))
        self.assertIn('ctrlCreate ["ACME_IV_Clean", -1, _layer]',src('ivPrepPaint'))
        self.assertIn('getVariable ["ACME_UI_NoShake", false]',src('uiShakeApply'))
        self.assertIn('setVariable ["ACME_UI_NoShake", true]',src('ivMinigameInit'))

if __name__=='__main__':unittest.main()
