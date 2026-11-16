//! The seam between the Zig host and the delivery solver's Roc
//! (roc/delivery.roc on roc/platform/main.roc). The Roc provides two C
//! functions, each a shift's seed in and JSON bytes out, and calls the four
//! runtime functions exported here for its memory and its crashes.
//!
//! Every allocation carries a header with its size, because `roc_dealloc`
//! and `roc_realloc` are told only the pointer. The memory comes from the
//! target's general allocator, so a solve frees what it is done with as it
//! goes: one solve makes millions of short-lived lists.

const std = @import("std");
const builtin = @import("builtin");

/// Roc's `List(U8)`: its bytes, how many, and its capacity (shifted left one;
/// the low bit set marks a seamless slice).
pub const RocBytes = extern struct { bytes: ?[*]u8, length: usize, capacity_or_alloc_ptr: usize };

extern fn roc_plan(seed: u32) callconv(.c) RocBytes;
extern fn roc_gold(seed: u32) callconv(.c) RocBytes;

/// The page's plan for the shift `seed`: routes, display minutes and the
/// solve-replay frames, as the JSON main.ts reads. Free it with `release`.
pub fn plan(seed: u32) RocBytes {
    return roc_plan(seed);
}

/// The facts solver_gold.json pins for the shift `seed`, with the map's.
pub fn gold(seed: u32) RocBytes {
    return roc_gold(seed);
}

pub fn slice(l: RocBytes) []const u8 {
    const p = l.bytes orelse return &.{};
    return p[0..l.length];
}

/// Frees a list the Roc handed back and the host has finished with. Its
/// allocation starts one refcount word before its bytes (a `List(U8)` is
/// aligned to the word).
pub fn release(l: RocBytes) void {
    const p = l.bytes orelse return;
    if (l.capacity_or_alloc_ptr & 1 != 0) @panic("roc_seam.release: the Roc answered a seamless slice, which the host never frees");
    free(p - @sizeOf(usize));
}

const allocator = if (builtin.cpu.arch.isWasm()) std.heap.wasm_allocator else std.heap.smp_allocator;

/// Each allocation's size and a mark, before what Roc is given. Sixteen
/// bytes: Roc asks for at most sixteen's alignment.
const header = 16;
const mark: usize = 0x5eed_de11;

fn allocate(len: usize, alignment: usize) [*]u8 {
    if (alignment > header) std.debug.panic("roc_alloc: alignment {d} is past the header's {d}", .{ alignment, header });
    const got = allocator.alignedAlloc(u8, .fromByteUnits(header), header + len) catch @panic("roc_alloc: out of memory");
    const words: [*]usize = @ptrCast(got.ptr);
    words[0] = len;
    words[1] = mark;
    return got.ptr + header;
}

fn free(ptr: [*]u8) void {
    const base = ptr - header;
    const words: [*]usize = @ptrCast(@alignCast(base));
    if (words[1] != mark) @panic("roc_dealloc: a pointer the host never gave out");
    const len = words[0];
    words[1] = 0;
    allocator.free(@as([]align(header) u8, @alignCast(base[0 .. header + len])));
}

fn roc_alloc(len: usize, alignment: usize) callconv(.c) *anyopaque {
    return allocate(len, alignment);
}

fn roc_realloc(ptr: *anyopaque, len: usize, alignment: usize) callconv(.c) *anyopaque {
    const old: [*]u8 = @ptrCast(ptr);
    const words: [*]usize = @ptrCast(@alignCast(old - header));
    if (words[1] != mark) @panic("roc_realloc: a pointer the host never gave out");
    const was = words[0];
    const new = allocate(len, alignment);
    @memcpy(new[0..@min(was, len)], old[0..@min(was, len)]);
    free(old);
    return new;
}

fn roc_dealloc(ptr: *anyopaque, alignment: usize) callconv(.c) void {
    _ = alignment;
    free(@ptrCast(ptr));
}

/// A Roc crash is a solver bug: an overflow, or a `crash` on a case its
/// invariants rule out. The host stops, with Roc's message.
fn roc_crashed(bytes: [*]const u8, len: usize) callconv(.c) void {
    std.debug.panic("roc crashed: {s}", .{bytes[0..len]});
}

fn roc_dbg(bytes: [*]const u8, len: usize) callconv(.c) void {
    std.debug.panic("roc dbg in the solver: {s}", .{bytes[0..len]});
}

fn roc_expect_failed(bytes: [*]const u8, len: usize) callconv(.c) void {
    std.debug.panic("roc expect failed in the solver: {s}", .{bytes[0..len]});
}

comptime {
    @export(&roc_alloc, .{ .name = "roc_alloc" });
    @export(&roc_realloc, .{ .name = "roc_realloc" });
    @export(&roc_dealloc, .{ .name = "roc_dealloc" });
    @export(&roc_crashed, .{ .name = "roc_crashed" });
    @export(&roc_dbg, .{ .name = "roc_dbg" });
    @export(&roc_expect_failed, .{ .name = "roc_expect_failed" });
}
