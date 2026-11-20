# Dog Park

A small browser game about herding. You leash one dog and drag it through a
park full of critters, and everything near it reacts. **The goal: herd all
the cows into one bunch.**

It is a static page: the physics is Roc and Zig compiled to WebAssembly, and
the page runs it alone, 16 ticks a second. On the dev channel it is
`/dog-park/` (`build.shale`, below).

## The game

The park is a checkerboard of grass tiles. The world wraps around, top to
bottom and side to side (a torus), so walking off one edge brings you back on
the other. **Level One** is a small park of dogs and two cows; **Level Two**
is a bigger one with four breeds of dog, more cows, chickens and goats. Win a
level to unlock the next; once both are unlocked, a button each moves between
them, and each level keeps its own game.

- **Press a dog to leash it, and drag.** Dogs of its breed follow it, in herds
  and chains; other breeds keep their distance. A dog reacts to critters that
  are moving, so the leashed dog leads, and a herd that has formed stays
  together.
- **Cows fear dogs, and like each other.** A cow runs from a moving dog and
  drifts toward a moving cow nearby, nudging its neighbours along. You herd a
  cow with a dog, and the cows keep themselves together.
- **Goats are bold.** A goat walks straight up to a dog moving nearby, and
  dogs give a goat room, so a goat can push your herd about. Goats stick with
  goats and ignore the cows.
- **The herds leave a trail of poop,** and the chickens wander out to eat it:
  quickly enough to keep the park clean, slowly enough that you can see where
  the herds went.
- **The park moves when you drag.** Let go, and it waits for you. The leash
  comes off 20 seconds after you stop.
- **Press empty grass and drag** to move your view. **Map** (or `m`) shows the
  whole world, with your view as a rectangle you can drag or tap.
- **Try to drag a cow, a chicken or a goat,** or walk your dog straight into
  someone, and the park will tell you what it thinks of that.
- The score at the top counts your biggest herd of cows. **Start over** puts
  every critter back where the level began.

**The browser keeps your park:** close the tab, come back, and each level is
where you left it, with the level you were playing and the levels you
unlocked. It lives in `localStorage` (`docs/PHYSICS.md`, "The park, kept in
the browser", says what and when). Where storage is blocked, such as some
private windows, the game plays the same and starts fresh at the next visit.

The critters are text emoji, so each device draws them in its own emoji font:
they look different on an iPhone, an Android phone and a desktop. The park and
the physics are the same everywhere.

## Changing the game in Roc

**If you know Roc, start here.** (How Roc is written here:
`../docs/roc-style.md`.) The game's behaviour is Roc: what the world is, where
everyone starts, what each critter does about the others, and how they all
move each moment. Zig is the host: it runs the Roc in the page's WebAssembly,
keeps the books (who stands in which cell, which poops are where), and checks
the Roc's work. You can change the game from the Roc alone.

The Roc is in `roc/`, roughly in reading order:

- **`World.roc`**: the world's numbers: tile sizes, the levels, each kind of
  critter (`kinds`) and the breeds. Change a size here and the whole game
  follows.
- **`Layout.roc`**: the park laid out, by a rule per tile (`tile_spots`).
  **`print_world.roc`** holds any layout to the physics' needs with `expect`s
  (everyone apart, everyone inside the park) and prints the world for the Zig
  and the page.
- **`Words.roc`** and **`Look.roc`**: what the game says and how it looks.
  **`print_page.roc`** prints them for the page.
- **`Rules.roc`**: what a critter does about each critter it sees moving. A
  rule is `Ignore`, `Keep(distance)`, `Herd({ inner, outer })` or
  `Close(distance)`; `rule` gives one for every pair of kinds, a `match` the
  compiler holds to every pair, and `mover` says how each kind takes what it
  sees, and its pace. The chickens' foraging and the herd's poop are here too.
  This is the file to play with first.
- **`Wish.roc`**: a critter's wish, the step it wants, from the moving
  critters around it. Its `expect`s are the rules' worked examples.
- **`Walk.roc`**: one pixel-tick: the leashed dog's step, then everyone else's
  walk out from it. This is the hot path, written for speed: numbers in its
  loops in place of tags, and each list owned by one variable
  (`docs/ROC-SPEED.md` says why). Read it last.

**To change something and see it**, from roc-apps' root:

    shale dog-park/build.shale    # every check, then the page into the dev channel

and, in `dog-park/`, for the inner loop:

    zig build roc        # print the world and rules for the Zig and the page
    zig build test       # zig fmt, the physics' tests and the page's tests: the fast tier
    zig build roc-test   # Roc's own expects, and `roc fmt --check roc`

**Every build needs the pinned Roc** (`../roc-version`): it builds the physics
from `roc/`. The build finds it at `~/tools/roc-<pin>/roc` (else `roc` on the
PATH; `-Droc=<path>` overrides both), and stops, saying so, when `roc version`
prints anything but the pin. `build.shale` passes the one `pinned_roc` finds.
`zig build roc` rewrites the checked-in files the `roc/print_*.roc` apps print
(`src/world.zon`, `src/rules.zon`, `web/world.js`, `web/words.js`,
`web/look.js`): commit them with your change (`zig build check`
fails on a stale one).

**The Roc is as `roc fmt` lays it out.** `roc fmt` keeps long lines long. To
break a long record, list, call or lambda's arguments, put a comma after its
last item, and `roc fmt` lays it out one item a line.

**To know a change is right:** `shale dog-park/build.shale`. The Zig tests
hold the Roc to recordings of today's game (the golden runs), which fail,
saying so, when the world or the rules change: record them anew with
`physics_golden_test.zig`'s `print`. A change meant to keep behaviour (a
refactor, a speed-up) keeps `zig build physics-bench -- lines` the same, byte
for byte: every move of a set of scripted drags. Diff its output before and
after.

