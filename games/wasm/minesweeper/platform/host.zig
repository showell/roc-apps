//! The minesweeper wasm host. Written by games/gen.py from the export table. Do not edit.
//! Two doors onto the same Roc functions: the page's (one model, a message)
//! and the grader's (Damian's export contract, by handle over a table of
//! boxed models; a refused transition answers the same handle, decided by
//! the move counter `moves`). See games/gen.py.

const std = @import("std");
const builtins = @import("builtins");
const host_alloc = @import("host_alloc");

const RocOps = builtins.host_abi.RocOps;
const RocList = builtins.list.RocList;
const Model = ?[*]u8;

extern fn roc_init(seed: i64) callconv(.c) Model;
extern fn roc_step(model: Model, msg: i64) callconv(.c) Model;
extern fn roc_view(model: Model) callconv(.c) RocList;
extern fn roc_drop(model: Model) callconv(.c) void;
extern fn roc_mine(model: Model, a0: i64) callconv(.c) i64;
extern fn roc_shown(model: Model, a0: i64) callconv(.c) i64;
extern fn roc_adj(model: Model, a0: i64) callconv(.c) i64;
extern fn roc_count(model: Model) callconv(.c) i64;
extern fn roc_hits(model: Model) callconv(.c) i64;
extern fn roc_moves(model: Model) callconv(.c) i64;
extern fn roc_done(model: Model) callconv(.c) i64;
extern fn roc_won(model: Model) callconv(.c) i64;
extern fn roc_safe(model: Model) callconv(.c) i64;
extern fn roc_open(model: Model, a0: i64) callconv(.c) Model;
extern fn roc_ai(model: Model) callconv(.c) i64;

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

fn noDec(_: ?*anyopaque, _: ?[*]u8) callconv(.c) void {}

/// A reference for a call that keeps nothing: Roc's decrement restores ours.
fn borrowed(m: Model) Model {
    builtins.utils.increfDataPtrC(m, 1, &roc_ops);
    return m;
}

// ---- the page's door: one model -------------------------------------------

var current: Model = null;
// The last view's words, owned until the next view replaces them.
var frame: RocList = RocList.empty();

pub export fn newGame(seed: i32) void {
    if (current != null) roc_drop(current);
    current = roc_init(seed);
}
pub export fn step(msg: i32) void {
    if (current == null) current = roc_init(1);
    current = roc_step(current, msg);
}
pub export fn view() u32 {
    if (current == null) current = roc_init(1);
    frame.decref(@alignOf(u32), @sizeOf(u32), false, null, noDec, &roc_ops);
    frame = roc_view(borrowed(current));
    return @intCast(frame.length * 4);
}
pub export fn bufPtr() u32 {
    return @intCast(@intFromPtr(frame.bytes orelse return 0));
}

// ---- the grader's door: handles ---------------------------------------------

var table: std.ArrayList(Model) = .empty;

fn push(m: Model) i32 {
    table.append(wasm_allocator, m) catch @trap();
    return @intCast(table.items.len - 1);
}
fn at(h: i32) Model {
    if (h < 0 or @as(usize, @intCast(h)) >= table.items.len) @trap();
    return table.items[@intCast(h)];
}


pub export fn ms_new(seed: i32) i32 {
    return push(roc_init(seed));
}
pub export fn ms_mine(h: i32, a0: i32) i32 {
    return @intCast(roc_mine(borrowed(at(h)), a0));
}
pub export fn ms_shown(h: i32, a0: i32) i32 {
    return @intCast(roc_shown(borrowed(at(h)), a0));
}
pub export fn ms_adj(h: i32, a0: i32) i32 {
    return @intCast(roc_adj(borrowed(at(h)), a0));
}
pub export fn ms_count(h: i32) i32 {
    return @intCast(roc_count(borrowed(at(h))));
}
pub export fn ms_hits(h: i32) i32 {
    return @intCast(roc_hits(borrowed(at(h))));
}
pub export fn ms_moves(h: i32) i32 {
    return @intCast(roc_moves(borrowed(at(h))));
}
pub export fn ms_done(h: i32) i32 {
    return @intCast(roc_done(borrowed(at(h))));
}
pub export fn ms_won(h: i32) i32 {
    return @intCast(roc_won(borrowed(at(h))));
}
pub export fn ms_safe(h: i32) i32 {
    return @intCast(roc_safe(borrowed(at(h))));
}
pub export fn ms_open(h: i32, a0: i32) i32 {
    const old = at(h);
    const next = roc_open(borrowed(old), a0);
    if (roc_moves(borrowed(next)) == roc_moves(borrowed(old))) {
        roc_drop(next);
        return h;
    }
    return push(next);
}
pub export fn ms_ai(h: i32) i32 {
    return @intCast(roc_ai(borrowed(at(h))));
}
/// What the arcade calls at a new game: every handle freed.
pub export fn __heap_reset() void {
    for (table.items) |m| roc_drop(m);
    table.clearRetainingCapacity();
}
