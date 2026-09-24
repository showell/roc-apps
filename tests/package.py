#!/usr/bin/env python3
"""Package the ported Codex tests the way Roc shares code: a package.

    tests/package.py             write tests/ported/, verify every file, report
    tests/package.py --cap 16    a bigger package (KB of new text per test)
    tests/package.py --cap 0     every test the ladder passes, at any size
    tests/package.py --check     verify what is already there, write nothing

rocemit writes one Roc module per Codex chapter, and a Codex unit carries
every chapter it cites -- so 137 units carry 137 copies of ListUtils. That
is Codex's bundling, not Roc's. Roc shares code with a PACKAGE, so the
chapters go into `ported/codex/` once, under a package header, and each
test is a short app that imports what it needs:

    app [main!] { cdx: "./codex/main.roc" }
    import cdx.ListUtils

A chapter's text depends only on the chapter, which is what makes the
deduplication sound: rocemit emits a chapter from the chapter, not from the
program that cites it. The exception is the state a program threads -- a
chapter reaching a device is emitted over `Mem` or over `Machine` -- and a
test whose chapter is already here in another form is dropped, never given
the wrong one.

Each app is RUN and its output compared with the verdict before it is
kept, so nothing here ships untested.

**Not every passing test is packaged.** A Codex chapter is big -- one is
28 KB and exactly one test needs it -- so the tests are taken cheapest
first and one is dropped when it would add more than `--cap` KB of
chapter text nobody else needs.

A test is charged for the chapters no earlier test needed. rocemit's own
modules (`CceText`, `CceChar`, `Prelude`) are not chapters and are free: the
runtime every printing test needs, which charged to the first of them put
everything that prints over the cap. The default of 16 takes about two
thirds of the corpus; the whole set is in roc-apps either way.
"""
import os, re, shutil, subprocess, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "ported")
GEN = os.path.expanduser("~/build/roc-apps/gen/tests")
VERDICTS = os.path.expanduser("~/build/roc-apps/gen/verdicts")
# The compiler every roc-apps build uses: ../roc-nightly.txt.
NIGHTLY = open(os.path.join(HERE, "..", "roc-nightly.txt")).read().strip()
ROC = os.environ.get("ROC", os.path.expanduser(f"~/build/roc-nightly/{NIGHTLY}/roc"))
TESTS_ROOT = os.environ.get("TESTS_ROOT", os.path.expanduser("~/showell_repos/cobblestone-u62"))
COBBLESTONE = "https://github.com/damiant3/Cobblestone"
ROC_APPS = "https://github.com/showell/roc-apps"

HEADER = """# {title}
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      {cob}/blob/master/codex/test/{unit}.codex
#   emitted   by rocemit, {apps} (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
{expect}
"""


def units():
    """The units the ladder ran to their verdict, in order."""
    out = []
    for line in open(os.path.join(HERE, "ledger.txt"), encoding="utf-8", errors="replace"):
        # A SLOW unit (tests/slow.txt) was left out of the run; its last
        # real verdict is the one that counts here.
        if line.startswith("PASS ") or (line.startswith("SLOW ") and "| last PASS," in line):
            out.append(line.split()[1])
    return out


def imports_of(text):
    return [l.split()[1] for l in text.split("\n") if l.startswith("import ")]


def modules(unit):
    """A unit's emitted modules: the app's text and the chapters by name.

    rocemit already drops a chapter the app cannot reach, so everything
    here is part of the program.
    """
    d = os.path.join(GEN, unit)
    files = sorted(f for f in os.listdir(d) if f.endswith(".roc"))
    texts = {f[:-4]: open(os.path.join(d, f)).read() for f in files}
    app = [n for n, t in texts.items() if "\nmain! = " in t]
    if len(app) != 1:
        return None, None, f"{len(app)} apps among the modules"
    name = app[0]
    chapters = {n: t for n, t in texts.items() if n != name}
    return texts[name], chapters, None


def as_app(text, chapters):
    """The emitted app as a Roc app over the package.

    The header comes first and the emitted module's own imports become
    imports from the package; a program that reaches no chapter needs no
    package at all.
    """
    imports = imports_of(text)
    head = 'app [main!] { cdx: "./codex/main.roc" }' if imports else "app [main!] {}"
    body = [l for l in text.split("\n") if not l.startswith("import ")]
    while body and not body[0].strip():
        body.pop(0)
    return "\n".join([head, ""] + ["import cdx." + m for m in imports] + ([""] if imports else []) + body)


