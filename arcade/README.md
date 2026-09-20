# The arcade

roc-ray's own example games, running on a web page and as native programs from
the same Roc. `movies/` is the other half of the building: a movie is played, a
game is driven.

    arcade/build.sh snake       the page,   http://<box>:9210/snake/
    arcade/native.sh snake      the native program
    node arcade/web/page_check.mjs snake
    node arcade/web/lens_check.mjs      the camera, on both ends

Four of them: `snake`, `pong`, `breakout`, `camera`.

## Where the splits are

| | |
|---|---|
| `snake_web.roc` | the app a browser runs — sits on `web/platform/`, uses `lib.GameApp` |
| `snake_native.roc` | the app roc-ray runs — uses `native/GameRunner` |
| `snake/` | **the game**, and everything that is only about it, its page included. Neither app's half; it cannot tell which is running |
| `lib/` | a package: `Game`, `Keys`, `Random`, `Shapes`, `Brush`, `Font`, and the two wire edges |
| `web/` | the page's end: the wasm platform and host, `shapewire.js` (a frame, decoded and painted), `game_runner.js` (the clock, the input, the speaker), `page_check.mjs`, `lens_check.mjs` |
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
`game_runner.js` builds one from the page's events.

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
