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

Every chapter's text is identical wherever it appears, which is what makes
the deduplication sound: rocemit emits a chapter from the chapter, not
from the program that cites it (checked over all 137 units).

Each app is RUN and its output compared with the verdict before it is
kept, so nothing here ships untested.

**Not every passing test is packaged.** A Codex chapter is big -- one is
28 KB and exactly one test needs it -- so the tests are taken cheapest
first and one is dropped when it would add more than `--cap` KB of
chapter text nobody else needs. At the default of 8 KB that is 103 of the
137, in a quarter of the bytes; the whole set is in roc-apps either way.
"""
import os, re, shutil, subprocess, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "ported")
GEN = os.path.expanduser("~/build/roc-apps/gen/tests")
VERDICTS = os.path.expanduser("~/build/roc-apps/gen/verdicts")
ROC = os.environ.get("ROC", os.path.expanduser("~/build/roc-nightly/roc"))
TESTS_ROOT = os.environ.get("TESTS_ROOT", os.path.expanduser("~/showell_repos/cobblestone-u58"))
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
        if line.startswith("PASS "):
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
        all_n=len(units()), cap=cap,
    ))


def stat_line(unit, t):
    path = os.path.join(OUT, zig_name(unit) + ".roc")
    lines = sum(1 for _ in open(path))
    return f"| `{zig_name(unit)}.roc` | {lines} | {t*1000:.0f} |"


README = """# Codex tests, ported to Roc

{n} programs from [Cobblestone]({cob})'s own test suite, machine-translated
from Codex to Roc and checked against the output Cobblestone records for
each one.

{n} of the {all_n} the emitter runs to their verdict are here: a Codex
chapter can be 28 KB and needed by exactly one program, so a test is left
out when it would add more than {cap} KB of chapter text nobody else
needs. The rest are in [roc-apps]({apps}).

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

A Codex program carries every chapter it cites, so the 137 units carried
137 copies of the same chapters; a chapter's emitted text is identical
wherever it appears, which is what lets them be shared here. Nothing was
edited by hand, and every app was run and compared with its expected
output before it was kept.

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

`ttt-perfect` is the outlier, and the cost is in checking its 40-line app
rather than the chapters it imports: the app calls three small mutually
recursive functions that return a record, and check time grows with the
number of call sites into them. It is a whole-tree tic-tac-toe search, so
it is also the most work here, and that work takes 3 ms at run time.

## The tests

| file | lines | ms |
|---|---|---|
{table}
"""


def pick(order, cap):
    """The tests to package, cheapest first, under a per-test byte cap.

    The cost of a test is its own file plus the chapters no test before it
    already needed, so a test that shares everything is nearly free and one
    that drags in a 28 KB chapter of its own is not.
    """
    sizes = {}
    for u in order:
        _, chapters, why = modules(u)
        if not why:
            sizes[u] = {c: len(t) for c, t in chapters.items()}
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
    cap = 8
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
        if r.stdout != expect:
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
    print(f"{len(kept)} packaged, {len(dropped)} dropped, {len(skipped)} over the {cap} KB cap")
    for u, why in dropped:
        print(f"  dropped {u}: {why}")
    total = sum(times[u] for u in kept)
    print(f"total {total:.1f}s, median {sorted(times[u] for u in kept)[len(kept)//2]*1000:.0f} ms")
    print("slowest:")
    for t, u in slow:
        print(f"  {t*1000:6.0f} ms  {u}")


main()
