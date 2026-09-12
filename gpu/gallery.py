#!/usr/bin/env python3
"""The gallery: every gpushow demo page whose kernels write pixels, as one
Roc app and one web page.

    gpu/gallery.py            writes gpu/roc/GalleryApp.roc and gpu/web/gallery.js
    gpu/gallery.py --table    prints what it found and writes nothing

A page is a PLAN: its storage buffers by size, its compute passes in order
(kernel, entry, how many gids, which buffer each binding is), and the buffer
the render pass reads per pixel. A single-pass page is the plasma shape and
its plan is read off the page; a page with two passes has its plan written
here by hand from its bind groups, since that is the page's knowledge and
not the kernel's. Each pass's Codex entry is read for its parameter order,
and the Roc call passes the device, the buffer handles, the frame and the
gid in that order. Pages that seed an input buffer or draw points and quads
are listed as skipped, with the reason.
"""
import os, re, sys
ROOT = os.environ.get("KERNELS_ROOT", os.path.expanduser("~/showell_repos/cobblestone-u58"))
HERE = os.path.dirname(os.path.abspath(__file__))
WEB = os.path.join(ROOT, "apps/gpushow/web")
KER = os.path.join(ROOT, "apps/gpushow/kernels")

# The two-pass pages, from their bind groups. A buffer is (name, size), a
# pass is (kernel, entry, gids, [buffer per binding]).
N, SM = 1024 * 768, 1024 * 1024
GBUF = [("galb", N), ("gnrm", N), ("gdep", N), ("outBuf", N)]
PLANS = {
    "bloom": dict(buffers=[("sceneBuf", N), ("outBuf", N)],
                  passes=[("BloomSceneKernel", "bloom_scene_step", N, ["sceneBuf"]),
                          ("BloomKernel", "bloom_step", N, ["sceneBuf", "outBuf"])]),
    "radial": dict(buffers=[("sceneBuf", N), ("outBuf", N)],
                   passes=[("BloomSceneKernel", "bloom_scene_step", N, ["sceneBuf"]),
                           ("RadialKernel", "radial_step", N, ["sceneBuf", "outBuf"])]),
    "deferred": dict(buffers=GBUF,
                     passes=[("GbufKernel", "gbuf_step", N, ["galb", "gnrm", "gdep"]),
                             ("DeferredKernel", "deferred_step", N, ["galb", "gnrm", "gdep", "outBuf"])]),
    "ssao": dict(buffers=GBUF,
                 passes=[("GbufKernel", "gbuf_step", N, ["galb", "gnrm", "gdep"]),
                         ("SsaoKernel", "ssao_step", N, ["gdep", "galb", "gnrm", "outBuf"])]),
    "shadowmap": dict(buffers=[("shadowBuf", SM), ("outBuf", N)],
                      passes=[("ShadowMapKernel", "shadowmap_step", SM, ["shadowBuf"]),
                              ("ShadowSceneKernel", "shadowmain_step", N, ["shadowBuf", "outBuf"])]),
}

def page_plan(path):
    """The page's plan: hand-written above, or read off a single-pass page."""
    page = os.path.basename(path)[:-5]
    html = open(path).read()
    wh = re.search(r"const W = (\d+), H = (\d+)", html)
    if not wh: return None, "no W, H"
    w, h = int(wh.group(1)), int(wh.group(2))
    if "pts[y * " not in html: return None, "no per-pixel readback"
    if page in PLANS:
        return dict(PLANS[page], w=w, h=h, out="outBuf"), None
    m = re.search(r"kernels/([A-Za-z]+Kernel)\.wgsl", html)
    if not m: return None, "no kernel fetched"
    entries = [e for e in re.findall(r"entryPoint: '([a-z_0-9]+)'", html) if e.endswith("_main")]
    if len(entries) != 1: return None, f"{len(entries)} compute entries and no plan"
    if html.count("createBuffer") != 2 or html.count("writeBuffer") != 1: return None, "a seeded input buffer, and no plan"
    return dict(w=w, h=h, buffers=[("outBuf", w * h)], out="outBuf",
                passes=[(m.group(1), entries[0][: -len("_main")], w * h, ["outBuf"])]), None

