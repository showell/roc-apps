# BASIC, in Roc

A BASIC interpreter written by hand in Roc, a web page that runs it, and
the corpora that grade it.

The dialect is **ECMA-55 Minimal BASIC** — a published standard with a
published acceptance suite. The extensions past it are the ones the 1978
Creative Computing listings and the page need, and each is marked `EXT`
where it is implemented.

## Why this subject

A BASIC interpreter is a small program with an enormous state space: every
run is thousands of iterations of the same dispatch over a different
machine, and a wrong answer is a single wrong value that a graded corpus
catches. It is idiomatic Roc throughout, so whatever it turns up in the
compiler is already in the form a report needs.

## Laying it out

    basic/roc/Basic.roc     the interpreter: the machine, the statements, the doors
    basic/roc/Listing.roc   ECMA-55's check of each line and statement, before a run
    basic/roc/Program.roc   ECMA-55's check of the whole program: jumps, loops, DEFs, arrays
    basic/roc/BasicApp.roc  the interpreter behind one boxed machine, for the page
    basic/wasm/             the page's platform and host
    basic/web/basic.html    the page
    basic/build.sh          the page and its module, into the preview
    basic/gen.py            one corpus program as its own Roc app
    basic/ladder.sh         run a corpus, grade, count
    basic/nbs-reports.txt   what each NBS program must show that its own verdict cannot
    basic/nbs-input/        replies for NBS programs whose corpus replies are placeholders
    basic/fetch.sh          the corpora, into ~/build/basic-corpus

## The doors

- **`run`** — a microcomputer's BASIC, as a batch: listing, keystrokes and
  a seed in, output text out. The games are graded through it.
- **`run_ecma`** — the same in ECMA-55: the listing is checked before its
  first statement, and TAB counts columns the standard's way. The NBS
  suite is graded through it.
- **`start` / `resume`** — the page's door. The machine suspends when it
  wants a line, sleeps, prints a line, or has run a few thousand
  statements; the page paints what it drew and resumes it.

Roc's default platform has no file or stdin effect, so for the batch doors
a program travels as a string literal and its keystrokes as a list of them.

## The corpora

**`nbs/`** — the National Bureau of Standards' 208 Minimal BASIC test
programs. Most grade themselves: a conformant run never prints
`TEST FAILED`. The rest cannot say so on their own — an exception that must
be reported, a malformed program that must be rejected, a verdict only a
reader can resolve — and `nbs-reports.txt` says what each must show.

**`games/`** — 99 listings from *BASIC Computer Games* (David Ahl, 1978),
public domain, each with a capture of what a real BASIC printed for the
keystrokes beside it. A listing that calls `RND` cannot match byte for
byte, since the captured run had its own random numbers; the rest are
graded.

## What Roc does not have

Each is something a real program needs and a synthetic benchmark does not:

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
- **A string of any length** in an INPUT reply (P112): ECMA-55's limit is
  at least 18 characters, and this one has none, so there is no string
  overflow to report.
- **THEN followed by a statement** rather than a line number, a quoted
  **prompt on INPUT**, `+` joining strings, and the extension statements
  and functions (POKE, PLOT, SLEEP, PEEK, CHR$ and the rest), which the
  check does not look inside.
