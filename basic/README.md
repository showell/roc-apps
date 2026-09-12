# BASIC, in Roc

A BASIC interpreter, hand-written in Roc, and the corpus that grades it.

The dialect is **ECMA-55 Minimal BASIC** — an actual published standard,
which matters because it comes with an actual acceptance suite. The
extensions past it are the ones the 1978 Creative Computing listings need,
and each is marked `EXT` where it is implemented.

## Why this subject

Everything we had shown Roc until now came out of a generator: emitted
Codex, in shapes no human writes. Both issues we filed had to be reduced
to a hand-written form before they were filable. This is the other kind of
subject — idiomatic Roc, written by hand, with two ready-made graded
corpora behind it.

It is also a program with a small amount of code and an enormous state
space, which is the shape that finds compiler bugs: every run is thousands
of iterations of the same dispatch over a different machine, and a wrong
answer is a single wrong value that the corpus catches.

## Laying it out

    basic/roc/Basic.roc   the interpreter
    basic/roc/Listing.roc ECMA-55's check of a whole listing, before it runs
    basic/nbs-reports.txt what each NBS exception and ERROR program must show
    basic/gen.py          one BASIC program as its own Roc app
    basic/ladder.sh       run the corpus, diff, count
    basic/fetch.sh        the corpora, into ~/build/basic-corpus

Roc's default platform has no file or stdin effect, so a program travels
as a string literal and its keystrokes as a list of them. The interpreter
is a pure function: listing, keystrokes and a seed in, output text out.

## The corpora

**`nbs/`** — 219 National Bureau of Standards Minimal BASIC test programs.
These **grade themselves**: a conformant interpreter never prints the
words `TEST FAILED`. That is the byte-exact grader.

**`games/`** — 99 listings from *BASIC Computer Games* (David Ahl, 1978),
public domain, each with a capture of what a real BASIC printed for the
keystrokes beside it. A listing that calls `RND` cannot match byte for
byte, since the captured run had its own generator; those are a smoke
test, and the ones without `RND` are graded.

## What Roc does not have

Written down as it was met, because each one is a thing a real program
needs and a synthetic benchmark does not:

- **No `exp`, no `log`, no `floor`, no `round` on `F64`.** There is `abs`,
  `sqrt`, `sin`, `cos`, `tan`, `atan` and `pow`, and that is the list. So
  `EXP` is `pow` on e, `LOG` is an atanh series after a reduction by
  powers of two, and `INT` is truncation corrected downward.
- **No number parsing on `Str`.** No `to_f64`, no `to_i64`. A numeric
  literal is accumulated from its bytes as it is scanned.
- **No `List.walk`.** Every fold in here is an explicit recursion.

## Accepted past ECMA-55

The NBS suite's ERROR programs are malformed on purpose, and ECMA-55 lets
a processor either reject such a program or run it and document what it
does. The ECMA-55 door (`run_ecma`) rejects before the first statement;
these are the forms it runs instead, each a row marked `accepts` in
`nbs-reports.txt`:

- **Spaces before a line number** (P187) are skipped.
- **No space between a line number and its keyword**, or before THEN
  (P190: `250LET`, `10THEN`).
- **A sign after an operator** (P038: `4 ^ -2` is `4 ^ (-2)`).
- **Lowercase** (P204, P205): upper-cased outside quotes, kept inside.
- **`<`, `>`, `<=` and `>=` between strings** (P206): byte order.
- **THEN followed by a statement** rather than a line number, a quoted
  **prompt on INPUT**, `+` joining strings, and the extension statements
  and functions (POKE, PLOT, SLEEP, PEEK, CHR$ and the rest), which the
  check does not look inside.
