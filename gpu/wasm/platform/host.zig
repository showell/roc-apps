//! The gpu wasm host: three exports over one boxed Roc model, as the safari
//! host keeps its ride. step(kernel, frame) moves the model through the
//! app's step, which owns the old one and answers the new; view() borrows
//! it (an increment the callee's decrement restores) and keeps the returned
//! List until the next view; bufPtr is where its words are.
//!
//! The runtime scaffolding (allocator, RocOps, no imports) is the safari
//! host's, wasm/platform/host.zig, which explains it.

const std = @import("std");
const builtins = @import("builtins");
const host_alloc = @import("host_alloc");

const RocOps = builtins.host_abi.RocOps;
const RocList = builtins.list.RocList;

extern fn roc_init() callconv(.c) ?[*]u8;
extern fn roc_step(model: ?[*]u8, kernel: i64, frame: i64) callconv(.c) ?[*]u8;
extern fn roc_view(model: ?[*]u8) callconv(.c) RocList;

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

// THE MODEL, one reference the host owns.
var model: ?[*]u8 = null;
// The last view's words, owned until the next view replaces them.
var frame: RocList = RocList.empty();

fn noDec(_: ?*anyopaque, _: ?[*]u8) callconv(.c) void {}

fn ensure() void {
    if (model == null) model = roc_init();
}

/// Frame `n` of demo `k`: the model moves on.
pub export fn step(k: u32, n: u32) void {
    ensure();
    model = roc_step(model, @intCast(k), @intCast(n));
}

/// The words to draw; their byte length.
pub export fn view() u32 {
    ensure();
    frame.decref(@alignOf(u32), @sizeOf(u32), false, null, noDec, &roc_ops);
    builtins.utils.increfDataPtrC(model, 1, &roc_ops);
    frame = roc_view(model);
    return @intCast(frame.length * 4);
}
pub export fn bufPtr() u32 {
    return @intCast(@intFromPtr(frame.bytes orelse return 0));
}
