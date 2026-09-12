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

const Model = ?[*]u8;

extern fn roc_start(src: RocList, seed: i64) callconv(.c) Model;
extern fn roc_resume(model: Model, line: RocList) callconv(.c) Model;
extern fn roc_view(model: Model) callconv(.c) RocList;
extern fn roc_status(model: Model) callconv(.c) i64;
extern fn roc_pause(model: Model) callconv(.c) i64;
extern fn roc_drop(model: Model) callconv(.c) void;

/// A reference for a call that keeps nothing: Roc's decrement restores ours.
fn borrowed(m: Model) Model {
    builtins.utils.increfDataPtrC(m, 1, &roc_ops);
    return m;
}

// ---- the page's door ---------------------------------------------------
//
// **THE MACHINE CROSSES THE SEAM, NOT THE TRANSCRIPT.** A BASIC program
// stops in the middle of itself -- an INPUT with nothing to read prints
// its prompt and suspends, a SLEEP asks for a delay -- so the page holds a
// machine and feeds it, rather than handing over every keystroke in
// advance and reading a printout.
//
// And because the machine is a VALUE, every state it has been in is still
// a state: `history` keeps them all and `back` is a pop. Time travel costs
// one pointer per line typed.

const src_cap: usize = 128 * 1024;
const keys_cap: usize = 4 * 1024;

var src_buf: [src_cap]u8 = undefined;
var keys_buf: [keys_cap]u8 = undefined;

var history: std.ArrayList(Model) = .empty;
/// The last view's bytes, owned until the next view replaces them.
var frame: RocList = RocList.empty();

fn top() Model {
    if (history.items.len == 0) return null;
    return history.items[history.items.len - 1];
}

fn push(m: Model) void {
    history.append(wasm_allocator, m) catch @trap();
}

pub export fn srcPtr() u32 {
    return @intCast(@intFromPtr(&src_buf));
}
pub export fn keysPtr() u32 {
    return @intCast(@intFromPtr(&keys_buf));
}
pub export fn capacity(which: u32) u32 {
    return if (which == 0) @intCast(src_cap) else @intCast(keys_cap);
}
pub export fn screenBytes() u32 {
    return 2000;
}

/// Start the listing in the source buffer. Everything before is dropped.
pub export fn newRun(src_len: u32, seed: i32) void {
    if (src_len > src_cap) @trap();
    for (history.items) |m| roc_drop(m);
    history.clearRetainingCapacity();
    push(roc_start(RocList.fromSlice(u8, src_buf[0..src_len], false, &roc_ops), seed));
}

/// One line into a waiting machine, or a wake for a sleeping one.
pub export fn send(line_len: u32) void {
    const cur = top() orelse return;
    if (line_len > keys_cap) @trap();
    push(roc_resume(borrowed(cur), RocList.fromSlice(u8, keys_buf[0..line_len], false, &roc_ops)));
}

/// Carry on a machine that slept or spent its fuel. Nobody typed anything,
/// so the new state REPLACES the old one instead of stacking on it, and the
/// old one is handed over OWNED: a borrowed machine is still reachable, and
/// Roc copies a list it can still reach, which here is the framebuffer and
/// the transcript once a tank, forever.
pub export fn wake() void {
    const cur = history.pop() orelse return;
    push(roc_resume(cur, RocList.empty()));
}

/// Undo one line. The first state is kept, so `back` at the start is a
/// no-op rather than an empty machine.
pub export fn back() u32 {
    if (history.items.len <= 1) return 0;
    roc_drop(history.pop() orelse return 0);
    return 1;
}

pub export fn depth() u32 {
    return @intCast(history.items.len);
}

pub export fn runStatus() i32 {
    return @intCast(roc_status(borrowed(top() orelse return -1)));
}

pub export fn pauseMs() i32 {
    return @intCast(roc_pause(borrowed(top() orelse return 0)));
}

/// The screen (2,000 bytes) and then the transcript, as one buffer.
pub export fn view() u32 {
    const cur = top() orelse return 0;
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
