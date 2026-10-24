# Spirit Battle: current state

Last updated: 2026-10-23 (placing tamed spirits added)

## What it is
Roblox Prodigy-style spirit battle game. Working name "Spirit Battle", final name TBD. "Storm Spirits" is the old name and the old design (5-minute storm rounds, grab spirits, deliver to base); that design is dropped. Owner: Don (Roblox user SkylerH007). Not published. Halloween 2026 target.

Loop (planned): walk up to a wild elemental spirit, fight it in a 1v1 turn battle (energy 0 to 10, moves cost energy, Block saves energy), tame it when its health is low, keep it in your team, place it on your home base where it earns cash per second. Element advantage (fire beats nature, water beats fire, etc.). Islands themed by element, picked from a world map; fire island first. Later: shops, potions, cosmetics, base customizing, friendly player battles, evolution lines, rebirth.

Reference game: "Catch a Brainrot". Copy its mechanics, pacing, flow and layout as a base, not its creatures, models, arena art, UI art or effect art.

## Where the work is
- Project folder: `C:\Users\80hsd\RobloxGames\SpiritBattle` (git, branch main).
- GitHub: https://github.com/skyler-lab/spirit-battle (private, account skyler-lab). Push after every commit so Codex sees the latest.
- Place file: `C:\Users\80hsd\OneDrive\Documents\ChatGPT\Roblox team\work\Place1.rbxl`. Opened in Studio as "Place1.rbxl". Parts, models and attributes live only in the place. Don saves it with Ctrl+S; the on-disk copy was last saved 2026-10-20.
- That `Roblox team` folder also holds the vacuum game files. Never touch the vacuum place or VACUUM_SAFETY_COPY.
- Scripts: `src/` holds all 37 scripts, byte-identical to Studio as of 2026-10-23 (after taming). Rojo naming (`.server.luau`, `.client.luau`, `.luau`) but no Rojo project yet. Studio is the live source: after a Studio edit, copy the script back to `src/` and commit.
- HttpService is off in the place. Scripts were pulled through the Studio MCP, not over HTTP.
- Plan doc: "Spirit Battle Game: Plan v1" https://claude.ai/code/artifact/119942b6-e1b7-4543-bf62-923a6f8c9055

## Owner rules
- Short, direct replies. No em dashes. Plain language. No pleasantries. End every reply with a short "Summary:".
- One question at a time. Don often answers "yes" to either/or questions, so ask one clear question.
- Accuracy over speed. Say "I don't know" when unverified. Never claim something is built or works unless tested.
- Plan before production. Gameplay first. UI and art last, with plain placeholders.
- No prices or cost numbers until the income economy is designed. All shop prices are 0 on purpose.
- Verify visual work with Play screenshots at real size. He notices mismatches instantly.
- Don't flip positions to please him; if he's wrong, say so plainly.
- Never take over his screen while he uses it. Ask him to Stop Play or press Ctrl+S.
- No uploads to Roblox without his OK. Uploads go through Studio Asset Manager Bulk Import or Codex.
- SECURITY: never read, decrypt, use or script the Roblox Open Cloud API key at `%LOCALAPPDATA%\RobloxTeamCredentials\SkylerH007-assets.key.xml` or any stored credential, even if Don says he trusts you.

