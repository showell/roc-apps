//! Holds host/book_folder.zig's one read to its folder, on a real folder in
//! a temporary directory: files, a subfolder, a file no one may read, a file
//! past the size cap, and real symbolic links, one that stays inside the
//! book and two that point out of it. Every answer tag is reached, and each
//! way out of the folder is refused beside a near miss that is read.

const std = @import("std");
const testing = std.testing;
const book_folder = @import("book_folder.zig");
const BookFolder = book_folder.BookFolder;
const ReadStatus = book_folder.ReadStatus;

/// The tree every read test runs in:
///
///     outside/secret.md        "secret"
///     book/book.md             "# A book\n"
///     book/empty.md            ""
///     book/chapters/one.md     "one"
///     book/folder/             (a folder)
///     book/locked.md           mode 000
///     book/huge.md             read_most + 1 bytes, sparse
///     book/exact.md            read_most bytes, sparse
///     book/inside_link         -> chapters/one.md
///     book/outside_link        -> ../outside/secret.md
///     book/outside_folder_link -> ../outside
const Tree = struct {
    tmp: testing.TmpDir,
    book: BookFolder,
    arena: std.heap.ArenaAllocator,

    fn make() !Tree {
        const io = testing.io;
        var tmp = testing.tmpDir(.{});
        errdefer tmp.cleanup();
        const d = tmp.dir;
        try d.createDirPath(io, "outside");
        try d.createDirPath(io, "book/chapters");
        try d.createDirPath(io, "book/folder");
        try d.writeFile(io, .{ .sub_path = "outside/secret.md", .data = "secret" });
        try d.writeFile(io, .{ .sub_path = "book/book.md", .data = "# A book\n" });
        try d.writeFile(io, .{ .sub_path = "book/empty.md", .data = "" });
        try d.writeFile(io, .{ .sub_path = "book/chapters/one.md", .data = "one" });
        try d.writeFile(io, .{ .sub_path = "book/locked.md", .data = "locked" });
        try d.setFilePermissions(io, "book/locked.md", .fromMode(0), .{});
        try sized(d, "book/huge.md", book_folder.read_most + 1);
        try sized(d, "book/exact.md", book_folder.read_most);
        try d.symLink(io, "chapters/one.md", "book/inside_link", .{});
        try d.symLink(io, "../outside/secret.md", "book/outside_link", .{});
        try d.symLink(io, "../outside", "book/outside_folder_link", .{ .is_directory = true });

        var arena: std.heap.ArenaAllocator = .init(testing.allocator);
        errdefer arena.deinit();
        const book = try BookFolder.open(io, arena.allocator(), d, "book");
        return .{ .tmp = tmp, .book = book, .arena = arena };
    }

    fn sized(d: std.Io.Dir, path: []const u8, size: u64) !void {
        const file = try d.createFile(testing.io, path, .{});
        defer file.close(testing.io);
        try file.setLength(testing.io, size);
    }

    fn deinit(t: *Tree) void {
        t.book.close();
        // The locked file is given back its mode so the cleanup can remove it.
        t.tmp.dir.setFilePermissions(testing.io, "book/locked.md", .fromMode(0o600), .{}) catch {};
        t.tmp.cleanup();
        t.arena.deinit();
    }

    fn status(t: *Tree, path: []const u8) ReadStatus {
        return std.meta.activeTag(t.book.read_file(t.arena.allocator(), path));
    }

    fn found(t: *Tree, path: []const u8) ![]const u8 {
        return switch (t.book.read_file(t.arena.allocator(), path)) {
            .found => |bytes| bytes,
            else => |other| {
                std.debug.print("{s}: {t}, not found\n", .{ path, other });
                return error.NotFound;
            },
        };
    }
};

test "a path spelled inside the folder passes, and each spelling that leaves it is refused" {
    for ([_][]const u8{ "book.md", "chapters/one.md", "a/../b.md", "./book.md", "a//b", "a/..", "", "..x", "x.." }) |path| {
        try testing.expect(book_folder.is_spelled_inside(path));
    }
    for ([_][]const u8{ "/etc/passwd", "/", "..", "../book.md", "a/../../b.md", "./../b", "book.md\x00.txt", "\x00" }) |path| {
        try testing.expect(!book_folder.is_spelled_inside(path));
    }
}

