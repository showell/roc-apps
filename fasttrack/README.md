# Fast Track

Fast Track, the board game, ported from
[showell/elm-fasttrack](https://github.com/showell/elm-fasttrack). The rules
and the whole page are Roc; `web/fasttrack.js` runs the wasm and draws what
Roc answers.

    fasttrack/build.sh                  tests, builds and plays the page: http://<box>:9210/fasttrack/
    node fasttrack/web/page_check.mjs ~/build/roc-apps/next/fasttrack
    SEED=42 SETUP=5 SEATS=cccc CLICKS=300 SHOT=/tmp/b.png node fasttrack/web/page_check.mjs <dir>
    FAST=1 fasttrack/build.sh           the dev backend alone, no checks: a quick look
    fasttrack/run_exp.sh exp_win_focus                                         an experiment, detached

The page takes `?seats=` for who plays red, blue, green and purple — `h` a
person, `c` the computer — default `hccc`, you against three computers;
`?teams=anytime|oncehome` for partnerships; `?pause=<ms>` for the computer's pause per click (350);
`?seed=<millis>` to replay a deal; and `?setup=<n>` to start from one of
Setup.roc's scenarios (1 forced to reverse, 2 discard, 3 cover, 4 bullseye,
5 seven split).

## What is ported

Everything in the Elm game except `WhatIf.elm`, the start of a computer
player, which only logged; `Search.roc` and `Strategy.roc` are the computer
player instead. Four
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
| `Strategy`, `Search`, `SquareValues`, `Board` | | the computer player: what it plays for, its turn search, the square values, square numbering |
| `Arena`, `exp_*.roc` | | experiments on the strategy |
| `Rank`, `Reach`, `gen_square_values.roc` | | Steve's ranking of the squares, and the generator that writes SquareValues from it |
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

**It plays the real rules** (`Search.roc`). A choice is a message
`Game.update_game` already answers — a distinct card, a starting square, an
end square, a card to discard or cover — and a line of play is those
messages applied to a real Game. Elm's WhatIf.elm simulated a turn with a
copy of the rules of its own; this has no copy to drift.

**The search** tries every line of play to the end of the turn: a play is a
card and every click it takes, a split seven included, and a move-again card
goes on to the next. A player holding a playable card must play one. The
same position reached two ways is kept once. A line stops where the hand is
refilled, so the computer never sees a card it has not drawn; it searches
again with the cards it drew.

**The strategy is a value** (`Strategy.roc`). A position is worth the
squares its team's pieces stand on — `SquareValues.roc`, a table generated
from Steve's ranking of the squares (`Rank.roc`, `gen_square_values.roc`):
the best square, B4, 6100, the pen 0 — plus a bonus a step down its own
base, plus what the cards it hoards are worth while they stay in its hand,
tapering as pieces reach the base. Opponents' pieces count for nothing, so a
capture is only ever an accident. `Strategy.champion` is what every computer
seat plays: base bonus 1000, A and joker worth 1500, 1000, 500 and 0 with 0,
1, 2 and 3 pieces home.

**The page drives it with a tick.** In a computer's seat the view names
`Codes.agent_step` as its `tick`; the page sends it back after a pause, and
each tick is one click of the plan the computer made for its turn. So a
person watches the computer choose a card, a piece and a square, as they
would. Nothing in a computer's turn takes a click, and a stale click is
ignored.

**Experiments are values too** (`Arena.roc`). An experiment is a small app
(`exp_*.roc`) that lists variants — a Strategy for each seat, the one under
test in red's — plays them seed by seed, printing a line a game, and ends
with `Arena.report`: red's wins, red's turns to get home, idle turns (turns
begun with a discard), captures, and two checks that read 0. `run_exp.sh`
builds one with LLVM and runs it detached, each log line stamped with the
time; the built-in platform's `echo!` writes no newline, so each app has a
`line!`. Every variant is dealt the same cards: each player's deck is
shuffled once from the seed. When an experiment settles a number, it goes
into `Strategy.champion`, the losing variants go, and `TUNING.md` keeps the
result.

## The compiler, met

The nightly (`2026-09-07-14d9829`) got four things wrong while this was
built. Two failed loudly, and two quietly produced a page that ran and was
wrong, which is why `build.sh` builds with both backends and
`web/backends_check.mjs` plays the builds against each other in lockstep:

| what | where | workaround |
|---|---|---|
| LLVM ends a `while $next != $d` loop after one pass when the pass is a local closure: an early computer's distance tables came out all "far" | the relaxation loops, now `Reach.fewest_over` | the pass reports whether it changed anything; reduced in `findings/llvm-closure-loop-alias/` |
| the dev backend dropped `partner` from `"${player.color} and ${partner}"` in a closure inside `Game.winner` | `Game.winner` | `Str.concat` in each arm |
| an or-pattern binding a variable (`Partner(p) \| PartnerOnceHome(p) =>`) in a lambda: `roc check` fails with OutOfMemory | `Game.winner`, `Strategy.team` | one arm each |
| a closure passed as an argument (`partner_of : U64 -> U64`): `roc build --opt=speed` crashes with SIGSEGV | an early computer's danger term, since removed | a list of partners instead |

Only the first is reduced; the others are recorded here as met, not as
findings.

## Layout

| where | what |
|---|---|
| `*.roc` | the game, and `web.roc`, the app root |
| `web/platform/` | the platform: `main.roc` (`init`, `update`, `view`, `release` over a boxed model), `Wire.roc` (the view's types), `host.zig` (the exports `start`, `update`, `computeView`) |
| `web/build.zig`, `web/options.zig` | the host object; copies of canvas_apps' files, differing only in the comment |
| `web/fasttrack.js`, `web/page.html` | the page |
| `web/page_check.mjs` | plays the built page with no browser; see below |
| `web/elm_random_oracle.mjs` | elm/random's arithmetic as compiled JavaScript |
| `web/backends_check.mjs` | the LLVM and dev builds played against each other, click for click |

## The checks

`build.sh` first regenerates the square values and fails if
`SquareValues.roc` differs. `roc test web.roc` runs every expect: Example.elm's
tests, ElmRandom against its oracle, Assoc's order, the codes' round trip,
the first deal of seed 0, the partnership rules, the strategy's values, and
four computers playing a game to its end.

`page_check.mjs` loads the built wasm, the generated reader and the page's own
`fasttrack.js` against a stand-in document, and plays: "done" when offered,
else the first square that takes a click, else the first enabled card, and
"oops" every seventh step. After every click it checks that sixteen pieces are
on the board, the board has its 89 squares, and the document holds exactly
the nodes Roc sent. In a computer's seat it sends the view's tick, and checks
that nothing else takes a click; after a win, that nothing does. With `SHOT` it paints the last board through
`canvas_apps/web/mini_canvas.mjs` (outlines as one-pixel rings, since that
rasterizer only fills) and prints the page's text.
