#!/usr/bin/env python3
"""Generate IV minigame artwork row bounds from the shipped PAA alpha silhouettes.

The limb textures also contain a narrow adjacent body strip. Limb rows are therefore
tracked from a known vein seed and followed by overlap so the generated hit mask stays
on the worked arm/leg rather than the adjacent torso. The EJ view is one contiguous
head/upper-torso silhouette and uses the outer opaque run directly.

Run with --write to regenerate functions/fn_ivLimbBounds.sqf, or --check to verify it.
"""
from pathlib import Path
import argparse
import math
import re
import numpy as np
from paa import read_paa

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'functions' / 'fn_ivLimbBounds.sqf'
# body part, texture, seed site, minimum/maximum usable canvas V.
# The small top/bottom trims exclude antialiased single-pixel tails while retaining the
# full clinically usable silhouette, including hands and feet.
PROFILES = (
    ('leftarm',  'iv_left_arm_ca',        'middle', .10, .94),
    ('leftarm',  'iv_left_arm_rear_ca',   'upper',  .10, .94),
    ('rightarm', 'iv_right_arm_ca',       'middle', .10, .94),
    ('rightarm', 'iv_right_arm_rear_ca',  'upper',  .10, .94),
    ('leftleg',  'iv_left_leg_ca',        'lower',  .08, .98),
    ('leftleg',  'iv_left_leg_rear_ca',   'middle', .08, .98),
    ('rightleg', 'iv_right_leg_ca',       'lower',  .08, .98),
    ('rightleg', 'iv_right_leg_rear_ca',  'middle', .08, .98),
)
EJ_TEXTURE = 'body_background_ej_view'
EJ_VALID_MIN_V = 0.420
EJ_VALID_MAX_V = 0.590
EJ_MIN_V, EJ_MAX_V = .070, .856
MIP = 1024
ALPHA_THRESHOLD = 128
# Two source mip pixels keeps the SQF profile compact while remaining visually exact.
MAX_EDGE_ERROR = 2 / MIP


def catalog_seeds(root=ROOT):
    source = (root / 'functions' / 'fn_ivSiteData.sqf').read_text(encoding='utf-8-sig')
    seeds = {}
    pattern = r'\["(leftarm|rightarm|leftleg|rightleg)#(\w+)",\s*\[([^\]]+)\]\]'
    for body_part, site, row in re.findall(pattern, source):
        values = re.findall(r'"[^"]*"|[-\d.]+', row)
        seeds[(body_part, site)] = (float(values[4]), float(values[5]))
    return seeds


def opaque_runs(alpha_row):
    changes = np.diff(np.r_[False, alpha_row >= ALPHA_THRESHOLD, False].astype(int))
    # Ignore isolated bevel-sized noise. Every clinically usable limb run is much wider.
    return [(int(a), int(b)) for a, b in zip(np.flatnonzero(changes == 1),
                                            np.flatnonzero(changes == -1)) if b - a >= 8]


def measured_limb_rows(body_part, texture, seed_site, min_v, max_v, root=ROOT, want=MIP):
    _, alpha = read_paa(root / 'ui' / 'iv' / (texture + '.paa'), want=want)
    height, width = alpha.shape
    seed_u, seed_v = catalog_seeds(root)[(body_part, seed_site)]
    first = math.ceil(min_v * height - .5)
    last = math.floor(max_v * height - .5)
    seed_row = min(last, max(first, int(seed_v * height)))
    candidates = [run for run in opaque_runs(alpha[seed_row])
                  if run[0] <= seed_u * width < run[1]]
    if len(candidates) != 1:
        raise ValueError(f'{texture}: seed does not identify one limb run')
    chosen = {seed_row: candidates[0]}
    for step, limit in ((1, last + 1), (-1, first - 1)):
        previous = chosen[seed_row]
        for row in range(seed_row + step, limit, step):
            candidates = opaque_runs(alpha[row])
            scored = sorted(((max(0, min(b, previous[1]) - max(a, previous[0])), a, b)
                             for a, b in candidates), reverse=True)
            if not scored or scored[0][0] < (previous[1] - previous[0]) * .20:
                raise ValueError(f'{texture}: limb continuity lost at row {row}')
            _, left, right = scored[0]
            previous = chosen[row] = (left, right)
    return np.array([[(row + .5) / height, chosen[row][0] / width,
                      chosen[row][1] / width] for row in range(first, last + 1)])


def measured_ej_rows(root=ROOT, want=MIP):
    _, alpha = read_paa(root / 'ui' / 'iv' / (EJ_TEXTURE + '.paa'), want=want)
    height, width = alpha.shape
    first = math.ceil(EJ_MIN_V * height - .5)
    last = math.floor(EJ_MAX_V * height - .5)
    rows = []
    for row in range(first, last + 1):
        runs = opaque_runs(alpha[row])
        if not runs:
            continue
        rows.append([(row + .5) / height,
                     min(a for a, _ in runs) / width,
                     max(b for _, b in runs) / width])
    return np.array(rows)


