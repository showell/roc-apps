# The arcade

roc-ray's own example games, running on a web page and as native programs from
the same Roc. `movies/` is the other half of the building: a movie is played, a
game is driven.

    arcade/build.sh snake       the page,   http://<box>:9210/snake/
    arcade/native.sh snake      the native program
    node arcade/web/page_check.mjs snake

## Where the splits are

| | |
|---|---|
| `snake_web.roc` | the app a browser runs — sits on `web/platform/`, uses `lib.GameApp` |
| `snake_native.roc` | the app roc-ray runs — uses `native/GameRunner` |
| `snake/` | **the game**, and everything that is only about it, its page included. Neither app's half; it cannot tell which is running |
| `lib/` | a package: `Game`, `Keys`, `Random`, `Shapes`, `Brush`, `Font`, and the two wire edges |
| `web/` | the page's end: the wasm platform and host, `blitter.js`, `page_check.mjs` |
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
`Keys.Snapshot` is built like roc-ray's `Devices.Snapshot`, so a game's
`read_controls` compiles against either: `GameRunner` converts the host's
snapshot into one and `blitter.js` builds one from keydown and keyup. `Random`
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
additive glow is approximated with radial fills, because a shape carries a
brush but not a blend mode.

Sound is reported but not played: the game says which tones a step set off, the
page lights a widget in the corner, and the native runner ignores it for now.
