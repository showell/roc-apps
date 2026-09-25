//! Fast Track's experiment host: the command line in as a List(Str), lines out
//! to stdout, each with its newline, and memory from the C library's allocator.
//! A copy of machine/native's host without the drives.

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

// Allocation counts, reported to stderr at exit when ROC_COUNT_ALLOCS is set: the
// same numbers roc2rust's runtime reports, for comparing the two builds. Live
// bytes are what the program asked for, without the size prefix host_alloc adds.
var count_allocs: u64 = 0;
var count_reallocs: u64 = 0;
var count_bytes: u64 = 0;
var count_live: u64 = 0;
var count_peak: u64 = 0;

fn liveGrow(by: usize) void {
    count_live += by;
    count_peak = @max(count_peak, count_live);
}
fn liveLength(ptr: *anyopaque, alignment: usize) usize {
    return host_alloc.storedTotalSize(ptr) - host_alloc.sizeStorageBytes(alignment);
}

fn roc_alloc(length: usize, alignment: usize) callconv(.c) ?*anyopaque {
    count_allocs += 1;
    count_bytes += length;
    liveGrow(length);
    return host_alloc.alloc(allocator, length, alignment) orelse host_alloc.allocFailed();
}
fn roc_dealloc(ptr: *anyopaque, alignment: usize) callconv(.c) void {
    count_live -= liveLength(ptr, alignment);
    host_alloc.dealloc(allocator, ptr, alignment);
}
fn roc_realloc(ptr: *anyopaque, new_length: usize, alignment: usize) callconv(.c) ?*anyopaque {
    count_reallocs += 1;
    count_bytes += new_length;
    count_live -= liveLength(ptr, alignment);
    liveGrow(new_length);
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

fn hostedEchoLine(line: RocStr) callconv(.c) void {
    defer line.decref(&roc_ops);
    const s = line.asSlice();
    var at: usize = 0;
    while (at < s.len) {
        const n = std.c.write(1, s.ptr + at, s.len - at);
        if (n <= 0) break;
        at += @intCast(n);
    }
    _ = std.c.write(1, "\n", 1);
}

comptime {
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
    const code = roc_main(args);
    if (std.c.getenv("ROC_COUNT_ALLOCS") != null) {
        var buf: [128]u8 = undefined;
        const line = std.fmt.bufPrint(&buf, "allocs {d} reallocs {d} bytes {d}\npeak live bytes {d}\n", .{ count_allocs, count_reallocs, count_bytes, count_peak }) catch return code;
        _ = std.c.write(2, line.ptr, line.len);
    }
    return code;
}

comptime {
    @export(&main, .{ .name = "main" });
}
