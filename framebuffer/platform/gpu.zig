//! The GPU codex-vm models behind ports 0x400-0x417, drawing into the GOP
//! framebuffer: tools/codex-vm.c's gpu_clear_fb, gpu_fade_clear,
//! gpu_clear_depth, gpu_rasterize_band, gpu_lerp_color, gpu_atmosphere_glow,
//! gpu_cinematic_post, and gpu_shade_globe with its two samplers, over the
//! program's own memory. A program writes triangles into the command buffer at
//! 0xBE000000, 72 bytes each; clears the framebuffer (port 0x401) or fades it
//! toward a colour (0x40E), and clears the depth buffer at 0xBE800000 (0x402);
//! and flushes a count (0x400). Each triangle is filled where its three edge
//! functions agree, its depth and colour interpolated across it, a pixel drawn
//! only where it is strictly nearer than what the depth buffer holds; then the
//! glow tints the background within 16 pixels of what was drawn.
//!
//! A triangle with texture coordinates samples the texture the host last
//! committed (ports 0x408-0x40B, in core.zig): in mode 0, three bytes a texel
//! read bilinearly and shaded as a globe under the light and eye of ports
//! 0x404-0x407; in mode 1, a word a texel read nearest, modulating the vertex
//! colour. One before any texture, which codex-vm shades with a procedural
//! Earth, stops the run by name.
//!
//! Port 0x410 turns on the cinematic pass. While it is on, a triangle's first
//! texture word is its blend: 1 adds its colour to the pixels under it, 2 adds
//! a soft round sprite (centre at the next two words, radius the one after),
//! and either ignores the depth buffer; and after a flush the frame is bloomed,
//! tonemapped, graded and vignetted in place of the glow.
//!
//! codex-vm addresses the framebuffer's rows by the visible width, so with a
//! padded stride it draws nothing (gop_host_gpu_refuses), and so does this. No
//! program here arms the viewport, so it is not modelled, and codex-vm's frame
//! pacing is the page's to do. The shadow map and every other port stop the run
//! by name.

const std = @import("std");

pub const cmd_base: u64 = 0xBE000000;
pub const depth_base: u64 = 0xBE800000;
pub const fb_base: u64 = 0xBF000000;
pub const port_lo: u64 = 0x400;
pub const port_hi: u64 = 0x417;
pub const max_tris: usize = 65536;

const depth_far: u32 = 999999;
const shadow_flag: u32 = 0x40000000;
const glow_radius: i32 = 16;

/// The bloom buffers' length for a screen: a quarter of each side, three
/// channels, and a row and a pixel more, which the composite's index reaches
/// when a side is not a multiple of four.
pub fn bloomLen(w: usize, h: usize) usize {
    return ((w / 4) * (h / 4 + 1) + 1) * 3;
}

