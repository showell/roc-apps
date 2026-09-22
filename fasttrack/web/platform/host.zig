//! The fasttrack wasm host: three exports over a Roc model it holds as one
//! boxed pointer. The page calls `start` once, `update` for every click, and
//! `computeView` after each, and reads the view through the generated glue.
//!
//! A game is driven by events, not a clock, so unlike canvas_apps' host
//! there is no tick: nothing happens between clicks.
//!
//! OWNERSHIP AT THE BOUNDARY. A Roc function that takes a `Box` owns that
//! reference. `update` returns the next model, so the host's reference moves
//! out and a new one comes back. `view` keeps nothing, so the host
//! increments the count first and Roc's decrement restores it. The view is a
//! `Box` the host owns until the next one replaces it, when the host hands
//! it back through `release` and Roc frees it with the layout it has.

const std = @import("std");
const builtins = @import("builtins");
const host_alloc = @import("host_alloc");

const RocOps = builtins.host_abi.RocOps;

extern fn roc_init(millis: u64, setup: u32) callconv(.c) ?[*]u8;
extern fn roc_update(model: ?[*]u8, code: u32) callconv(.c) ?[*]u8;
extern fn roc_view(model: ?[*]u8) callconv(.c) ?[*]u8;
extern fn roc_release(view: ?[*]u8) callconv(.c) void;

// NO IMPORTS. The page instantiates the module with an empty import object,
// so a panic is a wasm trap -- the page sees a RuntimeError.
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
// The last view, owned until the next one replaces it.
var view_box: ?[*]u8 = null;

/// A new game. `millis` seeds the deck, as Elm's `Time.now` did; `setup`
/// picks Setup.InitSetup by its position in FastTrack.setups.
pub export fn start(millis: f64, setup: u32) void {
    model = roc_init(@intFromFloat(millis), setup);
}

/// One click: the code the view gave the thing clicked.
pub export fn update(code: u32) void {
    model = roc_update(model, code);
}

/// **THIS IS THE EFFECT**, which is why it is a verb: it releases the last
/// view, asks Roc for a new one, and answers the address of the word that
/// points at it -- an address that never moves, which the glue reads as a
/// `Box`.
pub export fn computeView() u32 {
    if (view_box != null) roc_release(view_box);
    builtins.utils.increfDataPtrC(model, 1, &roc_ops);
    view_box = roc_view(model);
    return @intCast(@intFromPtr(&view_box));
}
