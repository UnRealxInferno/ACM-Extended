"""IV artwork silhouette/bounds regression checks; does not execute Arma."""
from functools import lru_cache
from pathlib import Path
import re
import unittest
import numpy as np
from generate_iv_limb_bounds import (
    PROFILES, EJ_TEXTURE, catalog_seeds, measured_limb_rows, measured_ej_rows,
    simplify, render, MAX_EDGE_ERROR,
)

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / 'functions' / 'fn_ivLimbBounds.sqf').read_text(encoding='utf-8')
SITE_DATA = (ROOT / 'functions' / 'fn_ivSiteData.sqf').read_text(encoding='utf-8-sig')


@lru_cache(maxsize=1)
def source_profiles():
    out = {}
    pattern = re.compile(
        r'case "\\acm_extended\\ui\\iv\\([^"\\]+)\.paa":\s*\{\s*\[\s*(.*?)\s*\]\s*\};',
        re.S,
    )
    for texture, body in pattern.findall(SOURCE):
        rows = np.array([
            [float(a), float(b), float(c)]
            for a, b, c in re.findall(r'\[([\d.]+),\s*([\d.]+),\s*([\d.]+)\]', body)
        ])
        out[texture] = rows
    return out


def at(profile, v):
    return tuple(float(np.interp(v, profile[:, 0], profile[:, col])) for col in (1, 2))


class IVArtworkBounds(unittest.TestCase):
    def test_all_authored_iv_views_are_bounded(self):
        expected = {texture for _, texture, _, _, _ in PROFILES} | {EJ_TEXTURE}
        self.assertEqual(set(source_profiles()), expected)
        for body_part in ('leftarm', 'rightarm', 'leftleg', 'rightleg', 'ej'):
            self.assertIn(f'case "{body_part}"', SOURCE)
        self.assertIn('default {[]};', SOURCE)
        self.assertNotRegex(SOURCE, r'\b(?:setVariable|ctrlSetAngle|remoteExec|publicVariable|setPos)\b')

    def test_profiles_are_finite_ordered_and_bounded(self):
        for texture, profile in source_profiles().items():
            with self.subTest(texture=texture):
                self.assertGreaterEqual(len(profile), 2)
                self.assertLessEqual(len(profile), 80)
                self.assertTrue(np.isfinite(profile).all())
                self.assertTrue((np.diff(profile[:, 0]) > 0).all())
                self.assertTrue((profile[:, 1] < profile[:, 2]).all())
                self.assertTrue(((profile >= 0) & (profile <= 1)).all())

    def test_source_matches_generator_exactly(self):
        self.assertEqual(SOURCE, render())

    def test_generated_profile_centers_stay_on_full_resolution_art(self):
        # Full-resolution alpha can differ from the 1024 mip at antialiased edges. The important
        # invariant is that the center of every generated valid row remains on the same worked
        # limb/head silhouette rather than jumping onto transparent canvas or the adjacent torso.
        for body_part, texture, seed_site, min_v, max_v in PROFILES:
            full = measured_limb_rows(body_part, texture, seed_site, min_v, max_v, want=2048)
            profile = source_profiles()[texture]
            sample = full[::max(1, len(full)//200)]
            for v, left, right in sample:
                pleft, pright = at(profile, v)
                center = (pleft + pright) * .5
                with self.subTest(texture=texture, v=v):
                    self.assertLess(left, center)
                    self.assertGreater(right, center)

        full_ej = measured_ej_rows(want=2048)
        profile = source_profiles()[EJ_TEXTURE]
        sample = full_ej[::max(1, len(full_ej)//200)]
        for v, left, right in sample:
            pleft, pright = at(profile, v)
            center = (pleft + pright) * .5
            self.assertLess(left, center)
            self.assertGreater(right, center)

    def test_catalog_stick_targets_land_inside_their_view_art(self):
        seeds = catalog_seeds()
        # Parse body/site -> texture from the source catalog itself.
        views = {}
        for bp, site, texture in re.findall(
            r'\["(leftarm|rightarm|leftleg|rightleg)#(upper|middle|lower)",\s*\["([^"]+)"',
            SITE_DATA,
        ):
            views[(bp, site)] = texture
        self.assertEqual(len(views), 12)
        for key, (u, v) in seeds.items():
            texture = views[key]
            left, right = at(source_profiles()[texture], v)
            with self.subTest(site=key, texture=texture):
                self.assertLessEqual(left, u)
                self.assertGreaterEqual(right, u)

    def test_right_arm_angle_neutral_axis_still_uses_row_bounds(self):
        # Expanded silhouettes are also used as a validity mask, but the catheter-angle
        # correction remains intentionally right-arm-only in fn_ivMinigameTick.sqf.
        tick = (ROOT / 'functions' / 'fn_ivMinigameTick.sqf').read_text(encoding='utf-8-sig')
        self.assertIn('if (_bpT == "rightarm") then', tick)
        self.assertIn('call ACME_fnc_ivLimbBounds', tick)


if __name__ == '__main__':
    unittest.main()