pub const Gpu = struct {
    w: usize,
    h: usize,
    stride: usize,
    /// stride * h words at fb_base.
    fb: []u32,
    /// w * h words at depth_base.
    db: []u32,
    /// max_tris * 18 words at cmd_base.
    cmd: []u32,
    /// The glow's distance field, w * h; codex-vm keeps it between flushes and
    /// recomputes it on frames 1, 5, 9 ...
    glow: []u8,
    glow_valid: bool = false,
    frames: u32 = 0,
    /// The cinematic pass, on while nonzero, and its two bloom buffers.
    cine: u32 = 0,
    bloom: []f32,
    bloom_tmp: []f32,
    /// The light's direction and the eye's (ports 0x404-0x407), each a
    /// thousandth of the word written; the eye's y and z are the light's.
    light: [3]f32 = .{ 0, 0, 0 },
    eye: [3]f32 = .{ 0, 0, 0 },
    /// The texture port 0x40B last committed, copied out of the program's
    /// memory by the host, which owns it: three bytes a texel in mode 0, a
    /// 0x00RRGGBB word a texel in mode 1. Empty until one is committed.
    tex: []const u8 = &.{},
    tex_w: usize = 0,
    tex_h: usize = 0,
    tex_mode: u32 = 0,
    /// The bytes the last asset load read (port 0x417), answered on 0x40E and
    /// 0x40F.
    asset_size: u64 = 0,

    fn refuses(g: *const Gpu) bool {
        return g.stride != g.w;
    }

    /// A write of `value` to one of the GPU's own ports in 0x400-0x417; the
    /// texture's and the asset loader's reach the program's memory and are the
    /// host's (core.zig). Answers null, or the message the run stops with.
    pub fn portOut(g: *Gpu, port: u64, value: u32, msg: []u8) ?[]const u8 {
        switch (port) {
            0x401 => g.clear(value),
            0x40E => g.fadeClear(value),
            0x402 => {
                if (value != 0) return "gpu: port-out-32 to port 0x402 arms the GPU's shadow map, which this platform does not model";
                g.clearDepth();
            },
            0x400 => {
                if (value & shadow_flag != 0) return "gpu: port-out-32 to port 0x400 with the shadow flag, a shadow pass this platform does not model";
                // codex-vm reads the count as an int: one with bit 31 set draws nothing.
                if (g.flush(@bitCast(value))) |why| return why;
            },
            // The viewport's origin, which does nothing until 0x40F arms it.
            0x403 => {},
            0x40F => {
                if (value != 0) return "gpu: port-out-32 to port 0x40F arms the GPU's viewport, which this platform does not model";
            },
            0x410 => g.cine = value,
            0x404 => g.light[0] = milli(value),
            0x405 => g.light[1] = milli(value),
            0x406 => g.light[2] = milli(value),
            0x407 => g.eye = .{ milli(value), g.light[1], g.light[2] },
            else => return std.fmt.bufPrint(msg, "gpu: port-out-32 to GPU port 0x{X}, which this platform does not model", .{port}) catch "gpu: port-out-32 to a GPU port this platform does not model",
        }
        return null;
    }

    /// A read of a port in 0x400-0x417: 0x403 answers that a rasterizer is
    /// there, and 0x40E and 0x40F the low and high halves of the last asset
    /// load's size. Null for a port this does not model.
    pub fn portIn(g: *const Gpu, port: u64) ?u32 {
        return switch (port) {
            0x403 => 1,
            0x40E => @truncate(g.asset_size),
            0x40F => @truncate(g.asset_size >> 32),
            else => null,
        };
    }

    /// Port 0x401: every visible pixel, rows stepped by the width.
    fn clear(g: *Gpu, color: u32) void {
        if (g.refuses()) return;
        @memset(g.fb[0 .. g.w * g.h], color);
    }

    /// Port 0x40E: every visible pixel seven eighths of the way back toward the
    /// colour, so what moves leaves a fading trail.
    fn fadeClear(g: *Gpu, color: u32) void {
        if (g.refuses()) return;
        const tr: i32 = @intCast((color >> 16) & 0xFF);
        const tg: i32 = @intCast((color >> 8) & 0xFF);
        const tb: i32 = @intCast(color & 0xFF);
        for (g.fb[0 .. g.w * g.h]) |*p| {
            const r: i32 = @intCast((p.* >> 16) & 0xFF);
            const gr: i32 = @intCast((p.* >> 8) & 0xFF);
            const b: i32 = @intCast(p.* & 0xFF);
            const nr: u32 = @intCast(tr + @divTrunc((r - tr) * 7, 8));
            const ng: u32 = @intCast(tg + @divTrunc((gr - tg) * 7, 8));
            const nb: u32 = @intCast(tb + @divTrunc((b - tb) * 7, 8));
            p.* = (nr << 16) | (ng << 8) | nb;
        }
    }

    /// Port 0x402 with 0: the depth buffer to far.
    fn clearDepth(g: *Gpu) void {
        if (g.refuses()) return;
        @memset(g.db[0 .. g.w * g.h], depth_far);
    }

    /// Port 0x400: the first `count` triangles, at most 65,536, then the
    /// cinematic pass or the glow.
    fn flush(g: *Gpu, count: i32) ?[]const u8 {
        if (g.refuses()) return null;
        g.frames +%= 1;
        const n: usize = if (count < 0) 0 else @min(@as(usize, @intCast(count)), max_tris);
        for (0..n) |t| {
            if (g.triangle(t)) |why| return why;
        }
        if (g.cine != 0) g.cinematicPost() else g.glowPass();
        return null;
    }

    fn triangle(g: *Gpu, t: usize) ?[]const u8 {
        const tri = g.cmd[t * 18 ..][0..18];
        const x0: i64 = @as(i32, @bitCast(tri[0]));
        const y0: i64 = @as(i32, @bitCast(tri[1]));
        const x1: i64 = @as(i32, @bitCast(tri[2]));
        const y1: i64 = @as(i32, @bitCast(tri[3]));
        const x2: i64 = @as(i32, @bitCast(tri[4]));
        const y2: i64 = @as(i32, @bitCast(tri[5]));
        var blend: i32 = 0;
        var textured = false;
        if (g.cine != 0) {
            // u0: 0 opaque, 1 a hard add, 2 a soft round sprite at (u1, v1), radius u2.
            blend = @bitCast(tri[12]);
        } else if (tri[12] | tri[13] | tri[14] | tri[15] | tri[16] | tri[17] != 0) {
            if (g.tex.len == 0) return "gpu: a textured triangle before any texture is committed, which codex-vm shades with a procedural Earth this platform does not draw";
            textured = true;
        }
        const cx: i32 = @bitCast(tri[14]);
        const cy: i32 = @bitCast(tri[15]);
        const radius: i32 = @bitCast(tri[16]);
        const minx = @max(@min(x0, x1, x2), 0);
        const miny = @max(@min(y0, y1, y2), 0);
        const maxx = @min(@max(x0, x1, x2), @as(i64, @intCast(g.w)) - 1);
        const maxy = @min(@max(y0, y1, y2), @as(i64, @intCast(g.h)) - 1);
        if (minx > maxx or miny > maxy) return null;
        const area = edge(x0, y0, x1, y1, x2, y2);
        if (area == 0) return null;
        const sign: i64 = if (area > 0) 1 else -1;
        const abs_area = if (area > 0) area else -area;
        const c0 = tri[6];
        const c1 = tri[7];
        const c2 = tri[8];
        const d0: i64 = @as(i32, @bitCast(tri[9]));
        const d1: i64 = @as(i32, @bitCast(tri[10]));
        const d2: i64 = @as(i32, @bitCast(tri[11]));
        var y = miny;
        while (y <= maxy) : (y += 1) {
            var x = minx;
            while (x <= maxx) : (x += 1) {
                const bw0 = edge(x1, y1, x2, y2, x, y) * sign;
                const bw1 = edge(x2, y2, x0, y0, x, y) * sign;
                const bw2 = edge(x0, y0, x1, y1, x, y) * sign;
                if (bw0 < 0 or bw1 < 0 or bw2 < 0) continue;
                const idx = @as(usize, @intCast(y)) * g.w + @as(usize, @intCast(x));
                if (blend == 1) {
                    g.fb[idx] = add(g.fb[idx], lerp(c0, c1, c2, bw0, bw1, bw2, abs_area), 1.0);
                } else if (blend == 2) {
                    const ddx: i32 = @as(i32, @intCast(x)) -% cx;
                    const ddy: i32 = @as(i32, @intCast(y)) -% cy;
                    const dr2 = ddx *% ddx +% ddy *% ddy;
                    const r2 = radius *% radius;
                    if (r2 > 0 and dr2 < r2) {
                        const tt: f32 = 1.0 - @as(f32, @floatFromInt(dr2)) / @as(f32, @floatFromInt(r2));
                        g.fb[idx] = add(g.fb[idx], lerp(c0, c1, c2, bw0, bw1, bw2, abs_area), tt * tt);
                    }
                } else {
                    const depth: u32 = @bitCast(@as(i32, @truncate(@divTrunc(d0 * bw0 + d1 * bw1 + d2 * bw2, abs_area))));
                    if (depth < g.db[idx]) {
                        g.fb[idx] = if (textured) g.texel(tri, bw0, bw1, bw2, abs_area) else lerp(c0, c1, c2, bw0, bw1, bw2, abs_area);
                        g.db[idx] = depth;
                    }
                }
            }
        }
        return null;
    }

    /// After a flush: every pixel equal to the top-left one is background; the
    /// distance from each background pixel to the nearest other pixel is found
    /// in two passes of four sweeps, and a background pixel less than 16 away
    /// gains 25 red, 55 green and 150 blue scaled by (1 - d/16) cubed.
    fn glowPass(g: *Gpu) void {
        const w = g.w;
        const h = g.h;
        const total = w * h;
        if ((g.frames & 3) == 1 or !g.glow_valid) {
            const bg = g.fb[0];
            for (0..total) |i| g.glow[i] = if (g.fb[i] == bg) 255 else 0;
            for (0..2) |_| {
                for (0..h) |yy| {
                    const row = yy * w;
                    var x: usize = 1;
                    while (x < w) : (x += 1) relax(g.glow, row + x, row + x - 1);
                    x = w - 1;
                    while (x > 0) : (x -= 1) relax(g.glow, row + x - 1, row + x);
                }
                for (0..w) |xx| {
                    var yy: usize = 1;
                    while (yy < h) : (yy += 1) relax(g.glow, yy * w + xx, (yy - 1) * w + xx);
                    yy = h - 1;
                    while (yy > 0) : (yy -= 1) relax(g.glow, (yy - 1) * w + xx, yy * w + xx);
                }
            }
            g.glow_valid = true;
        }
        for (0..total) |i| {
            const d: i32 = g.glow[i];
            if (d > 0 and d < glow_radius) {
                // Single-precision, as codex-vm computes it; every step is exact.
                const t: f32 = 1.0 - @as(f32, @floatFromInt(d)) / @as(f32, @floatFromInt(glow_radius));
                const glow = t * t * t;
                const p = g.fb[i];
                const r = tint((p >> 16) & 0xFF, glow * 25);
                const gr = tint((p >> 8) & 0xFF, glow * 55);
                const b = tint(p & 0xFF, glow * 150);
                g.fb[i] = (r << 16) | (gr << 8) | b;
            }
        }
    }

    /// After a flush with the cinematic pass on: a bright pass over every
    /// fourth pixel into a quarter-size bloom, blurred twice across and down
    /// with a nine-tap gaussian; then every pixel gains its bloom, and is
    /// exposed, tonemapped, given contrast, graded toward orange in the lights
    /// and teal in the shadows, and vignetted. Single-precision, step for step
    /// as codex-vm computes it.
    fn cinematicPost(g: *Gpu) void {
        const w = g.w;
        const h = g.h;
        const bw = w / 4;
        const bh = h / 4;
        if (bw < 1 or bh < 1) return;
        const bloom = g.bloom;
        const tmp = g.bloom_tmp;
        for (0..bh) |y| {
            for (0..bw) |x| {
                const p = g.fb[(y * 4) * w + x * 4];
                const r = channelOf(p, 16);
                const gr = channelOf(p, 8);
                const b = channelOf(p, 0);
                const lum = 0.299 * r + 0.587 * gr + 0.114 * b;
                var t = lum - 78.0;
                if (t < 0) t = 0;
                var k = t / 170.0;
                if (k > 1.5) k = 1.5;
                const i = (y * bw + x) * 3;
                bloom[i] = r * k;
                bloom[i + 1] = gr * k;
                bloom[i + 2] = b * k;
            }
        }
        const wt = [5]f32{ 0.2270, 0.1940, 0.1216, 0.0540, 0.0162 };
        for (0..2) |_| {
            for (0..bh) |y| {
                for (0..bw) |x| {
                    var ar: f32 = 0;
                    var ag: f32 = 0;
                    var ab: f32 = 0;
                    var k: i32 = -4;
                    while (k <= 4) : (k += 1) {
                        const xx: usize = @intCast(std.math.clamp(@as(i32, @intCast(x)) + k, 0, @as(i32, @intCast(bw)) - 1));
                        const ww = wt[@abs(k)];
                        const i = (y * bw + xx) * 3;
                        ar += bloom[i] * ww;
                        ag += bloom[i + 1] * ww;
                        ab += bloom[i + 2] * ww;
                    }
                    const o = (y * bw + x) * 3;
                    tmp[o] = ar;
                    tmp[o + 1] = ag;
                    tmp[o + 2] = ab;
                }
            }
            for (0..bh) |y| {
                for (0..bw) |x| {
                    var ar: f32 = 0;
                    var ag: f32 = 0;
                    var ab: f32 = 0;
                    var k: i32 = -4;
                    while (k <= 4) : (k += 1) {
                        const yy: usize = @intCast(std.math.clamp(@as(i32, @intCast(y)) + k, 0, @as(i32, @intCast(bh)) - 1));
                        const ww = wt[@abs(k)];
                        const i = (yy * bw + x) * 3;
                        ar += tmp[i] * ww;
                        ag += tmp[i + 1] * ww;
                        ab += tmp[i + 2] * ww;
                    }
                    const o = (y * bw + x) * 3;
                    bloom[o] = ar;
                    bloom[o + 1] = ag;
                    bloom[o + 2] = ab;
                }
            }
        }
        const cxf: f32 = @as(f32, @floatFromInt(w)) * 0.5;
        const cyf: f32 = @as(f32, @floatFromInt(h)) * 0.5;
        const maxd2 = cxf * cxf + cyf * cyf;
        for (0..h) |y| {
            for (0..w) |x| {
                const idx = y * w + x;
                const p = g.fb[idx];
                const bi = ((y >> 2) * bw + (x >> 2)) * 3;
                const r = channelOf(p, 16) + bloom[bi] * 0.9;
                const gr = channelOf(p, 8) + bloom[bi + 1] * 0.9;
                const b = channelOf(p, 0) + bloom[bi + 2] * 0.9;
                var rn = r / 255.0;
                var gn = gr / 255.0;
                var bn = b / 255.0;
                const ex: f32 = 1.25;
                rn *= ex;
                gn *= ex;
                bn *= ex;
                rn = rn / (1.0 + rn);
                gn = gn / (1.0 + gn);
                bn = bn / (1.0 + bn);
                rn = (rn - 0.5) * 1.28 + 0.5;
                gn = (gn - 0.5) * 1.28 + 0.5;
                bn = (bn - 0.5) * 1.28 + 0.5;
                const luma = 0.299 * rn + 0.587 * gn + 0.114 * bn;
                const s = luma - 0.5;
                rn += s * 0.12;
                bn -= s * 0.10;
                gn += s * 0.015;
                if (luma < 0.5) {
                    const sh = (0.5 - luma) * 0.14;
                    bn += sh;
                    gn += sh * 0.5;
                }
                const dx = @as(f32, @floatFromInt(x)) - cxf;
                const dy = @as(f32, @floatFromInt(y)) - cyf;
                const vd = (dx * dx + dy * dy) / maxd2;
                const vig = 1.0 - 0.5 * vd;
                rn *= vig;
                gn *= vig;
                bn *= vig;
                g.fb[idx] = (byteOf(rn) << 16) | (byteOf(gn) << 8) | byteOf(bn);
            }
        }
    }

    /// A textured fragment: its texture coordinates interpolated as its depth
    /// is, then in mode 1 the texel modulating the vertex colour, and in mode 0
    /// the globe's shading.
    fn texel(g: *const Gpu, tri: *const [18]u32, bw0: i64, bw1: i64, bw2: i64, area: i64) u32 {
        const u = interp(tri[12], tri[14], tri[16], bw0, bw1, bw2, area);
        const v = interp(tri[13], tri[15], tri[17], bw0, bw1, bw2, area);
        if (g.tex_mode == 1) {
            const t = g.samplePlain(u, v);
            const lit = lerp(tri[6], tri[7], tri[8], bw0, bw1, bw2, area);
            return (modulate(lit >> 16, t >> 16) << 16) | (modulate(lit >> 8, t >> 8) << 8) | modulate(lit, t);
        }
        return g.shadeGlobe(u, v);
    }

    /// Mode 0's sample: three bytes a texel, bilinear, with u reversed and
    /// wrapped and v reversed and held at the edges.
    fn sampleGlobe(g: *const Gpu, tu: i32, tv: i32) u32 {
        var fu: f32 = 1.0 - @as(f32, @floatFromInt(tu)) / 1000.0;
        var fv: f32 = 1.0 - @as(f32, @floatFromInt(tv)) / 1000.0;
        fu = fu - @floor(fu);
        if (fv < 0) fv = 0;
        if (fv > 1) fv = 1;
        const px = fu * @as(f32, @floatFromInt(g.tex_w - 1));
        const py = fv * @as(f32, @floatFromInt(g.tex_h - 1));
        const ix: usize = @intFromFloat(px);
        const iy: usize = @intFromFloat(py);
        const fx = px - @as(f32, @floatFromInt(ix));
        const fy = py - @as(f32, @floatFromInt(iy));
        const ix1 = if (ix + 1 < g.tex_w) ix + 1 else 0;
        const iy1 = if (iy + 1 < g.tex_h) iy + 1 else iy;
        const t = g.tex;
        const p00 = (iy * g.tex_w + ix) * 3;
        const p10 = (iy * g.tex_w + ix1) * 3;
        const p01 = (iy1 * g.tex_w + ix) * 3;
        const p11 = (iy1 * g.tex_w + ix1) * 3;
        var out: u32 = 0;
        for (0..3) |c| {
            const s = @as(f32, @floatFromInt(t[p00 + c])) * (1 - fx) * (1 - fy) + @as(f32, @floatFromInt(t[p10 + c])) * fx * (1 - fy) + @as(f32, @floatFromInt(t[p01 + c])) * (1 - fx) * fy + @as(f32, @floatFromInt(t[p11 + c])) * fx * fy;
            out = (out << 8) | @as(u32, @intFromFloat(s));
        }
        return out;
    }

    /// Mode 1's sample: a 0x00RRGGBB word a texel, nearest, both axes wrapped.
    fn samplePlain(g: *const Gpu, tu: i32, tv: i32) u32 {
        var fu: f32 = @as(f32, @floatFromInt(tu)) / 1000.0;
        var fv: f32 = @as(f32, @floatFromInt(tv)) / 1000.0;
        fu = fu - @floor(fu);
        fv = fv - @floor(fv);
        const w: i32 = @intCast(g.tex_w);
        const h: i32 = @intCast(g.tex_h);
        const ix = std.math.clamp(@as(i32, @intFromFloat(fu * @as(f32, @floatFromInt(w)))), 0, w - 1);
        const iy = std.math.clamp(@as(i32, @intFromFloat(fv * @as(f32, @floatFromInt(h)))), 0, h - 1);
        const at: usize = @intCast((iy * w + ix) * 4);
        return std.mem.readInt(u32, g.tex[at..][0..4], .little) & 0xFFFFFF;
    }

    /// codex-vm's globe shader: the texture pinched toward the meridian near
    /// the poles and faded to ice at them, a sphere's normal made from the
    /// coordinates, wrapped diffuse light, specular where a texel is blue enough
    /// to be water, and a Fresnel rim that fades out above 45 degrees of
    /// latitude. Single-precision, step for step as codex-vm computes it.
    fn shadeGlobe(g: *const Gpu, u: i32, v: i32) u32 {
        const uf: f32 = @floatFromInt(u);
        const vf: f32 = @floatFromInt(v);
        var tex: u32 = undefined;
        if (v < 140 or v > 860) {
            const pole_t: f32 = if (v < 140) vf / 140.0 else @as(f32, @floatFromInt(1000 - v)) / 140.0;
            const u_fixed: i32 = @intFromFloat(500.0 + @as(f32, @floatFromInt(u - 500)) * pole_t);
            const v_edge: i32 = if (v < 140)
                @intFromFloat(vf + @as(f32, @floatFromInt(140 - v)) * (1.0 - pole_t))
            else
                @intFromFloat(vf - @as(f32, @floatFromInt(v - 860)) * (1.0 - pole_t));
            const sampled = g.sampleGlobe(u_fixed, v_edge);
            tex = if (pole_t < 0.3) colorLerp(0xD8E0EC, sampled, pole_t / 0.3) else sampled;
        } else {
            tex = g.sampleGlobe(u, v);
        }
        const px_lon: f32 = -3.14159 + (uf / 1000.0) * 6.28318;
        const px_lat: f32 = 1.5708 - (vf / 1000.0) * 3.14159;
        const clat = @cos(px_lat);
        const slat = @sin(px_lat);
        const clon = @cos(px_lon);
        const slon = @sin(px_lon);
        const nx = clat * clon;
        const ny = slat;
        const nz = clat * slon;
        const l = g.light;
        const e = g.eye;
        const ndl = nx * l[0] + ny * l[1] + nz * l[2];
        var wrap = (ndl + 0.5) / 1.5;
        if (wrap < 0) wrap = 0;
        var intensity = 0.22 + wrap * 1.1;
        if (intensity > 1.4) intensity = 1.4;
        var nde = nx * e[0] + ny * e[1] + nz * e[2];
        if (nde < 0) nde = 0;
        var fresnel = 1.0 - nde;
        if (fresnel < 0) fresnel = 0;
        const rim = fresnel * fresnel * fresnel;
        var spec: f32 = 0;
        const is_water = (tex & 0xFF) > ((tex >> 16) & 0xFF) + 15;
        if (is_water and ndl > 0) {
            var hx = l[0] + e[0];
            var hy = l[1] + e[1];
            var hz = l[2] + e[2];
            const hlen = @sqrt(hx * hx + hy * hy + hz * hz);
            if (hlen > 0.001) {
                hx /= hlen;
                hy /= hlen;
                hz /= hlen;
            }
            const ndh = nx * hx + ny * hy + nz * hz;
            if (ndh > 0) {
                const s4 = ndh * ndh * ndh * ndh;
                const sharp = s4 * s4 * s4 * s4 * 0.7;
                spec = sharp + s4 * 0.12;
            }
        }
        const lat_abs = @abs(px_lat * 57.2958);
        const rim_scale: f32 = if (lat_abs > 65) 0 else if (lat_abs > 45) (65 - lat_abs) / 20.0 else 1;
        const r = shaded((tex >> 16) & 0xFF, intensity, spec, rim * rim_scale * 40);
        const gr = shaded((tex >> 8) & 0xFF, intensity, spec, rim * rim_scale * 70);
        const b = shaded(tex & 0xFF, intensity, spec, rim * rim_scale * 140);
        return (r << 16) | (gr << 8) | b;
    }
};

