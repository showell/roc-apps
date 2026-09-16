//! The floor's native host, the checker: core.zig's memory, block device,
//! clock, screen and GPU in an ordinary Linux process.
//!
//!     <program> [-disk <path>] [-disk2 <path>] [-disk-out <path>]
//!               [-screen <width> <height> <stride>] [-key <scancode>]...
//!               [-mouse <x> <y> <buttons>]... [-ppm <path>]
//!               [-frames <n> | -flushes <n>] [-wall]
//!               [-fault <kind>] [-fault-every <n>] [-fault-lba <lba>] [-report]
//!
//! **A PROGRAM GETS A SCREEN ONLY WHEN -screen ASKS FOR ONE**, so a program
//! that only reaches the disk prints its console and nothing else. With a
//! screen, every frame's time and a hash of its visible pixels go out as a
//! line, as the framebuffer platform's checker prints them, and -ppm writes the
//! last frame.
//!
//! With -frames (1 when neither is given), a frame is a run of the program's
//! opening, with the clock cell 100 ms further on each time. With -flushes, a
//! frame is a GPU flush, for a program that draws in a loop of its own and
//! never ends its run.
//!
//! An image named by -disk or -disk2 is read into the host, which then owns it:
//! the run's writes land in the host's copy, and the file on disk is untouched
//! unless -disk-out names somewhere to write the primary image back.
//!
//! The clock is virtual unless -wall asks for the host's, so a run repeats
//! exactly. -fault puts the floor in a mode where it breaks its promises on
//! purpose (refuse-read, refuse-write, tear-write); -report prints what the run
//! cost and how often a fault bit.

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

pub fn nowNs() u64 {
    var ts: std.c.timespec = undefined;
    _ = std.c.clock_gettime(std.c.CLOCK.MONOTONIC, &ts);
    return @as(u64, @intCast(ts.sec)) * 1_000_000_000 + @as(u64, @intCast(ts.nsec));
}

pub fn sleepNs(ns: u64) void {
    var req = std.c.timespec{ .sec = @intCast(ns / 1_000_000_000), .nsec = @intCast(ns % 1_000_000_000) };
    _ = std.c.nanosleep(&req, &req);
}

fn nowUs() u64 {
    return nowNs() / 1000;
}

comptime {
    core.exportSymbols();
}

fn usage() c_int {
    write(2, "usage: <program> [-disk <path>] [-disk2 <path>] [-disk-out <path>]\n");
    write(2, "                 [-screen <w> <h> <stride>] [-key <scancode>]... [-mouse <x> <y> <buttons>]...\n");
    write(2, "                 [-ppm <path>] [-frames <n> | -flushes <n>] [-wall]\n");
    write(2, "                 [-fault <kind>] [-fault-every <n>] [-fault-lba <lba>] [-report]\n");
    write(2, "       a fault kind is refuse-read, refuse-write or tear-write\n");
    return 2;
}

fn number(arg: [*:0]u8) ?u32 {
    return std.fmt.parseInt(u32, std.mem.span(arg), 10) catch null;
}

// ---- the images ----------------------------------------------------------

/// The whole file at `path`, which the caller then owns.
fn slurp(path: [*:0]const u8) ?[]u8 {
    const fd = std.c.open(path, .{ .ACCMODE = .RDONLY });
    if (fd < 0) return null;
    defer _ = std.c.close(fd);
    const end = std.c.lseek(fd, 0, std.c.SEEK.END);
    if (end < 0 or std.c.lseek(fd, 0, std.c.SEEK.SET) != 0) return null;
    const bytes = allocator.alloc(u8, @intCast(end)) catch stop("no memory for a disk image");
    var at: usize = 0;
    while (at < bytes.len) {
        const n = std.c.read(fd, bytes.ptr + at, bytes.len - at);
        if (n <= 0) break;
        at += @intCast(n);
    }
    if (at != bytes.len) return null;
    return bytes;
}

fn spill(path: [*:0]const u8, bytes: []const u8) bool {
    const fd = std.c.open(path, .{ .ACCMODE = .WRONLY, .CREAT = true, .TRUNC = true }, @as(std.c.mode_t, 0o644));
    if (fd < 0) return false;
    defer _ = std.c.close(fd);
    var at: usize = 0;
    while (at < bytes.len) {
        const n = std.c.write(fd, bytes.ptr + at, bytes.len - at);
        if (n <= 0) return false;
        at += @intCast(n);
    }
    return true;
}

fn attachFrom(p: u64, path: [*:0]u8) c_int {
    var msg: [256]u8 = undefined;
    const bytes = slurp(path) orelse {
        write(2, std.fmt.bufPrint(&msg, "cannot read {s} as drive {d}\n", .{ std.mem.span(path), p }) catch "cannot read a disk image\n");
        return 2;
    };
    if (!core.attach(p, bytes)) {
        write(2, std.fmt.bufPrint(&msg, "{s} is {d} bytes, which is not a whole number of 512-byte sectors\n", .{ std.mem.span(path), bytes.len }) catch "a disk image that is not whole sectors\n");
        return 2;
    }
    return 0;
}

// ---- the assets ----------------------------------------------------------

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

// ---- the screen ----------------------------------------------------------