def trimmed(text):
    return text.rstrip("\n") + "\n" if text.strip() else text


def zig_name(unit):
    return "codex_" + unit.replace("-", "_")


def write_artifacts(kept, times, shared, cap):
    """The expected outputs, a ready-to-paste runner table, and the README."""
    exp_dir = os.path.join(OUT, "expected")
    os.makedirs(exp_dir, exist_ok=True)
    rows, consts = [], []
    for unit in kept:
        expect = open(os.path.join(VERDICTS, unit + ".expected")).read()
        open(os.path.join(exp_dir, zig_name(unit) + ".txt"), "w").write(expect)
        consts.append(
            f'const {zig_name(unit)}_stdout =\n'
            + "\n".join(f'    \\\\{l}' for l in expect.rstrip("\n").split("\n"))
            + '\n    ++ "\\n";\n'
        )
        rows.append(
            f'    .{{ .id = 0, .suite = .codex, .name = "codex: {unit}", .backend = .interpreter, '
            f'.body = .{{ .command = .{{ .args = &.{{"--opt=interpreter"}}, '
            f'.roc_file = "test/codex/{zig_name(unit)}.roc", .stdout_exact = {zig_name(unit)}_stdout }} }} }},'
        )
    open(os.path.join(OUT, "runner_rows.zig"), "w").write(
        "// Generated by roc-apps tests/package.py. One row per ported test,\n"
        "// in the shape src/cli/test/parallel_cli_runner.zig uses. The\n"
        "// expected text is also in expected/<name>.txt, byte for byte.\n\n"
        + "\n".join(consts) + "\n" + "\n".join(rows) + "\n"
    )
    total = sum(times[u] for u in kept)
    slow = sorted(((times[u], u) for u in kept), reverse=True)[:5]
    pkg_kb = sum(len(t) for t in shared.values()) // 1024
    app_kb = sum(os.path.getsize(os.path.join(OUT, zig_name(u) + ".roc")) for u in kept) // 1024
    open(os.path.join(OUT, "README.md"), "w").write(README.format(
        n=len(kept), total=f"{total:.0f}",
        median=f"{sorted(times[u] for u in kept)[len(kept)//2]*1000:.0f}",
        slow="\n".join(f"| `{u}` | {t*1000:.0f} |" for t, u in slow),
        table="\n".join(stat_line(u, times[u]) for u in sorted(kept)),
        cob=COBBLESTONE, apps=ROC_APPS, chapters=len(shared), pkg_kb=pkg_kb, app_kb=app_kb,
        all_n=len(units()), cap=cap, n_slow=len(SLOW),
    ))


def stat_line(unit, t):
    path = os.path.join(OUT, zig_name(unit) + ".roc")
    lines = sum(1 for _ in open(path))
    return f"| `{zig_name(unit)}.roc` | {lines} | {t*1000:.0f} |"


