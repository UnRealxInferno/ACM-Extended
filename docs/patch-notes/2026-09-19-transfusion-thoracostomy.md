# ACM Extended 1.2.1-rc1: transfusion and thoracostomy fixes

## Changes
- Removed the separate Hardcore Transfusion setting. The current bag preparation, Y-line, flush, infusion, and access-site workflows are standard.
- Removed the outdated 250 mL saline-bag requirement from the setting and tubing description. Y sets still pair blood with compatible saline and use the existing configured flush volume.
- Kept the existing standard calcium/citrate and hypothermic coagulation values. Old exported hardcore transfusion values no longer select an alternate model.
- Fixed catheter/IO clicks passing the wrong argument shape to the circulation UI state writer. Clicks now update the exact selected access, header, and bag lists together.
- Restored the standard Arma button click sound for access-site hotspots.
- Removed the top-left IV/IO toggle. The inventory-source switch remains available.
- Added removal and burping of a chest seal over an existing finger-thoracostomy tract.
- Added repeat finger sweeps without consuming another thoracostomy kit.
- Routed surgical aftercare through the patient owner with clinical-epoch, side, tube, and permission checks. Other wound seals and an opposite-side chest tube are preserved.

## Controls
Open Adjust Thoracostomy on the treated side and put down the held tool.
- RMB on the surgical seal removes it.
- Scroll over the seal to lift a corner. Five notches perform the burp; reverse the wheel to lay it down.
- After removing the seal, select the finger and click the existing tract to repeat the sweep. A chest tube can then be placed through the open tract.

In the existing gameplay model, sealing the surgical tract closes its drainage route. A remaining internal leak can cause pressure to build again. Removing the seal restores the open tract; a burp gives temporary pressure relief while leaving the dressing in place.

## Validation
Added 12 source-contract checks, including the exact UI argument shape, owner routing, selected-side writes, kit-free repeat-sweep path, control wiring, function registration, and delimiter balance.
The local execution runner became unavailable during this task. HEMTT, pytest, Windows PBO compilation, and Arma multiplayer behavior must be verified after pulling this patch. Static source validation is not an in-game test.

## In-game checks
1. Select different IV sites on one limb, another limb, an EJ, and an IO. Confirm the header, selected artwork, bag lists, and next bag action all use the clicked site and play the button click.
2. Confirm the route-toggle button is gone and inventory switching still works.
3. Prepare a single blood set without a saline bag. Prepare a Y set with a supported small saline bag and confirm the existing flush-volume rule applies.
4. Complete finger thoracostomy, seal it, close/reopen Adjust Thoracostomy, burp it, remove the seal, repeat the sweep without another kit, and insert a chest tube.
5. Repeat aftercare on a remote-owned casualty; confirm unrelated chest seals and the opposite-side tube remain unchanged.
