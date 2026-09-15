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
ROOT = os.environ.get("KERNELS_ROOT", os.path.expanduser("~/showell_repos/cobblestone-u61"))
HERE = os.path.dirname(os.path.abspath(__file__))
WEB = os.path.join(ROOT, "apps/gpushow/web")
KER = os.path.join(ROOT, "apps/gpushow/kernels")

# The pages with a plan of their own, from their bind groups: two passes,
# or a buffer the page uploads before the first dispatch (a Seeds function
# names it). A buffer is (name, size or the Roc expression that fills it),
# a pass is (kernel, entry, gids, [buffer per binding]). A particle page
# keeps its state across frames: `pingpong` swaps a pass's first two
# bindings on odd frames and reads the second back; `uniform` gives the
# constants its entry takes besides the frame; `frame_mod` is where the page
# restarts its frame count; `draw` is how the page draws the words (the
# pixel pages blit them).
N, SM = 1024 * 768, 1024 * 1024
QUAD = dict(kind="quads", clear="#04060c")
PARTICLES = {
    "cpuparticles": dict(buffers=[("a", "Seeds.cpu_particles({})"), ("b", 14000 * 4)], pingpong=True,
                         passes=[("CpuParticlesKernel", "cp_step", 14000, ["a", "b"])], out="b",
                         draw=dict(QUAD, scale=16, size=2.3, vmax=520, c0=[0.20, 0.45, 1.0], c1=[0.7, 0.95, 1.0], k=0.7, clear="#030510")),
    "nbody": dict(buffers=[("a", "Seeds.nbody({})"), ("b", 1024 * 4)], pingpong=True,
                  passes=[("NbodyKernel", "nbody_step", 1024, ["a", "b"])], out="b",
                  draw=dict(QUAD, scale=256, size=1.6, vmax=1600, c0=[0.15, 0.22, 0.6], c1=[1.0, 0.92, 0.75], k=0.55)),
    "particles": dict(buffers=[("a", "Seeds.particles_page({})"), ("b", 20000 * 4)], pingpong=True,
                      passes=[("ParticlesKernel", "particles_step", 20000, ["a", "b"])], out="b",
                      draw=dict(QUAD, scale=1, size=1.6, vmax=320, c0=[0.35, 0.10, 0.02], c1=[1.0, 0.85, 0.5], k=0.55)),
    "swarm": dict(buffers=[("a", "Seeds.swarm({})"), ("b", 8000 * 4)], pingpong=True,
                  passes=[("SwarmKernel", "swarm_step", 8000, ["a", "b"])], out="b",
                  draw=dict(QUAD, scale=1, size=1.6, vmax=9, c0=[0.05, 0.15, 0.5], c1=[0.7, 0.95, 1.0], k=0.6)),
    "fireworks": dict(buffers=[("out", 2600)], passes=[("FireworksKernel", "fw_burst_spark", 2600, ["out"])], out="out",
                      uniform=dict(cx=512, cy=300, nspark=2600), frame_mod=200,
                      draw=dict(kind="sparks", size=2.2, color=[1.0, 0.72, 0.32], clear="#050310")),
}
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
    "texture": dict(buffers=[("texBuf", "Seeds.texture({})"), ("outBuf", N)],
                    passes=[("TextureKernel", "texture_step", N, ["texBuf", "outBuf"])]),
    "gltf": dict(buffers=[("meshBuf", "Seeds.icosahedron({})"), ("outBuf", N)],
                 passes=[("GltfKernel", "gltf_step", N, ["meshBuf", "outBuf"])]),
    "d20": dict(buffers=[("meshBuf", "Seeds.icosahedron({})"), ("outBuf", N)],
                passes=[("D20Kernel", "d20_step", N, ["meshBuf", "outBuf"])]),
    "shadowmap": dict(buffers=[("shadowBuf", SM), ("outBuf", N)],
                      passes=[("ShadowMapKernel", "shadowmap_step", SM, ["shadowBuf"]),
                              ("ShadowSceneKernel", "shadowmain_step", N, ["shadowBuf", "outBuf"])]),
}

def page_plan(path):
    """The page's plan: hand-written above, or read off a single-pass page."""
    page = os.path.basename(path)[:-5]
    html = open(path).read()
    wh = re.search(r"const W = (\d+), H = (\d+)", html)
    if not wh and page not in PARTICLES: return None, "no W, H"
    w, h = (int(wh.group(1)), int(wh.group(2))) if wh else (0, 0)
    if "pts[y * " not in html and page not in PARTICLES: return None, "no per-pixel readback"
    if page in PLANS:
        return dict(PLANS[page], w=w, h=h, out="outBuf"), None
    if page in PARTICLES:
        return dict(PARTICLES[page], w=1024, h=768), None
    m = re.search(r"kernels/([A-Za-z0-9]+Kernel)\.wgsl", html)
    if not m: return None, "no kernel fetched"
    entries = [e for e in re.findall(r"entryPoint: '([a-z_0-9]+)'", html) if e.endswith("_main")]
    if len(entries) != 1: return None, f"{len(entries)} compute entries and no plan"
    if html.count("createBuffer") != 2 or html.count("writeBuffer") != 1: return None, "a seeded input buffer, and no plan"
    return dict(w=w, h=h, buffers=[("outBuf", w * h)], out="outBuf",
                passes=[(m.group(1), entries[0][: -len("_main")], w * h, ["outBuf"])]), None

