//! The book builder's program:
//!
//!     book <book folder>
//!
//! It opens the book's folder, calls the app once (`roc_main`) with the
//! folder's name, and writes the app's answer: a printed answer to stdout,
//! exiting 0, or a failure to stderr, exiting 1. The app reads only through
//! `read_file`, which stays inside the folder (host/book_folder.zig), and the
//! program writes nothing but those two streams. A folder that can't be
//! opened, or a command line that names none, exits 2 before the app runs.

const std = @import("std");
const abi = @import("abi.zig");
const book_folder = @import("book_folder.zig");

const usage = "usage: book <book folder>";

pub fn main(init: std.process.Init) !u8 {
    const io = init.io;
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    if (args.len != 2) {
        std.debug.print("{s}\n", .{usage});
        return 2;
    }
    const folder_name = args[1];
    // The app takes the name as text, so a name that isn't UTF-8 is refused
    // here rather than handed over.
    if (!std.unicode.utf8ValidateSlice(folder_name)) {
        std.debug.print("{s}\nthe book folder's name is not UTF-8\n", .{usage});
        return 2;
    }
    const folder = book_folder.BookFolder.open(io, arena, std.Io.Dir.cwd(), folder_name) catch |e| {
        std.debug.print("{s}\nthe book folder {s} cannot be opened ({t})\n", .{ usage, folder_name, e });
        return 2;
    };
    defer folder.close();

    abi.begin(arena, folder);
    const answer = abi.roc_main(.from(folder_name));
    const stream = switch (answer.outcome) {
        .printed => std.Io.File.stdout(),
        .failed => std.Io.File.stderr(),
    };
    try stream.writeStreamingAll(io, answer.text.slice());
    return switch (answer.outcome) {
        .printed => 0,
        .failed => 1,
    };
}
