# The arcade

roc-ray's own example games, running on a web page and as native programs from
the same Roc. `movies/` is the other half of the building: a movie is played, a
game is driven.

    arcade/build.sh snake       the page,   http://<box>:9210/snake/
    arcade/native.sh snake      the native program
    node arcade/web/page_check.mjs snake
    KEYS=3:Space DRAG=200,100,200,500 node arcade/web/page_check.mjs pong
    node arcade/web/lens_check.mjs      the camera, on both ends

Six of them: `snake`, `pong`, `breakout`, `camera`, `workshop`,
`trick_or_treat`. The last is the Halloween movie, named for its title so it
does not collide with `movies/halloween` in `next/` or on the dev server.

**Two of the six are not games.** `camera` is a world you fly around and
`trick_or_treat` is a movie you can scrub. `canvas_app_runner.js` hosts all
six; the `game` still in its local names is older than that and not yet
honest.

## Where the splits are

| | |
|---|---|
| `snake_web.roc` | the app a browser runs — sits on `web/platform/`, uses `lib.GameApp` |
| `snake_native.roc` | the app roc-ray runs — uses `native/GameRunner` |
| `snake/` | **the game**, and everything that is only about it, its page included. Neither app's half; it cannot tell which is running |
| `lib/` | a package: `Game`, `Keys`, `Random`, `Shapes`, `Brush`, `Font`, and the two wire edges |
| `web/` | the page's end: the wasm platform and host, `shapewire.js` (a frame, decoded and painted), `canvas_app_runner.js` (the clock, the input, the speaker), `page_check.mjs`, `lens_check.mjs` |

**One call for a frame.** `computeFrame()` is the effect and answers the
address of two words, the frame's start and its length. It used to be two
exports, `computeFrame()` then `frameAt()`, and that arrangement caught two
people who each wrote `decode(memory, frameAt(), computeFrame())` -- which
JavaScript evaluates left to right, so it read the previous frame's start with
this frame's length and misread far enough in to look like corrupt data.

**What `page_check` actually gates on.** `fills > frames`, because `draw`
clears the canvas with a counted `fillRect`, so a page painting no shape at all
still reported 29 fills over 31 frames and passed. And the picture changing at
least once, because a page whose `fps` is zero steps once and then never again
while every count stays healthy. Both were reproduced before the gates were
written, and both fail now.
| `native/` | roc-ray's end: `GameRunner.roc` |

**Why the two app files sit at the top rather than beside the game.** An app
file is where Roc's package root is, and a relative import may not climb above
it. `lib/` is fine outside because it is a package and a package reference is
not a relative import — but `native/GameRunner.roc` cannot be a package,
because **a package cannot see a platform**: it imports `rr.App` and `rr.Draw`,
and as a package module every roc-ray type comes back as an unresolved type
variable. So both apps live where everything they reach is below them, and the
file name says which is which.

Everything that is only about one game is in that game's directory, `page.html`
included, because nothing but Roc's imports is constrained.

## Nothing is staged and nothing is rewritten

Every file compiles where it is written. There is one copy of a game's rules
and both builds compile that copy — not two copies, and not one copy edited on
its way into a build.

That is what the shape of `lib/Keys.roc` and `lib/Random.roc` is for.
`Input.Snapshot` is built like roc-ray's `Devices.Snapshot` -- same
`key_down`, same `input.mouse.position()` -- so a game's `read_controls`
compiles against either: `GameRunner` converts the host's snapshot into one and
`canvas_app_runner.js` builds one from the page's events.

It is called `Input` and not `Devices` for a reason worth keeping: `GameRunner`
imports both, and two nominal types with the same qualified name are ambiguous
to the compiler, not only to a reader. roc-ray calls a tick's whole input
`App.Input`, so that is the name ours takes. For the same reason `mouse` is a
field on the snapshot rather than an accessor method -- an accessor would have
collided with roc-ray's field under static dispatch. `Random`
offers roc-ray's surface because `rr.Random` re-exports a package and the wasm
build has none. Without those two, `snake/Board.roc` would need a different
import line per platform.

