//! The seam between the Zig host and the delivery solver's Roc
//! (roc/delivery.roc on roc/platform/main.roc). The Roc provides two C
//! functions, each a shift's seed in and JSON bytes out, and calls the four
//! runtime functions exported here for its memory and its crashes.
//!
//! **ONE SOLVE, ONE ARENA.** Each call into the Roc first drops everything
//! the last call allocated, its answer included, and allocates from the
//! arena as it goes; `roc_dealloc` frees nothing. A solve allocates some
//! 86,000 times and 7.4 MB in all (the bench counts them), so the arena
//! holds a solve whole, and its pages are kept for the next. Each
//! allocation carries its size before it, for `roc_realloc` to copy.

const std = @import("std");
const builtin = @import("builtin");

/// Roc's `List(U8)`: its bytes, how many, and its capacity (shifted left one;
/// the low bit set marks a seamless slice).
pub const RocBytes = extern struct { bytes: ?[*]u8, length: usize, capacity_or_alloc_ptr: usize };

extern fn roc_plan(seed: u32) callconv(.c) RocBytes;
extern fn roc_gold(seed: u32) callconv(.c) RocBytes;

/// The page's plan for the shift `seed`: routes, display minutes and the
/// solve-replay frames, as the JSON main.ts reads. Its bytes last until the
/// next call into the Roc.
pub fn plan(seed: u32) RocBytes {
    _ = arena.reset(.retain_capacity);
    return roc_plan(seed);
}

/// The facts solver_gold.json pins for the shift `seed`, with the map's;
/// its bytes, too, last until the next call.
pub fn gold(seed: u32) RocBytes {
    _ = arena.reset(.retain_capacity);
    return roc_gold(seed);
}

pub fn slice(l: RocBytes) []const u8 {
    const p = l.bytes orelse return &.{};
    return p[0..l.length];
}

var arena: std.heap.ArenaAllocator = .init(if (builtin.cpu.arch.isWasm()) std.heap.wasm_allocator else std.heap.page_allocator);

/// Each allocation's size, before what Roc is given. Sixteen bytes: Roc asks
/// for at most sixteen's alignment.
const header = 16;

/// How many allocations the Roc has asked for, and their bytes, since the
/// host started: the bench reports them.
pub var allocations: u64 = 0;
pub var allocated_bytes: u64 = 0;

fn allocate(len: usize, alignment: usize) [*]u8 {
    allocations += 1;
    allocated_bytes += len;
    if (alignment > header) std.debug.panic("roc_alloc: alignment {d} is past the header's {d}", .{ alignment, header });
    const got = arena.allocator().alignedAlloc(u8, .fromByteUnits(header), header + len) catch @panic("roc_alloc: out of memory");
    const words: [*]usize = @ptrCast(got.ptr);
    words[0] = len;
    return got.ptr + header;
}

fn roc_alloc(len: usize, alignment: usize) callconv(.c) *anyopaque {
    return allocate(len, alignment);
}

fn roc_realloc(ptr: *anyopaque, len: usize, alignment: usize) callconv(.c) *anyopaque {
    const old: [*]u8 = @ptrCast(ptr);
    const words: [*]usize = @ptrCast(@alignCast(old - header));
    const was = words[0];
    const new = allocate(len, alignment);
    @memcpy(new[0..@min(was, len)], old[0..@min(was, len)]);
    return new;
}

fn roc_dealloc(ptr: *anyopaque, alignment: usize) callconv(.c) void {
    _ = .{ ptr, alignment };
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