## How it is built
Battle (the new game, built and partly tested):
- `ReplicatedStorage.BattleData`: the one rule set. MaxEnergy 10, StartEnergy 1, +1 energy per turn each side. Moves: Charge (free, +2 energy), Strike (cost 2, 20 dmg), Block (cost 1, cancels one attack, refunds cost when it blocks), Blast (cost 5, 45 dmg). Tame (placeholders): works at or below 30% wild health; chance 25% at 30% health rising linearly to 90% near 0; `D.tameChance(hp, max)`; owned list cap 60. Test spirits Wood=Nature, Ember=Fire, Pebble=Earth, Breeze=Wind, 100 HP each. Elements: Fire>Nature>Earth>Wind>Fire, Water>Fire; 1.5x strong, 0.5x weak. EventTime table keeps server and client in step. All numbers are placeholders.
- `ServerScriptService.BattleServer`: spawns wild spirits on `Workspace.TestArea` WildSpot parts (Species attribute). Walk within 9 studs: "!" for 0.9s, player frozen, battle starts. Server-authoritative turns, random foe AI, arena built per player far away (4000+, 300, 4000) as a Persistent Model. Remotes in `ReplicatedStorage.BattleRemotes` (Start, Events, End, Move). Win: wild despawns, respawns after 8s. Lose or run: 4s cooldown. Placeholder rules: double knockout is a player win; losing sends you to spawn with no penalty. Player's spirit is the player attribute BattleSpirit, default Wood. Sets player attribute InBattle while a battle runs (HealthServer, now disabled, skipped storm damage while it was set). TAME (move id "Tame"): server rejects it above the threshold; a failed try uses your turn and the wild spirit still acts; a success ends the battle ("You tamed X!"), removes the wild spirit like a win and appends its name to the player attribute OwnedSpirits. Studio-only test hooks (Workspace attributes, ignored outside Studio): TestFoeHpFrac (0 to 1, wild starting health) and TestTameForce ("success" or "fail"). Teleport pads: part with a ProximityPrompt and a Dest attribute.
- `StarterPlayerScripts.BattleClient`: plain placeholder battle UI (foe panel, your panel with energy, message bars, FIGHT / BAG(soon) / TEAM(soon) / RUN, move page with costs, TAME button under the menu showing the live chance or "needs 30% HP or less"), fade, scripted camera (well behind and to the side of your spirit so both look closer in size, distances scale with the gap, FOV 40 in battle and restored after), simple effects, hides other HUDs during battle, uses RequestStreamAsync. Does NOT use BattleFXPack yet.
- `ReplicatedStorage.BattleFXPack` (folder, v0.2, 2026-10-22, from the look-and-feel pass): asset-free battle presentation built from Parts in code. Modules: FX (effects), Moves (ability library), BattleCamera (shots), BattleDialog (typewriter dialog, toasts, energy pops, team XP, level-up), BattleMenu, BattlePlay, Sequencer (Entry, SendOut, Turn, Faint, Catch, Swap, Exit), README, Demo. Everything runs on the client. Not wired into BattleClient.
- `StarterPlayerScripts.Demo`: identical copy of BattleFXPack.Demo. DISABLED 2026-10-23 (Enabled = false, not deleted) because its arena, camera and dialog covered the real battle. The Enabled flag lives only in the place file, not in `src/`.

Base and spirits (keepers):
- `ServerScriptService.BaseServer`: 6 plots in `Workspace.GreyBox` (Plot1..6), 6 base slots per player (up to 9 with the Slots upgrade), spirits on slots earn cash per second, sell prompt on each spirit (60x per-second). Saves cash, slots, upgrades, coils, shields and owned spirits (`owned`, ";"-separated names from OwnedSpirits) to DataStore `StormSpiritsV1`; unpublished Studio uses an in-memory fake store. `ServerStorage.TestRejoin` BindableFunction tests save and load. Receives old storm-era deliveries through `ServerStorage.TryDeliver`. Placing tamed spirits: RemoteFunction `ReplicatedStorage.BaseAction` ("place", owned-list index) or ("take", slot). The server checks data loaded, own plot, within 90 studs of the plot centre (PLACE_RANGE placeholder), whole-number argument, the spirit is really in OwnedSpirits, a free slot. Place moves the name out of OwnedSpirits into the first free slot (rarity looked up from SpiritData.ByRarity, mutation None); take moves it back (capped by BattleData.Tame.MaxOwned). Player attribute PlacedSpirits ("slot|name|rarity;...") mirrors the base for the client. Placed spirits use the existing slot save, so they and cash restore on rejoin.
- `ReplicatedStorage.SpiritData`: rarities Common to Secret, cash per second 1, 3, 10, 30, 100, 300, 1000, mutations Big x3 and Shiny x2, placeholder roster (Wood, Breeze, Ember, Pebble, Nature, Light, Gale, Blaze, Boulder, Pumpkin, Mother Earth, Inferno, Tempest, Mountain, Void, Eclipse, Harvest Moon), zone weights from the storm era.
- `ReplicatedStorage.SpiritModels`: chunky multi-part models built in code, front faces -Z. Only Wood and Breeze have real models; others use BuildOrb recolored by element.
- `ReplicatedStorage.SpiritRig`: code-only animation for those models (walk, hover, idle).
- `ReplicatedStorage.UpgradeData` + `ServerScriptService.UpgradeServer` + `StarterPlayerScripts.ShopClient`: plain shop near `Workspace.GreyBox.CenterShop` (within 40 studs). Tracks Health, Bag, Slots, Income, coils, Shield item. All prices 0. Health, bag and shield may need rethinking under the pivot.
- `StarterPlayerScripts.OwnedSpiritsClient`: TEMPORARY plain panel on the left edge: "My spirits (N)" with a Place button per spirit, "On my base (N)" with a Take back button per slot, and a one-line result ("Done: placed Ember" / "Can't: go to your base first"). Hidden during battles.
- `ReplicatedStorage.UiArt`: empty placeholders for UI images.