The one path that must be true rather than checked: `<game>_native.roc` names
roc-ray as `../../roc-ray`, a sibling of roc-apps.

## A game

    <name>_web.roc        the app a browser runs
    <name>_native.roc     the app roc-ray runs
    <name>/
        <Name>Game.roc    the Game value: the keyboard, the clock, the sounds
        page.html         the page
        …                 the rules and the drawing

## Trick or Treat, moved

Not a port from upstream: roc-apps' own Halloween movie, moved out of
`movies/halloween` and run by the arcade's runners instead of a player of its
own. It takes its title as its name here, so the two builds do not collide. Its twelve modules came across with their import lines changed and one
field dropped -- `Brush.Linear` here derives `len2` from `dx` and `dy` rather
than being told it.

**A MOVIE IS A GAME THAT DOES NOT READ ITS KEYBOARD.** `Movie` and `Game` ask
for the same size, rate, init, frame and title. The six fields `Movie` has
besides are all things a PLAYER did rather than things a movie is:

| `Movie` field | what it is here |
|---|---|
| `back`, `skip` | scrubbing: Left, Right and Enter |
| `scene`, `scenes` | somewhere to skip to; Halloween has one scene and never needed them |
| `clock` | a number for naming a screenshot, which no runner here takes |
| `roll` | a camera turned, which is `Camera.with_rotation` and a `View` mark now |

So the six became five keys and a `paused` flag in `HalloweenGame.roc`, and
the scrubbing that each player had to implement is written once, in the movie,
and runs on both ends without either knowing a movie from a game.

**It is the same movie to the byte.** Neither wire ever carried `len2`, and
this one uses no blend, view or image mark, so the two wasm modules pack
identical frames: sampled every 75 ticks across the whole 900-tick walk, the
movie's `renderFrame`/`bufPtr` and the arcade's `computeFrame`/`frameAt` answer
the same bytes, 13360 down to 5104 and back.

What did not move: `HalloweenProof.roc`, which paints into a buffer and prints
coarse cells for a box with no screen. It imports safari's `Raster`, and
dragging that in would be a second copy of safari.

## Pixel Workshop, ported

roc-ray's `examples/generated_assets`: a 16 x 16 pixel canvas you drag on, with
four colours and a brush note. Upstream calls it "a tiny paint program with a
mutable GPU texture", and porting it **deleted the mutable GPU texture**.

There, the drawing lives twice. `pixels : List(Color.Rgba)` is in the model and
a `Assets.Texture` is on the GPU, and the editor answers
`Edited : { model, edits }` so that every branch changing one remembers to emit
the upload that changes the other -- upstream's own comment says that returning
both together "is what keeps the two from drifting apart".

Here a frame is a VALUE computed from the model, so there is no second copy to
drift. `Shapes.Image` carries the pixels themselves. `Upload` and
`UploadRegion` are gone, the `Edit` type with them, and the third edit --
`Play` -- is the `sounds` bitmask this seam already had. **The port is smaller
than the original because a whole synchronisation problem stopped existing.**

The trade is honest and worth stating: the whole picture crosses the wire every
frame rather than the one cell you painted. At 256 pixels beside the 9,000
words a frame already carries, that is not close. **A LOADED image is a
different thing** -- nobody re-sends a tileset sixty times a second -- and it
still wants a handle and a way to load one, which is where top_down and
cave_climb stop.

Each painter gets the picture in the form it can paint: `putImageData` into a
scratch canvas and `drawImage` with smoothing off on a page, and on roc-ray the
rectangles it is, the same way a concave polygon arrives as triangles.

Upstream's five brush pitches are five tones here, at the frequencies those
pitches produce, because a tone on this seam is a pitch and a length. What did
not come across: `Mouse.set_cursor!`, which is an effect with nowhere to go.

**One thing was added, because it was missing on both ends.** Upstream lights
the swatch under the pointer and then never reads a click on it, so the palette
can only be chosen with 1-4; the hover was an affordance with nothing behind
it. Clicking a swatch picks that colour here, and sounds that colour's note.
`swatch_bounds` moved into `Rules.roc` for it -- three things have to agree
about where a swatch is now, not two.

