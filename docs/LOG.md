# Log

## Decisions (approved / rejected)
One line each, newest first. Dates are when Don decided; "reported 2026-10-24" means Don told Claude on that date and the decision date is not recorded.
- Reported 2026-10-24: playtest verdict "slow and boring, nothing felt good". Reason: battle effects and animation are missing.
- Reported 2026-10-24: battle effects pack (BattleFXPack) NOT connected yet. Reason: the chat building it isn't finished.
- Reported 2026-10-24: voxel model style APPROVED. Reason: it is the reference look. The orange lizard sample REJECTED as too close to an existing character.
- 2026-10-23: Wood follower turned OFF (Workspace attribute DevShowcase false). Reason: leftover from the old game.
- 2026-10-23: home base is an island APPROVED (built with plain parts). Reason: Don's choice for the home base map.
- 2026-10-23: Sell prompt on placed spirits KEPT. Reason: the economy is not designed yet.
- 2026-10-23: storm turned OFF (disabled, not deleted). Reason: the pivot dropped it.

## 2026-10-24: Working copy and studio-skills
Request: confirm both copies match, pick the working copy, clone studio-skills from skyler-lab if missing, list and vet every skill file before use.
- Both copies point to github.com/skyler-lab/spirit-battle and are at commit 4715bb5.
- Working copy is now RobloxStudio\spirit-battle; written in CLAUDE.md and STATE.md.
- Cloned skyler-lab/studio-skills to RobloxStudio\studio-skills. Same commit and text as RobloxStudio\skills. Five text files, no scripts, nothing that runs commands, touches credentials, deletes files or sends data.
- Files: CLAUDE.md, docs/STATE.md, docs/LOG.md. No game objects changed.
- Open: Don's OK before using any skill.

## 2026-10-24: Shared skills, decision rule, decision log
Request: pull, read the shared skills line and the skills, add the approvals/rejections rule, log past decisions, check STATE.md against Studio.
- Pulled Don's commit pointing CLAUDE.md at ../skills. From this folder ../skills does not exist; the skills are at C:\Users\80hsd\RobloxStudio\skills (ui-principles, model-building, studio-mcp-lessons, verification).
- Added section 9 (approvals and rejections) to CLAUDE.md and a Decisions list at the top of this log.
- Checked STATE.md against Studio and fixed stale lines.
- Files: CLAUDE.md, docs/LOG.md, docs/STATE.md. No game objects changed.
- Open: two copies of this repo exist (RobloxGames\SpiritBattle and RobloxStudio\spirit-battle).

## 2026-10-23: Wood follower off
Request: turn off the Wood follower by setting the DevShowcase workspace setting off, delete nothing.
- Set Workspace attribute DevShowcase = false. Play check: no follower or showcase spirits near the player.
- Files: docs. Game object changed: Workspace attribute DevShowcase. Don to press Ctrl+S.

## 2026-10-23: Island fixes
Request: spawn on the ground facing the shop, invisible walls round the test area, teleport pads at about 8 studs, disable the showcase Wood and Breeze. Leave signs, island edge and borders.
- Spawn moved down onto the path (0, 2.19, -70) facing the shop. TestArea.EdgeWalls added. Both teleport prompts: range 12, line of sight off. DevShowcase script disabled.
- Play test: spawn faces the shop; portal from 8.9 and return pad from 9.2 studs; test-area edge stops the player; no showcase spirits.
- Files: src/ServerScriptService/DevShowcase.meta.json, docs. Old spawn and prompt values saved on ServerStorage.BeforeHomeIslandR1.
- Open: Wood follower (FollowClient, DevShowcase attribute). Don to press Ctrl+S.

## 2026-10-23: Home base island built
Request: build the island from docs/HOME-BASE-PLAN.md with plain parts, keep plot/shop/spawn names and positions, stop players walking off, test the full route.
- Backed up to ServerStorage.BeforeHomeIslandR1; storm rings, hub and pillars moved to ServerStorage.StormMapHidden. Built Workspace.HomeIsland (island, sand edge, plaza, paths, plot borders, signs, 72 invisible walls); baseplate recoloured as water; portal moved to the east edge with a frame.
- Play test: spawn, shop, portal both ways, tame, place, cash, rejoin and edge walls all worked.
- Files: docs and images (the plan file was restored from history). Game objects as above; no scripts changed.
- Open: floating spawn pad, blank signs, no walls in the test area. Don to press Ctrl+S.

## 2026-10-23: Keep the Sell prompt
Request: keep the Sell prompt on placed spirits.
- Decision recorded in STATE.md; open task removed. No code or game objects changed.

## 2026-10-23: Placing tamed spirits on the base
Request: place owned spirits on base slots and take them back (server decides), earn cash by rarity, save and restore, list clashes with the old delivery code, test.
- Studio matched STATE.md. Added BaseAction RemoteFunction to BaseServer (place/take with server checks) and PlacedSpirits attribute; Place and Take back buttons in OwnedSpiritsClient.
- Play test: Pebble earned exactly 3/s; fake requests refused; TestRejoin kept cash and the placed spirit.
- Clashes listed in STATE.md (shared slots, old Sell prompt, mutations, FollowClient follower). Nothing deleted.
- Files: BaseServer, OwnedSpiritsClient, docs. Test switches cleared.
- Open: keep or drop the Sell prompt on placed spirits. Don to press Ctrl+S.

