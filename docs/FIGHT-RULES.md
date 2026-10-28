# Fight rules (step 1 of FIGHT-PLAN-V3, 2026-10-28)

Status: ON PAPER, for Don to approve. All numbers are placeholders. Section A is how the game works now, checked against the code. Section D is the fixes Don approved on 2026-10-28; they are not built yet.

## A. How a turn works now
- Each side has health and energy. Energy goes from 0 to 10.
- Both sides start with 1 energy. After every turn, each side gets +1.
- You pick a move. At the same moment, the wild spirit picks one too.
- Order: blocks go up first, then your move, then the wild spirit's move. A spirit knocked out before its turn does not act.
- Element advantage: a strong hit does 1.5x damage and a weak hit does 0.5x.
  - Fire beats Nature, Nature beats Earth, Earth beats Wind, Wind beats Fire, and Water beats Fire.
- Win: the wild spirit reaches 0 health. Lose: yours reaches 0. Tame: allowed when the wild spirit is at 30% health or less.

## B. Moves (Wood and Ember, the step 2 fight)
| Spirit | Move | Energy | What it does |
|---|---|---|---|
| Both | Charge | free | +2 energy |
| Wood (Nature, 100 HP) | Vine Whip | 2 | 18 damage |
| | Regrow | 3 | heal 25 |
| | Leaf Storm | 5 | 45 damage |
| Ember (Fire, 90 HP) | Fireball | 2 | 18 damage |
| | Flame Guard | 1 | blocks one attack; you get the 1 energy back if it blocks |
| | Inferno | 5 | 45 damage |

## C. Example fight, real numbers: Wood vs Ember
- **Turn 1.** Wood has 1 energy, so it can only Charge (now 3). Ember Charges (now 3). After the turn: 4 and 4.
- **Turn 2.** Wood's Vine Whip does 9 (Nature is weak to Fire): Ember is at 81. Ember's Fireball does 27: Wood is at 73. After the turn: 3 and 3.
- **Turn 3.** Wood's Regrow heals it to 98. Ember's Fireball: Wood is at 71.
- **Result:** Wood loses this fight almost every time. Ember does 3 times Wood's damage.

## D. Problems I see, with fixes (all 4 APPROVED by Don 2026-10-28, built in step 2)
1. **Turn 1 is forced.** With 1 energy you can only Charge. Fix: start with 2 energy, so Vine Whip or Charge is a real choice on turn 1.
2. **Wood vs Ember is unfair on purpose (element advantage).** That makes it a bad first test of whether fighting is fun. Fix: test with Wood vs Breeze first. Nature vs Wind is even.
3. **Block is a guess.** A block wastes energy if the foe didn't attack. That is fine, but you can't read the foe. Fix: the wild spirit shows a hint before it acts (for example, it glows when it is about to use its big attack).
4. **Charge is the right move too often.** Fix later, only if playing shows it.

## E. How each move is designed (Don, 2026-10-28)
Every move gets four parts. None of these may be built from plain blocks or shapes.
1. **Body animation:** how the spirit moves (wind-up, lunge, recoil, idle).
2. **Attack effect:** real VFX made of textured particles, beams, trails, flipbook images and glow. No Part shapes.
3. **Screen effect:** zoom in, camera cut, screen shake, short freeze on impact, flash.
4. **Sound:** each one needs your OK.

Draft for the step 2 moves (only the step 3 move is built first):
| Move | Body | Effect | Screen |
|---|---|---|---|
| Charge | crouch, glow, rise | yellow energy sparks pulled in, a lightning flicker image | slight zoom in, small shake |
| Vine Whip | lean back, snap forward | vine trail whips across, leaf burst on hit | quick cut to the target, shake on hit |
| Regrow | arms up, sway | green light rising, leaf petals | slow push in on Wood |
| Leaf Storm | spin up, release | leaf tornado around the target | zoom on target, freeze on hit, big shake |
| Fireball | inhale, spit | fire orb with smoke trail, fire burst | follow the shot, shake on hit |
| Flame Guard | brace | flame shield shimmer | none |
| Inferno | rear up, slam | fire column and embers | zoom out, freeze, big shake, flash |
