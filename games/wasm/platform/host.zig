//! The games wasm host. Two doors onto the same Roc functions.
//!
//! THE PAGE'S DOOR is one model: newGame(seed), step(message) and view(),
//! the seam web/2048.html drives from the keyboard. A message is a small
//! integer the app decodes; the host knows nothing of keys.
//!
//! THE GRADER'S DOOR is Damian's export contract for the game
//! (apps/games/build-wasm.ps1, the handle contract): g2_new answers a
//! handle, g2_move(h, d) answers the handle of the state after the move,
//! and the queries read a handle. Here a handle is an index into a table of
//! boxed models the host owns; old handles stay valid, as the arcade's undo
//! assumes. A refused move answers the SAME handle, which the grader
//! requires and the engine makes decidable: an accepted move is the one
//! that advances the move counter. __heap_reset frees the table, which the
//! arcade calls at a new game. Roc frees each model on the way out, so
//! nothing leaks across a long autoplay.
//!
//! OWNERSHIP: a Roc function that takes a Box owns that reference, so a
//! call that must leave the host's reference alive increments the count
//! first (`borrowed`), as the safari host does. The runtime scaffolding is
//! the safari host's too (safari/wasm/platform/host.zig).

const std = @import("std");
const builtins = @import("builtins");
const host_alloc = @import("host_alloc");

const RocOps = builtins.host_abi.RocOps;
const RocList = builtins.list.RocList;
const Model = ?[*]u8;

extern fn roc_init(seed: i64) callconv(.c) Model;
extern fn roc_step(model: Model, msg: i64) callconv(.c) Model;
extern fn roc_view(model: Model) callconv(.c) RocList;
extern fn roc_move(model: Model, d: i64) callconv(.c) Model;
extern fn roc_cell(model: Model, i: i64) callconv(.c) i64;
extern fn roc_score(model: Model) callconv(.c) i64;
extern fn roc_moves(model: Model) callconv(.c) i64;
extern fn roc_done(model: Model) callconv(.c) i64;
extern fn roc_max(model: Model) callconv(.c) i64;
extern fn roc_empty(model: Model) callconv(.c) i64;
extern fn roc_sum(model: Model) callconv(.c) i64;
extern fn roc_can(model: Model, d: i64) callconv(.c) i64;
extern fn roc_ai(model: Model) callconv(.c) i64;
extern fn roc_drop(model: Model) callconv(.c) void;

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

pub export fn g2_new(seed: i32) i32 {
    return push(roc_init(seed));
}
pub export fn g2_move(h: i32, d: i32) i32 {
    const old = at(h);
    const next = roc_move(borrowed(old), d);
    // A refused direction leaves the move counter alone; an accepted one
    // advances it. The engine says so, and so the handle can.
    if (roc_moves(borrowed(next)) == roc_moves(borrowed(old))) {
        roc_drop(next);
        return h;
    }
    return push(next);
}
pub export fn g2_cell(h: i32, i: i32) i32 {
    return @intCast(roc_cell(borrowed(at(h)), i));
}
pub export fn g2_score(h: i32) i32 {
    return @intCast(roc_score(borrowed(at(h))));
}
pub export fn g2_moves(h: i32) i32 {
    return @intCast(roc_moves(borrowed(at(h))));
}
pub export fn g2_done(h: i32) i32 {
    return @intCast(roc_done(borrowed(at(h))));
}
pub export fn g2_max(h: i32) i32 {
    return @intCast(roc_max(borrowed(at(h))));
}
pub export fn g2_empty(h: i32) i32 {
    return @intCast(roc_empty(borrowed(at(h))));
}
pub export fn g2_sum(h: i32) i32 {
    return @intCast(roc_sum(borrowed(at(h))));
}
pub export fn g2_can(h: i32, d: i32) i32 {
    return @intCast(roc_can(borrowed(at(h)), d));
}
pub export fn g2_ai(h: i32) i32 {
    return @intCast(roc_ai(borrowed(at(h))));
}
/// What the arcade calls at a new game: every handle freed.
pub export fn __heap_reset() void {
    for (table.items) |m| roc_drop(m);
    table.clearRetainingCapacity();
}
