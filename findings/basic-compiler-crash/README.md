# BasicApp crashes the compiler on every nightly after 09-11

**Not reduced, not reported.** `basic/roc/BasicApp.roc` builds on
`nightly-2026-09-11-793f9d8` (the published BASIC page is that build) and
crashes the compiler on `2026-09-19-d025939`, `2026-09-22-e494788` and
`2026-09-23-c7852fd`, with a fresh cache, both `--target=wasm32 --opt=dev` and
a native `--opt=dev` build:

    Segmentation fault (SIGSEGV) in the Roc compiler.
    Fault address: 0xfffffffffffffff8

(09-15 dies of SIGILL on this box for any program.) BASIC is parked, so
`basic/build.sh` pins 09-11 instead of `../../roc-nightly.txt`. Found
2026-09-24 moving the pages to 09-22.
