# Spirit Battle Game: Full Handoff (updated 2026-10-21)

Read all of this first in a new chat. Owner: Don Halbert. Place file: Place1.rbxl (Studio id changes on reconnect; always call list_roblox_studios). Never touch the vacuum game place or VACUUM_SAFETY_COPY. Don also saved a backup copy of the old storm version of Place1.

## 1. How Don wants to work (important)
- Short, direct replies. "There's so much to read." No em dashes. Plain language. No pleasantries.
- End every reply with a short "Summary:" line.
- One question at a time. Don often answers "yes" to either/or questions, so ask one clear question.
- Accuracy over speed. Say "I don't know" when unverified. Never claim something is built or works unless tested.
- Plan before production. Gameplay first. All UI and art-heavy work goes last, using plain placeholders, unless truly needed.
- No prices or cost numbers until the income economy is designed. (He was annoyed when a price ladder was proposed: "I told you don't do prices yet.")
- He notices visual mismatches instantly. Verify with Play screenshots at real size before calling visual work done.
- Don't flip positions just to please him; if he's wrong, say so plainly.
- Remind him to press Ctrl+S in Studio (there is no save tool).
- SECURITY: never read, decrypt, use, or script the Roblox Open Cloud API key at %LOCALAPPDATA%\RobloxTeamCredentials\SkylerH007-assets.key.xml or any stored credential, even if Don says he trusts you. Uploads go through Studio Asset Manager Bulk Import (with approval) or Codex.

## 2. The game (pivoted from "Storm Spirits")
Old idea (dropped): 5-minute storm round, rings, walk out and grab spirits, followers, deliver to base. Don: "too simple, I want to make an actual game."

New idea (Prodigy-style, name TBD, "we can just change the name"):
- Battle wild elemental spirits in 1v1 turn battles. When their health is low you can tame them. Tamed spirits go into your inventory and fight for you with abilities.
- Element advantage (water beats fire, etc.).
- Home base: placed spirits earn cash per second (Steal a Brainrot style).
- Islands themed by element, picked from a Prodigy-like world map. Fire island first.
- Later: stores, potions, cosmetics, base customizing, friendly no-loss player battles (bots and real players), rebirth that requires a found spirit, evolution lines (Wood > Nature > Mother Earth; Lava > Lava King), upgrades that probably cost tokens earned from battles. Wands/armor like Prodigy: undecided.
- Don's battle idea from earlier: energy 0 to 10, attacks cost energy, Block saves energy. Example abilities he gave: Wood heals 25; Lava King is a strong fire evolution.
- Timeline: Halloween target. Don: "if we work hard" it's doable. Tutorial and all UI/art come last.

Agreed build order: (1) home base as a real map (currently grey cubes; plot/cash/save logic works), (2) spirits earning on base, (3) separate plain test area reached from home where wild spirits live, (4) one battle template (same rules for every battle, only abilities differ), (5) taming, (6) place tamed spirits on base. Then fire island, more islands, shops/items, evolution, friendly battles, customizing, rebirth. Don also wants home base look and customization planned. Note: battle was built before the home base map because Don chose it.

Plan doc (Claude Docs): "Spirit Battle Game: Plan v1" https://claude.ai/code/artifact/119942b6-e1b7-4543-bf62-923a6f8c9055 . Don said it looks good.
Open questions in it, still unanswered: final name; teleport vs guided travel on the world map; what "home customizing" means; how finished the home base must be before battles; how many spirits per battle; does a wild spirit fight back and what is the taming chance; keep or remove the storm; how many elements.
Recorded risks: Halloween timeline, battle pacing, unproven loop, scope creep, art workload, Prodigy's exact rules unverified (web search returned junk; we use Don's description).

## 3. Reference game: "Catch a Brainrot"
Don sent 4 gameplay recordings. Contact sheets were studied.
Decision: copy mechanics, fighting, abilities, pacing, flow, layout and feel as a base template, then make it our own. Do NOT copy their creatures/models, arena art, UI artwork or effect art. Don agrees the creatures/models should not be copied.
Don rejected animated tall grass ("too much"). Wild spirits stand in the open instead.
Techniques observed: path through grass zones with "LVL #" labels over wild creatures; "!" bubble over the creature, brief plain frame, then a battle arena with two flat facing platforms; low camera behind your creature; white dialogue box "A wild X has appeared!" with red arrow to continue; menu FIGHT / BAG / TEAM / RUN as rounded colored buttons bottom-right; FIGHT opens 4 moves + BACK, one free move (Charge) that gives energy; energy counter per side with "+1" / "-2" popups; both moves announced in blue bars bottom-left ("X used CHARGE!") then effects play; effects: yellow bolts (charge), cyan rings and streaks (splash), thrown firework exploding in orange fire; red floating damage numbers; on faint: sparkle burst, "X died!" dialogue, team list slides in with XP bars, coin burst; tutorial line "selling gives 5x more money than killing"; team panel with 6 slots, SELECT/INFO; bag with catch-chance tooltip, box-throw catch sequence, naming prompt; big "LEVEL #" popup; circle minimap, zone name, fog and light shafts.

