//! The seam between the host and the Roc archive (an app built on
//! platform/). It declares the app's one entry, `roc_main`, which
//! platform/main.roc provides; it exports the platform's one hosted function,
//! `read_file` (platform/Host.roc), answered by host/book_folder.zig; and it
//! exports the runtime functions the archive calls: the allocator,
//! `roc_crashed`, `roc_dbg` and `roc_expect_failed`.
//!
//! Roc lays a record out by alignment, then by field name, so the fields
//! below are in that order, not the source's. A tag union with no payloads is
//! one byte, its tags numbered alphabetically. host/abi_test.zig holds every
//! type here to what `roc glue` makes of the platform
//! (host/glue/platform_abi.zig), field by field and tag by tag.
//!
//! The program makes one Roc call and exits, so everything Roc allocates
//! comes from one arena, `allocator`, freed whole when the run ends:
//! `roc_dealloc` frees nothing and no refcount is kept by hand.

const std = @import("std");
const book_folder = @import("book_folder.zig");

/// A Roc `List(U8)` as glue lays one out: the elements' pointer, the
/// length, then the capacity shifted left once (or, for a slice, the
/// allocation's pointer with its low bit set). A list the host makes has a
/// refcount word just before its bytes.
pub const Bytes = extern struct {
    elements: ?[*]u8,
    length: usize,
    capacity_or_alloc_ptr: usize,

    pub fn slice(b: Bytes) []const u8 {
        const p = b.elements orelse return "";
        return p[0..b.length];
    }

    /// A new list holding a copy of `bytes`, in the run's arena.
    pub fn from(bytes: []const u8) Bytes {
        if (bytes.len == 0) return .{ .elements = null, .length = 0, .capacity_or_alloc_ptr = 0 };
        const w = @sizeOf(usize);
        const base = allocate(w + bytes.len, w);
        std.mem.writeInt(usize, base[0..w], 1, .little);
        const data = base + w;
        @memcpy(data[0..bytes.len], bytes);
        return .{ .elements = data, .length = bytes.len, .capacity_or_alloc_ptr = bytes.len << 1 };
    }
};

/// Host.roc's `read_file!` answer: the list, then the tag.
pub const ReadRec = extern struct { bytes: Bytes, status: book_folder.ReadStatus };

/// platform/main.roc's `main_for_host!` outcome, alphabetical.
pub const Outcome = enum(u8) { failed, printed };

/// platform/main.roc's `main_for_host!` answer: the list, then the tag.
pub const MainAnswer = extern struct { text: Bytes, outcome: Outcome };

pub extern fn roc_main(folder: Bytes) callconv(.c) MainAnswer;

/// What a Roc call may use, set before `roc_main` by `begin`: the arena it
/// allocates from and the book it reads.
pub var allocator: ?std.mem.Allocator = null;
pub var book: ?book_folder.BookFolder = null;

pub fn begin(arena: std.mem.Allocator, folder: book_folder.BookFolder) void {
    allocator = arena;
    book = folder;
}

pub export fn read_file(path: Bytes) callconv(.c) ReadRec {
    const folder = book orelse @panic("read_file: the Roc ran before `begin` named the book");
    return switch (folder.read_file(run_arena(), path.slice())) {
        .found => |bytes| .{ .bytes = .from(bytes), .status = .found },
        .not_a_file => .{ .bytes = .from(""), .status = .not_a_file },
        .not_found => .{ .bytes = .from(""), .status = .not_found },
        .outside_the_book => .{ .bytes = .from(""), .status = .outside_the_book },
        .read_failed => .{ .bytes = .from(""), .status = .read_failed },
    };
}

// The runtime.

comptime {
    @export(&roc_alloc, .{ .name = "roc_alloc" });
    @export(&roc_realloc, .{ .name = "roc_realloc" });
    @export(&roc_dealloc, .{ .name = "roc_dealloc" });
    @export(&roc_crashed, .{ .name = "roc_crashed" });
    @export(&roc_dbg, .{ .name = "roc_dbg" });
    @export(&roc_expect_failed, .{ .name = "roc_expect_failed" });
}

fn run_arena() std.mem.Allocator {
    return allocator orelse @panic("roc_alloc: the Roc ran before `begin` gave it an arena");
}

/// Each allocation's length sits in a header before what Roc is given, so
/// `roc_realloc`, which is not told it, knows how much to copy. The header
/// is 16 bytes because Roc asks for at most 16's alignment.
const header = 16;

fn allocate(len: usize, alignment: usize) [*]u8 {
    if (alignment > header) std.debug.panic("roc_alloc: an alignment of {d}, past the header's {d}", .{ alignment, header });
    const got = run_arena().alignedAlloc(u8, .fromByteUnits(header), header + len) catch
        std.debug.panic("roc_alloc: out of memory ({d} bytes)", .{len});
    std.mem.writeInt(usize, got[0..@sizeOf(usize)], len, .little);
    return got.ptr + header;
}

fn roc_alloc(len: usize, alignment: usize) callconv(.c) *anyopaque {
    return allocate(len, alignment);
}

fn roc_realloc(ptr: *anyopaque, len: usize, alignment: usize) callconv(.c) *anyopaque {
    const old: [*]u8 = @ptrCast(ptr);
    const was = std.mem.readInt(usize, (old - header)[0..@sizeOf(usize)], .little);
    const new = allocate(len, alignment);
    @memcpy(new[0..@min(was, len)], old[0..@min(was, len)]);
    return new;
}

fn roc_dealloc(ptr: *anyopaque, alignment: usize) callconv(.c) void {
    _ = ptr;
    _ = alignment;
}

fn roc_crashed(bytes: [*]const u8, len: usize) callconv(.c) void {
    std.debug.panic("roc crashed: {s}", .{bytes[0..len]});
}

fn roc_dbg(bytes: [*]const u8, len: usize) callconv(.c) void {
    std.debug.print("roc dbg: {s}\n", .{bytes[0..len]});
}

fn roc_expect_failed(bytes: [*]const u8, len: usize) callconv(.c) void {
    std.debug.panic("roc: an inline expect failed: {s}", .{bytes[0..len]});
}