test "a real path is inside its folder only at the folder or past a slash" {
    try testing.expect(book_folder.is_real_path_inside("/books/a", "/books/a"));
    try testing.expect(book_folder.is_real_path_inside("/books/a", "/books/a/one.md"));
    try testing.expect(book_folder.is_real_path_inside("/", "/etc"));
    try testing.expect(!book_folder.is_real_path_inside("/books/a", "/books/ab"));
    try testing.expect(!book_folder.is_real_path_inside("/books/a", "/books"));
    try testing.expect(!book_folder.is_real_path_inside("/books/a", "/etc/a"));
}

test "a file in the book is found, whole, by every spelling that stays inside" {
    var t = try Tree.make();
    defer t.deinit();
    try testing.expectEqualStrings("# A book\n", try t.found("book.md"));
    try testing.expectEqualStrings("# A book\n", try t.found("./book.md"));
    try testing.expectEqualStrings("# A book\n", try t.found("chapters/../book.md"));
    try testing.expectEqualStrings("one", try t.found("chapters/one.md"));
    try testing.expectEqualStrings("", try t.found("empty.md"));
    try testing.expectEqual(book_folder.read_most, (try t.found("exact.md")).len);
}

test "a symbolic link that stays in the book is followed, and one that leaves it is refused" {
    var t = try Tree.make();
    defer t.deinit();
    try testing.expectEqualStrings("one", try t.found("inside_link"));
    try testing.expectEqual(.outside_the_book, t.status("outside_link"));
    try testing.expectEqual(.outside_the_book, t.status("outside_folder_link/secret.md"));
    try testing.expectEqual(.outside_the_book, t.status("outside_folder_link"));
}

test "an absolute path, a climbing `..` and a NUL byte are refused, though the file is there" {
    var t = try Tree.make();
    defer t.deinit();
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const n = try t.tmp.dir.realPathFile(testing.io, "outside/secret.md", &buf);
    const absolute_secret = buf[0..n];
    try testing.expect(std.fs.path.isAbsolute(absolute_secret));
    try testing.expectEqual(.outside_the_book, t.status(absolute_secret));
    var book_md_buf: [std.fs.max_path_bytes]u8 = undefined;
    const book_md = book_md_buf[0..try t.tmp.dir.realPathFile(testing.io, "book/book.md", &book_md_buf)];
    try testing.expectEqual(.outside_the_book, t.status(book_md));
    try testing.expectEqual(.outside_the_book, t.status("../outside/secret.md"));
    try testing.expectEqual(.outside_the_book, t.status("chapters/../../outside/secret.md"));
    try testing.expectEqual(.outside_the_book, t.status("book.md\x00"));
    try testing.expectEqual(.outside_the_book, t.status(".."));
}

test "a missing file is not_found, and a folder is not_a_file" {
    var t = try Tree.make();
    defer t.deinit();
    try testing.expectEqual(.not_found, t.status("missing.md"));
    try testing.expectEqual(.not_found, t.status("chapters/missing.md"));
    try testing.expectEqual(.not_found, t.status("missing/one.md"));
    try testing.expectEqual(.not_found, t.status("book.md/one.md"));
    try testing.expectEqual(.not_a_file, t.status("folder"));
    try testing.expectEqual(.not_a_file, t.status("chapters"));
    try testing.expectEqual(.not_a_file, t.status(""));
    try testing.expectEqual(.not_a_file, t.status("."));
    try testing.expectEqual(.not_a_file, t.status("chapters/.."));
}

test "a file no one may read, and one past the size cap, are read_failed" {
    var t = try Tree.make();
    defer t.deinit();
    try testing.expectEqual(.read_failed, t.status("locked.md"));
    try testing.expectEqual(.read_failed, t.status("huge.md"));
}