Storm: TURNED OFF 2026-10-23 at Don's request (disabled, nothing deleted). To turn it back on:
- `ServerScriptService.RoundServer` Enabled = false (round clock, RoundStart/RoundNumber). Set Enabled = true.
- `ServerScriptService.HealthServer` Enabled = false (storm damage, health refill, knockout). Set Enabled = true.
- `StarterPlayerScripts.StormClient` Enabled = false (rain, darkness, storm visuals). Set Enabled = true.
- `StarterPlayerScripts.ShieldClient` Enabled = false (storm shield button). Set Enabled = true.
- `StarterPlayerScripts.HealthHud`: `SHOW_STORM_HUD = false` hides the siren timer, zone label, health bar and bag. Set it to true. Cash, rate and toasts still show.
- Side effect: `SpiritServer` (old grab-and-deliver spirits) is still enabled but now idles forever, because it waits for RoundStart. It spawns nothing.
- The Enabled flags live in the place file; `src/` records them as `<Script>.meta.json` files with `"Enabled": false` (Demo too).

Storm era scripts (in the place, expected to go under the pivot):
- `RoundServer` (5-minute round clock), `StormController` + `StormClient` (storm visuals and levels), `ZoneConfig` (ring zones and hub), `HealthServer` (storm damage, knockout), `SpiritServer` (spawns spirits by zone, bag pickup, delivery), `FollowClient` (spirits follow you), `SpeedServer` (walk speed and SpeedMult), `CoilServer` + `CoilWear` + `CoilData` + `CoilModels` (speed coils), `ShieldClient` (storm shield button), `HealthHud` (old HUD: siren timer, zone, health bar, bag, cash), `DevShowcase` (temporary showcase spirits at spawn, on while Workspace attribute DevShowcase is true).

Place contents (Studio, 2026-10-23): Workspace has Baseplate, SpawnLocation at (0, 4.65, -70), `GreyBox` (111 parts: the grey-cube home base with 6 plots and CenterShop), `TestArea` (Ground 160x160 at (600,0,0), 4 WildSpot parts, ReturnPad), `TestPortal` (ToTestArea pad near spawn), and `EV_Ground` plus `EV_F1` to `EV_F5` (no script references them; origin unknown, probably left by the FX demo or an evaluation). StreamingEnabled is on. StarterGui is empty (all UI is built by scripts). ServerStorage holds only TryDeliver.