README = """# Codex tests, ported to Roc

{n} programs from [Cobblestone]({cob})'s own test suite, machine-translated
from Codex to Roc and checked against the output Cobblestone records for
each one.

{n} of the {all_n} the emitter runs to their verdict are here. Two kinds
are left out. {n_slow} take more than a quarter of a second, and the reason
is the compiler rather than the program, so they are held back by name
rather than being a performance report inside a regression suite. The
rest are left out on size: a Codex chapter can be 28 KB and needed by
exactly one program, so a test goes when it would add more than {cap} KB
of chapter text nobody else needs. Everything is in [roc-apps]({apps}).

**These were not written for Roc.** They are one compiler's test suite for
another language, translated; they may or may not be valuable here, and
they are offered rather than recommended. What they are is ordinary
programs that must print an exact thing: arithmetic, lists, records,
tagged unions, pattern matching, recursion, text and a private character
alphabet, in shapes nobody designing a Roc test would have chosen.

## The shape

`codex/` is a package of the {chapters} Codex chapters the tests are
emitted from ({pkg_kb} KB), and each test is a short app over it
({app_kb} KB for all {n}):

    app [main!] {{ cdx: "./codex/main.roc" }}
    import cdx.ListUtils

A Codex program carries every chapter it cites, so the {all_n} units carried
{all_n} copies of the same chapters. A chapter's emitted text depends only on
the chapter, which is what lets them be shared here -- with one exception:
a chapter that reaches a device is emitted over the state its program
threads, so the same chapter is a different module in a program that reaches
the machine. Those programs are all far over the size cap anyway, and a test
whose chapter is already here in another form is dropped rather than given
the wrong one. Nothing was edited by hand, and every app was run and
compared with its expected output before it was kept.

## Where they come from

Each app is one Codex program from `codex/test/` in
[Cobblestone]({cob}), emitted by `rocemit`, the Codex-to-Roc emitter in
[roc-apps]({apps}). The header of every file names its source and the
bytes it must print; `expected/<name>.txt` holds those bytes exactly.

## Running them

    roc run codex_neg_int_parse.roc

`runner_rows.zig` holds one generated row per test in the shape
`src/cli/test/parallel_cli_runner.zig` uses, with the expected text as a
const, if wiring them into that table is how you would take them.

## What they cost

{total} seconds for all {n} on one core, median {median} ms. Every one of
them RUNS in about 3 ms; the rest is the compiler. The slowest:

| test | ms |
|---|---|
{slow}

The compiler EVALUATES a call whose arguments are known, so for these
programs the compile time is largely the program's own work and the run is
then two or three milliseconds. The {n_slow} where that adds up to more than
a quarter of a second are held back by name, and `ttt-perfect` is the
clearest case: 2.5 seconds to compile, because the
compiler plays the whole-tree tic-tac-toe search, and 3 ms to run, because
by then the answer is a constant.

## The tests

| file | lines | ms |
|---|---|---|
{table}
"""


# **SLOW PROGRAMS ARE HELD BACK BY NAME.** A regression suite should not
# also be a performance report: these each take more than a quarter of a
# second, and the reason is the compiler rather than the test. Most spend it
# in compile-time evaluation, which is roc-lang/roc#11334; bloom-spread
# spends it in the allocator, which is #11335; lib@hkdf-test is the one that
# really does work at run time. They are good programs and they are in
# roc-apps; they are simply not regression tests.
#
# **The list is MEASURED, not inherited.** A cold `roc build`, and then the
# built binary on its own, against a 0.11 s baseline, says where a program's
# time goes; the ladder's millisecond column says which to look at.
SLOW = {
    "ttt-perfect": "2.5 s: the compiler plays the whole tic-tac-toe game tree (#11334)",
    "interval-exhaustive": "2.4 s to compile and 3 ms to run (#11334)",
    "ui-theme-test": "0.35 s, all of it the compiler; the binary runs in 3 ms",
    "lib@msgpack-test": "0.27 s, all of it the compiler; the binary runs in 3 ms",
    "lib@hkdf-test": "1.7 s to compile, and 140 ms of real work at run time",
    "tcp-checksum-refuse": "1.3 s in compile-time evaluation (#11334)",
    "lorawan-encode": "1.0 s in compile-time evaluation (#11334)",
    "chacha20poly1305": "0.8 s in compile-time evaluation (#11334)",
    "aesgcm256": "0.6 s in compile-time evaluation (#11334)",
    "arp-cache-bound": "0.5 s in compile-time evaluation (#11334)",
    "poly1305": "0.45 s in compile-time evaluation (#11334)",
    "shell-build-keep": "0.44 s in compile-time evaluation (#11334)",
    "ga-core": "0.43 s in compile-time evaluation (#11334)",
    "kvstore-test": "0.36 s in compile-time evaluation (#11334)",
    "bloom-spread": "0.4 s, and 240 ms of it at run time in the allocator (#11335)",
}


# The modules rocemit writes itself rather than from a chapter: the runtime
# every test that prints needs, not a chapter one test drags in.
RUNTIME = {"CceText", "CceChar", "Prelude"}


def pick(order, cap):
    """The tests to package, cheapest first, under a per-test byte cap.

    The cost of a test is its own file plus the chapters no test before it
    already needed, so a test that shares everything is nearly free and one
    that drags in a 28 KB chapter of its own is not.
    """
    order = [u for u in order if u not in SLOW]
    sizes = {}
    for u in order:
        _, chapters, why = modules(u)
        if not why:
            sizes[u] = {c: len(t) for c, t in chapters.items() if c not in RUNTIME}
    if cap <= 0:
        return [u for u in order if u in sizes]
    have, kept, rest = {}, [], set(sizes)
    while rest:
        cand = [(sum(sz for c, sz in sizes[u].items() if c not in have), u) for u in rest]
        cand = [(c, u) for c, u in cand if c <= cap * 1024]
        if not cand:
            break
        _, u = min(cand)
        have.update(sizes[u]); kept.append(u); rest.discard(u)
    return [u for u in order if u in set(kept)]


