# Fast Track

The board game, in Roc: you play red against three computer players in the
browser. Ported from [showell/elm-fasttrack](https://github.com/showell/elm-fasttrack);
the rules and the whole page are Roc, and `web/fasttrack.js` only runs the
wasm and draws what Roc answers.

## Play

    fasttrack/build.sh          tests, builds and checks; publishes the dev page
    FAST=1 fasttrack/build.sh   the dev backend alone, no checks: a quick look

The page is http://143.244.172.148:9210/fasttrack/. In the URL: `?seed=<n>`
replays a deal, `?pause=<ms>` is the computer's pause per click (1050),
`?step=<ms>` a marble's time per square (150), and `?setup=<n>` starts from
one of Setup.roc's scenarios.

## The computer player

- **`Search.roc` plays the real rules.** It tries every line of play through
  the rest of the turn -- each a list of the messages `Game.update_game`
  answers -- and takes the one its strategy scores highest. It never sees a
  card it has not drawn. The same position reached two ways is one line;
  ties are broken by position, so the choice never depends on move order. A
  level past 20000 lines is cut, and counted (a hand of four jacks and a
  joker does it).
- **`Strategy.roc` says what a position is worth**: the squares its pieces
  stand on (`SquareValues.roc`, generated from Steve's ranking of the squares
  by `gen_square_values.roc` over `Rank.roc` and `Reach.roc`), plus
  `base_bonus` a step down its own base, plus the cards it hoards while they
  stay in its hand, worth less as pieces come home. Opponents count for
  nothing. `Strategy.champion` is what the page's computers play: base bonus
  2500, A, joker and J worth 1500, 1000, 500, 0 with 0-3 pieces home.
- **`TUNING.md`** is every experiment and its result, in order: what was
  tried, what won, what was noise.

## Tuning it

An experiment is a small app (`exp_*.roc`) on `cli/`, a native platform;
`fasttrack/run_exp.sh <name>` builds it with LLVM and runs it detached, its
log at `~/build/roc-apps/gen/fasttrack/<name>/log.md` (a line per seed, the
report at the end; earlier logs are kept).

- **Is B better than the champion?** Put B in `variants` in
  `exp_duplicate.roc`, e.g. `{ ..Strategy.champion, base_bonus: 3000 }`, and
  run it. Every seed is dealt four times with the decks turned a seat, and
  each strategy plays red on the same deals (`Arena.compare`). Read "paired,
  in standard errors": 500 seeds (2000 deals) take about five minutes a
  variant and resolve about 1.5 points of win rate. Confirm a winner on fresh
  seeds (`first_seed`) before it goes into `Strategy.champion`.
- **Is one decision right?** `exp_rollout.roc` plays a seed to red's turn and
  plays each of the champion's best lines out 1000 times from there, the
  undrawn cards shuffled afresh -- the sharpest tool there is, since whole
  games drown a decision in luck.
- **What do winners do?** `exp_cards.roc` (the cards each player drew and
  played) and `exp_table.roc` (turns, idle turns, captures, fast-track use)
  over `Arena.tally_game` and `Tables.roc`.
- **Why is a search slow?** `exp_search_size.roc`.
- **Did a change keep every decision?** Run `exp_cards` before and after and
  diff the two logs: the games must match (only a fast-track landing count
  may differ, when the same position is reached by another path).

What the experiments have taught, in short: the deal decides a lot (winners
draw more move-again cards), so strategies differ by a point or two of win
rate; compare them paired on the same deals; distrust anything under a
thousand deals, and anything not seen again on fresh seeds.

## How it is built

| modules | what |
|---|---|
| `Type` `Config` `Setup` `Color` `Piece` `LegalMove` `Player` `Move` `Game` `History` | the rules, ported from the Elm modules of the same names |
| `Board` `Routes` | every square a number from red's side (0-87 zone by zone, 88 the bullseye), a table turning them for each color, and every walk a card can make precomputed: a move is a lookup and a check that the walk passes no piece of its own color |
| `Assoc` `ElmRandom` | assoc-list's ordered dict and set; elm/random, to the bit, so a seed deals Elm's cards |
| `Page` `Motion` `Codes` `FastTrack` | the page as data, what each click moved (for the marbles), a click as a number, and the program the platform runs |
| `Strategy` `Search` `SquareValues` `Rank` `Reach` | the computer player and its square values |
| `Arena` `Tables` `exp_*.roc` `run_exp.sh` `cli/` | experiments |
| `RulesTests` `TeamTests`, expects in the modules | Elm's tests, the partnership rules, and the rest |

**The page has no virtual DOM and needs none** (`web/platform/Wire.roc`):
the board is 89 slots in a fixed order, drawn once and then patched, and the
rest of the page is a short list of nodes rebuilt on every click. A click
carries the code Roc gave the thing clicked; `fasttrack.js` knows no rule. A
view's `motions` are walked square by square before the computer's next
click. The reader for the view is generated by `glue/JsGlue.roc`.

**The checks** (`build.sh`): the square values must regenerate unchanged;
`roc test web.roc` runs every expect; the wasm is built by LLVM and by the dev
backend, and `web/backends_check.mjs` plays the two in lockstep;
`web/page_check.mjs` plays the built page against a stand-in document.

Partnerships (pagat.com's, and a "once home" style) and other seatings are
in the rules and the checks, but the page offers only red against three
computers.

## The compiler, met

The nightly (`2026-09-07-14d9829`), and what each needed:

| what | workaround |
|---|---|
| LLVM ends a `while $next != $d` loop after one pass when the pass is a local closure | the pass reports whether it changed anything (`Reach.fewest_over`; `findings/llvm-closure-loop-alias/`) |
| the dev backend dropped a variable from an interpolated string in a closure | `Str.concat` (`Game.winner`) |
| an or-pattern binding a variable in a lambda: `roc check` runs out of memory | one arm each |
| a literal list of Strategy records crashes `roc check` | build the list with `List.map` |
| a pure call on constants in `main!` is evaluated at compile time: a game simulation there crashes the compiler | tie it to the arguments (`seed + 0 * List.len(args)`) |
| the built-in platform of a headerless app maps a page per allocation (86% of the time in the kernel) and its `echo!` writes no newline | `cli/`, 12.7x faster; its `Echo.line!` writes the newline |
