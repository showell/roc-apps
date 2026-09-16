// The framebuffer platform's two hosts, each compiled against roc's own
// `builtins` and `host_alloc` modules from the roc checkout (-Droc=<path>,
// default ~/showell_repos/roc): the browser's (platform/host.zig), an object for
// wasm32-freestanding, and the native checker's (platform/native.zig), a static
// library for x86_64-linux-musl that roc links with musl's crt1.o and libc.a.
// The module graph is the one roc's build.zig gives the same hosts in its tests
// (test/wasm, test/fx); options.zig stands in for roc's generated build options.
// Each lands where the platform header expects it.
const std = @import("std");

const Roc = struct {
    builtins: *std.Build.Module,
    host_alloc: *std.Build.Module,
    shim_io: *std.Build.Module,
};

/// **THE FLOOR IS THE PLATFORM** (roc-apps floor/): its `core.zig` holds the
/// memory, the screen, the ports and the GPU these two hosts stand on, beside
/// the block device and the clock they do not use. It is a module rather than a
/// file beside them because it lives in the other directory; `gpu.zig` comes
/// with it, resolved against its own.
fn floorCore(b: *std.Build, roc: Roc) *std.Build.Module {
    return b.createModule(.{
        .root_source_file = .{ .cwd_relative = b.pathFromRoot("../floor/platform/core.zig") },
        .imports = &.{
            .{ .name = "builtins", .module = roc.builtins },
            .{ .name = "host_alloc", .module = roc.host_alloc },
        },
    });
}

/// A fresh module graph for one host: a module takes its target from the
/// compilation that imports it, so the two hosts do not share one.
fn rocModules(b: *std.Build, roc: []const u8) Roc {
    const at = struct {
        fn f(bb: *std.Build, root: []const u8, rel: []const u8) std.Build.LazyPath {
            return .{ .cwd_relative = bb.fmt("{s}/{s}", .{ root, rel }) };
        }
    }.f;
    const build_options = b.createModule(.{ .root_source_file = b.path("options.zig") });
    const tracy = b.createModule(.{
        .root_source_file = at(b, roc, "src/build/tracy.zig"),
        .imports = &.{.{ .name = "build_options", .module = build_options }},
    });
    const parse_float = b.createModule(.{ .root_source_file = at(b, roc, "vendor/parse_float/parse_float.zig") });
    const ryu = b.createModule(.{ .root_source_file = at(b, roc, "vendor/ryu.zig") });
    const str_view = b.createModule(.{ .root_source_file = at(b, roc, "src/default_platform/roc_str_view.zig") });
    const builtins = b.createModule(.{
        .root_source_file = at(b, roc, "src/builtins/mod.zig"),
        .imports = &.{
            .{ .name = "tracy", .module = tracy },
            .{ .name = "vendor_parse_float", .module = parse_float },
            .{ .name = "vendor_ryu", .module = ryu },
            .{ .name = "roc_str_view", .module = str_view },
        },
    });
    const host_alloc = b.createModule(.{
        .root_source_file = at(b, roc, "src/host_alloc/mod.zig"),
        .imports = &.{
            .{ .name = "builtins", .module = builtins },
            .{ .name = "build_options", .module = build_options },
        },
    });
    // roc's minimal std.Io for host archives (see native.zig's std options).
    const shim_io = b.createModule(.{ .root_source_file = at(b, roc, "src/shim_io.zig") });
    return .{ .builtins = builtins, .host_alloc = host_alloc, .shim_io = shim_io };
}

pub fn build(b: *std.Build) void {
    // The checkouts are siblings under showell_repos.
    const roc = b.option([]const u8, "roc", "the roc-lang/roc checkout") orelse
        b.pathFromRoot("../../roc");
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseFast });
    const copy = b.addUpdateSourceFiles();

    const web = rocModules(b, roc);
    const host = b.addObject(.{
        .name = "host",
        .root_module = b.createModule(.{
            .root_source_file = b.path("platform/host.zig"),
            .target = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .freestanding, .abi = .none }),
            .optimize = optimize,
            .pic = true,
            .imports = &.{
                .{ .name = "builtins", .module = web.builtins },
                .{ .name = "host_alloc", .module = web.host_alloc },
                .{ .name = "core", .module = floorCore(b, web) },
            },
        }),
    });
    host.use_llvm = true;
    host.link_function_sections = true;
    host.link_data_sections = true;
    host.bundle_compiler_rt = true;
    copy.addCopyFileToSource(host.getEmittedBin(), "platform/targets/wasm32/host.wasm");

    const native = rocModules(b, roc);
    const lib = b.addLibrary(.{
        .name = "host",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("platform/native.zig"),
            .target = b.resolveTargetQuery(.{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl }),
            .optimize = optimize,
            .pic = true,
            .link_libc = true,
            .imports = &.{
                .{ .name = "builtins", .module = native.builtins },
                .{ .name = "host_alloc", .module = native.host_alloc },
                .{ .name = "shim_io", .module = native.shim_io },
                .{ .name = "core", .module = floorCore(b, native) },
            },
        }),
    });
    lib.use_llvm = true;
    lib.bundle_compiler_rt = true;
    lib.link_function_sections = true;
    lib.link_data_sections = true;
    copy.addCopyFileToSource(lib.getEmittedBin(), "platform/targets/x64musl/libhost.a");

    b.getInstallStep().dependOn(&copy.step);
}
