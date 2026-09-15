//! The framebuffer platform's native host, the checker: core.zig's memory,
//! screen, ports and GPU in an ordinary Linux process. It gives the program a
//! screen and prints, for every frame, its time and a hash of its visible pixels
//! (core.hash, the one frames.mjs prints), then the console of the last frame
//! before its line. A crash prints the console so far and its message, and
//! exits 1.
//!
//!     <program> [-screen <width> <height> <stride>] [-key <scancode>]...
//!               [-mouse <x> <y> <buttons>]... [-ppm <path>] (-frames <n> | -flushes <n>)
//!
//! With -frames (1 when neither is given), a frame is a run of the program's
//! opening, with the clock 100 ms further on each time, as the page runs it.
//! With -flushes, a frame is a GPU flush, for a program that draws in a loop of
//! its own and never ends its run; the host stops at the nth. The program's own
//! command line is empty, as on the page; the heap's base moves with its length.
//!
//! Each -key and -mouse is handed to the host, in order, before the first run,
//! as the page's runner hands over what was queued before it started. -ppm
//! writes the last frame's visible pixels to a binary PPM.

const std = @import("std");
const shim_io = @import("shim_io");
const core = @import("core.zig");

// std.debug's I/O is roc's minimal shim rather than zig's threaded I/O, as in
// roc's own static archives: the threaded vtable brings stat and socket calls
// into the link, and the musl this platform links against has not all of them.
pub const std_options_elf_debug_info_search_paths = shim_io.elfDebugInfoSearchPaths;
pub const std_options_debug_io = shim_io.io();
pub const std_options_debug_threaded_io = null;
pub const std_options = shim_io.std_options_static_archive;

pub const allocator = std.heap.c_allocator;

fn write(fd: c_int, bytes: []const u8) void {
    var at: usize = 0;
    while (at < bytes.len) {
        const n = std.c.write(fd, bytes.ptr + at, bytes.len - at);
        if (n <= 0) return;
        at += @intCast(n);
    }
}

pub fn stop(msg: []const u8) noreturn {
    write(1, core.console());
    write(2, "stopped: ");
    write(2, msg);
    write(2, "\n");
    std.c.exit(1);
}

pub const panic = std.debug.FullPanic(panicImpl);
fn panicImpl(msg: []const u8, _: ?usize) noreturn {
    stop(msg);
}

comptime {
    core.exportSymbols();
}

fn usage() c_int {
    write(2, "usage: <program> [-screen <width> <height> <stride>] [-key <scancode>]... [-mouse <x> <y> <buttons>]... [-ppm <path>] (-frames <n> | -flushes <n>)\n");
    return 2;
}

fn number(arg: [*:0]u8) ?u32 {
    return std.fmt.parseInt(u32, std.mem.span(arg), 10) catch null;
}

fn nowUs() u64 {
    var ts: std.c.timespec = undefined;
    _ = std.c.clock_gettime(std.c.CLOCK.MONOTONIC, &ts);
    return @as(u64, @intCast(ts.sec)) * 1_000_000 + @as(u64, @intCast(ts.nsec)) / 1000;
}

/// A key or a mouse state from the command line, handed over before the first
/// run.
const Input = struct { key: bool, a: u32, b: u32, c: u32 };
var inputs: [64]Input = undefined;
var input_count: usize = 0;

var screen_w: u32 = 320;
var screen_h: u32 = 240;
var ppm_path: ?[*:0]u8 = null;

/// The visible pixels, red, green and blue a pixel, after a binary PPM header.
fn writePpm() void {
    const path = ppm_path orelse return;
    const fd = std.c.open(path, .{ .ACCMODE = .WRONLY, .CREAT = true, .TRUNC = true }, @as(std.c.mode_t, 0o644));
    if (fd < 0) stop("cannot open the -ppm file");
    defer _ = std.c.close(fd);
    var header: [48]u8 = undefined;
    write(fd, std.fmt.bufPrint(&header, "P6\n{d} {d}\n255\n", .{ screen_w, screen_h }) catch unreachable);
    const px = core.present();
    const row = allocator.alloc(u8, screen_w * 3) catch stop("no memory for a -ppm row");
    defer allocator.free(row);
    var y: usize = 0;
    while (y < screen_h) : (y += 1) {
        var x: usize = 0;
        while (x < screen_w) : (x += 1) {
            const at = (y * screen_w + x) * 4;
            row[x * 3] = px[at];
            row[x * 3 + 1] = px[at + 1];
            row[x * 3 + 2] = px[at + 2];
        }
        write(fd, row);
    }
}

/// One frame's line: its number, its time, and its pixels' hash; the last
/// frame's console goes before it, and its pixels to -ppm.
fn frameLine(n: u32, us: u64, last: bool) void {
    var line: [96]u8 = undefined;
    const h = core.hash(core.present());
    if (last) {
        write(1, core.console());
        writePpm();
    }
    write(1, std.fmt.bufPrint(&line, "-- frame {d}: {d} ms, hash {x:0>8}\n", .{ n, us / 1000, h }) catch "-- frame\n");
}

