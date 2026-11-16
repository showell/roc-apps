# Dog Park

A small browser game about herding. You leash one dog and drag it through
a park full of critters, and everything near it reacts. **The goal: herd
all the cows into one bunch.**

It is a static page: the physics is Roc and Zig compiled to WebAssembly,
and the page runs it alone, 16 ticks a second. On the dev channel it is
`/dog-park/` (`build.shale`, below).

## The game

The park is a checkerboard of grass tiles. The world wraps around, top to
bottom and side to side (a torus), so walking off one edge brings you back
on the other. There are two levels: **Level One**, a small park of 16 dogs
and 2 cows, and **Level Two**, 64 dogs of four breeds, 8 cows, 16 chickens
and 4 goats. Win a level to unlock the next; once both are unlocked, a
button each moves between them, and each level's game is kept apart.

- **Press a dog to leash it, and drag.** Dogs of its breed follow it, in
  herds and chains; other breeds keep their distance. A dog only reacts to
  critters that are moving, so the leashed dog leads, and a herd that has
  formed stays together.
- **Cows fear dogs, and like each other.** A cow runs from a moving dog
  and drifts toward a moving cow nearby, nudging its neighbours along. You
  never touch a cow: you herd it with a dog, and the cows keep themselves
  together.
- **Goats are bold.** A goat walks straight up to a dog moving nearby,
  and dogs give a goat room, so a goat can push your herd about. Goats
  stick with goats, and pay the cows no mind.
- **The herds leave a trail of poop,** and the chickens wander out to eat
  it: quickly enough that the park doesn't fill up, slowly enough that you
  can see where the herds went.
- **Nothing moves unless you drag.** Let go, and the park waits for you.
  The leash comes off 20 seconds after you stop.
- **Press empty grass and drag** to move your view. **Map** (or `m`)
  shows the whole world, with your view as a rectangle you can drag or
  tap.
- **Try to drag a cow, a chicken or a goat,** or walk your dog straight into
  someone, and the park will tell you what it thinks of that.
- The score at the top counts your biggest herd of cows. **Start over**
  puts every critter back where the level began.

**The browser keeps your park:** close the tab, come back, and each level
is where you left it, with the level you were playing and the levels you
unlocked. It is kept in the browser's `localStorage` (docs/PHYSICS.md,
"The park, kept in the browser", says what and when). Where the browser
keeps nothing, such as a private window with storage blocked, the game
plays the same and starts afresh at the next visit.

The critters are drawn as text emoji, so each device draws them in its own
platform's emoji font: they look different on an iPhone, an Android phone
and a desktop. The park and the physics are the same everywhere.

## Changing the game in Roc

**If you know Roc, start here.** (How Roc is written here:
`../docs/roc-style.md`.) The game's behaviour is Roc: what the world is,
where everyone starts, what each critter does about the others, and how
they all move each moment. Zig is the host: it runs the Roc in the page's
WebAssembly, keeps the books (who stands in which cell, which poops are
where), and checks the Roc's work. You can change the game without
reading the Zig.

The Roc is in `roc/`, roughly in the order to read it:

- **`World.roc`**: the world's numbers. Tile sizes, the levels (each a
  world and the park in its middle), each kind of critter (`kinds`: its
  name, its square's size, its emoji, the colour the page draws it in when
  it has no emoji), the breeds. Change a size here and the whole game
  follows.
