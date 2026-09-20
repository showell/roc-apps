//! The arcade wasm host: the eight exports web/canvas_app_runner.js binds, over a Roc
//! model the host holds as one boxed pointer.
//!
//! Where poc/drive_shim.zig in safari-codex had to keep the rider, the truck,
//! the clock and a history ring as flat zig statics -- a Codex record is a
//! pointer into an arena the shim rewinds every frame -- here the whole model
//! is a Roc value. Roc's reference counting keeps it alive between calls and
//! the app's `advance` and `back` return the next model; this file stores the
//! pointer it is handed and hands it back.
//!
//! OWNERSHIP AT THE BOUNDARY. A Roc function that takes a `Box` takes it by
//! value and owns that reference. `advance` and `back` return the model, so
//! the host's reference moves out and a new one comes back. A readout keeps
//! nothing, so the host increments the count before the call and Roc's
//! decrement on the way out restores it. `render` returns a List the host
//! owns until the next frame, when it is released.
//!
//! The draw buffer the runner reads is the List's own bytes: tag, colour,
//! count and f32 bit patterns as 32-bit words, packed in Roc (SafariApp.roc),
//! exactly the stream the zig shim wrote.

const std = @import("std");
const builtins = @import("builtins");
const host_alloc = @import("host_alloc");

const RocOps = builtins.host_abi.RocOps;
const RocList = builtins.list.RocList;

extern fn roc_init() callconv(.c) ?[*]u8;
extern fn roc_advance(model: ?[*]u8, held: u32, struck: u32, buttons: u32, clicks: u32, x: f32, y: f32, wheel: f32) callconv(.c) ?[*]u8;
extern fn roc_sounds(model: ?[*]u8) callconv(.c) u32;
extern fn roc_tone_count(model: ?[*]u8) callconv(.c) u32;
extern fn roc_tone_freq(model: ?[*]u8, index: u32) callconv(.c) u32;
extern fn roc_tone_ms(model: ?[*]u8, index: u32) callconv(.c) u32;
extern fn roc_frame(model: ?[*]u8) callconv(.c) RocList;
extern fn roc_release(frame: RocList) callconv(.c) void;
extern fn roc_width(model: ?[*]u8) callconv(.c) u32;
extern fn roc_height(model: ?[*]u8) callconv(.c) u32;
extern fn roc_fps(model: ?[*]u8) callconv(.c) u32;

// NO IMPORTS. web/canvas_app_runner.js instantiates the module with an empty import
// object, as it does the Codex-built one, so a panic is a wasm trap -- the
// page sees a RuntimeError -- and dbg output goes nowhere.
const env = struct {
    fn roc_panic(_: [*]const u8, _: usize) noreturn {
        @trap();
    }
    fn roc_dbg(_: [*]const u8, _: usize) void {}
};

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
// The last frame's words, owned until the next frame replaces them.
var packed_frame: RocList = RocList.empty();

fn ensure() void {
    if (model == null) model = roc_init();
}

/// A reference for a call that keeps nothing: Roc's decrement restores ours.
fn borrowed() ?[*]u8 {
    ensure();
    builtins.utils.increfDataPtrC(model, 1, &roc_ops);
    return model;
}

fn noDec(_: ?*anyopaque, _: ?[*]u8) callconv(.c) void {}

// Where the last frame is and how big it is, in two words at an address that
// never moves. **THE FRAME ITSELF MOVES** -- it is a fresh Roc list every
// tick -- so a caller that reads its address before asking for it gets the
// previous frame's start with this frame's length, which misreads far enough
// in to look like corrupt data rather than a mistake.
var frame_where: [2]u32 = .{ 0, 0 };

// **THIS IS THE EFFECT**, which is why it is a verb: it releases the last
// frame, asks Roc for a new one, and answers where the two words above are.
// There is ONE call, so there is no order to get wrong. It used to be two --
// `computeFrame` then `frameAt` -- and the trap that arrangement left caught
// two people who each wrote the natural spelling, `decode(memory, frameAt(),
// computeFrame())`, which JavaScript evaluates left to right.
pub export fn computeFrame() u32 {
    // **ROC FREES THE FRAME, NOT THIS.** Decrementing a List(Shape) means
    // walking each element's inner lists, which needs the tag union's layout.
    // Roc has that layout and the host does not, so the host hands the last
    // frame back and lets Roc drop it. No layout knowledge in Zig at all.
    roc_release(packed_frame);
    packed_frame = roc_frame(borrowed());
    return @intCast(@intFromPtr(&packed_frame));
}
// **THE INPUT ARRIVES WITH THE TICK.** One Input.Snapshot, flattened: the keys
// down and the keys struck, the same pair for mouse buttons, then where the
// pointer is and how far the wheel turned. The page's event loop owns all of
// it and packs it; nothing here remembers anything between ticks.
pub export fn advance(held: u32, struck: u32, buttons: u32, clicks: u32, x: f32, y: f32, wheel: f32) void {
    ensure();
    model = roc_advance(model, held, struck, buttons, clicks, x, y, wheel);
}

// How big a frame is, in the game's own coordinates. The page sizes its
// canvas from this rather than knowing one movie's numbers.
pub export fn width() u32 {
    return roc_width(borrowed());
}

pub export fn height() u32 {
    return roc_height(borrowed());
}

// How often the movie means to be stepped. The page paces itself by this
// rather than by however often the display happens to refresh.
pub export fn fps() u32 {
    return roc_fps(borrowed());
}

// A bit per tone the last step set off. The runner decides whether that is a
// speaker or a widget in the corner of a page.
pub export fn sounds() u32 {
    return roc_sounds(borrowed());
}

// How many tones the game HAS, so a runner never has to guess the width of
// the word above.
pub export fn toneCount() u32 {
    return roc_tone_count(borrowed());
}

// What one of them sounds like: a pitch in hertz and a length in
// milliseconds, which is what roc-ray's Audio.gen_tone takes as well.
pub export fn toneFreq(index: u32) u32 {
    return roc_tone_freq(borrowed(), index);
}

pub export fn toneMs(index: u32) u32 {
    return roc_tone_ms(borrowed(), index);
}