def pass_call(kernel, stem, bindings, buffers):
    """The Roc call for one pass: the entry's Codex parameters in order."""
    wgsl = open(os.path.join(KER, kernel + ".wgsl")).read()
    bufs = re.findall(r"@binding\((\d+)\) var<storage, read_write> " + stem + r"_([a-z0-9_]+)_buf", wgsl)
    if len(bufs) != len(bindings): return None, f"{stem}: {len(bufs)} storage bindings, the plan binds {len(bindings)}"
    uni = re.search(r"struct U_" + stem + r" \{\n((?:  [a-z0-9_]+ : i32,\n)+)\}", wgsl)
    fields = re.findall(r"  ([a-z0-9_]+) : i32", uni.group(1)) if uni else []
    if fields not in ([], ["frame"]): return None, f"{stem}: uniform fields {fields}"
    codex = open(os.path.join(KER, kernel + ".codex")).read()
    name = stem.replace("_", "-")
    m = re.search(r"^  " + re.escape(name) + r"((?: \([a-z0-9-]+\))+) =", codex, re.M)
    if not m: return None, f"no def `{name}` in {kernel}"
    handle = {p.replace("_", "-"): str([b for b, _ in buffers].index(bindings[i])) for i, (_, p) in enumerate(bufs)}
    args = []
    for p in re.findall(r"\(([a-z0-9-]+)\)", m.group(1)):
        if p in handle: args.append(handle[p])
        elif p == "frame": args.append("f")
        elif p == "gid": args.append("gid")
        else: return None, f"{name}: parameter `{p}` is not a buffer, the frame or the gid"
    return f"{kernel}.{stem}({', '.join(['d'] + args)})", None

rows, skipped = [], []
for f in sorted(os.listdir(WEB)):
    if not f.endswith(".html") or f == "index.html": continue
    page = f[:-5]
    plan, why = page_plan(os.path.join(WEB, f))
    if plan:
        calls = []
        for kernel, stem, gids, bindings in plan["passes"]:
            call, why = pass_call(kernel, stem, bindings, plan["buffers"])
            if why: break
            calls.append((gids, call))
    if why: skipped.append((page, why)); continue
    plan.update(page=page, calls=calls, kernels=[k for k, *_ in plan["passes"]])
    rows.append(plan)

if "--table" in sys.argv:
    for r in rows:
        print(f"{r['page']:12} {r['w']}x{r['h']}  " + "; ".join(f"{g} x {c}" for g, c in r["calls"]))
    for p, why in skipped: print(f"skip {p}: {why}")
    print(f"{len(rows)} in the gallery, {len(skipped)} skipped")
    sys.exit(0)

mods = sorted({k for r in rows for k in r["kernels"]})
roc = ["# The gallery app: every pixel-writing gpushow demo behind one render.",
       "# Written by gpu/gallery.py from the Cobblestone pages and kernels. Do not edit.",
       "#",
       "# render(kernel, frame) runs demo number `kernel` (gallery.js names them):",
       "# its buffers, its passes in order over their gids, and the buffer the",
       "# page reads, as packed pixels.",
       'app [render] { pf: platform "../wasm/platform/main.roc" }', "", "import Device"]
roc += [f"import {m}" for m in mods]
roc += ["", "pixels : Device.Device, I32 -> List(U32)",
        "pixels = |dev, out| List.map(Device.buffer(dev, out), |v| I32.to_u32_wrap(v))", "",
        "render : I64, I64 -> List(U32)", "render = |kernel, frame| {", "\tf = I64.to_i32_wrap(frame)", "\tmatch kernel {"]
for i, r in enumerate(rows):
    roc.append(f"\t\t{i} => ({{")
    roc.append(f"\t\t\tdev0 = Device.new([{', '.join(f'List.repeat(0, {n})' for _, n in r['buffers'])}])")
    for j, (gids, call) in enumerate(r["calls"]):
        roc.append(f"\t\t\tdev{j + 1} = Device.dispatch(dev{j}, {gids}, |d, gid| {call})")
    roc.append(f"\t\t\tpixels(dev{len(r['calls'])}, {[b for b, _ in r['buffers']].index(r['out'])})")
    roc.append("\t\t})")
roc += ["\t\t_ => []", "\t}", "}", ""]
open(os.path.join(HERE, "roc/GalleryApp.roc"), "w").write("\n".join(roc))
js = ["// The gallery's demos, by number, as GalleryApp.roc runs them.",
      "// Written by gpu/gallery.py. Do not edit.", "export const kernels = ["]
js += [f"  {{ id: {i}, page: '{r['page']}', kernel: '{' + '.join(r['kernels'])}', w: {r['w']}, h: {r['h']} }}," for i, r in enumerate(rows)]
js += ["];", ""]
open(os.path.join(HERE, "web/gallery.js"), "w").write("\n".join(js))
print(f"{len(rows)} demos in the gallery; skipped: {', '.join(p for p, _ in skipped)}")
