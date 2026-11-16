//! The book's folder, and the one read the platform allows under it. A path
//! the app names is relative to the folder, and nothing outside the folder is
//! ever read: `read_file` answers `outside_the_book` for a path that holds a
//! NUL byte, starts with `/`, or climbs above the folder with `..`, and for
//! one whose file, once opened, turns out to live elsewhere because a
//! symbolic link on its way points out of the folder.
//!
//! The link check is made on the opened file itself (`File.realPath`, which
//! asks the kernel where the open descriptor's file is), not on the path, so
//! nothing can be swapped in between the check and the read. A link that
//! stays inside the folder is followed.
//!
//! Every answer is a tag, never a crash: the app decides what a missing or
//! refused file means for the book.

const std = @import("std");
const Io = std.Io;

/// The most bytes a read answers; a larger file is `read_failed`, so one
/// huge file can't exhaust the build's memory. 16 MiB is far past any
/// chapter of a book.
pub const read_most = 16 * 1024 * 1024;

/// The answer's tags in Roc's order, alphabetical, as they cross the seam
/// (host/abi.zig).
pub const ReadStatus = enum(u8) { found, not_a_file, not_found, outside_the_book, read_failed };

pub const ReadAnswer = union(ReadStatus) {
    found: []const u8,
    not_a_file,
    not_found,
    outside_the_book,
    read_failed,
};

/// Whether `path`, by its spelling alone, stays inside the folder: no NUL,
/// not absolute, and no `..` that climbs above where it starts. `a/../b` is
/// inside; `a/../../b` is not. An empty part and `.` stay where they are.
pub fn is_spelled_inside(path: []const u8) bool {
    if (std.mem.indexOfScalar(u8, path, 0) != null) return false;
    if (std.mem.startsWith(u8, path, "/")) return false;
    var depth: usize = 0;
    var parts = std.mem.splitScalar(u8, path, '/');
    while (parts.next()) |part| {
        if (part.len == 0 or std.mem.eql(u8, part, ".")) continue;
        if (std.mem.eql(u8, part, "..")) {
            if (depth == 0) return false;
            depth -= 1;
        } else depth += 1;
    }
    return true;
}

/// Whether `real`, a canonical absolute path, is `folder` or below it. The
/// byte after the folder's own path must be a `/`, so `/books/a` does not
/// hold `/books/ab`.
pub fn is_real_path_inside(folder: []const u8, real: []const u8) bool {
    if (!std.mem.startsWith(u8, real, folder)) return false;
    if (real.len == folder.len) return true;
    if (std.mem.eql(u8, folder, "/")) return true;
    return real[folder.len] == '/';
}

pub const BookFolder = struct {
    io: Io,
    dir: Io.Dir,
    /// The folder's canonical absolute path, for the link check.
    real: []const u8,

    /// The folder at `path` under `parent`, opened for the run. `real` is
    /// kept in `arena`.
    pub fn open(io: Io, arena: std.mem.Allocator, parent: Io.Dir, path: []const u8) !BookFolder {
        const dir = try parent.openDir(io, path, .{});
        errdefer dir.close(io);
        var buf: [std.fs.max_path_bytes]u8 = undefined;
        const n = try dir.realPath(io, &buf);
        return .{ .io = io, .dir = dir, .real = try arena.dupe(u8, buf[0..n]) };
    }

    pub fn close(book: BookFolder) void {
        book.dir.close(book.io);
    }

    /// The file at `path`, relative to the folder: `found` with its bytes in
    /// `arena`, or the tag that says why not.
    pub fn read_file(book: BookFolder, arena: std.mem.Allocator, path: []const u8) ReadAnswer {
        if (!is_spelled_inside(path)) return .outside_the_book;
        const spelled = if (path.len == 0) "." else path;
        const file = book.dir.openFile(book.io, spelled, .{}) catch |e| return switch (e) {
            error.FileNotFound, error.NotDir => .not_found,
            error.IsDir => .not_a_file,
            else => .read_failed,
        };
        defer file.close(book.io);
        var buf: [std.fs.max_path_bytes]u8 = undefined;
        const n = file.realPath(book.io, &buf) catch return .read_failed;
        if (!is_real_path_inside(book.real, buf[0..n])) return .outside_the_book;
        const st = file.stat(book.io) catch return .read_failed;
        if (st.kind != .file) return .not_a_file;
        if (st.size > read_most) return .read_failed;
        const bytes = arena.alloc(u8, @intCast(st.size)) catch return .read_failed;
        const got = file.readPositionalAll(book.io, bytes, 0) catch return .read_failed;
        return .{ .found = bytes[0..got] };
    }
};
