//! The floor's native host: core.zig's memory, block device and clock in an
//! ordinary Linux process. It runs the program's opening once and prints what
//! it printed.
//!
//!     <program> [-disk <path>] [-disk2 <path>] [-disk-out <path>] [-wall]
//!               [-fault <kind>] [-fault-every <n>] [-fault-lba <lba>] [-report]
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

comptime {
    core.exportSymbols();
}

fn usage() c_int {
    write(2, "usage: <program> [-disk <path>] [-disk2 <path>] [-disk-out <path>] [-wall] [-fault <kind>] [-fault-every <n>] [-fault-lba <lba>] [-report]\n");
    write(2, "       a fault kind is refuse-read, refuse-write or tear-write\n");
    return 2;
}

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

fn faultKind(name: []const u8) ?core.Fault {
    if (std.mem.eql(u8, name, "refuse-read")) return .refuse_read;
    if (std.mem.eql(u8, name, "refuse-write")) return .refuse_write;
    if (std.mem.eql(u8, name, "tear-write")) return .tear_write;
    return null;
}

fn main(argc: c_int, argv: [*][*:0]u8) callconv(.c) c_int {
    var out_path: ?[*:0]u8 = null;
    var report = false;
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
            report = true;
            i += 1;
        } else {
            return usage();
        }
    }

    core.startClock();
    const t0 = nowNs();
    const code = core.run();
    const us = (nowNs() - t0) / 1000;
    write(1, core.console());

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

    if (report) {
        var line: [224]u8 = undefined;
        write(1, std.fmt.bufPrint(&line, "-- {d} ms, {d} pages, {d} sectors read, {d} written, {d} waits, fault {s} bit {d}\n", .{
            us / 1000,
            core.pages_made,
            core.sectors_read,
            core.sectors_written,
            core.waits,
            core.faultName(),
            core.faults_bitten,
        }) catch "-- a run\n");
    }

    if (code != 0) {
        var line: [64]u8 = undefined;
        write(2, std.fmt.bufPrint(&line, "exit {d}\n", .{code}) catch "a nonzero exit\n");
    }
    return code;
}

comptime {
    @export(&main, .{ .name = "main" });
}
