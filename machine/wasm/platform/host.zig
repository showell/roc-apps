//! The machine's wasm host: a disk buffer, one current machine, and the doors
//! the page calls. The allocator and Roc's ops are the same as every roc-apps
//! wasm host's.

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

const Model = ?[*]u8;

extern fn roc_new(image: RocList) callconv(.c) Model;
extern fn roc_step(model: Model, budget: i64) callconv(.c) Model;
extern fn roc_key(model: Model, code: i64) callconv(.c) Model;
extern fn roc_view(model: Model) callconv(.c) RocList;
extern fn roc_drop(model: Model) callconv(.c) void;

/// A reference for a call that keeps nothing: Roc's decrement restores ours.
fn borrowed(m: Model) Model {
    builtins.utils.increfDataPtrC(m, 1, &roc_ops);
    return m;
}

// ---- the page's doors ----------------------------------------------------

const disk_cap: usize = 1024 * 1024;
var disk_buf: [disk_cap]u8 = undefined;

var current: Model = null;
/// The last view's bytes, owned until the next view replaces them.
var frame: RocList = RocList.empty();

pub export fn diskPtr() u32 {
    return @intCast(@intFromPtr(&disk_buf));
}

pub export fn diskCapacity() u32 {
    return @intCast(disk_cap);
}

/// A fresh machine over the image in the disk buffer; the old one is dropped.
pub export fn newMachine(disk_len: u32) void {
    if (disk_len > disk_cap) @trap();
    if (current) |old| roc_drop(old);
    current = roc_new(RocList.fromSlice(u8, disk_buf[0..disk_len], false, &roc_ops));
}

/// Up to `budget` operations. The machine is handed over OWNED and replaced
/// by what comes back, so its lists stay uniquely held.
pub export fn step(budget: i32) void {
    const cur = current orelse return;
    current = roc_step(cur, budget);
}

/// A scancode into the machine's keyboard queue.
pub export fn key(code: i32) void {
    const cur = current orelse return;
    current = roc_key(cur, code);
}

pub export fn view() u32 {
    const cur = current orelse return 0;
    frame.decref(@alignOf(u8), @sizeOf(u8), false, null, noDec, &roc_ops);
    frame = roc_view(borrowed(cur));
    return @intCast(frame.length);
}

pub export fn outPtr() u32 {
    return @intCast(@intFromPtr(frame.bytes orelse return 0));
}

pub export fn outLen() u32 {
    return @intCast(frame.length);
}
