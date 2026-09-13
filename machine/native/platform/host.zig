//! The machine's native host: Echo's entry (the command line in as a List(Str),
//! lines out to stdout) and a block device answered from files. Two positions,
//! the primary channel's master and slave, each a file descriptor or nothing.
//!
//! A read answers 512 bytes: 255 in every byte from a position with nothing on
//! it, and zeros for the part of a sector past the end of its file. A write
//! past the end changes nothing, and a write that lands reaches the file
//! before it answers, as codex-vm flushes each sector to its image.

const std = @import("std");
const builtins = @import("builtins");
const host_alloc = @import("host_alloc");
const shim_io = @import("shim_io");

// std.debug's I/O is roc's minimal shim rather than zig's threaded I/O, as in
// roc's own static archives: the threaded vtable brings stat and socket calls
// into the link, and the musl this platform links against has not all of them.
pub const std_options_elf_debug_info_search_paths = shim_io.elfDebugInfoSearchPaths;
pub const std_options_debug_io = shim_io.io();
pub const std_options_debug_threaded_io = null;
pub const std_options = shim_io.std_options_static_archive;

const RocOps = builtins.host_abi.RocOps;
const RocList = builtins.list.RocList;
const RocStr = builtins.str.RocStr;

const allocator = std.heap.c_allocator;

/// A panic writes its message and aborts. The default handler prints through
/// std.debug, which drags zig's whole threaded I/O into the library, and the
/// musl the platform links against has none of its system calls.
pub const panic = std.debug.FullPanic(panicImpl);
fn panicImpl(msg: []const u8, _: ?usize) noreturn {
    _ = std.c.write(2, "host panic: ", 12);
    _ = std.c.write(2, msg.ptr, msg.len);
    _ = std.c.write(2, "\n", 1);
    std.c.abort();
}

fn noDec(_: ?*anyopaque, _: ?[*]u8) callconv(.c) void {}

fn roc_alloc(length: usize, alignment: usize) callconv(.c) ?*anyopaque {
    return host_alloc.alloc(allocator, length, alignment) orelse host_alloc.allocFailed();
}
fn roc_dealloc(ptr: *anyopaque, alignment: usize) callconv(.c) void {
    host_alloc.dealloc(allocator, ptr, alignment);
}
fn roc_realloc(ptr: *anyopaque, new_length: usize, alignment: usize) callconv(.c) ?*anyopaque {
    return host_alloc.realloc(allocator, ptr, new_length, alignment);
}
fn roc_dbg(bytes: [*]const u8, len: usize) callconv(.c) void {
    _ = std.c.write(2, bytes, len);
    _ = std.c.write(2, "\n", 1);
}
fn roc_expect_failed(bytes: [*]const u8, len: usize) callconv(.c) void {
    _ = std.c.write(2, "Expect failed: ", 15);
    _ = std.c.write(2, bytes, len);
    _ = std.c.write(2, "\n", 1);
}
fn roc_crashed(bytes: [*]const u8, len: usize) callconv(.c) void {
    _ = std.c.write(2, "Roc crashed: ", 13);
    _ = std.c.write(2, bytes, len);
    _ = std.c.write(2, "\n", 1);
    std.c.exit(1);
}

fn rocOpsAlloc(_: *RocOps, length: usize, alignment: usize) callconv(.c) ?*anyopaque {
    return roc_alloc(length, alignment);
}
fn rocOpsDealloc(_: *RocOps, ptr: *anyopaque, alignment: usize) callconv(.c) void {
    roc_dealloc(ptr, alignment);
}
fn rocOpsRealloc(_: *RocOps, ptr: *anyopaque, new_length: usize, alignment: usize) callconv(.c) ?*anyopaque {
    return roc_realloc(ptr, new_length, alignment);
}
fn rocOpsDbg(_: *RocOps, bytes: [*]const u8, len: usize) callconv(.c) void {
    roc_dbg(bytes, len);
}
fn rocOpsExpectFailed(_: *RocOps, bytes: [*]const u8, len: usize) callconv(.c) void {
    roc_expect_failed(bytes, len);
}
fn rocOpsCrashed(_: *RocOps, bytes: [*]const u8, len: usize) callconv(.c) void {
    roc_crashed(bytes, len);
}

