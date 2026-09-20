# The arcade

roc-ray's own example games, running on a web page and as native programs from
the same Roc. `movies/` is the other half of the building: a movie is played, a
game is driven.

    arcade/build.sh snake       the page,   http://<box>:9210/snake/
    arcade/native.sh snake      the native program
    node arcade/web/page_check.mjs snake

## Where the splits are

The two ends of a game are two files, named for where they run:

| | |
|---|---|
| `snake_web.roc` | the app a browser runs. Sits on `web/platform/`, uses `lib/GameApp` |
| `snake_native.roc` | the app roc-ray runs. Sits on roc-ray, uses `native/GameRunner` |
| `snake/` | **the game.** Both apps import it and neither can tell which is running |
| `lib/` | the vocabulary both ends use: `Game`, `Keys`, `Random`, `Shapes`, `Brush`, `Font` |
| `web/` | the page's end: the wasm platform and host, `blitter.js`, the page |
| `native/` | roc-ray's end: `GameRunner.roc` |

**The two app files sit at the top rather than beside the game because an app
file is where Roc's package root is**, and a relative import may not climb
above it (`roc check` says so; `roc build` segfaults instead, which is a
compiler bug worth reporting). So everything an app reaches sits below it, and
a module inside `snake/` may say `import ../lib/Random` because that stays
within the root.

## Nothing is staged and nothing is rewritten

Every file compiles where it is written. There is one copy of the game's rules
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

    arcade/<name>/
        <Name>Game.roc    the Game value: the keyboard, the clock, the sounds
        …                 the rules and the drawing

## Snake, ported

`Snake.roc` is upstream's verbatim. `Board.roc` and `Rules.roc` (upstream's
`Game.roc`, renamed so it does not collide with ours) changed their import
lines and nothing else. `SnakeDraw.roc` is the rewrite: upstream draws into a
`Draw.Frame`, and here a frame is a value, so it answers a list of shapes. Its
additive glow is approximated with radial fills, because a shape carries a
brush but not a blend mode.

Sound is reported but not played: the game says which tones a step set off, the
page lights a widget in the corner, and the native runner ignores it for now.