def simplify(rows, tolerance=MAX_EDGE_ERROR):
    """Keep a vertex wherever either interpolated edge exceeds the error budget."""
    keep = {0, len(rows) - 1}
    pending = [(0, len(rows) - 1)]
    while pending:
        a, b = pending.pop()
        if b - a < 2:
            continue
        fraction = (rows[a + 1:b, 0] - rows[a, 0]) / (rows[b, 0] - rows[a, 0])
        predicted = rows[a, 1:] + fraction[:, None] * (rows[b, 1:] - rows[a, 1:])
        errors = np.max(np.abs(rows[a + 1:b, 1:] - predicted), axis=1)
        index = int(np.argmax(errors))
        if errors[index] > tolerance + 1e-12:
            middle = a + 1 + index
            keep.add(middle)
            pending.extend(((a, middle), (middle, b)))
    return rows[sorted(keep)]


def render_profile(rows):
    profile = simplify(rows)
    entries = ',\n'.join('            [' + ', '.join(f'{value:.7f}' for value in row) + ']'
                          for row in profile)
    return '[\n' + entries + '\n        ]'


def render(root=ROOT):
    body_sections = []
    for body_part in ('leftarm', 'rightarm', 'leftleg', 'rightleg'):
        texture_sections = []
        for bp, texture, seed_site, min_v, max_v in PROFILES:
            if bp != body_part:
                continue
            rows = measured_limb_rows(bp, texture, seed_site, min_v, max_v, root)
            texture_sections.append(
                f'        case "\\acm_extended\\ui\\iv\\{texture}.paa": {{\n'
                f'        {render_profile(rows)}\n'
                f'        }};')
        body_sections.append(
            f'    case "{body_part}": {{\n'
            f'        switch (toLower _viewTexture) do {{\n' +
            '\n'.join(texture_sections) + '\n'
            f'            default {{[]}};\n'
            f'        }}\n'
            f'    }};')

    ej = render_profile(measured_ej_rows(root))
    body_sections.append(
        '    case "ej": {\n'
        '        switch (toLower _viewTexture) do {\n'
        f'            case "\\acm_extended\\ui\\iv\\{EJ_TEXTURE}.paa": {{\n'
        f'        {ej}\n'
        '            };\n'
        '            default {[]};\n'
        '        }\n'
        '    };')

    return '''/* Alpha-derived row bounds for IV arm, leg and EJ artwork, in body-canvas UV.
   [_bodyPart, _viewTexture, _v] call ACME_fnc_ivLimbBounds -> [leftU,rightU] or [].
   Generated by tools/generate_iv_limb_bounds.py from PAA alpha >= 128 at the 1024 mip.
   Limb profiles follow the worked limb from a catalog vein seed so the adjacent torso strip
   cannot become a valid puncture target. EJ uses the full opaque head/upper-torso silhouette.
   Returning [] means the point is outside the authored patient art at that canvas row.
   No state writes. */
params [["_bodyPart", "", [""]], ["_viewTexture", "", [""]], ["_v", -1, [0]]];
if (!finite _v) exitWith {[]};
private _profile = switch (toLower _bodyPart) do {
''' + '\n'.join(body_sections) + '''
    default {[]};
};
if (count _profile < 2) exitWith {[]};
// EJ punctures are intentionally limited to the lateral neck/trapezius window shown in the reference art:
// inferior to the chin and superior to the clavicles. The alpha silhouette still supplies the row's left/right
// edge, so face, upper chest and transparent canvas remain invalid even though they share the same background.
if ((toLower _bodyPart) == "ej" && {(_v < 0.420) || {_v > 0.590}}) exitWith {[]};
if (_v < ((_profile select 0) select 0) || {_v > ((_profile select ((count _profile) - 1)) select 0)}) exitWith {[]};
private _index = _profile findIf {(_x select 0) >= _v};
if (_index <= 0) exitWith {(_profile select 0) select [1,2]};
(_profile select (_index - 1)) params ["_v0", "_left0", "_right0"];
(_profile select _index) params ["_v1", "_left1", "_right1"];
private _fraction = (_v - _v0) / (_v1 - _v0);
[_left0 + (_left1 - _left0) * _fraction, _right0 + (_right1 - _right0) * _fraction]
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--write', action='store_true')
    group.add_argument('--check', action='store_true')
    args = parser.parse_args()
    content = render()
    if args.write:
        OUTPUT.write_text(content, encoding='utf-8')
    elif not OUTPUT.exists() or OUTPUT.read_text(encoding='utf-8') != content:
        raise SystemExit('IV artwork bounds differ from measured source; regenerate with --write')
    for body_part, texture, seed_site, min_v, max_v in PROFILES:
        rows = measured_limb_rows(body_part, texture, seed_site, min_v, max_v)
        profile = simplify(rows)
        error = max(np.max(np.abs(np.interp(rows[:, 0], profile[:, 0], profile[:, edge]) - rows[:, edge]))
                    for edge in (1, 2))
        print(f'{texture}: {len(profile)} vertices, {len(rows)} rows, max edge error {error:.7f} U')
    rows = measured_ej_rows()
    profile = simplify(rows)
    error = max(np.max(np.abs(np.interp(rows[:, 0], profile[:, 0], profile[:, edge]) - rows[:, edge]))
                for edge in (1, 2))
    print(f'{EJ_TEXTURE}: {len(profile)} vertices, {len(rows)} rows, max edge error {error:.7f} U')


if __name__ == '__main__':
    main()
