# Dog Park's physics, and the park the browser keeps

The board and the tick are `src/physics.zig`; their text is
`src/physics_wire.zig`; the page's exports are `src/physics_page.zig`,
compiled to `physics.wasm`, which `web/engine.js` runs. The world is said in
Roc: `roc/print_world.roc` says each level's size, the park in it and the
first layout, and `zig build roc` prints them into `src/world.zon` (which
`world.zig` imports) and `web/world.js` (the page's numbers). What critters
do about each other is `roc/Rules.roc`, which the critters' wish
(`roc/Wish.roc`) applies and `roc/print_rules.roc` prints into
`src/rules.zon` for the Zig's other uses; the walk, each pixel-tick's moves
after the leashed dog's, is `roc/Walk.roc`. The physics is tuned by playing
it.

**Tested, each with a purpose** (the README has the tiers):
- **the invariant:** no two critters ever overlap and none stands on
  poop, over seeded drags through the whole park that lay poop and shove
  chickens (`physics_test.zig`);
- **poop and chickens:** the trail comes from the herd's tail, going
  around never lands anyone on anything, the leashed dog doesn't bump
  what it can get around, eating, ripeness, the poops by tile
  (`physics_trails_test.zig`);
- **the page's architecture:** the same tests compiled to wasm32 pass
  too, so the page's answers are the native ones;
- **the text:** every line in its one form, a park's entries written and
  read back (`physics_wire_test.zig`), and a park kept and taken back, or
  refused (`physics_page.zig`'s tests);
- **the torus and the tiles:** the seam, the region's wrapped tiles;
- **the golden runs:** today's game, recorded (`physics_golden_test.zig`);
- **the walk's judge:** every pixel-tick of the Roc walk against a plain
  Zig reference that shares none of its code (`zig build walk-judge`).

The motion itself (who goes where, and how herds feel) is tested by
playing, not by unit tests.

## The rules

- **No randomness, no clock.** A tick is a function of the board and the
  player's inputs; drags are displacements.
- **Positions in 256ths of a pixel; 16 ticks a second;** the world is a
  torus of 350 px tiles, its size the level's (`roc/World.roc`'s
  `levels`: 4 × 4 tiles with a 2 × 2 park, or 6 × 6 with a 4 × 4 park),
  the park in its middle with a ring of empty tiles round it.
- **Distance is the larger axis** (Chebyshev): every reach is a square,
  as the critters are.
- **Nothing moves unless the leashed dog is dragged.**
- **No two critters ever overlap,** by induction: the first layout has
  none, and no step lands anyone on anyone.

## A tick

1. **The inputs** (`leash`, `grab`, `letgo`, `release`), in order, at most
   16 a tick.
2. **The drag, if one is on,** as its x part then its y part, cut into
   **pixel-ticks** of at most 1 px. In each:
   - **the leashed dog** takes the step, swept against everyone it sees,
     stopping just short of pressing into anyone. Stopped by a chicken, it
     shoves it; stopped by a poop, or a chicken it can't shove, it slides
     the step's size sideways. **A bump ends the drag, not the leash:** a
     dog or a cow in the way, or a slide that fails too; the rest of the
     tick's drag is dropped, the pointer is let go, and the let-go timer
     starts;
   - **then the walk** (below), if the leashed dog moved;
   - **then the poops due** (below).
3. **The chickens' turn,** once, after the drag, bumped or not, if the
   leashed dog's net move over the tick is more than nothing (below).
4. **The timer:** the leash comes off 320 ticks (20 s) after the drag
   ended, unless a `grab` came first. Unleashing puts the park to sleep.
5. **The checked lines:** every critter whose place changed over the
   tick, then a `bump`, a `release`, or a `rest` (nothing moved, no input,
   no timer running: the page stops ticking until the human acts).

A tick's drag moves the leashed dog at most `cap` (100 px) on each axis; a
faster flick is cut there for that tick, and at most 16 displacements a
tick are kept (the shared Zig adds any more into the 16th).

## The walk

**The walk is Roc's** (`roc/Walk.roc`, linked into the physics through
`src/roc_physics.zig`): once a pixel-tick, after the leashed dog's step,
the Zig lends it the critters (where each stands, the cell it stands in,
what it is), every cell's set of them, the poops by tile and room for its
working lists, all as lists over the Zig's own buffers; Roc moves the
critters in place, keeping the cells as it goes, and hands the lists back
with the visit order and the pooper. **Neither side allocates:** the
physics' `roc_alloc` panics, so a list Roc copies is a crash
([ROC-SPEED.md](ROC-SPEED.md) has the rules that keep it from copying,
and keep it fast). The leashed dog's own step (the sweep, the bump, going
around), the poop laid after the walk and the chickens' turn stay Zig's.
`zig build walk-judge` checks every pixel-tick against a plain Zig
reference (`src/walk_reference.zig`).

