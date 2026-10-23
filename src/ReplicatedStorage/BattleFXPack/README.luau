--[[
BattleFXPack  (v0.2, 2026-10-22)

A portable, asset-free battle presentation pack: attack VFX, hit feedback, send-out / recall / faint
animations, catch sequence, coin rewards, scripted camera, dialog strip, move toasts, team XP list,
level-up popup, and a sequencer that chains them. Built to mimic the timing and techniques of the
reference creature-battle game; all geometry is made from Parts in code, so it drops into any place.

INSTALL
  1. Put the BattleFXPack folder in ReplicatedStorage.
  2. From a LocalScript:
       local pack = game.ReplicatedStorage.BattleFXPack
       local Seq = require(pack.Sequencer)
       Seq.Setup({ playerPlatform = <Part>, enemyPlatform = <Part>, avatarRoot = <HumanoidRootPart>,
                   energyPillPlayer = <GuiObject?>, energyPillEnemy = <GuiObject?>, coinPill = <GuiObject?> })
  3. Call the sequences from your battle client when the server tells you what happened:
       Seq.Entry(wildModel, "A wild X has appeared!")
       local charge = Seq.SendOut(myModel)
       Seq.Turn({ {attacker=, target=, move="Bite", damage=17, cost=3, side="player"}, {...} })
       Seq.Faint(deadModel, "X died!", teamRows, coinCount, onCoin)
       Seq.Catch(avatarModel, targetModel, success, name)
       Seq.Swap(oldModel, newModel)
       Seq.Exit()

DEMO
  Enable the Demo LocalScript (set Disabled = false, or drop it in StarterPlayerScripts) and press Play.
  It builds its own arena far away and runs every sequence once, then cleans up.

MODULES
  FX            individual effects (Charge bolts, Splash, Bite, Firework, HitFlash, DamageNumber, Ghost,
                SendOut, Recall, Faint, Vanish, Puff, CoinBurst, CatchBox, BoxWobble, StarBurst, Starburst,
                SparkleRain, Sparkle, ScreenFlash, ScreenTint, Blur, Fade, Cleanup)
  Moves         ability library: name -> {cost, kind, play(ctx)}. Add moves here.
  BattleCamera  shots: Main, Intro, PlayerCloseup, BehindPlayer, EnemyPlatform, Zoom, Punch, Release
  BattleDialog  Say (typewriter + cursor), Ask, Toast, EnergyPop, EnergyCost, TeamXP, LevelUp
  Sequencer     Entry, SendOut, Turn, Faint, Catch, Swap, Exit

VERIFIED VS UNVERIFIED
  Matched to footage: Charge, Splash, Bite, Firework, send-out ghost, recall sparkle, faint tip-over,
  vanish + coin burst, catch box (red tint, slow arc, 3 wobbles, star burst), dialog cursor blink,
  toast stacking, team XP slide, level-up pop, camera cuts and drift, screen flash on big hits.
  Built from the same ingredients but not in footage: Shoot, Sword, Bomb, Shield.

NOTES
  - Models need a PrimaryPart (or any BasePart) and should face -Z or +Z consistently; the pack uses
    GetBoundingBox so odd rigs still work.
  - All UI here is plain placeholder styling. Replace colors/fonts/images with real art later; keep the
    motion and timing.
  - Effects parent to workspace.BattleFX; lighting effects are named BattleFX_*; FX.Cleanup removes all.
  - Everything runs on the client. Your server stays authoritative; it just tells the client what to play.
]]
return {version = "0.1"}
