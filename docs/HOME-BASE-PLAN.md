# Home base: plan for a real map

Written 2026-10-23. BUILT 2026-10-23 with plain parts (see STATE.md for what was built and what looks off). Top-down after building: `img/base-island-top.jpg`. Goal: turn the grey-box hub into a simple, readable home island that is fast to build. Gameplay first, art later.

Images: `img/base-current-top.jpg` (current base from above) and `img/base-plan-sketch.svg` (proposed layout, same view: up = -Z, right = +X).

## What is there now
- A round sage-green Hub disk (430 across) with 6 grey plot pads (80 x 90) in a ring 140 studs from the centre.
- The yellow CenterShop pad (50 x 50) in the middle. Spawn at (0, 5, -70) between the shop and Plot 4. The test-area portal sits right next to spawn at (14, 6, -70).
- Storm leftovers around it: five coloured ring zones (Zone1 to Zone5, out to 1850 across) and 98 grey pillars.
- The test area is a separate green plate at (600, 0, 0), reached by the portal. Its return pad drops you near spawn.

## Proposed layout
1. **Island:** one round grass island the size of the current hub (about 440 across), with a thin sand edge. The big baseplate around it becomes water-coloured.
2. **Plaza:** a round sand plaza (about 115 across) around the shop, with 6 straight paths out to the plots.
3. **Plots:** keep all 6 exactly where they are, so the slot and save code needs no change. Add a low border around each and a sign post where its path arrives.
4. **Shop:** stays in the centre. Plain stall shape later; the pad and its 40-stud buy range stay.
5. **Spawn:** stays at (0, 5, -70), on the plaza edge facing the shop.
6. **Portal:** moves from beside spawn to the east edge of the island at about (205, 6, 0), at the end of its own path between Plot 2 and Plot 3. The test area's return pad is pointed back to just inside the portal.
7. **Storm leftovers:** the ring zones and pillars are moved into a hidden folder (not deleted), so the island stands on its own.

## Stays plain for now
Flat coloured parts only: grass, sand, plot borders, a plain shop block, a glowing portal frame, plain sign boards using the existing billboard text. The slot circles and placeholder spirit orbs stay as they are.

## Art needed later
- Island ground (terrain grass, sand and water, or textured parts).
- Shop stall or building, portal arch, plot fences and sign posts.
- Trees, rocks and flowers around the edge (free Creator Store models, checked for scripts first).
- Real spirit models for everything except Wood and Breeze.
- Skybox and lighting mood, then plot customizing (what "home customizing" means is still an open question).

## Build steps (one short session)
1. Back up GreyBox to a ServerStorage folder named `BeforeHomeIslandR1`.
2. Hide the storm rings and pillars in a ServerStorage folder.
3. Add the island, sand edge and water colour.
4. Add the plaza and 7 paths.
5. Add plot borders and sign posts.
6. Move the portal and update the return pad's Dest.
7. Play test: spawn, shop range, placing a spirit, portal both ways, a battle. Screenshots from above and at play height.

Nothing in BaseServer, BattleServer or the save needs to change, because the plots, shop and spawn keep their positions.

Keep `Plot1` to `Plot6` and `CenterShop` inside `Workspace.GreyBox` with the same names: BaseServer, UpgradeServer, CoilServer and ShopClient find them there. Only the Zone rings, Hub disk and Pillars move to the hidden folder (the idle SpiritServer only uses the Pillar name to skip pillars).