/// A key or a mouse state from the command line, handed over before the first
/// run.
const Input = struct { key: bool, a: u32, b: u32, c: u32 };
var inputs: [64]Input = undefined;
var input_count: usize = 0;

var has_screen = false;
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

var flush_budget: u32 = 0;
var flushes: u32 = 0;
var frame_start: u64 = 0;

pub fn flushed() void {
    if (flush_budget == 0) return;
    frameLine(flushes, nowUs() - frame_start, flushes + 1 == flush_budget);
    flushes += 1;
    if (flushes == flush_budget) {
        report();
        std.c.exit(0);
    }
    frame_start = nowUs();
}

// ---- the run -------------------------------------------------------------

var reporting = false;
var run_us: u64 = 0;

fn report() void {
    if (!reporting) return;
    var line: [256]u8 = undefined;
    write(1, std.fmt.bufPrint(&line, "-- {d} ms, {d} pages, heap {d} loads {d} stores, disk {d} read {d} written, {d} waits, fault {s} bit {d}\n", .{
        run_us / 1000,
        core.pages_made,
        core.heap_loads,
        core.heap_stores,
        core.sectors_read,
        core.sectors_written,
        core.waits,
        core.faultName(),
        core.faults_bitten,
    }) catch "-- a run\n");
}

fn faultKind(name: []const u8) ?core.Fault {
    if (std.mem.eql(u8, name, "refuse-read")) return .refuse_read;
    if (std.mem.eql(u8, name, "refuse-write")) return .refuse_write;
    if (std.mem.eql(u8, name, "tear-write")) return .tear_write;
    return null;
}

fn main(argc: c_int, argv: [*][*:0]u8) callconv(.c) c_int {
    var out_path: ?[*:0]u8 = null;
    var stride: u32 = 320;
    var frames: u32 = 1;
    const n: usize = @intCast(argc);
    var i: usize = 1;
    while (i < n) {
        const a = std.mem.span(argv[i]);
        if (std.mem.eql(u8, a, "-disk") and i + 1 < n) {
            const bad = attachFrom(0, argv[i + 1]);
            if (bad != 0) return bad;
            i += 2;
        } else if (std.mem.eql(u8, a, "-disk2") and i + 1 < n) {
            const bad = attachFrom(1, argv[i + 1]);
            if (bad != 0) return bad;
            i += 2;
        } else if (std.mem.eql(u8, a, "-disk-out") and i + 1 < n) {
            out_path = argv[i + 1];
            i += 2;
        } else if (std.mem.eql(u8, a, "-screen") and i + 3 < n) {
            has_screen = true;
            screen_w = number(argv[i + 1]) orelse return usage();
            screen_h = number(argv[i + 2]) orelse return usage();
            stride = number(argv[i + 3]) orelse return usage();
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
        } else if (std.mem.eql(u8, a, "-wall")) {
            core.wall_clock = true;
            i += 1;
        } else if (std.mem.eql(u8, a, "-fault") and i + 1 < n) {
            core.fault_kind = faultKind(std.mem.span(argv[i + 1])) orelse return usage();
            i += 2;
        } else if (std.mem.eql(u8, a, "-fault-every") and i + 1 < n) {
            core.fault_every = std.fmt.parseInt(u64, std.mem.span(argv[i + 1]), 10) catch return usage();
            if (core.fault_every == 0) return usage();
            i += 2;
        } else if (std.mem.eql(u8, a, "-fault-lba") and i + 1 < n) {
            core.fault_lba = std.fmt.parseInt(u64, std.mem.span(argv[i + 1]), 10) catch return usage();
            i += 2;
        } else if (std.mem.eql(u8, a, "-report")) {
            reporting = true;
            i += 1;
        } else {
            return usage();
        }
    }

    if (flush_budget > 0 and !has_screen) {
        write(2, "-flushes counts GPU flushes, which need a screen: add -screen\n");
        return 2;
    }
    if (has_screen and !core.screen(screen_w, screen_h, stride)) {
        write(2, "the host cannot give the program that screen\n");
        return 2;
    }
    for (inputs[0..input_count]) |in| {
        if (in.key) core.keyPush(@intCast(in.a)) else core.mousePush(in.a, in.b, in.c);
    }

    core.startClock();
    var line: [96]u8 = undefined;
    var f: u32 = 0;
    while (flush_budget > 0 or f < frames) : (f += 1) {
        if (has_screen) core.clock(f * 100);
        const before = flushes;
        frame_start = nowUs();
        const t0 = nowUs();
        const code = core.run();
        run_us += nowUs() - t0;
        if (code != 0) {
            write(1, core.console());
            write(2, std.fmt.bufPrint(&line, "exit {d} in run {d}\n", .{ code, f }) catch "a nonzero exit\n");
            return code;
        }
        if (flush_budget > 0) {
            if (flushes == before) stop("the program ended a run without a GPU flush, so -flushes never arrives; use -frames");
        } else if (has_screen) {
            frameLine(f, nowUs() - t0, f + 1 == frames);
        } else {
            write(1, core.console());
        }
    }

    if (out_path) |path| {
        const img = core.image(0) orelse {
            write(2, "-disk-out with no -disk to write back\n");
            return 2;
        };
        if (!spill(path, img)) {
            write(2, "cannot write the image back\n");
            return 2;
        }
    }
    report();
    return 0;
}

comptime {
    @export(&main, .{ .name = "main" });
}
