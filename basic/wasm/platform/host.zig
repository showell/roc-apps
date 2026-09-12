//! The BASIC wasm host: one door onto one Roc function.

const std = @import("std");
const builtins = @import("builtins");
const host_alloc = @import("host_alloc");

const RocOps = builtins.host_abi.RocOps;
const RocList = builtins.list.RocList;

fn noDec(_: ?*anyopaque, _: ?[*]u8) callconv(.c) void {}

pub const panic = std.debug.FullPanic(panicImpl);
fn panicImpl(_: []const u8, _: ?usize) noreturn {
    @trap();
}

const wasm_allocator = std.heap.wasm_allocator;

fn roc_alloc(length: usize, alignment: usize) callconv(.c) ?*anyopaque {
    return host_alloc.alloc(wasm_allocator, length, alignment);
}
fn roc_dealloc(ptr: *anyopaque, alignment: usize) callconv(.c) void {
    host_alloc.dealloc(wasm_allocator, ptr, alignment);
}
fn roc_realloc(ptr: *anyopaque, new_length: usize, alignment: usize) callconv(.c) ?*anyopaque {
    return host_alloc.realloc(wasm_allocator, ptr, new_length, alignment);
}
fn roc_dbg(_: [*]const u8, _: usize) callconv(.c) void {}
fn roc_expect_failed(_: [*]const u8, _: usize) callconv(.c) void {}
fn roc_crashed(_: [*]const u8, _: usize) callconv(.c) void {
    @trap();
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

extern fn roc_run(src: RocList, keys: RocList, seed: i64) callconv(.c) RocList;

// ---- the page's door ---------------------------------------------------
//
// A BASIC run is a pure function of its listing, its keystrokes and a
// seed, so the seam is three buffers and one call. The page writes the
// listing at `srcPtr` and the keystrokes at `keysPtr`, says how long each
// is, and reads the transcript back at `outPtr`.
//
// The input buffers are static and fixed: the longest listing in the 1978
// corpus is under 32 KB and the keystrokes are a few hundred bytes, so a
// page that overruns them is a page with a bug, and `capacity` is there
// so it can find out rather than guess.

const src_cap: usize = 128 * 1024;
const keys_cap: usize = 32 * 1024;

var src_buf: [src_cap]u8 = undefined;
var keys_buf: [keys_cap]u8 = undefined;

/// The transcript of the last run, owned until the next one replaces it.
var out: RocList = RocList.empty();

pub export fn srcPtr() u32 {
    return @intCast(@intFromPtr(&src_buf));
}
pub export fn keysPtr() u32 {
    return @intCast(@intFromPtr(&keys_buf));
}
pub export fn capacity(which: u32) u32 {
    return if (which == 0) @intCast(src_cap) else @intCast(keys_cap);
}

/// Run, and answer how many bytes of transcript there are.
pub export fn runIt(src_len: u32, keys_len: u32, seed: i32) u32 {
    if (src_len > src_cap or keys_len > keys_cap) return 0;
    out.decref(@alignOf(u8), @sizeOf(u8), false, null, noDec, &roc_ops);
    const s = RocList.fromSlice(u8, src_buf[0..src_len], false, &roc_ops);
    const k = RocList.fromSlice(u8, keys_buf[0..keys_len], false, &roc_ops);
    out = roc_run(s, k, seed);
    return @intCast(out.length);
}

pub export fn outPtr() u32 {
    return @intCast(@intFromPtr(out.bytes orelse return 0));
}
