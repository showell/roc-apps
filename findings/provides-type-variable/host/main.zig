//! The host asks the Roc for a boxed model, then hands it back to be
//! released, and prints a line after each call, so the output shows which
//! call crashed.

const std = @import("std");

const Model = ?*anyopaque;

extern fn roc_init() callconv(.c) Model;
extern fn roc_release(model: Model) callconv(.c) void;

pub fn main() void {
    const model = roc_init();
    std.debug.print("roc_init gave a box\n", .{});
    roc_release(model);
    std.debug.print("roc_release returned\n", .{});
}

comptime {
    @export(&roc_alloc, .{ .name = "roc_alloc" });
    @export(&roc_realloc, .{ .name = "roc_realloc" });
    @export(&roc_dealloc, .{ .name = "roc_dealloc" });
    @export(&roc_crashed, .{ .name = "roc_crashed" });
    @export(&roc_dbg, .{ .name = "roc_dbg" });
    @export(&roc_expect_failed, .{ .name = "roc_expect_failed" });
}

// The program makes one small allocation and never frees it, so a fixed
// buffer that hands out 16-byte-aligned pieces is all the runtime it needs.
var heap: [1 << 16]u8 align(16) = undefined;
var used: usize = 0;

fn roc_alloc(len: usize, alignment: usize) callconv(.c) *anyopaque {
    _ = alignment;
    used = std.mem.alignForward(usize, used, 16);
    if (used + len > heap.len) @panic("roc_alloc: out of memory");
    const p = &heap[used];
    used += len;
    return p;
}

fn roc_realloc(ptr: *anyopaque, len: usize, alignment: usize) callconv(.c) *anyopaque {
    _ = ptr;
    _ = len;
    _ = alignment;
    @panic("roc_realloc: not expected");
}

fn roc_dealloc(ptr: *anyopaque, alignment: usize) callconv(.c) void {
    _ = ptr;
    _ = alignment;
}

fn roc_crashed(bytes: [*]const u8, len: usize) callconv(.c) void {
    std.debug.print("roc crashed: {s}\n", .{bytes[0..len]});
    std.process.exit(1);
}

fn roc_dbg(bytes: [*]const u8, len: usize) callconv(.c) void {
    std.debug.print("roc dbg: {s}\n", .{bytes[0..len]});
}

fn roc_expect_failed(bytes: [*]const u8, len: usize) callconv(.c) void {
    std.debug.print("roc expect failed: {s}\n", .{bytes[0..len]});
    std.process.exit(1);
}
