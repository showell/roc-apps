# The arcade

roc-ray's own example games, running on a web page and as native programs from
the same Roc. `movies/` is the other half of the building: a movie is played,
a game is driven.

    arcade/build.sh snake       the page into dev, http://<box>:9210/snake/
    arcade/native.sh snake      the native program, ~/build/roc-apps/arcade/snake/
    arcade/portable.sh snake    which files both builds run byte for byte
    node arcade/web/page_check.mjs snake

## What is portable, and how that is enforced

A game's rules are ONE file that both builds run — not two copies, and not one
copy rewritten on its way into a build. `portable.sh` compares what each build
actually staged against the source here and prints anything that is not
identical in both. Today that is four files and they are all platform edges:

| file | page | native |
|---|---|---|
| `lib/GameApp.roc` | the wasm edge | — |
| `ray/GameRunner.roc` | — | the roc-ray edge |
| `<game>/<Name>App.roc` | names the wasm platform | — |
| `<game>/main.roc` | — | names roc-ray |

The last two are the only files a build edits, and only their `platform "…"`
line, because a staging directory is flat and elsewhere on disk.

**That is what the shape of `Keys.roc` and `Random.roc` is for.** `Keys.Snapshot`
is built like roc-ray's `Devices.Snapshot` so a game's `read_controls` compiles
against either; `GameRunner` converts the host's snapshot into one, and
`blitter.js` builds one from keydown and keyup. `Random` offers roc-ray's
surface because the wasm build is a flat pile of Roc with no package manifest,
and `rr.Random` re-exports a package. Without those two, `Board.roc` would need
a different import line per platform, which is the thing being avoided.

## A game

    arcade/<name>/
        <Name>Game.roc    the Game value: the keyboard, the clock, the sounds
        <Name>App.roc     the wasm app
        main.roc          the roc-ray app
        page.html         the page
        …                 the rules and the drawing

`lib/` is the vocabulary: `Game`, `Keys`, `Random`, `Shapes`, `Brush`, `Font`,
and the wire and shader edges. It is a copy of `movie/`'s, not a share, so this
directory is a whole program.

## Snake, ported

`Snake.roc` is upstream's verbatim. `Board.roc` and `Rules.roc` (upstream's
`Game.roc`, renamed) changed their import lines and nothing else. `SnakeDraw.roc`
is the rewrite: upstream draws into a `Draw.Frame` and here a frame is a value,
so it answers a list of shapes. Its additive glow is approximated with radial
fills, because a shape carries a brush but not a blend mode.

Sound is reported but not played: the game says which tones a step set off, the
page lights a widget in the corner, and the native runner ignores it for now.