- **`Layout.roc`**: the park laid out, by a rule per tile (`tile_spots`:
  a dog of each breed in the corners, then a cow or two chickens by the
  tile's colour, and a goat above the chickens on four blue tiles).
  **`print_world.roc`** holds any layout to the physics' needs with
  `expect`s (nobody starts overlapping, everyone inside the park) and
  prints the world and the layout for the Zig and the page.
- **`Words.roc`** and **`Look.roc`**: what the game says (the quips when a
  cow is pressed, the bump lines, the score and the win) and how it looks
  and feels (each breed's emoji, the park's colours, the edge bands, the
  herd's reach). **`print_page.roc`** prints them for the page
  (`web/words.js`, `web/look.js`).
- **`Rules.roc`**: what a critter does about each critter it sees moving.
  A rule is `Ignore`, `Keep(distance)`, `Herd({ inner, outer })` or
  `Close(distance)`; `rule` says one for every pair of kinds, a `match`
  the compiler holds to every pair, and `mover` says how each kind takes
  what it sees, and its pace. The chickens' foraging and the herd's poop
  are here too. This is the file to play with first.
- **`Wish.roc`**: a critter's wish, the step it wants, from the moving
  critters around it, by the rules. Its `expect`s read as the rules'
  worked examples.
- **`Walk.roc`**: one pixel-tick: the leashed dog's step, then everyone
  else's walk out from it (who moves, the nudge, the shove, the
  sidestep). This is the hot path, written for speed: numbers in its
  loops rather than tags, and each list owned by one variable
  (`docs/ROC-SPEED.md` says why). Read it last.

**To change something and see it**, from roc-apps' root:

    shale dog_park/build.shale    # every check, then the page into the dev channel

and, in `dog_park/`, for the inner loop:

    zig build roc        # print the world and rules for the Zig and the page
    zig build test       # zig fmt, the physics' tests and the page's tests: the fast tier
    zig build roc-test   # Roc's own expects, and `roc fmt --check roc`

**Every build needs `roc`**, the nightly roc-apps' `roc-version` pins: it
builds the physics from `roc/` into its cache. The build finds it itself
at `~/tools/roc-<pin>/roc` (else `roc` on the PATH; `-Droc=<path>`
overrides both), and stops, saying so, if there is no Roc or another one:
`roc version` must print exactly the pin. `build.shale` passes the one
the repository's Shale prelude finds (`pinned_roc`).
`zig build roc` rewrites the checked-in `src/world.zon`, `src/rules.zon`,
`web/world.js`, `web/words.js` and `web/look.js` from
`roc/print_world.roc`, `roc/print_rules.roc` and `roc/print_page.roc`:
commit them with your change (`zig build check` fails on one left stale).

**The Roc is as `roc fmt` lays it out.** `roc fmt` doesn't wrap lines.
To break a long record, list, call or lambda's arguments, put a comma
after its last item, and `roc fmt` lays it out one item a line.

**To know a change is right:** `shale dog_park/build.shale` (below). The
Zig tests hold the Roc to recordings of today's game (the golden runs),
which fail, saying so, when the world or the rules change: record them
anew with `physics_golden_test.zig`'s `print`. A change that should leave
behaviour alone (a refactor, a speed-up) keeps
`zig build physics-bench -- lines` the same, byte for byte: its 14,946
lines are every move of a full drag with each dog leashed in turn (on the
park as laid out, and moved across the world's edge), a drag through
poop the chickens eat as they go, a packed herd, and a short drag written
as a report with its drags. Diff its output before and after.

**A new kind of critter is Roc's alone.** The Zig names no kind: its
kinds, their sizes, ranks, kin and who is leashed are `roc/World.roc`'s
`kinds`, and their moves and answers to each other are `roc/Rules.roc`'s
`mover` and `rule`, by pair of kinds. To add one, say it in World.roc (a
name, a size, a colour, an emoji, a rank, its kin), lay it out in
`roc/print_world.roc`, give it its tag, its number (`roc/Wish.roc`'s
`kind_of`) and its pairs (the compiler lists the ones missing), and run
`zig build roc`. The page draws a kind by its `emoji`, or with none as a
square of its colour. `tools/new_kind.shale` proves it:
`test/new_kind/sheep.patch` adds sheep touching nothing but `roc/*.roc`,
and the same Zig, byte for byte, plays them (`src/new_kind_test.zig` and
the walk's judge).

**What isn't Roc yet.** The poops by tile, placing and eating a poop,
the park's text, and the independent checks (`overlaps`, `onPoops`, the
walk's judge), are Zig. The rules
[docs/PHYSICS.md](docs/PHYSICS.md) gives are the spec either way.

## How it is built

| where | what |
|---|---|
| `roc/` | the game's rules, world and words, and `physics.roc`, the walk the Zig calls, on `roc/platform/` |
| `src/physics.zig` | the board and the tick; `roc_physics.zig` is its seam with the Roc |
| `src/physics_wire.zig` | the text of a tick's lines and of a park's entries |
| `src/physics_page.zig` | the wasm's exports: the board, the tick, and the park written and read back |
| `src/walk_reference.zig` | the plain Zig walk the Roc is judged against |
| `src/physics_bench.zig` | `zig build physics-bench` and `walk-judge` |
| `web/` | the page: `index.html`, `park.js` (the DOM, the frame loop, the browser's storage), `engine.js` (the tick and the park kept, no DOM), `physics.js` (the wasm's exports), `scene.js`, `pointer.js`, `blit.js`, `quips.js`, and the files the Roc prints |
| `tools/` | the test runner, the node tests (`test_page_modules.mjs`, `test_engine.mjs`, with `lib/page_rig.mjs`), `run_wasi.mjs`, `new_kind.shale`, `page_check.mjs` |
| `build.shale` | the gate, then the page into the dev channel |

It needs the box's Zig (0.17, `build.zig.zon`), the Roc roc-apps pins,
node, and Shale for `build.shale`. It has no Zig dependencies.

## The checks

`shale dog_park/build.shale`, from roc-apps' root, runs every check, each
with its count held exactly, and publishes only when all pass:

- `zig build check`: `zig fmt --check` over the Zig and the generated
  .zon; the physics' Zig tests (60) natively and compiled to wasm32-wasi
  under node; the page's node tests on the Debug and the served wasm;
  Roc's expects (134 in 5 `roc test` runs) and `roc fmt --check roc`;
  and roc-fresh, each file the Roc prints compared with the checked-in one;
- the page's node tests once more, for their counts:
  `test_page_modules.mjs` (42) and `test_engine.mjs` (11), none failed,
  skipped or left to do;
- `zig build walk-judge`;
- `tools/new_kind.shale`;
- `tools/page_check.mjs`, on the page staged in the dev channel
  (`/dog-park.staging/`) before it is swapped in: headless Chromium loads
  it, drags a dog with the mouse, and checks that localStorage kept the
  park and that a reload picks it up; then it loads it again with
  localStorage refusing every use and checks that the game plays and says
  so once. Any console error fails it. Its shots are in
  `~/build/roc-apps/gen/dog_park/shots/`; the box has no emoji font, so
  they show the tiles and the leash's ring but not the critters.

Every Zig test is built with `tools/test_runner.zig`, std's runner but
stricter: a skipped test fails, and so does a test binary with no named
tests in it. A node test fails on a skip or a todo, not only on its exit
code.

The tiers, in `dog_park/`:

    zig build physics-test   # the physics' tests alone, natively: the fastest
    zig build test           # after every edit
    zig build check          # before a commit
    zig build slow           # the full fuzz, and the wasm tests in ReleaseSafe as served

`-Dfuzz=full` gives any step the full fuzz. The bench
(`zig build physics-bench`) is in no tier.

## Status (2026-11-16)

Dog Park plays on the dev channel, at `/dog-park/`. It is not on staging
or prod yet, and the landing page has no card for it.
