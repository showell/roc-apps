//! The safari wasm host: the sixteen exports web/blitter.js binds, over a Roc
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
//! The draw buffer the blitter reads is the List's own bytes: tag, colour,
//! count and f32 bit patterns as 32-bit words, packed in Roc (SafariApp.roc),
//! exactly the stream the zig shim wrote.

const std = @import("std");
const builtins = @import("builtins");
const host_alloc = @import("host_alloc");

const RocOps = builtins.host_abi.RocOps;
const RocList = builtins.list.RocList;

extern fn roc_init() callconv(.c) ?[*]u8;
extern fn roc_advance(model: ?[*]u8) callconv(.c) ?[*]u8;
extern fn roc_back(model: ?[*]u8) callconv(.c) ?[*]u8;
extern fn roc_render(model: ?[*]u8) callconv(.c) RocList;
extern fn roc_probe_frame(model: ?[*]u8) callconv(.c) u32;
extern fn roc_probe_expand(model: ?[*]u8) callconv(.c) u32;
extern fn roc_clock(model: ?[*]u8) callconv(.c) u32;
extern fn roc_rider_seg(model: ?[*]u8) callconv(.c) u32;
extern fn roc_rider_tilt(model: ?[*]u8) callconv(.c) f32;
extern fn roc_cam_focal(model: ?[*]u8) callconv(.c) f32;
extern fn roc_gaze_yaw(model: ?[*]u8) callconv(.c) f32;
extern fn roc_sky_top(model: ?[*]u8) callconv(.c) u32;
extern fn roc_sky_horizon(model: ?[*]u8) callconv(.c) u32;
extern fn roc_sun_visible(model: ?[*]u8) callconv(.c) u32;
extern fn roc_sun_x(model: ?[*]u8) callconv(.c) f32;
extern fn roc_sun_y(model: ?[*]u8) callconv(.c) f32;
extern fn roc_sun_scale(model: ?[*]u8) callconv(.c) f32;
extern fn roc_rider_v(model: ?[*]u8) callconv(.c) f32;
extern fn roc_truck_lead(model: ?[*]u8) callconv(.c) f32;
extern fn roc_truck_v(model: ?[*]u8) callconv(.c) f32;

// NO IMPORTS. web/blitter.js instantiates the module with an empty import
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
fn roc_dbg(bytes: [*]const u8, len: usize) callconv(.c) void {
    env.roc_dbg(bytes, len);
}
fn roc_expect_failed(bytes: [*]const u8, len: usize) callconv(.c) void {
    env.roc_dbg(bytes, len);
}
fn roc_crashed(bytes: [*]const u8, len: usize) callconv(.c) void {
    env.roc_panic(bytes, len);
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
var frame: RocList = RocList.empty();
var frame_high: usize = 0;

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

pub export fn renderFrame() u32 {
    frame.decref(@alignOf(u32), @sizeOf(u32), false, null, noDec, &roc_ops);
    frame = roc_render(borrowed());
    const bytes = frame.length * 4;
    if (bytes > frame_high) frame_high = bytes;
    return @intCast(bytes);
}
// Timing probes: the frame before expansion, and after, by command count.
pub export fn probeFrame() u32 {
    return roc_probe_frame(borrowed());
}
pub export fn probeExpand() u32 {
    return roc_probe_expand(borrowed());
}
pub export fn bufPtr() u32 {
    return @intCast(@intFromPtr(frame.bytes orelse return 0));
}
pub export fn bufHighWater() u32 {
    return @intCast(frame_high);
}
pub export fn bufCap() u32 {
    return @intCast(frame.getCapacity() * 4);
}
pub export fn advance() void {
    ensure();
    model = roc_advance(model);
}
pub export fn back() void {
    ensure();
    model = roc_back(model);
}
pub export fn clock() u32 {
    return roc_clock(borrowed());
}
pub export fn riderSeg() u32 {
    return roc_rider_seg(borrowed());
}
pub export fn riderTilt() f32 {
    return roc_rider_tilt(borrowed());
}
pub export fn camFocal() f32 {
    return roc_cam_focal(borrowed());
}
pub export fn gazeYaw() f32 {
    return roc_gaze_yaw(borrowed());
}
pub export fn skyTop() u32 {
    return roc_sky_top(borrowed());
}
pub export fn skyHorizon() u32 {
    return roc_sky_horizon(borrowed());
}
pub export fn sunVisible() u32 {
    return roc_sun_visible(borrowed());
}
pub export fn sunX() f32 {
    return roc_sun_x(borrowed());
}
pub export fn sunY() f32 {
    return roc_sun_y(borrowed());
}
pub export fn sunScale() f32 {
    return roc_sun_scale(borrowed());
}
pub export fn riderV() f32 {
    return roc_rider_v(borrowed());
}
pub export fn truckLead() f32 {
    return roc_truck_lead(borrowed());
}
pub export fn truckV() f32 {
    return roc_truck_v(borrowed());
}
