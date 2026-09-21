# ACM Extended 1.2.2: remove the release drag handle

## Changes

The drag handle still failed to move casualties reliably in game. It has been removed from the public release on `main` and retained on `dev` for further work. Public releases must now be built from `main`.

- Removed Attach Drag Handle and Release Drag Handle from the medical menu, patient interactions and self interactions.
- Removed the handle's function registrations, startup hooks, owner dispatch cases, rope creation, force driver, movement restrictions and cleanup handlers from the release source.
- Removed handle state checks from seizure, patient settling, training patient and Semi-Fowler's handlers. The existing seizure and transport guards remain.
- Preserved standard ACE dragging and carrying, Get Up actions, head elevation transport handling and the rest of the 1.2.2 fixes.
- Retained the shared ACE fast roping dependency because IV bag and training patient helpers still use it.
- Updated the cumulative and Discord notes so the public release no longer advertises the experimental handle.

Version remains 1.2.2, with build metadata 1.2.2.0. The development branch retains its existing handle implementation.

## Validation

All 31 focused tests passed. These cover strict HEMTT 1.21.0 diagnostics, complete addon config compilation, absence of handle entry points and runtime code, preservation of shared transport dependencies, patient motion and seizure contracts, debug seizure routing, chest interactions and auscultation contracts.

The source scan found no remaining drag handle references in shipping SQF, CPP or HPP files. Shared rope helpers, normal ACE drag/carry overrides and Get Up interactions remain present. HEMTT used its bundled Arma command metadata because its wiki refresh was unavailable.

The updated package still needs a Windows release build and verification in Arma. Check that both Attach and Release Drag Handle are absent, then confirm normal ACE dragging/carrying and Get Up with AI and player patients, including a patient owned by another machine.

Use the PowerShell commands in the [repository README](../../README.md) to switch to `main`, pull and run `hemtt release`.
