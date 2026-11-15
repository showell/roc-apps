const std = @import("std");

/// `zig build run -Droc=<path to roc>` builds app/main.roc on platform/
/// into an archive with that Roc, links it under host/main.zig, and runs it.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const roc = b.option([]const u8, "roc", "The Roc compiler") orelse "roc";

    const archive = b.addSystemCommand(&.{ roc, "build", "app/main.roc", "--target=x64musl", "--opt=dev" });
    archive.setCwd(b.path("."));
    archive.addFileInput(b.path("app/main.roc"));
    archive.addFileInput(b.path("platform/main.roc"));
    archive.addFileInput(.{ .cwd_relative = roc });
    const app = archive.addPrefixedOutputFileArg("--output=", "app.a");

    const mod = b.createModule(.{ .root_source_file = b.path("host/main.zig"), .target = target, .optimize = optimize });
    mod.addObjectFile(app);
    const exe = b.addExecutable(.{ .name = "provides-type-variable", .root_module = mod });
    const run = b.addRunArtifact(exe);
    run.stdio = .inherit;
    run.has_side_effects = true;
    b.step("run", "Build the app and run it").dependOn(&run.step);
}