fn edge(ax: i64, ay: i64, bx: i64, by: i64, px: i64, py: i64) i64 {
    return (bx - ax) * (py - ay) - (by - ay) * (px - ax);
}

fn lerp(c0: u32, c1: u32, c2: u32, w0: i64, w1: i64, w2: i64, area: i64) u32 {
    const r = channel(c0 >> 16, c1 >> 16, c2 >> 16, w0, w1, w2, area);
    const g = channel(c0 >> 8, c1 >> 8, c2 >> 8, w0, w1, w2, area);
    const b = channel(c0, c1, c2, w0, w1, w2, area);
    return (r << 16) | (g << 8) | b;
}

fn channel(a: u32, b: u32, c: u32, w0: i64, w1: i64, w2: i64, area: i64) u32 {
    const v = @divTrunc(@as(i64, a & 0xFF) * w0 + @as(i64, b & 0xFF) * w1 + @as(i64, c & 0xFF) * w2, area);
    const clamped: i32 = @truncate(v);
    return @intCast(@max(@min(clamped, 255), 0));
}

/// A pixel's colour with another added, the addend scaled by `scale` (an int
/// cast of each scaled channel, as codex-vm's soft sprite takes it), each
/// channel held at 255.
fn add(dst: u32, src: u32, scale: f32) u32 {
    var out: u32 = 0;
    var shift: u5 = 16;
    while (true) : (shift -= 8) {
        const s: i32 = if (scale == 1.0)
            @intCast((src >> shift) & 0xFF)
        else
            @intFromFloat(@as(f32, @floatFromInt((src >> shift) & 0xFF)) * scale);
        const v: i32 = @as(i32, @intCast((dst >> shift) & 0xFF)) + s;
        out |= @as(u32, @intCast(@min(v, 255))) << shift;
        if (shift == 0) break;
    }
    return out;
}

