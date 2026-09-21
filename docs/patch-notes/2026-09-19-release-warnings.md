# ACM Extended 1.2.2: release check corrections

This is a historical development record. The drag handle subsequently remained on `dev` and was removed from `main`; see [release drag handle removal](2026-09-19-release-drag-removal.md). The syringe UI scaling fix remains in the public release.

## Changes

- Fixed two drag handle condition errors that could interrupt attachment and release checks.
- Fixed a missing UI scaling definition when changing syringe size in the Narc Box.
- Added a regression test that runs the actual HEMTT parser and linter with warnings treated as errors. The test also checks the diagnostics text because successful packaging alone does not establish that the source is clean.

## Causes

The two compound conditions in `fn_dragHandleStartMedic.sqf` did not enclose the entire Boolean expression in parentheses. HEMTT consequently parsed `if` before the following `||` clauses, reporting five L-S12 type warnings. Both conditions now group their full expressions before `exitWith`.

`fn_skApplySize.sqf` included the syringe geometry definitions without first including the circulation component header. That left `NORMALIZE_UISCALE` unexpanded in the plunger geometry and produced 28 L-S17 warnings. The function now uses the same header order as ACM's native syringe functions, so the existing UI scale formula expands correctly for all four syringe sizes.

## Validation

- Reproduced all 33 warnings with HEMTT 1.21.0 before editing.
- After the fixes, `hemtt check --error-on-all --no-color` passed across 16 addon configs, 1,591 SQF files and 12 stringtables with no code diagnostics.
- All 16 focused tests passed: the strict HEMTT check, 13 drag handle tests and two Narc Box size/plunger tests.
- HEMTT used its bundled Arma command metadata because its wiki refresh was unavailable. This was an environment message, not a remaining source diagnostic.

The uploaded Windows log confirms that release packaging completed and produced `ACM-1.2.2.0.zip` before these corrections. Pull and rebuild to include them. The corrected package has not been tested in Arma; verify drag attachment, release and syringe size changes in game.

Version remains 1.2.2, with build metadata 1.2.2.0.