## 2026-10-23: Storm turned off
Request: turn the storm off completely (disable, don't delete), hide the storm HUD, check base, test area and battles, no knockout after battle.
- Disabled RoundServer, HealthServer, StormClient, ShieldClient. HealthHud hides siren, zone, health bar and bag (SHOW_STORM_HUD = false).
- Play test: base loads, test area clear and safe, battle works, no knockout 8s after the battle. SpiritServer now idles (waits for the round clock).
- Files: HealthHud, new .meta.json files in src/ recording the disabled scripts, docs. Game objects: 4 scripts Enabled = false.
- Open: decide whether to remove the storm for good. Don to press Ctrl+S.

## 2026-10-23: Camera back, real win and real tame
Request: move the battle camera back, win a real battle showing effects, tame with the normal roll, screenshots of each.
- Camera now further back, FOV 40; both spirits fully in view and closer in size.
- Real win vs Pebble: effects visible (small green shot), "Pebble was defeated!". Real tame: 68% roll succeeded, list showed Pebble.
- Found storm knocking the player out in the test area. Paused storm damage during battles (InBattle attribute); still knocked out after a battle ends. tameChance now 0 at 0 HP.
- Files: BattleClient, BattleServer, HealthServer, BattleData, docs.
- Open: storm vs test area needs Don's call. No faint effect on win. Don to press Ctrl+S.

## 2026-10-23: Battle camera framing
Request: fix the battle camera so both spirits are clearly visible, show a screenshot.
- Tuned live in a Wood vs Breeze battle, then wrote it into BattleClient.setCamera: behind and to the side of your spirit, scaled to the gap, FOV 52.
- Battle end restores the normal FOV. Fresh Play test matched the tuned shot. RUN tested for the first time: works.
- Files: BattleClient, docs.
- Open: win ending and visible effects still untested. Don to press Ctrl+S.

## 2026-10-23: Disable the FX Demo, re-check battle view
Request: disable the FX Demo LocalScript (don't delete it) and screenshot the real battle view.
- Set StarterPlayerScripts.Demo Enabled = false. The script is still there.
- Play test: the real battle now shows with no Demo arena or dialog. Wood fills the foreground; Pebble is a yellow-looking placeholder orb far away.
- Files: docs only. Game object changed: Demo.Enabled. Test attribute cleared.
- Open: battle camera framing; foe orb looks like a sun. Don to press Ctrl+S.

## 2026-10-23: Taming
Request: add TAME to the battle (works at 30% health or less, lower health = better chance), save tamed spirits, show an owned list, test fail, success and rejoin.
- Studio matched STATE.md before starting. Added tame numbers and tameChance to BattleData, the TAME turn to BattleServer, owned-spirit saving to BaseServer, a TAME button to BattleClient, new OwnedSpiritsClient list.
- Tested in Play with Studio-only hooks: fail used the turn, success said "You tamed Pebble!", list showed Pebble, still there after TestRejoin.
- Found: the enabled FX Demo's camera and dialog cover the real battle.
- Files: BattleData, BattleServer, BaseServer, BattleClient, OwnedSpiritsClient (new), docs. Workspace test attributes cleared.
- Open: disable the Demo (needs Don's OK); choose which owned spirit fights; the unforced random roll is untested. Don to press Ctrl+S.

## 2026-10-23: Docs for Codex and private GitHub repo
Request: add docs/STATE.md and docs/LOG.md in the vacuum game format, add the after-every-task rule to CLAUDE.md, check for secrets, create a private GitHub repo and push, explain how to connect Codex.
- Checked Studio: all 36 scripts still match src/ byte for byte. Found that StarterPlayerScripts.Demo (FX demo) is enabled and BattleClient does not use BattleFXPack yet; recorded both in STATE.md.
- Wrote docs/STATE.md and docs/LOG.md, added section 8 to CLAUDE.md.
- Secret scan of the repo: clean. Only the word "Secret" (a rarity) and the key file path in CLAUDE.md, no credentials.
- Files: CLAUDE.md, docs/STATE.md, docs/LOG.md. No game objects changed.
- Don created https://github.com/skyler-lab/spirit-battle (private) on github.com; GitHub CLI sign-in did not complete.
- Don added the remote and pushed main. Added a local permission rule so Claude can git push from here.
- Open: Codex still needs access to the repo.

## 2026-10-22: Project folder, git and script export
Request: read the handoff as CLAUDE.md, check the Studio connection, set up git, export all Place1 scripts as files, change no game code.
- Studio MCP connected to the open Place1.rbxl in Edit mode with no changes needed.
- Exported all 36 scripts from the live Studio session into src/ with Rojo naming, verified byte-identical.
- The handoff file was missing at first; Don created `C:\Users\80hsd\RobloxGames\SpiritBattle` with CLAUDE.md already in it, and the session moved there.
- Files: CLAUDE.md, README.md, .gitignore, .gitattributes, src/ (36 files). Git on main, one commit. No game objects changed.
- Open: Place1.rbxl on disk last saved 2026-10-20; Don to press Ctrl+S.
