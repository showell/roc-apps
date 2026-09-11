# roc-apps

Roc programs on this box, and the tooling around them: the Roc compiler
built from source, its test suite run as our installation check, and
safari, emitted from Codex by rust-codex-compiler's `rocemit` into
`safari/roc/` and graded by `safari/emitted.sh` against the Codex verdicts.

## The Roc is tracked; everything else the tools write is not

`safari/roc/` holds the emitted Roc -- one module per Codex chapter, the spec
apps, and the baked stills -- and is committed, because those files are the
point: they are the code the screensaver will import and the specs grade.
`safari/emitted.sh` rewrites the directory; a diff there is a change in what
the emitter says, and it is reviewed like any other change.

## Outputs live OUTSIDE this repository

Nothing the compiler writes lands here. The Roc checkout is
`~/showell_repos/roc` (roc-lang/roc, main); its build goes to
`~/build/roc/out` with caches in `~/build/roc/zig-cache` and
`~/build/zig-global`; every program's build and run output goes under
`~/build/roc-apps/`. A `git status` that shows a generated file is a
mistake to fix, not a file to commit.

## The compiler

**Use the nightly.** roc-lang/nightlies publishes a release build of the new
compiler every day (`gh release list -R roc-lang/nightlies`); the tarball's
`roc` is installed as `~/build/roc-nightly/roc`, and it is what the sweeps
and the wasm build use. It checks a 4,000-literal file in a third of a
second where the debug build below takes thirty, and the 54-unit sweep in
27 seconds where the debug build takes five minutes.

    cd ~/build/roc-nightly
    gh release download <tag> -R roc-lang/nightlies -p 'roc_nightly-linux_x86_64-*.tar.gz'
    tar xzf roc_nightly-linux_x86_64-<tag>.tar.gz
    ln -sfn roc_nightly-linux_x86_64-<tag>/roc roc

The build from source is for working ON the compiler:

Roc's new compiler (zig, `roc-lang/roc` main) needs zig 0.16.0, which this
box has at `~/zig-0.16.0/zig`. The build on this box is a DEBUG build:

    cd ~/showell_repos/roc
    ~/zig-0.16.0/zig build \
      --prefix ~/build/roc/out --cache-dir ~/build/roc/zig-cache \
      --global-cache-dir ~/build/zig-global

The binary is `~/build/roc/out/bin/roc` (2.6 GB, `roc version` prints
`debug-<sha>`). `-Doptimize=ReleaseFast` does not finish here: the final
`roc` link (all of LLVM, statically) is terminated on this 8 GB box, twice
(`~/build/roc/build.log`, `build2.log`). Debug is fast enough for the specs:
a small one runs in about three seconds, the 54 in about five minutes.

The installation check is Roc's own eval suite, run in two processes:

    ~/zig-0.16.0/zig build run-test-eval \
      --prefix ~/build/roc/out --cache-dir ~/build/roc/zig-cache \
      --global-cache-dir ~/build/zig-global

At 68267ddd: 2086 passed, 0 failed, 47 minutes (`~/build/roc/eval.log`).

The release page's `alpha4` tarballs are the OLD compiler and are not what
the ports were written against.