/// A word written to a light or eye port, as thousandths.
fn milli(value: u32) f32 {
    return @as(f32, @floatFromInt(@as(i32, @bitCast(value)))) / 1000.0;
}

/// A texture coordinate interpolated across a triangle, the int of a 64-bit
/// quotient as codex-vm takes it.
fn interp(a: u32, b: u32, c: u32, w0: i64, w1: i64, w2: i64, area: i64) i32 {
    const wide = @as(i64, @as(i32, @bitCast(a))) * w0 + @as(i64, @as(i32, @bitCast(b))) * w1 + @as(i64, @as(i32, @bitCast(c))) * w2;
    return @truncate(@divTrunc(wide, area));
}

/// One channel of a colour scaled by a texel's, in 255ths.
fn modulate(lit: u32, tex: u32) u32 {
    return ((lit & 0xFF) * (tex & 0xFF)) / 255;
}

/// `c0` moved toward `c1` by `t`, each channel truncated, as codex-vm's
/// color_lerp does it.
fn colorLerp(c0: u32, c1: u32, t: f32) u32 {
    if (t <= 0) return c0;
    if (t >= 1.0) return c1;
    var out: u32 = 0;
    var shift: u5 = 16;
    while (true) : (shift -= 8) {
        const a: i32 = @intCast((c0 >> shift) & 0xFF);
        const b: i32 = @intCast((c1 >> shift) & 0xFF);
        const v: i32 = @intFromFloat(@as(f32, @floatFromInt(a)) + @as(f32, @floatFromInt(b - a)) * t);
        out |= @as(u32, @bitCast(v)) << shift;
        if (shift == 0) break;
    }
    return out;
}

/// A channel of the globe's shading: the texel's by the light's intensity,
/// with the specular and the rim added, held to a byte.
fn shaded(c: u32, intensity: f32, spec: f32, rim: f32) u32 {
    const v: i32 = @intFromFloat(@as(f32, @floatFromInt(c)) * intensity + spec * 255 + rim);
    return @intCast(std.math.clamp(v, 0, 255));
}

fn channelOf(p: u32, shift: u5) f32 {
    return @floatFromInt((p >> shift) & 0xFF);
}

fn byteOf(v: f32) u32 {
    const i: i32 = @intFromFloat(v * 255.0);
    return @intCast(std.math.clamp(i, 0, 255));
}

/// dist[at] becomes dist[from] + 1 where that is smaller.
fn relax(d: []u8, at: usize, from: usize) void {
    if (@as(u32, d[at]) > @as(u32, d[from]) + 1) d[at] = d[from] + 1;
}

fn tint(c: u32, amount: f32) u32 {
    const v: i32 = @intFromFloat(@as(f32, @floatFromInt(c)) + amount);
    return @intCast(@min(v, 255));
}