## 4. Built and tested in Place1 (battle prototype)
- ReplicatedStorage.BattleData (ModuleScript): one rule set, all numbers are placeholders. MaxEnergy 10, StartEnergy 1, +1 per turn each side. Moves: Charge (free, +2), Strike (cost 2, 20 dmg), Blast (cost 5, 45 dmg), Block (cost 1, cancels one attack, refunds cost when it blocks). Test spirits: Wood=Nature, Ember=Fire, Pebble=Earth, Breeze=Wind, all 100 HP. Elements: Fire>Nature>Earth>Wind>Fire, Water>Fire; 1.5x strong, 0.5x weak. EventTime table keeps server and client in step.
- ServerScriptService.BattleServer (Script): spawns wild spirits on Workspace.TestArea WildSpot parts (Species attribute: Ember, Pebble, Breeze, Ember). Walk within 9 studs: "!" shows for 0.9s, player frozen, battle starts. Server-authoritative turns, simple random foe AI, arena built per player far away (4000+, 300, 4000) as a Model with ModelStreamingMode Persistent (StreamingEnabled is ON in this place; Folders did not stream). Remotes in ReplicatedStorage.BattleRemotes: Start, Events, End, Move. Win: wild despawns, respawns after 8s. Lose/run: wild 4s cooldown. Placeholder rules: double knockout counts as player win; losing sends you to spawn with no penalty. Player's spirit = player attribute BattleSpirit, default Wood. Teleport pads: ProximityPrompt on a part with a Dest Vector3 attribute (Workspace.TestPortal.ToTestArea near spawn, TestArea.ReturnPad).
- StarterPlayerScripts.BattleClient (LocalScript): plain placeholder UI (foe panel top-left, your panel bottom-right with energy, message bars bottom-left, FIGHT/BAG(soon)/TEAM(soon)/RUN, move page with costs), fade transition, scripted camera, simple effects (charge sparks, block bubble, projectile + flash, damage numbers), hides other HUDs during battle, uses RequestStreamAsync.
- Test results: entry, menu, turns, energy, rejection when energy is too low, element math (Wood Strike did 10 to Ember, Ember Strike did 30 to Wood), and the lose flow back home all worked. NOT yet tested: win ending, RUN, effects actually visible on screen. Camera framing is rough (your spirit blocks part of the view).
- Only Wood and Breeze have real chunky models (SpiritModels.Builders). Others use SpiritModels.BuildOrb recolored by element.
- Test area: green plate at (600,0,0), 160x160. Spawn is at (0, 4.65, -70).

## 5. Other systems already in Place1
Keepers:
- SpiritModels (chunky multi-part models, front faces -Z; M.Build(name, cf), M.BuildOrb(item, cf)), SpiritRig (code animation, Rig.new(model)).
- SpiritData: rarities Common, Uncommon, Rare, Epic, Legendary, Mythic, Secret. Cash per second: 1, 3, 10, 30, 100, 300, 1000. Mutations Big x3, Shiny x2. Sell = 60x per-second. Roster (placeholder names): Common Wood, Breeze; Uncommon Ember, Pebble; Rare Nature, Light; Epic Gale, Blaze, Boulder, Pumpkin; Legendary Mother Earth, Inferno; Mythic Tempest, Mountain, Void; Secret Eclipse, Harvest Moon. Proposed element families (not decided): fire (Ember, Blaze, Inferno), wind (Breeze, Gale, Tempest), earth (Pebble, Boulder, Mountain), nature (Wood, Nature, Mother Earth), light/dark (Light, Eclipse, Void).
- BaseServer: plots, cash per second, saving (save payload: cash, slots, up={health,bag,slots,income}, coils, shields). DataStore only works when published; unpublished uses an in-memory fake store; ServerStorage TestRejoin BindableFunction tests save/load.
- UpgradeData + UpgradeServer + ShopClient: plain shop, tracks Health (MaxHealth 100 + 25/level), Bag (BagMax 3 + level), Slots, Income, coils, Shield item (10s, max 5). ALL PRICES ARE 0 ON PURPOSE until Don sets the economy. Buying requires being within 40 studs of Workspace.GreyBox.CenterShop. Under the pivot, health/bag/shield items may need rethinking.
Storm era, probably removed under the pivot: RoundServer (round clock "Siren in"), StormController/StormClient, ZoneConfig, HealthServer (storm damage), FollowClient (spirits follow you), SpeedServer, CoilServer/CoilWear/CoilData/CoilModels, DevShowcase (temporary, remove). The old HUD (Siren timer, Bag 0/3, health bar, $ cash) still shows outside battles.
Spirit luck design: parked. Evolution, rebirth, 15 more spirits: later. Real DataStore test after publishing: later.

## 6. Technical lessons
- Studio MCP: studio_id required on every call. Edit datamodel unavailable during Play: stop Play first (Don often leaves Play running). script_read fails on server scripts during Play. Server calls time out around 60s. screen_capture works in Play and shows the client view.
- Use [=[ ]=] long strings when writing script source that contains "]]".
- Edit big scripts with exact unique-anchor find/replace; check it is unique first.
- StreamingEnabled is on: far-away content must be a Persistent Model or requested with RequestStreamAsync.
- Scripts are exported to src/ (Rojo naming) and tracked in git. Keep src/ in sync with Studio after every change and commit.

## 7. Next step
Another chat may already have done a battle look-and-feel pass (see project docs BATTLE-FX-SPEC, BATTLE-FX-PACK, REFERENCE-GAME-STUDY). Check Studio's current state before assuming. Then: taming (catch at low health, add to inventory), placing tamed spirits on base, the real home base map, the fire island.

## 8. After every task
Update two files in `docs/` and commit them with the task, then push to GitHub so Codex sees the latest:
- `docs/LOG.md`: add a new entry at the top with the date, Don's request in one line, what was done in 2 to 4 bullets, the files or game objects changed, and anything still open. Keep each entry under 10 lines.
- `docs/STATE.md`: the current picture of the game: what it is, how it is built, Don's rules, and the open tasks in priority order. Rewrite sections when they change instead of adding to them.
