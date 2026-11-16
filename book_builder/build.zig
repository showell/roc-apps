const std = @import("std");

/// The book builder's build. The pinned Roc (roc-apps' roc-version, one
/// folder up) builds a book app on platform/ into an archive, which is
/// linked under the host (host/main.zig) as the program `book`.
///
///   zig build                    zig-out/bin/book, the one-page example
///                                (examples/one_page/) unless -Dapp names
///                                another app
///   zig build run -- <folder>    the program run on a book's folder
///   zig build test               the host's tests: the seam against roc
///                                glue, and the book folder's reads on a
///                                real folder with real links
///
/// The app is built on Roc's dev backend. The seam's test links the app's
/// archive, whose `roc_main` abi.zig declares; the folder's tests are plain
/// Zig.
pub fn build(b: *std.Build) void {
    const app_root = b.option([]const u8, "app", "The book app's main.roc (examples/one_page/main.roc)") orelse "examples/one_page/main.roc";
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    const roc = rocCompiler(b);

    const app = rocArchive(b, roc, app_root);
    const mod = b.createModule(.{ .root_source_file = b.path("host/main.zig"), .target = target, .optimize = optimize });
    mod.addObjectFile(app);
    const exe = b.addExecutable(.{ .name = "book", .root_module = mod });
    b.installArtifact(exe);

    const run = b.addRunArtifact(exe);
    run.addPassthruArgs();
    run.stdio = .inherit;
    b.step("run", "The program run on a book's folder: -- <folder>").dependOn(&run.step);

    const tests = b.step("test", "The host's tests: the seam against roc glue, and the book folder's reads on a real folder");
    // The seam's test declares roc_main, so it links the app's archive too.
    const abi_test = b.createModule(.{ .root_source_file = b.path("host/abi_test.zig"), .target = target, .optimize = optimize });
    abi_test.addObjectFile(app);
    tests.dependOn(&testRun(b, abi_test).step);
    const folder_test = b.createModule(.{ .root_source_file = b.path("host/book_folder_test.zig"), .target = target, .optimize = optimize });
    tests.dependOn(&testRun(b, folder_test).step);
}

/// The app on platform/, built by the pinned Roc for x64musl into an
/// archive, on Roc's dev backend.
fn rocArchive(b: *std.Build, roc: []const u8, app_root: []const u8) std.Build.LazyPath {
    const archive = b.addSystemCommand(&.{ roc, "build", app_root, "--target=x64musl", "--opt=dev" });
    archive.setCwd(b.path("."));
    rocInputs(b, archive, "platform");
    rocInputs(b, archive, std.fs.path.dirname(app_root) orelse ".");
    archive.addFileInput(.{ .cwd_relative = roc });
    return archive.addPrefixedOutputFileArg("--output=", "app-x64musl.a");
}

/// One root's tests, run on every `zig build test`. Zig otherwise replays a
/// run whose inputs are unchanged and leaves its tests out of the summary.
fn testRun(b: *std.Build, module: *std.Build.Module) *std.Build.Step.Run {
    const run = b.addRunArtifact(b.addTest(.{ .root_module = module }));
    run.has_side_effects = true;
    return run;
}

/// Every file in `folder` is an input of the archive, found rather than
/// listed, so a change to any module builds it again.
fn rocInputs(b: *std.Build, run: *std.Build.Step.Run, folder: []const u8) void {
    b.dependOnDirectoryContents(b.path(folder));
    const io = b.graph.io;
    var dir = b.root.root_dir.handle.openDir(io, folder, .{ .iterate = true }) catch |e|
        std.process.fatal("the Roc: cannot open {s} ({t})", .{ folder, e });
    defer dir.close(io);
    var it = dir.iterate();
    while (it.next(io) catch |e| std.process.fatal("the Roc: cannot list {s} ({t})", .{ folder, e })) |entry| {
        if (entry.kind != .file) continue;
        run.addFileInput(b.path(b.fmt("{s}/{s}", .{ folder, entry.name })));
    }
}

/// The Roc is roc-apps' pin, the nightly named in ../roc-version:
/// `-Droc=<path>`, else `~/tools/roc-<pin>/roc`. Either is refused unless
/// `roc version` names the pin, because another nightly lays the seam out
/// its own way.
fn rocCompiler(b: *std.Build) []const u8 {
    const io = b.graph.io;
    const pin_text = b.root.root_dir.handle.readFileAlloc(io, "../roc-version", b.allocator, .limited(256)) catch |e|
        std.process.fatal("the Roc: cannot read roc-apps' ../roc-version ({t})", .{e});
    const pin = std.mem.trim(u8, pin_text, " \r\n");
    const roc = b.option([]const u8, "roc", "The Roc compiler; it must be the pin in ../roc-version") orelse blk: {
        const home = b.graph.environ_map.get("HOME") orelse
            std.process.fatal("the Roc: no HOME, so no ~/tools/roc-{s}/roc; name it with -Droc", .{pin});
        break :blk b.fmt("{s}/tools/roc-{s}/roc", .{ home, pin });
    };
    var code: u8 = undefined;
    const said = b.runAllowFail(&.{ roc, "version" }, &code, .ignore) catch |e|
        std.process.fatal("the Roc: `{s} version` did not run ({t}); install the pin {s} there", .{ roc, e, pin });
    if (std.mem.indexOf(u8, said, pin) == null)
        std.process.fatal("the Roc: {s} is not the pin {s} (../roc-version); it says: {s}", .{ roc, pin, std.mem.trim(u8, said, " \n") });
    return roc;
}