def pass_call(kernel, stem, bindings, buffers, uniform):
    """The Roc call for one pass: the entry's Codex parameters in order."""
    wgsl = open(os.path.join(KER, kernel + ".wgsl")).read()
    bufs = re.findall(r"@binding\((\d+)\) var<storage, read_write> " + stem + r"_([a-z0-9_]+)_buf", wgsl)
    if len(bufs) != len(bindings): return None, f"{stem}: {len(bufs)} storage bindings, the plan binds {len(bindings)}"
    uni = re.search(r"struct U_" + stem + r" \{\n((?:  [a-z0-9_]+ : i32,\n)+)\}", wgsl)
    fields = re.findall(r"  ([a-z0-9_]+) : i32", uni.group(1)) if uni else []
    if sorted(fields) != sorted(["frame"] + list(uniform)) and fields != []: return None, f"{stem}: uniform fields {fields}"
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
        elif p in uniform: args.append(str(uniform[p]))
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
            call, why = pass_call(kernel, stem, bindings, plan["buffers"], plan.get("uniform", {}))
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
if any(isinstance(n, str) for r in rows for _, n in r["buffers"]): mods.append("Seeds")
names = [b for r in rows for b, _ in r["buffers"]]
roc = ["# The gallery app: every gpushow demo behind one model.",
       "# Written by gpu/gallery.py from the Cobblestone pages and kernels. Do not edit.",
       "#",
       "# A model is a demo number and its device. step(model, kernel, frame) makes",
       "# the demo's buffers when the number changes (gallery.js names them), runs",
       "# its passes over their gids for the frame, and remembers which buffer",
       "# the page reads; view answers that buffer as words.",
       'app [Model, program] { pf: platform "../wasm/platform/main.roc" }', "", "import Device"]
roc += [f"import {m}" for m in mods]
roc += ["", "Model : { kernel : I64, dev : Device.Device, out : I32 }", "",
        "init : {} -> Box(Model)", "init = |{}| Box.box({ kernel: -1, dev: Device.new([]), out: 0 })", "",
        "view : Box(Model) -> List(U32)",
        "view = |boxed| { m = Box.unbox(boxed)\n\tList.map(Device.buffer(m.dev, m.out), |v| I32.to_u32_wrap(v)) }", "",
        "step : Box(Model), I64, I64 -> Box(Model)", "step = |boxed, kernel, frame| {", "\tm = Box.unbox(boxed)",
        "\tf = I64.to_i32_wrap(frame)", "\todd = I64.rem_by(frame, 2) == 1",
        "\tdev0 = if m.kernel == kernel { m.dev } else { make(kernel) }", "\tmatch kernel {"]
for i, r in enumerate(rows):
    roc.append(f"\t\t{i} => ({{")
    bufs = [b for b, _ in r["buffers"]]
    for j, (gids, call) in enumerate(r["calls"]):
        if r.get("pingpong"):
            # the call names buffers 0 and 1; odd frames read 1 and write 0
            swapped = call.replace("(d, 0, 1,", "(d, 1, 0,")
            roc.append(f"\t\t\tdev{j + 1} = if odd {{ Device.dispatch(dev{j}, {gids}, |d, gid| {swapped}) }} else {{ Device.dispatch(dev{j}, {gids}, |d, gid| {call}) }}")
        else:
            roc.append(f"\t\t\tdev{j + 1} = Device.dispatch(dev{j}, {gids}, |d, gid| {call})")
    out = bufs.index(r["out"])
    out_expr = f"(if odd {{ 0 }} else {{ 1 }})" if r.get("pingpong") else str(out)
    roc.append(f"\t\t\tBox.box({{ kernel: kernel, dev: dev{len(r['calls'])}, out: {out_expr} }})")
    roc.append("\t\t})")
roc += ["\t\t_ => Box.box({ kernel: kernel, dev: Device.new([]), out: 0 })", "\t}", "}", "",
        "# A demo's buffers, fresh: zeros of the size, or what the page uploads.",
        "make : I64 -> Device.Device", "make = |kernel| match kernel {"]
for i, r in enumerate(rows):
    fill = [n if isinstance(n, str) else f"List.repeat(0, {n})" for _, n in r["buffers"]]
    roc.append(f"\t{i} => Device.new([{', '.join(fill)}])")
roc += ["\t_ => Device.new([])", "}", "",
        "program = { init, step, view }", ""]
open(os.path.join(HERE, "roc/GalleryApp.roc"), "w").write("\n".join(roc))
js = ["// The gallery's demos, by number, as GalleryApp.roc runs them.",
      "// Written by gpu/gallery.py. Do not edit.", "export const kernels = ["]
import json
js += [f"  {{ id: {i}, page: '{r['page']}', kernel: '{' + '.join(r['kernels'])}', w: {r['w']}, h: {r['h']}, frameMod: {r.get('frame_mod', 0)}, draw: {json.dumps(r.get('draw', dict(kind='pixels')))} }}," for i, r in enumerate(rows)]
js += ["];", ""]
open(os.path.join(HERE, "web/gallery.js"), "w").write("\n".join(js))
print(f"{len(rows)} demos in the gallery; skipped: {', '.join(p for p, _ in skipped)}")
