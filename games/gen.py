#!/usr/bin/env python3
"""Per game, the platform and the host, from Damian's export table.

    games/gen.py            writes games/wasm/<id>/platform/{main.roc,host.zig} and the build files

A game's host has two doors onto the same Roc functions. THE PAGE'S DOOR is
one model: newGame(seed), step(message), view() and bufPtr, the seam the
page drives; a message is one small integer the app decodes. THE GRADER'S
DOOR is the game's export contract from apps/games/build-wasm.ps1, by
handle: <xx>_new answers a handle, a query reads one, a transition answers
the handle of the state after it. A handle is an index into a table of
boxed models; old handles stay valid; a refused transition answers the SAME
handle, decided by the app's `same`, a structural equality: a shell answers
the state it was given when it refuses. __heap_reset frees the table.

The app (games/roc/<App>.roc, hand-written) provides the program record:
init, step, view, drop, same, and one function per export under its short
name (g2_cell is `cell`). An export's kind is read off the emitted shell
chapter's signature: a QUERY takes a handle and answers a number, a
TRANSITION takes a handle and answers one, a MAKE takes numbers and answers
a handle (kd_new, kd_run), a PURE takes numbers and answers a number
(kd_rank). A handle is anything the app boxes, a game or a finished run.
"""
import os, re, shutil
HERE = os.path.dirname(os.path.abspath(__file__))
ROC_DIR = os.path.join(HERE, "roc")

# id: the app, the shell chapter, the export table (name, shell function,
# arity counting the handle), and the counter a transition advances.
GAMES = {
    "2048": dict(app="G2048App", shell="Game2048Wasm", exports=[
        ("g2_new", "g2_wasm_new", 1), ("g2_cell", "g2_wasm_cell", 2), ("g2_score", "g2_wasm_score", 1),
        ("g2_moves", "g2_wasm_moves", 1), ("g2_done", "g2_wasm_done", 1), ("g2_max", "g2_wasm_max", 1),
        ("g2_empty", "g2_wasm_empty", 1), ("g2_sum", "g2_wasm_sum", 1), ("g2_can", "g2_wasm_can", 2),
        ("g2_move", "g2_wasm_move", 2), ("g2_ai", "g2_wasm_ai", 1)]),
    "minesweeper": dict(app="MinesweeperApp", shell="MinesweeperWasm", exports=[
        ("ms_new", "ms_wasm_new", 1), ("ms_mine", "ms_wasm_mine", 2), ("ms_shown", "ms_wasm_revealed", 2),
        ("ms_adj", "ms_wasm_adjacent", 2), ("ms_count", "ms_wasm_count", 1), ("ms_hits", "ms_wasm_hits", 1),
        ("ms_moves", "ms_wasm_moves", 1), ("ms_done", "ms_wasm_done", 1), ("ms_won", "ms_wasm_won", 1),
        ("ms_safe", "ms_wasm_safe", 1), ("ms_open", "ms_wasm_reveal", 2), ("ms_ai", "ms_wasm_ai", 1)]),
    "klondike": dict(app="KlondikeApp", shell="KlondikeWasm", exports=[
        ("kd_new", "kd_wasm_new", 2), ("kd_rank", "kd_wasm_rank", 1), ("kd_suit", "kd_wasm_suit", 1),
        ("kd_coln", "kd_wasm_col_size", 2), ("kd_card", "kd_wasm_card", 3), ("kd_down", "kd_wasm_down", 2),
        ("kd_found", "kd_wasm_found", 2), ("kd_foundcard", "kd_wasm_found_card", 2), ("kd_stockn", "kd_wasm_stock_size", 1),
        ("kd_wasten", "kd_wasm_waste_size", 1), ("kd_wastetop", "kd_wasm_waste_top", 1), ("kd_founded", "kd_wasm_founded", 1),
        ("kd_moves", "kd_wasm_moves", 1), ("kd_drawn", "kd_wasm_draw_count", 1), ("kd_won", "kd_wasm_won", 1),
        ("kd_runlen", "kd_wasm_run_len", 3), ("kd_can", "kd_wasm_can_move", 4), ("kd_move", "kd_wasm_move", 4),
        ("kd_candraw", "kd_wasm_can_draw", 1), ("kd_draw", "kd_wasm_draw", 1), ("kd_canrecyc", "kd_wasm_can_recycle", 1),
        ("kd_recycle", "kd_wasm_recycle", 1), ("kd_ai", "kd_wasm_ai", 1), ("kd_mfrom", "kd_wasm_move_from", 1),
        ("kd_mstart", "kd_wasm_move_start", 1), ("kd_mto", "kd_wasm_move_to", 1), ("kd_run", "kd_wasm_run", 2),
        ("kd_rfound", "kd_wasm_run_founded", 1), ("kd_rmoves", "kd_wasm_run_moves", 1), ("kd_rwon", "kd_wasm_run_won", 1)]),
}
SCALARS = ("I64", "U64", "I32", "F64", "Bool", "Str", "List(")

