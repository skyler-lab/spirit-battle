# Reference attack breakdown (2026-10-28)

Frame by frame, from Don's recordings, at 5 frames a second (each step is about 0.2s). We take example from the timing, the shots and the tricks. We don't copy their creatures or their exact effect art.

Where each attack is:
- Charge: video 2 at about 0:41.
- Splash: video 3 at 0:01.
- Bite: video 2 at 1:03.
- Firework: video 3 at 0:08.
- Faint and coins: video 3 at 0:11.

Video 1 is a catch with no attacks. Its move page reads Charge, Shield, Sword, Bomb.

## The big surprise
**The creatures barely move.** They bob in place, hop a little and turn. They never run up and hit. The attack is a big effect object that travels to the target and does something there: jaws, a rocket, a geyser. So the "animation" is mostly the effect, the camera and the target's reaction, not the attacker's body.

## Charge (about 2s)
| Time | What happens |
|---|---|
| 0.0 | Message pill "X USED CHARGE!" bottom-left. The camera cuts to a wide shot of the spirit that is acting. |
| 0.2 to 0.6 | The spirit does a small hop. A tall, thin, bright yellow lightning bar flashes up next to it. |
| 0.6 to 1.2 | The bar shrinks into a small yellow lightning-bolt shape that starts orbiting the spirit. Each energy point adds one bolt. |
| at the same time | Over the spirit's energy pill: a green flash and a "+1" popup with a small bolt icon. |
| 1.2 to 2.0 | The camera goes back to the main shot. The bolts keep orbiting for the rest of the fight. |

The bolts are flat, chunky, cartoon lightning shapes with a glow, not thin sticks.

## Splash, a water geyser on the target (about 2.4s)
| Time | What happens |
|---|---|
| 0.0 | "X USED SPLASH!" The attacker's bolts flare up and fly off. Its energy pill turns red with "-2". |
| 0.2 to 0.8 | Wide shot. **The sky and the light go darker**: a wind-up that tells you something big is coming. |
| 1.0 | Hard cut to a close, low shot of the target. **The target turns solid red** (a silhouette). A crown of tall cyan crystal spikes bursts up all around it. |
| 1.2 | Cyan droplets and long ovals fly up. A big red damage number with a dark outline pops ("-27"). |
| 1.4 to 1.8 | The camera shakes and drifts. Cyan streaks keep shooting up. Glowing cyan rings spread over the whole floor. |
| 2.0 to 2.4 | Back to the main shot. The rings stay on the floor and fade. The health bar drains. |

## Bite, giant jaws (about 1.6s after the message)
| Time | What happens |
|---|---|
| 0.0 | "X USED BITE!" The attacker's bolts jump up big and fly off. The energy pill turns red with "-3". |
| 0.2 to 0.6 | Wide shot from behind the attacker toward the target. The attacker stays put. |
| 0.8 | **A huge white jaw** appears over the attacker: two flat rows of zigzag teeth with a dark outline. It fills a quarter of the screen. |
| 1.0 to 1.2 | The jaw flies toward the target and opens wide, top teeth and bottom teeth apart. |
| 1.4 | It **snaps shut** on the target. The jaw turns red, the target turns solid red, and little red bits fly off. Damage number. |
| 1.6 to 2.2 | The red jaw lingers over the target and fades. The target wobbles. |

## Firework, a rocket (about 2.8s, the finishing blow)
| Time | What happens |
|---|---|
| 0.0 | "X USED FIREWORK!" The bolts fly off and the pill turns red. |
| 0.4 to 0.8 | Wide shot. A red-and-white striped rocket launches from beside the attacker. |
| 1.0 to 1.8 | The rocket flies in an arc toward the target, spinning, with orange flame puffs behind it. |
| 2.0 | Impact: a big outlined "-53", purple and pink sparks. |
| 2.2 | Explosion: neon pink, green and white streaks shoot up, with a **huge bloom glow**. The whole screen tints. |
| 2.4 to 3.2 | Glowing sparkles drift over the whole arena. The tint fades. The target lies flat. |

## Faint and rewards (about 10s)
| Time | What happens |
|---|---|
| 0 | The beaten spirit lies on its side on its platform. White text box: "X died!" with a red arrow. |
| 1 to 4 | The team list slides in from the left with each spirit's level and XP bar. |
| 4 to 5 | The camera cuts to the empty enemy platform. The spirit turns into a **white ghost shape** that rises and pops in a white puff. |
| 5 to 7 | The platform glows gold. Coins with faces burst out and fly to the coin counter, which counts up (523 to 547 to 578). A white puff at the counter. |
| 7+ | Text tip, then back to the world. |

## The tricks, in plain words
1. **The effect is the attack.** Every attack has one big, readable object: jaws, a rocket, a geyser. It is bright, simple and outlined, and big enough to fill a good part of the screen.
2. **Flat cartoon shapes and images, not little blocks.** Teeth, bolts, droplets and coins are flat shapes or images with outlines and glow.
3. **The target always reacts.** It goes solid red for about half a second, wobbles, and a big outlined number pops.
4. **The camera tells the story.** A wide shot while an attack travels, a close shot for a big hit, a shake on impact, then back to the main shot.
5. **Light changes with the attack.** The sky darkens before a big move, and a bloom and colour tint follow an explosion.
6. **Energy is a thing on screen.** Bolts orbit; spending them makes them fly off; the pill flashes red or green with a number.
7. **Something lingers.** Rings on the floor and sparkles drifting, so the screen never goes empty between moves.

## What this means for us (not built yet)
- Each of our moves needs one big effect object of its own, for example:
  - Vine Whip: a big leafy vine that lashes out of the ground under the target.
  - Leaf Storm: a whirl of big leaves.
  - Gust: a swirl.
  - Tempest: a tornado.
- Those objects need real art: meshes or flat images with outlines. That is the image-source decision (Toolbox, ChatGPT images or Studio's generator).
- These parts don't need art and can be built with code:
  - the red silhouette on hit;
  - the outlined damage number;
  - the camera cuts and shake;
  - the sky darkening and bloom;
  - orbiting bolts once there is a good bolt image.
- Don also wants the spirits' bodies to animate. The reference barely does that. Our spirits can still wind up and recoil, but most of the wow comes from the effect object.
