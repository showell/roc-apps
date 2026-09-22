# Fast Track

Fast Track, the board game, ported from
[showell/elm-fasttrack](https://github.com/showell/elm-fasttrack). The rules
and the whole page are Roc; `web/fasttrack.js` runs the wasm and draws what
Roc answers.

    fasttrack/build.sh                  tests, builds and plays the page: http://<box>:9210/fasttrack/
    node fasttrack/web/page_check.mjs ~/build/roc-apps/next/fasttrack
    SEED=42 SETUP=5 CLICKS=300 SHOT=/tmp/b.png node fasttrack/web/page_check.mjs <dir>

The page takes `?seed=<millis>` to replay a deal and `?setup=<n>` to start
from one of Setup.roc's scenarios (1 forced to reverse, 2 discard, 3 cover,
4 bullseye, 5 seven split).

## What is ported

Everything in the Elm game except `WhatIf.elm`, the start of a computer
player, which only logged. Four players, as in Elm. Each Elm module has a Roc
module of the same name and the same functions, in snake case:

| Roc | from | what |
|---|---|---|
| `Type` | Type.elm | the vocabulary; Elm's tuples are records, its Maybe is Try |
| `Config` `Setup` `Color` `Graph` `History` | the same | the board's squares, the cards, the starting setups, zone order, graph walks, undo |
| `Piece` `LegalMove` `Player` `Move` `Game` | the same | the rules |
| `Page` | View.elm, Polygon.elm | the page as data |
| `FastTrack` | Main.elm | the model, and the program the platform runs |
| `Assoc` | pzp1997/assoc-list, erlandsona/assoc-set | ordered dict and set |
| `ElmRandom` | elm/random | `initialSeed`, `int`, `step`, to the bit |
| `Codes` | | a message as the number a click sends back |
| `RulesTests` | tests/Example.elm | the Elm tests, test for test |

Two libraries are ported rather than replaced, because their behaviour
reaches the game:

- **Assoc keeps assoc-list's order**: `insert` removes and prepends. That
  order is the order of the legal moves, and Elm's `==` on these lists, which
  History's undo check uses, sees it.
- **ElmRandom deals Elm's cards.** Elm compiles `*` to a double multiply, and
  `peel`'s product passes 2^53, so JavaScript rounds before taking the low 32
  bits. `peel` rounds through F64 at the same point; exact integer arithmetic
  deals entirely different cards. `web/elm_random_oracle.mjs` is the
  arithmetic as compiled JavaScript, and its draws are pinned in the expects.

Setup.elm's constant developer switch is a parameter of `Game.begin_game`,
which is how the page and the checks start from its scenarios.

## The page: no virtual DOM, and none needed

Elm rebuilds the page on every message and lets its virtual DOM diff it. This
game does not need that, because **the board never changes shape**: once the
players are seated it is 89 squares, and rotating it to the next player
recolors squares without moving one. So the page is two things
(`web/platform/Wire.roc`):

- **`slots`**, one per square, always in the same order. The page builds the
  SVG once and afterwards sets only the attributes that differ from the last
  view. Roc computes the geometry too (Polygon.elm's panels, pushed out by the
  incircle radius and turned about the centre); with four sides every turn is
  a multiple of 90 degrees, so a square stays a square and a slot is a centre
  and a size.
- **`nodes`**, the rest of the page, as a flat list in document order: each
  node names its parent by index. The page rebuilds these on every click —
  a handful of buttons and lines — and moves the board's SVG into the node
  tagged `board`.

A click carries the code Roc gave the thing clicked (`Codes.roc`), and the
page hands it straight to `update`. Nothing in `fasttrack.js` knows a rule, a
color or a word of the game.

The page's reader is generated: `build.sh` runs `roc glue` with
`glue/JsGlue.roc` over the platform, which is why `Wire.roc` spells the view
out in full. Fast Track is JsGlue's second user and the reason it reads `Str`.

## Layout

| where | what |
|---|---|
| `*.roc` | the game, and `web.roc`, the app root |
| `web/platform/` | the platform: `main.roc` (`init`, `update`, `view`, `release` over a boxed model), `Wire.roc` (the view's types), `host.zig` (the exports `start`, `update`, `computeView`) |
| `web/build.zig`, `web/options.zig` | the host object; copies of canvas_apps' files, differing only in the comment |
| `web/fasttrack.js`, `web/page.html` | the page |
| `web/page_check.mjs` | plays the built page with no browser; see below |
| `web/elm_random_oracle.mjs` | elm/random's arithmetic as compiled JavaScript |

## The checks

`roc test web.roc` runs every expect: Example.elm's tests, ElmRandom against
its oracle, Assoc's order, the codes' round trip, the first deal of seed 0.

`page_check.mjs` loads the built wasm, the generated reader and the page's own
`fasttrack.js` against a stand-in document, and plays: "done" when offered,
else the first square that takes a click, else the first enabled card, and
"oops" every seventh step. After every click it checks that sixteen pieces are
on the board, the board has its 89 squares, and the document holds exactly
the nodes Roc sent. With `SHOT` it paints the last board through
`canvas_apps/web/mini_canvas.mjs` (outlines as one-pixel rings, since that
rasterizer only fills) and prints the page's text.

Not yet checked against the Elm build itself: that needs the `elm` binary to
replay seeded games side by side.
