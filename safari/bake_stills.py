#!/usr/bin/env python3
"""The stills as Roc: one string constant per still, and the decoder that
reads them back into StillPoly records at run time.

    safari/bake_stills.py        writes ~/build/roc-apps/gen/baked/{Stills,CatStills,EmojiStills}.roc

WHY STRINGS. Roc's type checker is superlinear in the number of literal
elements in a file, whatever their type and however they are grouped: 1k,
2k and 4k points check in 3.6, 9.9 and 31 seconds, and the cat's 13,453
points took eight minutes. The same data as a string checks in half a
second and decodes at run time in about five. So rocemit leaves any
constant of 256 or more literal leaves out, with a `# baked:` line naming
it, and this supplies the names.

WHERE THE NUMBERS COME FROM. The tracked Codex chapters port/CatStills.codex
and port/EmojiStills.codex, which safari-codex's harness/bake_stills.py
generated from the game's frame tables and which the verdicts were graded
from. The decimal in the Codex literal is the decimal in the Roc string, so
the double Roc parses is the double Codex parsed.

THE ENCODING is the record shapes of Safari chapter Stills, flattened:
polygons joined by "/", each `color|grad|pts`; a grad is "" or the fifteen
StillGrad fields joined by ","; pts are "x,y" joined by ";".
"""
import os
import pathlib
import re
import sys

SAFARI = pathlib.Path(os.environ.get("SAFARI_ROOT", "~/showell_repos/safari-codex")).expanduser()
OUT = pathlib.Path("~/build/roc-apps/gen/baked").expanduser()

DECODER = '''# Stills -- the decoder for baked stills; see roc-apps/safari/bake_stills.py.

stills_real : Str -> F64
stills_real = |t| F64.from_str(t) ?? crash("stills: bad real")

stills_int : Str -> I64
stills_int = |t| I64.from_str(t) ?? crash("stills: bad integer")

stills_pt : Str -> StillPt
stills_pt = |t| match Str.split_first(t, ",") {
\tOk(r) => { x: stills_real(r.before), y: stills_real(r.after) }
\tErr(_) => crash("stills: bad point")
}

stills_field : List(Str), U64 -> Str
stills_field = |f, i| List.get(f, i) ?? crash("stills: short row")

stills_grad : Str -> List(StillGrad)
stills_grad = |t| if Str.is_empty(t) { [] } else { stills_grad_row(Str.split_on(t, ",")) }

stills_grad_row : List(Str) -> List(StillGrad)
stills_grad_row = |f| [{ kind: stills_int(stills_field(f, 0)), rgba0: stills_int(stills_field(f, 1)), rgba1: stills_int(stills_field(f, 2)), off0: stills_real(stills_field(f, 3)), off1: stills_real(stills_field(f, 4)), ax: stills_real(stills_field(f, 5)), ay: stills_real(stills_field(f, 6)), bx: stills_real(stills_field(f, 7)), by: stills_real(stills_field(f, 8)), cx: stills_real(stills_field(f, 9)), cy: stills_real(stills_field(f, 10)), ux: stills_real(stills_field(f, 11)), uy: stills_real(stills_field(f, 12)), vx: stills_real(stills_field(f, 13)), vy: stills_real(stills_field(f, 14)) }]

stills_poly : Str -> StillPoly
stills_poly = |t| stills_poly_row(Str.split_on(t, "|"))

stills_poly_row : List(Str) -> StillPoly
stills_poly_row = |f| { color: stills_int(stills_field(f, 0)), grad: stills_grad(stills_field(f, 1)), pts: List.map(Str.split_on(stills_field(f, 2), ";"), stills_pt) }

stills_polys : Str -> List(StillPoly)
stills_polys = |t| List.map(Str.split_on(t, "/"), stills_poly)
'''


DEF = re.compile(r"^  ([a-z-]+) : List StillPoly\n  \1 =\n    (\[.*)$", re.M)
POLY = re.compile(r"StillPoly \{ color = (\d+), grad = \[(.*?)\], pts = \[(.*?)\] \}")
PT = re.compile(r"StillPt \{ x = (.*?), y = (.*?) \}")
GRAD = re.compile(r"StillGrad \{ (.*) \}")
NEG = re.compile(r"\(0\.0 - (.*)\)")


def num(t):
    """A Codex Real literal as a plain signed decimal: `(0.0 - 0.04)` is `-0.04`."""
    m = NEG.fullmatch(t)
    return "-" + m.group(1) if m else t


def grad(t):
    """The StillGrad's fifteen fields, in declaration order, joined by commas."""
    if not t:
        return ""
    m = GRAD.fullmatch(t)
    if not m:
        raise SystemExit(f"unreadable gradient: {t[:80]}")
    return ",".join(num(kv.split(" = ")[1]) for kv in m.group(1).split(", "))


def polys(text):
    """One Codex list literal of StillPoly -> the string, and the point count."""
    out, n = [], 0
    for color, g, pts in POLY.findall(text):
        ps = PT.findall(pts)
        n += len(ps)
        out.append(f"{color}|{grad(g)}|" + ";".join(f"{num(x)},{num(y)}" for x, y in ps))
    return "/".join(out), len(out), n


def chapter(name):
    src = (SAFARI / "port" / f"{name}.codex").read_text()
    text = f"# {name} -- baked by roc-apps/safari/bake_stills.py from port/{name}.codex.\n"
    for m in DEF.finditer(src):
        binding = m.group(1).replace("-", "_")
        data, np, n = polys(m.group(2))
        text += (f"\n# {np} polygons, {n} points.\n{binding} : List(StillPoly)\n"
                 f"{binding} = stills_polys(\"{data}\")\n")
        print(f"{name}.{binding}: {np} polygons, {n} points")
    (OUT / f"{name}.roc").write_text(text)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "Stills.roc").write_text(DECODER)
    chapter("CatStills")
    chapter("EmojiStills")
    return 0


if __name__ == "__main__":
    sys.exit(main())
