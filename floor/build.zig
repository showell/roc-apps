// The floor's two hosts, each compiled against roc's own `builtins`,
// `host_alloc` and `shim_io` modules from the roc checkout (-Droc=<path>,
// default ~/showell_repos/roc): the browser's (platform/host.zig), an object
// for wasm32-freestanding, and the native checker's (platform/native.zig), a
// static library for x86_64-linux-musl that roc links with musl's crt1.o and
// libc.a. Both are one compilation of the same core.zig, so a program behaves
// the same in each. The module graph is the one roc's build.zig gives the same
// hosts in its tests (test/wasm, test/fx); options.zig stands in for roc's
// generated build options.
//
// A third root -- a real machine's, with its own framebuffer and its own
// clock -- is another compilation beside these two and nothing more.
const std = @import("std");

const Roc = struct {
    builtins: *std.Build.Module,
    host_alloc: *std.Build.Module,
    shim_io: *std.Build.Module,
};

/// A fresh module graph for one host: a module takes its target from the
/// compilation that imports it, so two hosts do not share one.
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
            },
        }),
    });
    lib.use_llvm = true;
    lib.bundle_compiler_rt = true;
    lib.link_function_sections = true;
    lib.link_data_sections = true;
    copy.addCopyFileToSource(lib.getEmittedBin(), "platform/targets/x64musl/libhost.a");

    // **THE THIRD ROOT: NO OPERATING SYSTEM.** The same core.zig again, for a
    // machine QEMU boots with `-kernel`. roc links this object with the app's
    // for target x64elf ("x86_64-unknown-none-elf"), which is the one target in
    // its list with no OS under it.
    const bare = rocModules(b, roc);
    const kernel = b.addObject(.{
        .name = "host",
        .root_module = b.createModule(.{
            .root_source_file = b.path("platform/bare.zig"),
            .target = b.resolveTargetQuery(.{
                .cpu_arch = .x86_64,
                .os_tag = .freestanding,
                .abi = .none,
                // No SSE: a kernel that has not enabled it faults on the first
                // xmm register the compiler chooses to use.
                .cpu_features_sub = std.Target.x86.featureSet(&.{ .sse, .sse2, .avx, .avx2 }),
                .cpu_features_add = std.Target.x86.featureSet(&.{.soft_float}),
            }),
            .optimize = optimize,
            .pic = false,
            .code_model = .kernel,
            .imports = &.{
                .{ .name = "builtins", .module = bare.builtins },
                .{ .name = "host_alloc", .module = bare.host_alloc },
            },
        }),
    });
    kernel.use_llvm = true;
    kernel.bundle_compiler_rt = true;
    copy.addCopyFileToSource(kernel.getEmittedBin(), "platform/targets/x64elf/host.o");

    // **THE PROBE**: a kernel that is only the virtio driver and a serial
    // port, so the driver can be put on virtual hardware before anything is
    // built on it. `zig build probe --build-file floor/build.zig`, then
    // floor/probe/run.sh.
    const probe = b.addExecutable(.{
        .name = "probe.elf",
        .root_module = b.createModule(.{
            .root_source_file = b.path("probe/kernel.zig"),
            .target = b.resolveTargetQuery(.{
                .cpu_arch = .x86_64,
                .os_tag = .freestanding,
                .abi = .none,
                // A kernel that has not enabled SSE faults on the first xmm
                // register the compiler reaches for, and it reaches for them
                // in memcpy unless told not to.
                .cpu_features_sub = std.Target.x86.featureSet(&.{ .sse, .sse2, .avx, .avx2 }),
                .cpu_features_add = std.Target.x86.featureSet(&.{.soft_float}),
            }),
            .optimize = .ReleaseSafe,
            .pic = false,
            .code_model = .kernel,
            .imports = &.{
                .{ .name = "virtio", .module = b.createModule(.{ .root_source_file = b.path("platform/virtio.zig") }) },
            },
        }),
    });
    probe.setLinkerScript(b.path("probe/link.ld"));
    probe.entry = .{ .symbol_name = "_start" };
    const probe_copy = b.addUpdateSourceFiles();
    probe_copy.addCopyFileToSource(probe.getEmittedBin(), "probe/probe.elf");
    b.step("probe", "the virtio probe kernel").dependOn(&probe_copy.step);

    b.getInstallStep().dependOn(&copy.step);
}