comptime {
    host_alloc.exportRuntimeFns(.{
        .alloc = &roc_alloc,
        .dealloc = &roc_dealloc,
        .realloc = &roc_realloc,
        .dbg = &roc_dbg,
        .expect_failed = &roc_expect_failed,
        .crashed = &roc_crashed,
    });
}

var host_context: u8 = 0;
var roc_ops = RocOps{
    .env = @ptrCast(&host_context),
    .roc_alloc = rocOpsAlloc,
    .roc_dealloc = rocOpsDealloc,
    .roc_realloc = rocOpsRealloc,
    .roc_dbg = rocOpsDbg,
    .roc_expect_failed = rocOpsExpectFailed,
    .roc_crashed = rocOpsCrashed,
    .hosted_fns = builtins.host_abi.emptyHostedFunctions(),
};

// ---- the drives ----------------------------------------------------------

const Drive = struct { fd: c_int, size: u64 };
var drives: [2]?Drive = .{ null, null };

fn position(p: u64) ?Drive {
    return if (p < drives.len) drives[p] else null;
}

fn hostedDriveOpen(p: u64, path: RocStr) callconv(.c) bool {
    defer path.decref(&roc_ops);
    if (p >= drives.len) return false;
    const name = path.asSlice();
    var buf: [4096]u8 = undefined;
    if (name.len >= buf.len) return false;
    @memcpy(buf[0..name.len], name);
    buf[name.len] = 0;
    const fd = std.c.open(@ptrCast(&buf), .{ .ACCMODE = .RDWR });
    if (fd < 0) return false;
    const end = std.c.lseek(fd, 0, std.c.SEEK.END);
    if (end < 0) return false;
    drives[p] = .{ .fd = fd, .size = @intCast(end) };
    return true;
}

fn hostedDriveSectorCount(p: u64) callconv(.c) u64 {
    const d = position(p) orelse return 0;
    return d.size / 512;
}

fn hostedDriveRead(p: u64, lba: u64) callconv(.c) RocList {
    var sector: [512]u8 = undefined;
    if (position(p)) |d| {
        @memset(&sector, 0);
        if (lba < d.size / 512) {
            const n = std.c.pread(d.fd, &sector, sector.len, @intCast(lba * 512));
            if (n != sector.len) roc_crashed("machine: a drive read came up short", 35);
        }
    } else {
        @memset(&sector, 255);
    }
    return RocList.fromSlice(u8, &sector, false, &roc_ops);
}

fn hostedDriveWrite(p: u64, lba: u64, bytes: RocList) callconv(.c) void {
    defer bytes.decref(@alignOf(u8), @sizeOf(u8), false, null, noDec, &roc_ops);
    const d = position(p) orelse return;
    if (lba >= d.size / 512 or bytes.length != 512) return;
    const data = bytes.bytes orelse return;
    const n = std.c.pwrite(d.fd, data, 512, @intCast(lba * 512));
    if (n != 512) roc_crashed("machine: a drive write came up short", 36);
}

fn hostedEchoLine(line: RocStr) callconv(.c) void {
    defer line.decref(&roc_ops);
    const s = line.asSlice();
    var at: usize = 0;
    while (at < s.len) {
        const n = std.c.write(1, s.ptr + at, s.len - at);
        if (n <= 0) break;
        at += @intCast(n);
    }
}

comptime {
    @export(&hostedDriveOpen, .{ .name = "roc_drive_open", .visibility = .hidden });
    @export(&hostedDriveRead, .{ .name = "roc_drive_read", .visibility = .hidden });
    @export(&hostedDriveSectorCount, .{ .name = "roc_drive_sector_count", .visibility = .hidden });
    @export(&hostedDriveWrite, .{ .name = "roc_drive_write", .visibility = .hidden });
    @export(&hostedEchoLine, .{ .name = "roc_echo_line", .visibility = .hidden });
}

// ---- the entry -----------------------------------------------------------

extern fn roc_main(args: RocList) callconv(.c) i8;

fn main(argc: c_int, argv: [*][*:0]u8) callconv(.c) c_int {
    const count: usize = if (argc > 1) @intCast(argc - 1) else 0;
    const strs = allocator.alloc(RocStr, count) catch return 1;
    defer allocator.free(strs);
    for (strs, 0..) |*s, i| s.* = RocStr.fromSlice(std.mem.span(argv[i + 1]), &roc_ops);
    const args = RocList.fromSlice(RocStr, strs, true, &roc_ops);
    return roc_main(args);
}

comptime {
    @export(&main, .{ .name = "main" });
}
