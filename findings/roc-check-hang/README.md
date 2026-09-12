# `roc check` spins on a small program

**Not filed yet.** The reproducer and the reduction that found it, kept
here so the numbers and the file are one thing.

## What happens

`hang.roc` is 29 lines and self-contained. `roc check` on it does not
finish: killed after ten minutes at 100% of one core and 80 MB, which is
a loop rather than an allocation blow-up.

    $ roc --version
    Roc compiler version nightly-2026-09-11-793f9d8
    $ time roc check --no-cache hang.roc
    (killed at 600s)

The build is the release tarball from roc-lang/nightlies
(`roc_nightly-linux_x86_64-2026-09-11-793f9d8`), not a debug build of our
own, on x86-64 Linux.

## Where it came from

It is a reduction of a program in a corpus we emit from Codex, which took
2.7 seconds to check as it shipped. The 2.7 seconds was already odd: the
file is 40 lines and its run takes 3 ms. Inlining the three imported
modules into one file, which should have changed nothing, turned the 2.7
seconds into a hang, so the same definitions cost seconds when the
compiler solves them as four modules and do not terminate when it solves
them as one.

## The reduction

`reduce.py` shrinks the file while checking at every step that it still
spins, so nothing in `smallest.roc` is incidental. It removes a line, or a
record field, or an argument, keeps the removal only when the timeout
still fires, and writes the smallest file it has reached along with a log.

    findings/roc-check-hang/reduce.py hang.roc 15

## What is already ruled out

Each of these was tested on its own and is NOT the cause:

- mutual recursion between the functions (removing it still spins);
- the record update `{ ..b, field: x }` (replacing it still spins);
- the nested `if` (flattening it still spins);
- a `List` field in the record (an `I64` field still spins);
- an undefined name, which errors in 28 ms as it should.

What remains in the smallest file so far: three record type aliases, a
self-recursive function over one of them whose recursive call rebuilds its
argument through two other functions, and an app that calls it once.
