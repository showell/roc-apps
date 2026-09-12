#!/usr/bin/env python3
"""The gallery: every gpushow demo page whose kernel writes pixels, as one
Roc app and one web page.

    gpu/gallery.py            writes gpu/roc/GalleryApp.roc and gpu/web/gallery.js
    gpu/gallery.py --table    prints what it found and writes nothing

A page qualifies when it is the plasma shape: one storage buffer of W*H
packed 0xRRGGBB words the kernel writes, a uniform holding only `frame`,
and a render pass that reads the buffer back per pixel. The Codex entry's
parameter order is read from the kernel source, since the Roc call must
pass the device, the buffer handle, the frame and the gid in that order.
Pages with a second pass, a seeded input buffer, or a point/quad render
are listed as skipped, with the reason.
"""
import os, re, sys
ROOT = os.environ.get("KERNELS_ROOT", os.path.expanduser("~/showell_repos/cobblestone-u58"))
HERE = os.path.dirname(os.path.abspath(__file__))
WEB = os.path.join(ROOT, "apps/gpushow/web")
KER = os.path.join(ROOT, "apps/gpushow/kernels")

def page_info(path):
    html = open(path).read()
    m = re.search(r"kernels/([A-Za-z]+Kernel)\.wgsl", html)
    if not m: return None, "no kernel fetched"
    kernel = m.group(1)
    entries = [e for e in re.findall(r"entryPoint: '([a-z_0-9]+)'", html) if e.endswith("_main")]
    if len(entries) != 1: return None, f"{len(entries)} compute entries"
    wh = re.search(r"const W = (\d+), H = (\d+)", html)
    if not wh: return None, "no W, H"
    if html.count("createBuffer") != 2 or html.count("writeBuffer") != 1: return None, "extra buffers or writes (a second pass or a seeded input)"
    if "pts[y * " not in html: return None, "no per-pixel readback"
    return dict(kernel=kernel, entry=entries[0], w=int(wh.group(1)), h=int(wh.group(2))), None

def kernel_info(kernel, entry):
    wgsl = open(os.path.join(KER, kernel + ".wgsl")).read()
    stem = entry[: -len("_main")]
    bufs = re.findall(r"@binding\((\d+)\) var<storage, read_write> " + stem + r"_([a-z0-9_]+)_buf", wgsl)
    uni = re.search(r"struct U_" + stem + r" \{\n((?:  [a-z0-9_]+ : i32,\n)+)\}", wgsl)
    fields = re.findall(r"  ([a-z0-9_]+) : i32", uni.group(1)) if uni else []
    if fields != ["frame"]: return None, f"uniform fields {fields}"
    if len(bufs) != 1: return None, f"{len(bufs)} storage buffers"
    codex = open(os.path.join(KER, kernel + ".codex")).read()
    name = stem.replace("_", "-")
    m = re.search(r"^  " + re.escape(name) + r"((?: \([a-z0-9-]+\))+) =", codex, re.M)
    if not m: return None, f"no def `{name}` in the Codex"
    params = re.findall(r"\(([a-z0-9-]+)\)", m.group(1))
    args = []
    for p in params:
        if p == bufs[0][1].replace("_", "-"): args.append("0")
        elif p == "frame": args.append("f")
        elif p == "gid": args.append("gid")
        else: return None, f"parameter `{p}` is not the buffer, the frame or the gid"
    return dict(fn=stem, args=args), None

rows, skipped = [], []
for f in sorted(os.listdir(WEB)):
    if not f.endswith(".html") or f == "index.html": continue
    page = f[:-5]
    info, why = page_info(os.path.join(WEB, f))
    if info:
        k, why = kernel_info(info["kernel"], info["entry"])
        if k: info.update(k)
    if why: skipped.append((page, why)); continue
    info["page"] = page
    rows.append(info)

if "--table" in sys.argv:
    for r in rows: print(f"{r['page']:12} {r['kernel']:22} {r['fn']}({', '.join(r['args'])}) {r['w']}x{r['h']}")
    for p, why in skipped: print(f"skip {p}: {why}")
    print(f"{len(rows)} in the gallery, {len(skipped)} skipped")
    sys.exit(0)

mods = sorted({r["kernel"] for r in rows})
roc = ["# The gallery app: every pixel-writing gpushow kernel behind one render.",
       "# Written by gpu/gallery.py from the Cobblestone pages and kernels. Do not edit.",
       "#",
       "# render(kernel, frame) dispatches kernel number `kernel` (gallery.js",
       "# names them) over its W*H gids on the CPU and answers the packed pixels.",
       'app [render] { pf: platform "../wasm/platform/main.roc" }', "", "import Device"]
roc += [f"import {m}" for m in mods]
roc += ["", "pixels : I32, I32, (Device.Device, I32 -> (Device.Device, I32)) -> List(U32)",
        "pixels = |w, h, kernel| {",
        "\tdev = Device.new([List.repeat(0, I32.to_u64_wrap(w * h))])",
        "\tout = Device.dispatch(dev, w * h, kernel)",
        "\tList.map(Device.buffer(out, 0), |v| I32.to_u32_wrap(v))", "}", "",
        "render : I64, I64 -> List(U32)", "render = |kernel, frame| {", "\tf = I64.to_i32_wrap(frame)", "\tmatch kernel {"]
for i, r in enumerate(rows):
    roc.append(f"\t\t{i} => pixels({r['w']}, {r['h']}, |d, gid| {r['kernel']}.{r['fn']}({', '.join(['d'] + r['args'])}))")
roc += ["\t\t_ => []", "\t}", "}", ""]
open(os.path.join(HERE, "roc/GalleryApp.roc"), "w").write("\n".join(roc))
js = ["// The gallery's kernels, by number, as GalleryApp.roc dispatches them.",
      "// Written by gpu/gallery.py. Do not edit.", "export const kernels = ["]
js += [f"  {{ id: {i}, page: '{r['page']}', kernel: '{r['kernel']}', w: {r['w']}, h: {r['h']} }}," for i, r in enumerate(rows)]
js += ["];", ""]
open(os.path.join(HERE, "web/gallery.js"), "w").write("\n".join(js))
print(f"{len(rows)} kernels in the gallery; skipped: {', '.join(p for p, _ in skipped)}")