var asset_buf: []u8 = &.{};

/// The bytes of the file at `path`, relative to the working directory, as
/// codex-vm's asset loader finds it; null when there is none. They are the
/// host's until the next asset.
pub fn asset(path: []const u8) ?[]const u8 {
    var z: [256]u8 = undefined;
    if (path.len >= z.len) return null;
    @memcpy(z[0..path.len], path);
    z[path.len] = 0;
    const fd = std.c.open(z[0..path.len :0].ptr, .{ .ACCMODE = .RDONLY });
    if (fd < 0) return null;
    defer _ = std.c.close(fd);
    const end = std.c.lseek(fd, 0, std.c.SEEK.END);
    if (end <= 0 or std.c.lseek(fd, 0, std.c.SEEK.SET) != 0) return null;
    if (asset_buf.len > 0) allocator.free(asset_buf);
    asset_buf = allocator.alloc(u8, @intCast(end)) catch stop("no memory for an asset");
    var at: usize = 0;
    while (at < asset_buf.len) {
        const n = std.c.read(fd, asset_buf.ptr + at, asset_buf.len - at);
        if (n <= 0) break;
        at += @intCast(n);
    }
    return asset_buf[0..at];
}

var flush_budget: u32 = 0;
var flushes: u32 = 0;
var frame_start: u64 = 0;

pub fn flushed() void {
    if (flush_budget == 0) return;
    frameLine(flushes, nowUs() - frame_start, flushes + 1 == flush_budget);
    flushes += 1;
    if (flushes == flush_budget) std.c.exit(0);
    frame_start = nowUs();
}

fn main(argc: c_int, argv: [*][*:0]u8) callconv(.c) c_int {
    var s: u32 = 320;
    var frames: u32 = 1;
    const n: usize = @intCast(argc);
    var i: usize = 1;
    while (i < n) {
        const a = std.mem.span(argv[i]);
        if (std.mem.eql(u8, a, "-screen") and i + 3 < n) {
            screen_w = number(argv[i + 1]) orelse return usage();
            screen_h = number(argv[i + 2]) orelse return usage();
            s = number(argv[i + 3]) orelse return usage();
            i += 4;
        } else if (std.mem.eql(u8, a, "-frames") and i + 1 < n) {
            frames = number(argv[i + 1]) orelse return usage();
            i += 2;
        } else if (std.mem.eql(u8, a, "-flushes") and i + 1 < n) {
            flush_budget = number(argv[i + 1]) orelse return usage();
            if (flush_budget == 0) return usage();
            i += 2;
        } else if (std.mem.eql(u8, a, "-key") and i + 1 < n and input_count < inputs.len) {
            const code = number(argv[i + 1]) orelse return usage();
            if (code > 255) return usage();
            inputs[input_count] = .{ .key = true, .a = code, .b = 0, .c = 0 };
            input_count += 1;
            i += 2;
        } else if (std.mem.eql(u8, a, "-mouse") and i + 3 < n and input_count < inputs.len) {
            inputs[input_count] = .{
                .key = false,
                .a = number(argv[i + 1]) orelse return usage(),
                .b = number(argv[i + 2]) orelse return usage(),
                .c = number(argv[i + 3]) orelse return usage(),
            };
            input_count += 1;
            i += 4;
        } else if (std.mem.eql(u8, a, "-ppm") and i + 1 < n) {
            ppm_path = argv[i + 1];
            i += 2;
        } else {
            return usage();
        }
    }
    if (!core.screen(screen_w, screen_h, s)) {
        write(2, "the host cannot give the program that screen\n");
        return 2;
    }
    for (inputs[0..input_count]) |in| {
        if (in.key) core.keyPush(@intCast(in.a)) else core.mousePush(in.a, in.b, in.c);
    }
    var line: [96]u8 = undefined;
    var f: u32 = 0;
    while (flush_budget > 0 or f < frames) : (f += 1) {
        core.clock(f * 100);
        const before = flushes;
        frame_start = nowUs();
        const t0 = nowUs();
        const code = core.run();
        const us = nowUs() - t0;
        if (code != 0) {
            write(1, core.console());
            write(2, std.fmt.bufPrint(&line, "exit {d} in run {d}\n", .{ code, f }) catch "a nonzero exit\n");
            return code;
        }
        if (flush_budget > 0) {
            if (flushes == before) stop("the program ended a run without a GPU flush, so -flushes never arrives; use -frames");
        } else {
            frameLine(f, us, f + 1 == frames);
        }
    }
    return 0;
}

comptime {
    @export(&main, .{ .name = "main" });
}
