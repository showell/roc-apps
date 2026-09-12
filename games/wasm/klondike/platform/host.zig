//! The klondike wasm host. Written by games/gen.py from the export table. Do not edit.
//! Two doors onto the same Roc functions: the page's (one model, a message)
//! and the grader's (Damian's export contract, by handle over a table of
//! boxed models; a refused transition answers the same handle, decided by
//! the app's structural `same`). See games/gen.py.

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
extern fn roc_same(a: Model, b: Model) callconv(.c) i64;
extern fn roc_new(a0: i64, a1: i64) callconv(.c) Model;
extern fn roc_rank(a0: i64) callconv(.c) i64;
extern fn roc_suit(a0: i64) callconv(.c) i64;
extern fn roc_coln(model: Model, a0: i64) callconv(.c) i64;
extern fn roc_card(model: Model, a0: i64, a1: i64) callconv(.c) i64;
extern fn roc_down(model: Model, a0: i64) callconv(.c) i64;
extern fn roc_found(model: Model, a0: i64) callconv(.c) i64;
extern fn roc_foundcard(model: Model, a0: i64) callconv(.c) i64;
extern fn roc_stockn(model: Model) callconv(.c) i64;
extern fn roc_wasten(model: Model) callconv(.c) i64;
extern fn roc_wastetop(model: Model) callconv(.c) i64;
extern fn roc_founded(model: Model) callconv(.c) i64;
extern fn roc_moves(model: Model) callconv(.c) i64;
extern fn roc_drawn(model: Model) callconv(.c) i64;
extern fn roc_won(model: Model) callconv(.c) i64;
extern fn roc_runlen(model: Model, a0: i64, a1: i64) callconv(.c) i64;
extern fn roc_can(model: Model, a0: i64, a1: i64, a2: i64) callconv(.c) i64;
extern fn roc_move(model: Model, a0: i64, a1: i64, a2: i64) callconv(.c) Model;
extern fn roc_candraw(model: Model) callconv(.c) i64;
extern fn roc_draw(model: Model) callconv(.c) Model;
extern fn roc_canrecyc(model: Model) callconv(.c) i64;
extern fn roc_recycle(model: Model) callconv(.c) Model;
extern fn roc_ai(model: Model) callconv(.c) i64;
extern fn roc_mfrom(a0: i64) callconv(.c) i64;
extern fn roc_mstart(a0: i64) callconv(.c) i64;
extern fn roc_mto(a0: i64) callconv(.c) i64;
extern fn roc_run(a0: i64, a1: i64) callconv(.c) Model;
extern fn roc_rfound(model: Model) callconv(.c) i64;
extern fn roc_rmoves(model: Model) callconv(.c) i64;
extern fn roc_rwon(model: Model) callconv(.c) i64;

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


pub export fn kd_new(a0: i32, a1: i32) i32 {
    return push(roc_new(a0, a1));
}
pub export fn kd_rank(a0: i32) i32 {
    return @intCast(roc_rank(a0));
}
pub export fn kd_suit(a0: i32) i32 {
    return @intCast(roc_suit(a0));
}
pub export fn kd_coln(h: i32, a0: i32) i32 {
    return @intCast(roc_coln(borrowed(at(h)), a0));
}
pub export fn kd_card(h: i32, a0: i32, a1: i32) i32 {
    return @intCast(roc_card(borrowed(at(h)), a0, a1));
}
pub export fn kd_down(h: i32, a0: i32) i32 {
    return @intCast(roc_down(borrowed(at(h)), a0));
}
pub export fn kd_found(h: i32, a0: i32) i32 {
    return @intCast(roc_found(borrowed(at(h)), a0));
}
pub export fn kd_foundcard(h: i32, a0: i32) i32 {
    return @intCast(roc_foundcard(borrowed(at(h)), a0));
}
pub export fn kd_stockn(h: i32) i32 {
    return @intCast(roc_stockn(borrowed(at(h))));
}
pub export fn kd_wasten(h: i32) i32 {
    return @intCast(roc_wasten(borrowed(at(h))));
}
pub export fn kd_wastetop(h: i32) i32 {
    return @intCast(roc_wastetop(borrowed(at(h))));
}
pub export fn kd_founded(h: i32) i32 {
    return @intCast(roc_founded(borrowed(at(h))));
}
pub export fn kd_moves(h: i32) i32 {
    return @intCast(roc_moves(borrowed(at(h))));
}
pub export fn kd_drawn(h: i32) i32 {
    return @intCast(roc_drawn(borrowed(at(h))));
}
pub export fn kd_won(h: i32) i32 {
    return @intCast(roc_won(borrowed(at(h))));
}
pub export fn kd_runlen(h: i32, a0: i32, a1: i32) i32 {
    return @intCast(roc_runlen(borrowed(at(h)), a0, a1));
}
pub export fn kd_can(h: i32, a0: i32, a1: i32, a2: i32) i32 {
    return @intCast(roc_can(borrowed(at(h)), a0, a1, a2));
}
pub export fn kd_move(h: i32, a0: i32, a1: i32, a2: i32) i32 {
    const old = at(h);
    const next = roc_move(borrowed(old), a0, a1, a2);
    // A refusal answers the state it was given; the same handle, then.
    if (roc_same(borrowed(old), borrowed(next)) == 1) {
        roc_drop(next);
        return h;
    }
    return push(next);
}
pub export fn kd_candraw(h: i32) i32 {
    return @intCast(roc_candraw(borrowed(at(h))));
}
pub export fn kd_draw(h: i32) i32 {
    const old = at(h);
    const next = roc_draw(borrowed(old));
    // A refusal answers the state it was given; the same handle, then.
    if (roc_same(borrowed(old), borrowed(next)) == 1) {
        roc_drop(next);
        return h;
    }
    return push(next);
}
pub export fn kd_canrecyc(h: i32) i32 {
    return @intCast(roc_canrecyc(borrowed(at(h))));
}
pub export fn kd_recycle(h: i32) i32 {
    const old = at(h);
    const next = roc_recycle(borrowed(old));
    // A refusal answers the state it was given; the same handle, then.
    if (roc_same(borrowed(old), borrowed(next)) == 1) {
        roc_drop(next);
        return h;
    }
    return push(next);
}
pub export fn kd_ai(h: i32) i32 {
    return @intCast(roc_ai(borrowed(at(h))));
}
pub export fn kd_mfrom(a0: i32) i32 {
    return @intCast(roc_mfrom(a0));
}
pub export fn kd_mstart(a0: i32) i32 {
    return @intCast(roc_mstart(a0));
}
pub export fn kd_mto(a0: i32) i32 {
    return @intCast(roc_mto(a0));
}
pub export fn kd_run(a0: i32, a1: i32) i32 {
    return push(roc_run(a0, a1));
}
pub export fn kd_rfound(h: i32) i32 {
    return @intCast(roc_rfound(borrowed(at(h))));
}
pub export fn kd_rmoves(h: i32) i32 {
    return @intCast(roc_rmoves(borrowed(at(h))));
}
pub export fn kd_rwon(h: i32) i32 {
    return @intCast(roc_rwon(borrowed(at(h))));
}
/// What the arcade calls at a new game: every handle freed.
pub export fn __heap_reset() void {
    for (table.items) |m| roc_drop(m);
    table.clearRetainingCapacity();
}
