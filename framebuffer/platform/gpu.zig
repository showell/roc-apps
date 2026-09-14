//! The GPU codex-vm models behind ports 0x400-0x417, drawing into the GOP
//! framebuffer: tools/codex-vm.c's gpu_clear_fb, gpu_fade_clear,
//! gpu_clear_depth, gpu_rasterize_band, gpu_lerp_color, gpu_atmosphere_glow
//! and gpu_cinematic_post, over the program's own memory. A program writes
//! triangles into the command buffer at 0xBE000000, 72 bytes each; clears the
//! framebuffer (port 0x401) or fades it toward a colour (0x40E), and clears the
//! depth buffer at 0xBE800000 (0x402); and flushes a count (0x400). Each
//! triangle is filled where its three edge functions agree, its depth and colour
//! interpolated across it, a pixel drawn only where it is strictly nearer than
//! what the depth buffer holds; then the glow tints the background within 16
//! pixels of what was drawn.
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
//! pacing is the page's to do. A textured triangle, the shadow map and every
//! other port stop the run by name.

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

    fn refuses(g: *const Gpu) bool {
        return g.stride != g.w;
    }

    /// A write of `value` to a port in 0x400-0x417. Answers null, or the
    /// message the run stops with.
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
            else => return std.fmt.bufPrint(msg, "gpu: port-out-32 to GPU port 0x{X}, which this platform does not model", .{port}) catch "gpu: port-out-32 to a GPU port this platform does not model",
        }
        return null;
    }

    /// A read of a port in 0x400-0x417: 0x403 answers that a rasterizer is
    /// there, and 0x40E and 0x40F the size of the last asset loaded, which with
    /// none loaded is 0. Null for a port this does not model.
    pub fn portIn(port: u64) ?u32 {
        return switch (port) {
            0x403 => 1,
            0x40E, 0x40F => 0,
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
        if (g.cine != 0) {
            // u0: 0 opaque, 1 a hard add, 2 a soft round sprite at (u1, v1), radius u2.
            blend = @bitCast(tri[12]);
        } else if (tri[12] | tri[13] | tri[14] | tri[15] | tri[16] | tri[17] != 0) {
            return "gpu: a textured triangle, which this platform's GPU does not draw";
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
                        g.fb[idx] = lerp(c0, c1, c2, bw0, bw1, bw2, abs_area);
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