After each pixel-tick of the leashed dog, up to `walk_most` (48) critters
move, one at a time, out from the leashed dog, **shortest link first.**
Only the kinds that walk (`roc/Rules.roc`'s `walks`: dogs, cows and
goats); chickens take none of the 48.
- the leashed dog lines up its `walk_fan` (3) nearest critters of the
  kinds that walk, each waiting keyed by its distance from the critter
  that lined it up;
- the walk visits the waiting critter with the least key (ties to the
  lower rank, then the lower number); it works out its wish, steps, and
  lines up its own 3 nearest not yet visited, from where it now stands. A
  critter already waiting takes the nearer of its keys;
- so a pack close together is walked to its end before a critter farther
  from whoever found it, however near the leashed dog that one is. A
  critter the walk doesn't reach stays put this pixel-tick.

**A critter reacts only to critters in motion:** the leashed dog and the
critters the walk visited before it this pixel-tick, where they now
stand. Its wish is `roc/Wish.roc`'s, from the moving critters near it and
the vectors to them the short way round, by the rules (`roc/Rules.roc`):
for each kind, an answer to each kind it sees (keep a distance, herd
against the nearest, close in, or nothing), and whether it sums every
answer or takes its nearest moving critter's alone.
- **A dog** keeps `wary` from each moving dog of another breed, a smaller
  room from each moving cow or goat, and its place in the herd: its
  **anchor** is the nearest moving dog of its own breed (the leashed dog
  leads its breed). Past the band's outer edge it wants to close the
  excess; inside the inner edge to open the shortfall; in the band it is
  content.
- **A cow** heeds only its **nearest** moving critter (ties to the lower
  rank), at any distance: a cow within reach, it closes the gap to
  touching; a dog, it keeps `wary` from it. Cows are, in effect, a slower
  breed that follows its nearest kin instead of the leashed dog.
- **A goat** heeds only its nearest moving critter too, and is bold: a
  dog within reach, it closes the gap to touching (and dogs keep their
  room from a goat, so a goat that reaches the herd pushes dogs about); a
  goat, it herds against it. It heeds no cow, and no cow or chicken heeds
  it.

Each wish is a step straight away from (or toward) the other, as long as
the shortfall (or the excess); they add up. The step is the total, cut to
the pixel-tick's move times the kind's pace (a dog's whole, a cow's or a
goat's half); a total under the **dead zone** (1 px) is no step. **The
veto:** a critter takes its step whole, or not at all if its square there
would overlap anyone who isn't kin. **The nudge:** kin in the way (a cow
for a cow, a goat for a goat, a dog of its breed for a dog, never the
leashed dog) take the same step with it, and nudge their own kin in turn,
up to `nudge_most` (8) in all; if any of them is blocked, none moves.
Nobody is ever pressed into, and still critters never attract or repel.

**Going around:**
- **The shove.** A chicken in the way of a dog or a cow of the step is
  knocked by the step plus as much again sideways, away from that
  critter's centre line (on the line: south, or east for a step north or
  south). It counts only if every chicken shoved lands clear of every
  critter (where the step leaves each one: still, nudged or shoved) and of
  every poop; all is checked before anyone moves, and then all move or
  none. So a chicken slides off the front of a dog instead of being
  plowed ahead. A chicken shoves nobody.
