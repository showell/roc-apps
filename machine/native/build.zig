// The machine's native host: platform/host.zig compiled to a static library
// for x86_64-linux-musl against roc's own `builtins` and `host_alloc` modules,
// taken from the roc checkout (-Droc=<path>, default ~/showell_repos/roc). The
// module graph is the wasm host's (../wasm/build.zig); the target and the
// library shape are the ones roc's build.zig gives its fx test platform, which
// `roc run` links on Linux from targets/x64musl/.
const std = @import("std");

pub fn build(b: *std.Build) void {
    const roc = b.option([]const u8, "roc", "the roc-lang/roc checkout") orelse
        b.pathFromRoot("../../../roc");
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseFast });
    const target = b.resolveTargetQuery(.{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl });

    const src = struct {
        fn at(bb: *std.Build, root: []const u8, rel: []const u8) std.Build.LazyPath {
            return .{ .cwd_relative = bb.fmt("{s}/{s}", .{ root, rel }) };
        }
    };
    const build_options = b.createModule(.{ .root_source_file = b.path("options.zig") });
    const tracy = b.createModule(.{
        .root_source_file = src.at(b, roc, "src/build/tracy.zig"),
        .imports = &.{.{ .name = "build_options", .module = build_options }},
    });
    const parse_float = b.createModule(.{ .root_source_file = src.at(b, roc, "vendor/parse_float/parse_float.zig") });
    const ryu = b.createModule(.{ .root_source_file = src.at(b, roc, "vendor/ryu.zig") });
    const str_view = b.createModule(.{ .root_source_file = src.at(b, roc, "src/default_platform/roc_str_view.zig") });
    const builtins = b.createModule(.{
        .root_source_file = src.at(b, roc, "src/builtins/mod.zig"),
        .imports = &.{
            .{ .name = "tracy", .module = tracy },
            .{ .name = "vendor_parse_float", .module = parse_float },
            .{ .name = "vendor_ryu", .module = ryu },
            .{ .name = "roc_str_view", .module = str_view },
        },
    });
    const host_alloc = b.createModule(.{
        .root_source_file = src.at(b, roc, "src/host_alloc/mod.zig"),
        .imports = &.{
            .{ .name = "builtins", .module = builtins },
            .{ .name = "build_options", .module = build_options },
        },
    });

    // roc's minimal std.Io for host archives (see host.zig's std options).
    const shim_io = b.createModule(.{ .root_source_file = src.at(b, roc, "src/shim_io.zig") });

    const host = b.addLibrary(.{
        .name = "host",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("platform/host.zig"),
            .target = target,
            .optimize = optimize,
            .pic = true,
            .link_libc = true,
            .imports = &.{
                .{ .name = "builtins", .module = builtins },
                .{ .name = "host_alloc", .module = host_alloc },
                .{ .name = "shim_io", .module = shim_io },
            },
        }),
    });
    host.use_llvm = true;
    host.bundle_compiler_rt = true;
    host.link_function_sections = true;
    host.link_data_sections = true;

    const copy = b.addUpdateSourceFiles();
    copy.addCopyFileToSource(host.getEmittedBin(), "platform/targets/x64musl/libhost.a");
    b.getInstallStep().dependOn(&copy.step);
}