**A new kind of critter is Roc's alone.** The Zig names no kind: the kinds and
their traits are `roc/World.roc`'s `kinds`, and their moves are
`roc/Rules.roc`'s `mover` and `rule`, by pair of kinds. To add one, say it in
`World.roc`, lay it out in `roc/print_world.roc`, give it its tag, its number
(`roc/Wish.roc`'s `kind_of`) and its pairs (the compiler lists the missing
ones), and run `zig build roc`. The page draws a kind by its `emoji`, or as a
square of its colour. `tools/new_kind.shale` proves it:
`test/new_kind/sheep.patch` adds sheep by changing `roc/*.roc` alone, and the
same Zig, byte for byte, plays them.

**What Zig keeps:** the poops by tile, placing and eating a poop, the park's
text, and the independent checks (`overlaps`, `onPoops`, the walk's judge).
[docs/PHYSICS.md](docs/PHYSICS.md) is the spec for both languages.

## How it is built

`roc/physics.roc` is the walk the Zig calls, on `roc/platform/`.
`src/physics.zig` is the board and the tick, with `roc_physics.zig` its seam
with the Roc, and `src/walk_reference.zig` the plain Zig walk the Roc is
judged against. The page is `web/index.html`, from `web/park.js`. Read the
code for the rest. It needs Zig (the version `build.zig.zon` names), the
pinned Roc, node, and Shale for `build.shale`; it has no Zig dependencies.

## The checks

`shale dog-park/build.shale`, from roc-apps' root, runs every check, each with
its count held exactly, and publishes once all pass:

- `zig build check`: `zig fmt --check`, the physics' Zig tests natively and on
  wasm32-wasi under node, the page's node tests on the Debug and the served
  wasm, Roc's expects and `roc fmt --check roc`, and roc-fresh, each file the
  Roc prints compared with the checked-in one;
- the page's node tests once more, for their counts;
- `zig build walk-judge`;
- `tools/new_kind.shale`;
- `tools/page_check.mjs`, on the staged page before it is swapped in: headless
  Chromium drags a dog, checks that `localStorage` kept the park and that a
  reload picks it up, then loads it with storage refused and checks that the
  game plays and says so once. A console error fails it;
- `tools/card_shot.mjs`, the landing page's picture (below).

Every Zig test is built with `tools/test_runner.zig`, std's runner made
stricter: a skipped test fails, and so does a test binary with no named tests.
A node test fails on a skip or a todo as well as on its exit code.

The tiers, in `dog-park/`:

    zig build physics-test   # the physics' tests alone, natively: the fastest
    zig build test           # after every edit
    zig build check          # before a commit
    zig build slow           # the full fuzz, and the wasm tests in ReleaseSafe as served

`-Dfuzz=full` gives any step the full fuzz. The bench
(`zig build physics-bench`) runs on its own.

## The landing page's picture

`build.shale` takes it of each build it publishes, as the page's `shot.png`:
`tools/card_shot.mjs` plays Level Two in headless Chromium and drags a dog
round a loop, and `site/squeeze_png.mjs` makes it small. The critters are
emoji, so the build needs a colour emoji font, and stops without one. To
install Noto Color Emoji for one user: download `fonts/NotoColorEmoji.ttf` at
a release tag of [googlefonts/noto-emoji](https://github.com/googlefonts/noto-emoji)
into `~/.local/share/fonts/`, check that `git hash-object` of it is the blob
GitHub names for that path at that tag, and run `fc-cache`.
