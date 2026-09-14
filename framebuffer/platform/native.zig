//! The framebuffer platform's native host, the checker: core.zig's memory,
//! screen, ports and GPU in an ordinary Linux process. It gives the program a
//! screen and prints, for every frame, its time and a hash of its visible pixels
//! (core.hash, the one frames.mjs prints), then the console of the last frame
//! before its line. A crash prints the console so far and its message, and
//! exits 1.
//!
//!     <program> [-screen <width> <height> <stride>] (-frames <n> | -flushes <n>)
//!
//! With -frames (1 when neither is given), a frame is a run of the program's
//! opening, with the clock 100 ms further on each time, as the page runs it.
//! With -flushes, a frame is a GPU flush, for a program that draws in a loop of
//! its own and never ends its run; the host stops at the nth. The program's own
//! command line is empty, as on the page; the heap's base moves with its length.

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
    write(2, "usage: <program> [-screen <width> <height> <stride>] (-frames <n> | -flushes <n>)\n");
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

/// One frame's line: its number, its time, and its pixels' hash; the last
/// frame's console goes before it.
fn frameLine(n: u32, us: u64, last: bool) void {
    var line: [96]u8 = undefined;
    const h = core.hash(core.present());
    if (last) write(1, core.console());
    write(1, std.fmt.bufPrint(&line, "-- frame {d}: {d} ms, hash {x:0>8}\n", .{ n, us / 1000, h }) catch "-- frame\n");
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
    var w: u32 = 320;
    var h: u32 = 240;
    var s: u32 = 320;
    var frames: u32 = 1;
    const n: usize = @intCast(argc);
    var i: usize = 1;
    while (i < n) {
        const a = std.mem.span(argv[i]);
        if (std.mem.eql(u8, a, "-screen") and i + 3 < n) {
            w = number(argv[i + 1]) orelse return usage();
            h = number(argv[i + 2]) orelse return usage();
            s = number(argv[i + 3]) orelse return usage();
            i += 4;
        } else if (std.mem.eql(u8, a, "-frames") and i + 1 < n) {
            frames = number(argv[i + 1]) orelse return usage();
            i += 2;
        } else if (std.mem.eql(u8, a, "-flushes") and i + 1 < n) {
            flush_budget = number(argv[i + 1]) orelse return usage();
            if (flush_budget == 0) return usage();
            i += 2;
        } else {
            return usage();
        }
    }
    if (!core.screen(w, h, s)) {
        write(2, "the host cannot give the program that screen\n");
        return 2;
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