def signatures(shell):
    text = open(os.path.join(ROC_DIR, shell + ".roc")).read()
    return dict(re.findall(r"^\t([a-z_0-9]+) : (.+)$", text, re.M))

HOST_HEAD = open(os.path.join(HERE, "host_head.zig")).read()

for gid, g in GAMES.items():
    sigs = signatures(g["shell"])
    prefix = g["exports"][0][0].split("_")[0] + "_"
    rows = []  # (export, short, arity, kind)
    for name, fn, arity in g["exports"]:
        short = name[len(prefix):]
        params, ret = sigs[fn].rsplit("->", 1)
        first = params.split(",")[0].strip()
        takes = not first.startswith(SCALARS)
        gives = not ret.strip().startswith(SCALARS)
        kind = {(True, True): "move", (True, False): "query", (False, True): "make", (False, False): "pure"}[(takes, gives)]
        rows.append((name, short, arity, kind))
    d = os.path.join(HERE, "wasm", gid, "platform")
    os.makedirs(os.path.join(d, "targets", "wasm32"), exist_ok=True)
    # the platform
    req = ["init : I64 -> Box(model)", "step : Box(model), I64 -> Box(model)", "view : Box(model) -> List(U32)",
           "drop : Box(model) -> {}", "same : Box(model), Box(model) -> I64"]
    prov = [("roc_init", "init"), ("roc_step", "step"), ("roc_view", "view"), ("roc_drop", "drop"), ("roc_same", "same")]
    for name, short, arity, kind in rows:
        takes = kind in ("move", "query")
        args = ", ".join((["Box(model)"] if takes else []) + ["I64"] * (arity - (1 if takes else 0)))
        req.append(f"{short} : {args} -> " + ("Box(model)" if kind in ("move", "make") else "I64"))
        prov.append((f"roc_{short}", short))
    exports = ["newGame", "step", "view", "bufPtr"] + [name for name, *_ in rows] + ["__heap_reset"]
    main = [f"# The {gid} platform. Written by games/gen.py from the export table. Do not edit.",
            "# Two doors onto one app: the page's (newGame, step, view) over one model,",
            "# and the grader's, Damian's export contract by handle (host.zig).",
            'platform ""', "\trequires {", "\t\t[Model : model] for program : {"]
    main += [f"\t\t\t{r}," for r in req]
    main += ["\t\t}", "\t}", "\texposes []", "\tpackages {}", "\tprovides {"]
    main += [f'\t\t"{p}": {s}_for_host,' for p, s in prov]
    main += ["\t}", "\ttargets: {", '\t\tinputs_dir: "targets/",', "\t\twasm32: {", '\t\t\tinputs: ["host.wasm", app],',
             "\t\t\texports: [" + ", ".join(f'"{e}"' for e in exports) + "],", "\t\t},", "\t}", ""]
    main += [f"{s}_for_host = program.{s}" for _, s in prov] + [""]
    open(os.path.join(d, "main.roc"), "w").write("\n".join(main))
    # the host
    host = [f"//! The {gid} wasm host. Written by games/gen.py from the export table. Do not edit.",
            "//! Two doors onto the same Roc functions: the page's (one model, a message)",
            "//! and the grader's (Damian's export contract, by handle over a table of",
            "//! boxed models; a refused transition answers the same handle, decided by",
            "//! the app's structural `same`). See games/gen.py.", "", HOST_HEAD]
    host.append("extern fn roc_init(seed: i64) callconv(.c) Model;")
    host.append("extern fn roc_step(model: Model, msg: i64) callconv(.c) Model;")
    host.append("extern fn roc_view(model: Model) callconv(.c) RocList;")
    host.append("extern fn roc_drop(model: Model) callconv(.c) void;")
    host.append("extern fn roc_same(a: Model, b: Model) callconv(.c) i64;")
    for name, short, arity, kind in rows:
        takes = kind in ("move", "query")
        params = ", ".join((["model: Model"] if takes else []) + [f"a{i}: i64" for i in range(arity - (1 if takes else 0))])
        host.append(f"extern fn roc_{short}({params}) callconv(.c) " + ("Model" if kind in ("move", "make") else "i64") + ";")
    host.append(open(os.path.join(HERE, "host_body.zig")).read())
    for name, short, arity, kind in rows:
        takes = kind in ("move", "query")
        extra = [f"a{i}" for i in range(arity - (1 if takes else 0))]
        params = ", ".join((["h: i32"] if takes else []) + [f"{a}: i32" for a in extra])
        rest = ", ".join(extra)
        if kind == "make":
            host += [f"pub export fn {name}({params}) i32 {{", f"    return push(roc_{short}({rest}));", "}"]
        elif kind == "pure":
            host += [f"pub export fn {name}({params}) i32 {{", f"    return @intCast(roc_{short}({rest}));", "}"]
        elif kind == "query":
            host += [f"pub export fn {name}({params}) i32 {{",
                     f"    return @intCast(roc_{short}(borrowed(at(h)){', ' + rest if rest else ''}));", "}"]
        else:
            host += [f"pub export fn {name}({params}) i32 {{", "    const old = at(h);",
                     f"    const next = roc_{short}(borrowed(old){', ' + rest if rest else ''});",
                     "    // A refusal answers the state it was given; the same handle, then.",
                     "    if (roc_same(borrowed(old), borrowed(next)) == 1) {",
                     "        roc_drop(next);", "        return h;", "    }", "    return push(next);", "}"]
    host += ["/// What the arcade calls at a new game: every handle freed.", "pub export fn __heap_reset() void {",
             "    for (table.items) |m| roc_drop(m);", "    table.clearRetainingCapacity();", "}", ""]
    open(os.path.join(d, "host.zig"), "w").write("\n".join(host))
    # the build files, from the gpu host's, one directory deeper
    src = os.path.join(HERE, "..", "gpu", "wasm")
    bz = open(os.path.join(src, "build.zig")).read().replace('b.pathFromRoot("../../../roc")', 'b.pathFromRoot("../../../../roc")').replace("// The gpu wasm host: platform/host.zig", f"// The {gid} game's wasm host: platform/host.zig (games/gen.py)")
    open(os.path.join(HERE, "wasm", gid, "build.zig"), "w").write(bz)
    shutil.copy(os.path.join(src, "options.zig"), os.path.join(HERE, "wasm", gid, "options.zig"))
    open(os.path.join(HERE, "wasm", gid, ".gitignore"), "w").write("platform/targets/\n")
    kinds = {k: sum(1 for r in rows if r[3] == k) for k in ("query", "move", "make", "pure")}
    print(f"{gid}: {len(rows)} exports {kinds}, app {g['app']}")