- **The sidestep.** A step vetoed by a poop, or by a chicken it can't
  shove, is tried once more: zero the step on the axis where the blocker
  is farther off (a tie zeroes x); on the other, keep the step's own
  part, or, if it has none, go the step's whole size away from the
  blocker (on the line, +). Vetoed again, the critter stays.
- **The leashed dog** is swept, not vetoed: stopped by a chicken, it
  shoves it with the rest of its step; stopped by a poop or a chicken it
  can't shove, it slides the step's size (1 px) sideways, away from it,
  whole or not at all. It bumps only when the slide fails too. There is
  no setback.

## Poop and chickens

The herds leave a trail of poop behind them, and the chickens clean it up.
Neither gets in the way: what's in the way is gone around, not stopped at.
The numbers are `roc/Rules.roc`'s `poop` and `chickens`.

**The trail:**
- **When:** each time the leashed dog's walk (every step it takes,
  counted by its larger axis) passes another `poop.every` px, after that
  pixel-tick's walk.
- **Who:** the deepest dog of the leashed dog's breed in that walk. The
  leashed dog has depth 0; a visited dog whose anchor is dog j has j's
  depth + 1; the greatest depth wins, ties to the dog visited later; with
  no follower, the leashed dog. Depth lives only for that walk.
- **Where:** `poop.back` px (centre to centre) **behind** the pooper: away
  from its anchor; for the leashed dog, back along its step. That spot
  taken, the spots on rings `poop.grid` px apart around it, out to
  `poop.reach`, each ring walked clockwise from its north-west corner. A
  spot must overlap no critter and no poop. None fits: no poop.
- **Poop stays until a chicken eats it.** The park's poops take
  `poop.slots` slots in turn, counted since the layout (`laid`), so a
  slot is reused only after that many more.
- **Poop blocks dogs and cows;** nothing pushes it. A step onto one is
  vetoed, then sidestepped; the leashed dog slides around it.
- **Ripe:** every poop is ripe but the park's newest, the one in slot
  `laid − 1` mod slots (`ripe`): it comes free from the slot counter.

