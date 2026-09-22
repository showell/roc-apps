# Fast Track

Fast Track, the board game, ported from
[showell/elm-fasttrack](https://github.com/showell/elm-fasttrack). The rules
and the whole page are Roc; `web/fasttrack.js` runs the wasm and draws what
Roc answers.

    fasttrack/build.sh                  tests, builds and plays the page: http://<box>:9210/fasttrack/
    node fasttrack/web/page_check.mjs ~/build/roc-apps/next/fasttrack
    SEED=42 SETUP=5 SEATS=cccc CLICKS=300 SHOT=/tmp/b.png node fasttrack/web/page_check.mjs <dir>
    GAMES=40 node fasttrack/web/arena.mjs ~/build/roc-apps/next/fasttrack     the computer against the naive player

The page takes `?seats=` for who plays red, blue, green and purple — `h` a
person, `c` the computer, `n` the naive player — default `hccc`, you against
three computers; `?pause=<ms>` for the computer's pause per click (350);
`?seed=<millis>` to replay a deal; and `?setup=<n>` to start from one of
Setup.roc's scenarios (1 forced to reverse, 2 discard, 3 cover, 4 bullseye,
5 seven split).

## What is ported

Everything in the Elm game except `WhatIf.elm`, the start of a computer
player, which only logged; `Agent.roc` is the computer player instead. Four
players, as in Elm. Elm never said who won; `Game.winner` does (a color whose
four base squares are all its own). Each Elm module has a Roc
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
| `Agent` | | the computer player |
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

## The computer player

**It plays the real rules.** A choice is a message `Game.update_game` already
answers — a distinct card, a starting square, an end square, a card to
discard or cover — and a line of play is those messages applied to a real
Game. Elm's WhatIf.elm simulated a turn with a copy of the rules of its own
(one that never drew a card); this has no copy to drift.

**The search** goes a card play at a time: a play is a card and every click
it takes to finish, a split seven included. The best six positions after each
play are kept, and the best position at the end of the turn is the plan. A
line stops where the hand is refilled, so the computer never sees a card it
has not drawn.

**The heuristic** is distance: steps left for each piece to its own B4,
computed on the board's real graph on an empty board, with 4 extra steps for
waiting in the pen for an A, 6 or joker and 6 for waiting in the bullseye for
a face card. A position is worth the opponents' steps less four times the
mover's own, so sending a piece home counts, but moving your own counts more.

**The page drives it with a tick.** In a computer's seat the view names
`Codes.agent_step` as its `tick`; the page sends it back after a pause, and
each tick is one click — the plan is made again from the position in front of
it, and its first message played. So a person watches the computer choose a
card, a piece and a square, as they would. Nothing in a computer's turn takes
a click, and a stale click is ignored.

Measured with `arena.mjs` (LLVM build), 20 deals each played as cncn and
ncnc: the computer won 19 of 20 against the naive player. A computer click
averages about 5 ms, and the slowest seen was about 100 ms, under the page's
pause.

## Layout

| where | what |
|---|---|
| `*.roc` | the game, and `web.roc`, the app root |
| `web/platform/` | the platform: `main.roc` (`init`, `update`, `view`, `release` over a boxed model), `Wire.roc` (the view's types), `host.zig` (the exports `start`, `update`, `computeView`) |
| `web/build.zig`, `web/options.zig` | the host object; copies of canvas_apps' files, differing only in the comment |
| `web/fasttrack.js`, `web/page.html` | the page |
| `web/page_check.mjs` | plays the built page with no browser; see below |
| `web/arena.mjs` | the computer against the naive player, over many deals |
| `web/elm_random_oracle.mjs` | elm/random's arithmetic as compiled JavaScript |

## The checks

`roc test web.roc` runs every expect: Example.elm's tests, ElmRandom against
its oracle, Assoc's order, the codes' round trip, the first deal of seed 0.

`page_check.mjs` loads the built wasm, the generated reader and the page's own
`fasttrack.js` against a stand-in document, and plays: "done" when offered,
else the first square that takes a click, else the first enabled card, and
"oops" every seventh step. After every click it checks that sixteen pieces are
on the board, the board has its 89 squares, and the document holds exactly
the nodes Roc sent. In a computer's seat it sends the view's tick, and checks
that nothing else takes a click; after a win, that nothing does. With `SHOT` it paints the last board through
`canvas_apps/web/mini_canvas.mjs` (outlines as one-pixel rings, since that
rasterizer only fills) and prints the page's text.
