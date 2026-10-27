# Battle feel plan (2026-10-27)

Status: BUILT 2026-10-27 (Don's OK given the same day). Tested in Play; screenshots in docs/img/battle-feel/. Waiting for Don's feel check.
Changes found while testing: placeholder orbs sit on the platform in the arena (they floated 7 studs up, so hits missed them); a gentle white screen flash instead of the pack's ScreenFlash (it washed the view out); the tame tint is light instead of dark red; orbs drop instead of tipping over (a ball looks the same tipped over).

## Goal
Battles look and feel alive, using the effects pack already in the place (ReplicatedStorage.BattleFXPack). The server rules stay the same: same moves, damage, energy and taming.

## What the pack has (read from src, 2026-10-27)
- Effects: charge bolts, hit flash, damage numbers, send-out, recall, faint tip-over, vanish, puff, sparkle, star burst, catch box with wobbles, screen flash, camera punch.
- Ready-made moves: Charge, Shield, Shoot, Sword (lunge), Bomb (arcing throw). Also Bite, Splash, Firework.
- Camera shots: intro on the wild spirit, close-up, behind your spirit, main view, zoom.
- Text: typewriter dialog box, "X used Y!" toasts, energy "+1" / "-2" pops.
- Sequences that chain these: Entry, SendOut, Turn, Faint, Catch, Exit.
- It is not connected to the real battle yet. It runs only on the player's screen, so the server stays in charge.

## Steps (each one tested in Play with real clicks and shown to Don with screenshots before the next)
1. **Connect the pack.** BattleClient uses the pack for the battle start, each turn, and the end. Keep the old path behind an on/off switch so it can be turned back.
2. **Our moves, our look.** Map our 4 moves to pack effects, coloured by the spirit's element:
   - Charge: charge bolts.
   - Strike: your spirit lunges forward and hits.
   - Blast: an arcing shot with a flash and camera punch.
   - Block: a bubble shield that pops when hit.
   Bite, Splash and Firework are left out because they copy the reference game's effect art, which Don said not to copy.
3. **Hits that land.** Big damage numbers, a white hit flash, the target jolts back, a camera punch on big hits, and a "Super effective!" pop.
4. **Real endings.**
   - Win: the wild spirit tips over, fades and gives a sparkle burst. No coins, because there is no economy yet.
   - Tame: the catch sequence (box flies, wobbles, star burst or "it got out").
   - Lose: your spirit tips over, then fade out.
5. **Spirits feel alive.** A small idle bob and breathing, using the existing SpiritRig. The intro camera circles the wild spirit before your spirit is sent out.
6. **Keep server and client in step.** The server currently waits a fixed time per event (BattleData.EventTime). Animations now take their own time, so both sides read one shared table of times per move in BattleData. The goal is a turn under about 3.5 seconds. It is about 2.5 now, and the animations will add some time back.

## Not in this pass
- **Menu buttons:** stay the current plain ones. Your rule is that UI comes last, and the pack's menu is placeholder styling too.
- **Different abilities per spirit:** this is a game design job and its own task. It's the other half of "battles are not good".
- **Sound:** needs sound uploads, and uploads need your OK.
- **Real spirit models:** placeholder orbs stay for now.
- **Team swapping and rewards:** later.

## Risks
- The pack is marked v0.2, and its chat may not have finished it. Some parts may break inside the real battle. I would find that out in step 1.
- Turns get a little longer again because the animations take time.
- StreamingEnabled: effects are made far away at the arena, so they need the arena to stay loaded. It already is, because the arena is a Persistent model.

## How it is checked
Real-size Play screenshots and real mouse clicks for each step, turn times measured, and no errors in the output. Statuses as the verification skill asks: source committed, Studio check, and Don's approval.