def main():
    check_only = "--check" in sys.argv
    # The cost of a test is the chapters no test before it needed. rocemit's
    # own modules are not chapters and cost nothing (RUNTIME): charged, the
    # first test to print paid all 16 KB of CceText and CceChar, and at a cap
    # of 16 nothing that prints was ever admitted (17 tests, not 526).
    cap = 16
    if "--cap" in sys.argv:
        cap = int(sys.argv[sys.argv.index("--cap") + 1])
    if not check_only:
        shutil.rmtree(OUT, ignore_errors=True)
        os.makedirs(OUT)
    kept, dropped, times, shared = [], [], {}, {}
    chosen = pick(units(), cap)
    skipped = [u for u in units() if u not in set(chosen)]
    # First pass: gather the chapters, so the package exists before a run.
    for unit in chosen:
        _, chapters, why = modules(unit)
        if why:
            continue
        for cname, ctext in chapters.items():
            shared.setdefault(cname, ctext)
    if not check_only:
        pkg = os.path.join(OUT, "codex")
        os.makedirs(pkg, exist_ok=True)
        for cname, ctext in shared.items():
            open(os.path.join(pkg, cname + ".roc"), "w").write(ctext)
        listed = ",\n\t\t".join(sorted(shared))
        open(os.path.join(pkg, "main.roc"), "w").write(
            "# The Codex chapters these tests are emitted from, as a Roc\n"
            "# package. Written by roc-apps tests/package.py. Do not edit.\n"
            f"package\n\t[\n\t\t{listed},\n\t]\n\t{{}}\n"
        )
    for unit in chosen:
        verdict_path = os.path.join(VERDICTS, unit + ".expected")
        if not os.path.exists(verdict_path):
            dropped.append((unit, "no verdict")); continue
        body, chapters, why = modules(unit)
        if why:
            dropped.append((unit, why)); continue
        for cname, ctext in chapters.items():
            seen = shared.setdefault(cname, ctext)
            if seen != ctext:
                dropped.append((unit, f"chapter {cname} differs from another unit's")); break
        else:
            body = as_app(body, chapters)
        expect = open(verdict_path).read()
        name = "codex_" + unit.replace("-", "_") + ".roc"
        header = HEADER.format(
            title=unit, unit=unit, cob=COBBLESTONE, apps=ROC_APPS,
            expect="\n".join("#     " + l for l in expect.rstrip("\n").split("\n")),
        )
        path = os.path.join(OUT, name)
        if not check_only:
            open(path, "w").write(header + "\n" + body)
        # RUN IT. A file that does not reproduce the verdict is not shipped.
        t0 = time.time()
        r = subprocess.run([ROC, "run", path], capture_output=True, text=True, timeout=300)
        times[unit] = time.time() - t0
        # The verdicts lost a trailing blank line in the capture, so the
        # comparison strips them from both sides, as the ladder does.
        if trimmed(r.stdout) != trimmed(expect):
            dropped.append((unit, "output differs after flattening"))
            if not check_only:
                os.remove(path)
            continue
        if "✗" in r.stderr:
            dropped.append((unit, "roc reported an error"))
            if not check_only:
                os.remove(path)
            continue
        kept.append(unit)
    if not check_only:
        write_artifacts(kept, times, shared, cap)
    slow = sorted(((t, u) for u, t in times.items() if u in kept), reverse=True)[:8]
    print(f"{len(kept)} packaged, {len(dropped)} dropped, {len(skipped)} over the {cap} KB cap, {len(SLOW)} held back as slow")
    for u, why in dropped:
        print(f"  dropped {u}: {why}")
    total = sum(times[u] for u in kept)
    print(f"total {total:.1f}s, median {sorted(times[u] for u in kept)[len(kept)//2]*1000:.0f} ms")
    print("slowest:")
    for t, u in slow:
        print(f"  {t*1000:6.0f} ms  {u}")


main()
