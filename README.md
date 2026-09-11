# roc-apps

Roc programs on this box, and the tooling around them: the Roc compiler
built from source, its test suite run as our installation check, and the
apps ported here from Codex.

## Outputs live OUTSIDE this repository

Nothing the compiler writes lands here. The Roc checkout is
`~/showell_repos/roc` (roc-lang/roc, main); its build goes to
`~/build/roc/out` with caches in `~/build/roc/zig-cache` and
`~/build/zig-global`; every program's build and run output goes under
`~/build/roc-apps/`. A `git status` that shows a generated file is a
mistake to fix, not a file to commit.

## The compiler

Roc's new compiler (zig, `roc-lang/roc` main) needs zig 0.16.0, which this
box has at `~/zig-0.16.0/zig`. Build:

    cd ~/showell_repos/roc
    ~/zig-0.16.0/zig build -Doptimize=ReleaseFast \
      --prefix ~/build/roc/out --cache-dir ~/build/roc/zig-cache \
      --global-cache-dir ~/build/zig-global

The binary is `~/build/roc/out/bin/roc`. The release page's `alpha4`
tarballs are the OLD compiler and are not what the ports were written
against.