**Chickens** are no part of the walk. Every other critter treats one as
an obstacle it may shove (above) and nothing more.
- **The chickens' turn:** once a tick, after the drag, and only if the
  leashed dog's net move over the tick (its larger axis) is more than
  nothing. Every chicken, in number order, steps at most half that move
  and at most `chickens.step`:
  - **forage:** toward the nearest ripe poop within `chickens.sight`
    (ties to the lower slot), going around what blocks it (the sidestep);
  - **else go home:** toward its spot in the first layout
    (`layout.zig`'s `home`) when more than `chickens.home_band` from it,
    whole or not at all: blocked, it waits;
  - **else it stays put,** and writes no line.
- **Eating:** after its step, a chicken eats every ripe poop its square
  overlaps.
- **No critter ever stands on poop** (`onPoops`, in the invariant): a
  dog's or a cow's step never lands on one; a chicken's own step is vetoed
  only by the newest, and it eats a ripe one it lands on there and then; a
  shove lands clear of every poop.

**The cost:** every square that asks about poop asks only the tiles of
the span it could reach (the Scene keeps its poops by tile), so a drag
through hundreds of poops costs what it does with none (`zig build
physics-bench`).

## The numbers

The critters' distances from each other, their paces, the chickens' and
the poop's numbers and the walk's limits are `roc/Rules.roc`'s; their
squares are `roc/World.roc`'s; the tick's (the pixel-tick `step_most`,
the drag's `cap` of 100 px an axis a tick, `let_go_ticks`) are constants
in `physics.zig`. **The goal**, the level's cows in one herd: two cows are
linked within two cow-widths, round the torus (`scene.js`'s
`largestHerd`).

**Arithmetic.** Positions are integer 256ths; every product is `i64`, and
only a quotient comes back to `i32`. A wish's axis is the vector's axis
times the wish's length over the vector's length, truncated toward zero
(`roc/Wish.roc`'s `along`; a poop's spot, `roc/Walk.roc`'s `away_from`).
In the text a position is hex with a point: `d80.40` is 3456 and 64/256
px.

## What the physics sees

**Every critter in the world, always.** The region (`region`, in
`physics.zig`) is the whole world, wherever the leashed dog stands, so no
critter is ever unseen and there is no edge for a step to keep clear of.
The neighbour searches (the walk's rings, the cells, the poops by tile)
wrap round the torus. The page holds the whole world too: the overview
shades every tile as held.

## Wall time

**The physics has no clock.** A tick is a step, not a duration. The page
runs 16 a second by its own clock (`requestAnimationFrame`), and that's
the only place wall time paces anything. A slow laptop ticks slowly and
the physics is unchanged; a page in a background tab doesn't tick at
all, and on its return catches up at most `most_catch_up_ticks` (8,
`web/engine.js`); the rest are dropped, never owed.

## What the page draws

The page draws on its own frames, between ticks: each critter part way
from where it was at the tick before to where it is now (`between` in
`scene.js`). With the labels on (`d`), under each dog its number and its
place in the last walk (`212 #4`); under a cow, its place in the walk when
it had one. The walk's order is drawing data from the wasm (`walkAt`).

## The lines

A tick's checked lines, as `physics_wire.zig` writes them, one a line:

| line | says |
|---|---|
| ` <kind> N a > b` | a critter whose position changed over the tick, from a to b, in rank order (each kind by rank, each by number); exactly one leading space |
| ` poop N x,y` | slot N holds a new poop, or its poop moved (a shove) |
| ` eaten N` | the poop in slot N is gone |
| `bump T <kind> N`, `bump T poop N` | the drag ended at tick T because the leashed dog pressed into that critter or poop: the let-go ticks start, the leash stays |
| `release T D` | the leash came off dog D at tick T (the let-go ticks ran out): the park sleeps |
| `rest T` | nothing changed over tick T, no input, no let-go timer running: a fixed point, so the page stops ticking until the human acts |

`zig build physics-bench -- lines` writes every line of many ticks (each
dog leashed in turn on the park as laid out and moved across the world's
seam, a drag through poop the chickens eat as they go, a packed herd),
and ends with them as the report the page once sent its server: a header
(`dogpark 2 physics H page E req R`), `from T`, and each tick's `grab` and
`t T +ms drag dx,dy@ms …` line before its lines, so the drags as merged and
capped are held too. A change that should leave behaviour alone keeps
those bytes the same.

## The park, kept in the browser

The page keeps each level's park in the browser (`localStorage`, every
read and write in try/catch, `web/park.js`'s `store`), so a reload picks
the game up. `physics_page.zig`'s `writePark` writes it and `readPark`
takes it back, as text:

```
dogpark park 1
level 2
tick 1043
laid 17
cow 0 36b.00,36b.00
…
dog 19 3e5.00,3e8.00 walked 2b.00
…
poop 3 3e8.00,41a.00
end
```

- **The lines:** the header; the level, 1-based; the last tick the page
  ran, so tick numbers carry on; the poops laid since the layout (`laid`,
  which says which slot is next and which poop is the newest); every
  critter the level lays out, in rank order, a dog with its walk when it
  has walked (which says when its next poop is due); each poop by number;
  `end`.
- **Not in it: the leash.** A park read back has nothing leashed, as a
  load from the server had: nothing in the physics rests on the leash
  surviving a reload, and a page that opens with a dog in hand and nobody
  holding it would be wrong.
- **Refused, and said:** a text that is not a park as `writePark` writes
  it (another version's, or torn), a park of another level, one whose
  critters are not those the level lays out (a world that changed), and
  one with two critters overlapping or one on a poop (the invariant).
  The board is then unchanged: the level's first layout is played, and
  the console says why.
- **When it is kept** (`web/engine.js`): after a tick that moves
  anything, at most once a second; at once when the park comes to rest, a
  leash comes off or a drag bumps; when the page is hidden or goes away;
  on a change of level and on Start over.
- **Beside it:** `dogpark.level`, the level played and the highest
  unlocked, as `level L of U`; and `dogpark.viewport.*`, where the player
  last looked, a level each. A level is open when it is unlocked, or is
  the next one and the level played is won, which unlocks it.
- **With storage blocked** a read is nothing and a write is dropped (the
  first failure said once on the console): the game plays the same,
  changes level the same, and starts afresh at the next load.
