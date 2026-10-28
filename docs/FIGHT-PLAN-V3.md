# Fight plan v3 (2026-10-28)

Status: PLAN ONLY. Nothing gets built until Don approves each step.

## Why the last three tries failed
- I kept adding effects on top of placeholder balls and judged it by screenshots, not by how it plays.
- I changed rules, camera, effects and timing all at once, so there was no way to tell what helped.
- Some things I can't do well alone: creature models and animation art made in code look like blocks. Sound needs real audio assets.

## What I can and can't do
- Can do well: battle rules, turns, the wild spirit's choices, timing, camera, hit feel (shake, freeze frame, knockback), menus that work, testing.
- Can do only with help or your OK: real creature models (Roblox AI mesh tool in Studio, free Toolbox models, or someone making them), sound (Roblox audio library, needs your OK per sound), styled UI art.
- Can't promise: that it looks like the reference game. Their creatures are made by artists.

## Rules for working
- One small step at a time. You play it before the next step starts.
- Each step changes only one layer: rules, feel, or looks.
- A step is done when you say it is better, not when I say so.

## Art rules (Don, 2026-10-28)
- No effects, icons or spirits made out of plain shapes. Don: the shape-built +2 charge lightning "looks terrible".
- Effects use real VFX: textured particles, beams, trails, flipbook images, glow.
- Where images come from:
  - Toolbox VFX and animations, checked for hidden scripts. Don OKs each one before it goes in.
  - Images Don makes in ChatGPT. Claude can't use ChatGPT, so Claude writes the prompts; Don uploads with Asset Manager.
  - Studio's own texture generator.
- Every move gets a body animation, an attack effect, a screen effect (zoom, cut, shake, freeze) and a sound. See docs/FIGHT-RULES.md section E.

## Steps
1. **Rules on paper.** One page: the moves, energy, what each choice does, and one example fight turn by turn. You read it and say yes or change it. No building.
2. **Strip it back.** BUILT 2026-10-28, waiting for Don's playtest. One fight only: Wood vs Ember. Turn off the extra effects, keep the camera simple. Make sure the turns are clear and fast.
3. **One great hit.** Make a single attack feel strong: short freeze on impact, screen shake, the target gets knocked back, flash, damage number. You play it.
4. **Models.** Pick how we get creatures (AI mesh tool, Toolbox, or an artist). Try it on Wood and Ember only. You judge them.
5. **Arena and menu.** A real battle floor and backdrop, styled buttons. Placeholder art first, real art later.
6. **Sound.** Hit, charge and win sounds, with your OK on each.
7. **Then spread it.** The other spirits, taming, losing, rewards after a win.

## Open question for Don
- Start with step 1, the rules on paper?