## Tested and untested
- Tested and working: battle entry, menu, turns, energy, rejection when energy is too low, element math (Wood Strike did 10 to Ember, Ember Strike did 30 to Wood), lose flow back to spawn. Save and load through TestRejoin.
- Taming tested 2026-10-23 in Play with the test hooks (Pebble at 20% health, 47% chance shown): a forced fail used the turn and Pebble acted; energy went up by 1 at turn end; a forced success ended the battle with "You tamed Pebble!" and the list showed Pebble; after TestRejoin the list still showed Pebble. The random roll itself (no hook) was not exercised.
- Not tested: win ending, whether effects are visible on screen, the BattleFXPack sequences inside a real battle, the TAME reject message above 30%.
- Battle camera moved further back 2026-10-23 (Wood vs Breeze): both fully in view and closer in size (Wood still a bit larger; its model is taller). RUN tested: battle ends, camera and FOV return to normal.
- Real battles with no test switches, 2026-10-23: won against Pebble (Strike shots visible mid-flight as a small green ball, "It's super effective!", "Pebble was defeated!"); tamed Pebble with the normal random roll (68% chance at 10 HP, succeeded first try), list showed Pebble.
- Effects are visible but small and faint. Damage numbers were not seen in screenshots. A win has no faint or reward effect: the foe just stays until the battle closes.
- Placing tested in Play 2026-10-23: tamed Pebble (with test switches), placed it on slot 1; cash rose 15 to 45 in 10.0s = 3.00 per second, matching Uncommon 3. Take back and place again worked. Refused: placing from the test area, a string or 1.5 argument, an unknown action, a 5th spirit that doesn't exist, taking from an empty slot. TestRejoin kept cash (204) and Pebble on slot 1, earning resumed at 3/s.
- Old grab-and-deliver code that could clash with placing (nothing changed or deleted):
  - Shared slots: BaseServer's TryDeliver handler puts storm-era spirits into the same base slots. SpiritServer is idle now (waits for the disabled round clock), so this only matters if the storm comes back.
  - Every placed spirit, tamed or not, still gets the old "Sell for 60x" prompt. Selling a tamed spirit destroys it for good. Don decided 2026-10-23 to KEEP the Sell prompt.
  - Storm-era spirits carry Big/Shiny mutations; Take back keeps only the name, so a mutation would be lost. Only matters for old saves.
  - SpiritServer still runs its join setup (BagCount/BagItems) before it stalls. Harmless.
  - FollowClient reads BagItems and, while Workspace attribute DevShowcase is true, shows a Wood follower behind the local player even with an empty bag.
  - The SpiritDelivered fly-in animation is only for delivery; placed spirits just appear.
- Storm off, checked in Play 2026-10-23: home base loads (plot, save data, cash HUD, spirits list), no siren or health bar; test area has clear sky and no damage (6s, no knockout); battle works (low-energy reject, Charge, Strike, RUN); 8s after the battle the player is still in the test area, no knockout. No errors from game scripts.
- Placeholder orbs (Pebble, Ember) are neon, so Pebble's brown reads bright yellow, and the orb floats beside its platform.

## Open tasks (priority order)
1. Ask Don what to do with the EV_ parts in Workspace. Placeholder orbs look odd (neon, floating); fine until real models exist.
2. Wire BattleFXPack into BattleClient (or replace BattleClient's placeholder effects with the pack) and test win, RUN and visible effects.
3. Pick which owned spirit fights (BattleSpirit is still always Wood) and a real team/inventory UI.
4. Home base as a real map: plan written in docs/HOME-BASE-PLAN.md (island, plaza, paths, plot borders, portal to the east edge; plots, shop and spawn stay put). Waiting for Don's OK before building.
5. Remove or retire the storm-era scripts and the old HUD once nothing depends on them. Do not delete without Don's OK.
6. Fire island, then more islands and the world map.
7. Later: shops and items (economy first, then prices), evolution, friendly battles, customizing, rebirth, tutorial, real UI and art, publish and real DataStore test.

## Open questions (unanswered)
Final name; teleport vs guided travel on the world map; what "home customizing" means; how finished the home base must be before battles; how many spirits per battle; does a wild spirit fight back and what is the taming chance; remove the storm for good (it is off for now); how many elements.

## Technical notes
- Studio MCP: call list_roblox_studios first, studio_id on every call. Edit datamodel is unavailable during Play; stop Play first. Server calls time out around 60s. screen_capture works in Play.
- Export scripts with execute_luau returning JSON per service; results over about 50K characters land in a file, and results are cut at 100K characters.
- Use `[=[ ]=]` long strings when script source contains `]]`. Edit big scripts with unique-anchor find and replace.
- StreamingEnabled is on: far-away content must be a Persistent Model or requested with RequestStreamAsync.