`page_check` learned `DRAG` for this one. A check that cannot press a key checks
the attract screen; a check that cannot drag checks a canvas nobody painted on.

## Camera world, ported

Not a game: roc-ray's `examples/camera`, a world larger than the window with a
camera over it and a HUD that is not. It is here because it is the first thing
that could not be said at all.

**A FRAME HAD NO WAY TO SAY WHERE ITS SHAPES WERE.** Upstream calls
`frame.with_camera!(camera, |world| …)` — a scope a platform opens. A frame
that is a value cannot open a scope, so the camera became `View`, a second
mark in the list beside `Blend`: `eye.view()` says the shapes after it are in
the world and `Shapes.screen` says the ones after that are back in the window.
Both painters already wanted it that way — `setTransform` on a canvas,
`BeginMode2D` on roc-ray — and a frame that never says `View` paints exactly as
it did before.

**A CAMERA IS ALSO ARITHMETIC THE GAME ITSELF NEEDS**, which is why
`lib/Camera.roc` is a value with `screen_to_world`, `world_to_screen` and
`viewport` and not just six numbers on a wire. The pointer arrives in pixels
and the rules are written in the world; no runner can do that conversion,
because only the game knows which camera to do it with. `viewport` is what
keeps the grid from drawing thirty-one lines that are not on screen.

**THE DEMO IS ITS OWN ORACLE.** The pointer is marked twice — a ring drawn
through the camera at `screen_to_world(mouse)`, and a crosshair drawn on the
screen at `world_to_screen` of that same point. If the canvas matrix and
`Camera.roc` ever disagreed, the two would separate, on whichever end was
wrong. `web/lens_check.mjs` says the same thing without a screen: it feeds
`shapewire.js` four lenses and checks the matrix it builds against the map
written the geometric way, since `setTransform`'s six numbers are easy to
transpose.

`Rules.roc` is upstream's `move_player`, `axis` and the body of its `update!`,
expects included. `lib/Keys.roc` grew Q and E, `lib/Font.roc` a comma and a
per-cent sign, and `lib/Shapes.roc` a `ring` — a circle's outline as the
strokes it is, since a hollow circle over a world that moves cannot be faked
with a smaller disc on top.

It also has no sounds at all, which is the case the speaker widget had never
been handed.

## Breakout, ported

The closest to a straight port of the three: upstream is already six modules,
and `Ball.roc`, `Bricks.roc` and `Paddle.roc` came across with one import line
changed each. `Rules.roc` is upstream's `Game.roc`, renamed. `lib/Math.roc`
grew `add` and `scale` for the ball's motion.

## Pong, ported

Upstream is one flat app file, so its rules are wrapped in the module block
this dialect wants — an indent — and its test fixtures and `expect`s sit
outside that block, the way roc-ray's own snake modules have them. Everything
else in `Rules.roc` is upstream's, palette and tests included.

It is the first game here to read a HELD key: the paddle moves for as long as
W or S is down, where Snake only asks whether a key was struck. Note that a key
struck is also a key down for that tick, so a tap nudges the paddle once.

`lib/Math.roc` and `lib/Color.roc` exist for this port: pong's rules call
`Math.circle_rect` and `Math.clamp`, and its world stores a flash `Color.Rgba`.
Both mirror roc-ray's surface under the same module names, so the rules changed
their import lines and nothing else.

## Snake, ported

`Snake.roc` is upstream's verbatim. `Board.roc` and `Rules.roc` (upstream's
`Game.roc`, renamed so it does not collide with ours) changed their import
lines and nothing else. `SnakeDraw.roc` is the rewrite: upstream draws into a
`Draw.Frame`, and here a frame is a value, so it answers a list of shapes. Its
glow is upstream's, additive: `Blend(Add)` marks the run and `Blend(Over)` ends
it.

Sound: the game says which tones a step set off and what each one sounds like,
the page plays them and lights one pip per tone in the corner, and the native
runner ignores them for now. The width is part of the seam (`tone_count`),
because a runner that guesses it gets the first game with more than three
wrong.
