# Fight redesign plan (2026-10-27)

Status: PLAN, not built. Waiting for Don's OK.
All numbers are placeholders to be tuned in playtests. No prices or rewards (the economy is not designed).

## Why the fight sucks now
- Every spirit has the same 4 moves and 100 HP. Only the element differs.
- The best play is almost always Charge, then Strike. Nothing to think about.
- The wild spirit picks at random, so there is nothing to read or outsmart.
- Each turn plays two spirits one after the other, plus text. It feels slow.

## The goal
A fight is about 5 turns and 20 to 30 seconds. Every turn has a real choice. Every spirit plays differently.

## 1. Both spirits act at once
- You pick, the wild spirit picks, and both moves play together in one short beat.
- **Target: 2 seconds a turn or less.** It is 2.6 to 3.0 now.
- One line of text per turn, shown while the moves play, not before them.
- Battle start until you can pick: 1.5 seconds or less.

## 2. Three basic moves that beat each other
Every spirit has these three. Your ideas, energy and Block, stay at the heart of it.

| Move | What it does | Beats | Loses to |
|---|---|---|---|
| **Attack** (your spirit's abilities) | Costs energy, does damage | Charge: a charging spirit takes extra damage | Block |
| **Block** | Stops the hit and stuns the attacker. Costs nothing if it blocks something. | Attack | Charge: blocking a charge wastes the turn |
| **Charge** | +3 energy | Block | Attack |

Because both pick at the same time, every turn is a small guess about what the other side will do. That's the real choice the fight is missing today.

## 3. Each spirit gets its own abilities
Each spirit gets 3 abilities of its own. They replace Strike and Blast.

| Spirit | Cheap ability | Special | Big ability |
|---|---|---|---|
| **Wood** (Nature) | Vine Whip: 2 energy, 18 damage | Regrow: 3 energy, heal 25 (your idea) | Thorn Wall: 4 energy, Block that also hurts the attacker |
| **Ember** (Fire) | Spark: 2 energy, 18 damage | Burn: 3 energy, 8 damage now plus 6 for 3 turns | Flare: 6 energy, 50 damage |
| **Pebble** (Earth) | Rock Toss: 2 energy, 18 damage | Harden: 2 energy, takes half damage for 2 turns | Quake: 5 energy, 30 damage and stuns |
| **Breeze** (Wind) | Gust: 1 energy, 12 damage | Tailwind: 2 energy, +2 energy for the next 2 turns | Cyclone: 5 energy, hits twice for 20 |

- Spirits also differ in health and speed. For example, Pebble is tough and slow, and Breeze is fragile and fast. The faster spirit's hit lands first when both attack.
- New effects for all spirits to share: burn, stun (the target loses its next move), heal, damage shield.
- Element strengths stay the same (1.5x strong, 0.5x weak).

## 4. A wild spirit you can read
- The wild spirit follows a simple plan for its type instead of random picks. For example, Ember builds up energy, then uses Flare.
- **Warnings:** before a big move it shows a sign, such as "Ember is getting hot!" with a glow. Then you choose: block it, or attack it while it charges.
- It sometimes breaks its pattern, so it can't be beaten blindly.

## 5. Taming fits in
- Taming stays: TAME works at 30% health or less.
- A stunned spirit is easier to tame, which gives Quake and Block a second use.

## How I will check it is fun before showing you
1. **Simulation:** play the rules thousands of times in a script, with no Studio needed. Check that:
   - a fight lasts about 4 to 7 turns;
   - no single move always wins;
   - each spirit wins some match-ups and loses others.
2. **Play test in Studio** with real clicks: turns under 2 seconds, and every ability's effect seen on screen.
3. **Your playtest:** the only real test of fun.

## Build order (after your OK)
1. **Rules and data.** Abilities, spirit stats, effects, simultaneous turns and wild spirit plans, all decided on the server.
2. **Simulation check,** then tune the numbers.
3. **Battle screen.** Your spirit's own ability buttons with their cost and a one-line description, plus the warning sign.
4. **Effects for each ability,** reusing the effects pack.
5. **Studio test,** screenshots, then your playtest.

## Not in this plan
- Models, a real arena and real UI. They come next, after the fight is fun.
- Rewards, XP and levels: these need the economy.
- Picking which of your spirits fights. Needed soon: today it is always Wood.
- Sound: needs uploads and your OK.

## Questions for later (one at a time)
- Should each spirit have 3 abilities, or 4?
- Should a spirit's abilities change when it evolves (for example Wood to Nature)?
