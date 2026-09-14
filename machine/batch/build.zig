// The machine batch host: platform/host.zig compiled to a wasm32-freestanding
// object against roc's own `builtins` and `host_alloc` modules, taken from the
// roc checkout (-Droc=<path>, default ~/showell_repos/roc). The module graph is
// the one roc's build.zig gives the same host in its tests (test/wasm and
// test/provided-callable-host); options.zig stands in for roc's generated
// build options. The object lands where the platform header expects it.
const std = @import("std");

pub fn build(b: *std.Build) void {
    // The checkouts are siblings under showell_repos.
    const roc = b.option([]const u8, "roc", "the roc-lang/roc checkout") orelse
        b.pathFromRoot("../../../roc");
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseFast });
    const target = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .freestanding, .abi = .none });

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

    const host = b.addObject(.{
        .name = "host",
        .root_module = b.createModule(.{
            .root_source_file = b.path("platform/host.zig"),
            .target = target,
            .optimize = optimize,
            .pic = true,
            .imports = &.{
                .{ .name = "builtins", .module = builtins },
                .{ .name = "host_alloc", .module = host_alloc },
            },
        }),
    });
    host.use_llvm = true;
    host.link_function_sections = true;
    host.link_data_sections = true;
    host.bundle_compiler_rt = true;

    const copy = b.addUpdateSourceFiles();
    copy.addCopyFileToSource(host.getEmittedBin(), "platform/targets/wasm32/host.wasm");
    b.getInstallStep().dependOn(&copy.step);
}
