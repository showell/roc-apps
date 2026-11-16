const std = @import("std");

/// Seattle Delivery's build. The solver is Roc (roc/), built by every build
/// into an archive for each target it runs on (`rocArchives`) and linked
/// under the Zig host in src/: the page's solver.wasm, and the native judge
/// and bench. The display is TypeScript (*.ts), bundled by esbuild into
/// app.js. zig/ keeps the Zig solver the Roc replaced, as the bench's
/// yardstick and with its own gold check.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const roc = rocCompiler(b);
    const roc_opt = b.option(RocOpt, "roc-opt", "how the Roc is compiled: speed (LLVM, the default, as served) or dev (the fast-to-build backend, for the fix loop)") orelse .speed;
    const roc_lib = rocArchives(b, roc, roc_opt);

    const wasm32 = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .freestanding });
    // `zig build -Dwasm-names=true -p zig-out-names`: a solver.wasm with its
    // function names, for node's CPU profiler.
    const wasm_names = b.option(bool, "wasm-names", "keep the function names in solver.wasm, for a profiler (the served one has none)") orelse false;

    // **THE PAGE**: zig-out/web/ holds what the dev channel serves, the
    // shell (web/index.html), the bundle (app.js) and the solver.
    const solver_wasm = b.addExecutable(.{ .name = "solver", .root_module = b.createModule(.{
        .root_source_file = b.path("src/wasm.zig"),
        .target = wasm32,
        .optimize = .ReleaseSafe,
        .strip = !wasm_names,
    }) });
    linkRoc(roc_lib, solver_wasm.root_module);
    solver_wasm.entry = .disabled;
    solver_wasm.rdynamic = true;
    const wasm_install = b.addInstallArtifact(solver_wasm, .{ .dest_dir = .{ .override = .{ .custom = "web" } } });
    b.getInstallStep().dependOn(&wasm_install.step);

    const app_js = esbuild(b, "main.ts", "app.js", .iife);
    b.getInstallStep().dependOn(&b.addInstallFileWithDir(app_js, .{ .custom = "web" }, "app.js").step);
    b.getInstallStep().dependOn(&b.addInstallFileWithDir(b.path("web/index.html"), .{ .custom = "web" }, "index.html").step);

    // **THE JUDGES**: the gold, natively against the Roc (src/gold_check.zig)
    // and on the page's own solver.wasm (wasm_check.ts, under node).
    const gold_exe = b.addExecutable(.{ .name = "gold_check", .root_module = b.createModule(.{
        .root_source_file = b.path("src/gold_check.zig"),
        .target = target,
        .optimize = .ReleaseSafe,
    }) });
    linkRoc(roc_lib, gold_exe.root_module);
    const gold_run = b.addRunArtifact(gold_exe);
    gold_run.setCwd(b.path("."));
    gold_run.stdio = .inherit;
    gold_run.has_side_effects = true;
    const gold_step = b.step("gold", "The Roc solver natively against solver_gold.json and solver_frames_gold.json, every shift");
    gold_step.dependOn(&gold_run.step);

    const wasm_check = esbuild(b, "wasm_check.ts", "wasm_check.mjs", .esm);
    const wasm_run = b.addSystemCommand(&.{"node"});
    wasm_run.addFileArg(wasm_check);
    wasm_run.addArtifactArg(solver_wasm);
    wasm_run.setCwd(b.path("."));
    wasm_run.stdio = .inherit;
    wasm_run.has_side_effects = true;
    const wasm_step = b.step("wasm-gold", "The page's solver.wasm, driven under node, against both gold files");
    wasm_step.dependOn(&wasm_run.step);

    // The Zig reference's solver.wasm (zig/wasm.zig), built as angry-gopher
    // served it, and the bench that times it against the Roc one under node.
    const reference_wasm = b.addExecutable(.{ .name = "reference_solver", .root_module = b.createModule(.{
        .root_source_file = b.path("zig/wasm.zig"),
        .target = wasm32,
        .optimize = .ReleaseSmall,
        .strip = true,
    }) });
    reference_wasm.entry = .disabled;
    reference_wasm.rdynamic = true;
    const wasm_bench = esbuild(b, "wasm_bench.ts", "wasm_bench.mjs", .esm);
    const wasm_bench_run = b.addSystemCommand(&.{"node"});
    wasm_bench_run.addFileArg(wasm_bench);
    wasm_bench_run.addArtifactArg(reference_wasm);
    wasm_bench_run.addArtifactArg(solver_wasm);
    wasm_bench_run.setCwd(b.path("."));
    wasm_bench_run.stdio = .inherit;
    wasm_bench_run.has_side_effects = true;
    wasm_bench_run.addPassthruArgs();
    b.step("wasm-bench", "Time the page's solve under node, the Zig reference's solver.wasm against the Roc one").dependOn(&wasm_bench_run.step);

    const typecheck = b.addSystemCommand(&.{ "node_modules/.bin/tsc", "--noEmit", "-p", "." });
    typecheck.setCwd(b.path("."));
    typecheck.has_side_effects = true;
    b.step("typecheck", "tsc over the display and the reference solver.ts").dependOn(&typecheck.step);

    // **THE YARDSTICK**: the Zig solver in zig/, its unit tests and its own
    // gold check, and the bench that times it against the Roc.
    const reference_gold = b.addExecutable(.{ .name = "reference_gold", .root_module = b.createModule(.{
        .root_source_file = b.path("zig/gold_check.zig"),
        .target = target,
        .optimize = .ReleaseFast,
    }) });
    const reference_run = b.addRunArtifact(reference_gold);
    reference_run.setCwd(b.path("zig"));
    reference_run.stdio = .inherit;
    reference_run.has_side_effects = true;
    b.step("reference-gold", "The Zig reference solver (zig/) against the gold").dependOn(&reference_run.step);

    const reference_test = b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = b.path("zig/reference.zig"),
        .target = target,
        .optimize = .Debug,
    }) });
    const reference_test_run = b.addRunArtifact(reference_test);
    reference_test_run.has_side_effects = true;
    b.step("reference-test", "The Zig reference solver's unit tests").dependOn(&reference_test_run.step);

    const bench = b.addExecutable(.{ .name = "bench", .root_module = b.createModule(.{
        .root_source_file = b.path("src/bench.zig"),
        .target = target,
        .optimize = .ReleaseFast,
        .imports = &.{.{ .name = "reference", .module = b.createModule(.{
            .root_source_file = b.path("zig/reference.zig"),
            .target = target,
            .optimize = .ReleaseFast,
        }) }},
    }) });
    linkRoc(roc_lib, bench.root_module);
    const bench_run = b.addRunArtifact(bench);
    bench_run.setCwd(b.path("."));
    bench_run.stdio = .inherit;
    bench_run.has_side_effects = true;
    bench_run.addPassthruArgs();
    b.step("bench", "Time the 20 gold shifts' solves natively, the Zig reference against the Roc").dependOn(&bench_run.step);
    // The bench installed (zig-out/bin/bench), for a profiler.
    b.step("bench-exe", "Install the bench as zig-out/bin/bench, for a profiler").dependOn(&b.addInstallArtifact(bench, .{}).step);

    // **THE ROC'S OWN CHECKS**: its expects, and its layout as `roc fmt` has it.
    const roc_test = b.addSystemCommand(&.{ roc, "test", "roc/delivery.roc" });
    roc_test.setCwd(b.path("."));
    roc_test.has_side_effects = true;
    const roc_fmt = b.addSystemCommand(&.{ roc, "fmt", "--check", "roc" });
    roc_fmt.setCwd(b.path("."));
    roc_fmt.has_side_effects = true;
    const roc_test_step = b.step("roc-test", "Roc's expects (roc test roc/delivery.roc) and roc fmt --check roc");
    roc_test_step.dependOn(&roc_test.step);
    roc_test_step.dependOn(&roc_fmt.step);

    const zig_fmt = b.addFmt(.{ .paths = &.{ b.path("build.zig"), b.path("build.zig.zon"), b.path("src") }, .check = true });
    b.step("fmt", "zig fmt --check over build.zig and src/").dependOn(&zig_fmt.step);
}

const RocOpt = enum { speed, dev };

fn esbuild(b: *std.Build, entry: []const u8, out_name: []const u8, format: enum { iife, esm }) std.Build.LazyPath {
    const run = b.addSystemCommand(&.{ "node_modules/.bin/esbuild", entry, "--bundle", "--target=es2022", "--log-level=warning" });
    run.setCwd(b.path("."));
    switch (format) {
        .iife => run.addArgs(&.{ "--format=iife", "--platform=browser" }),
        .esm => run.addArgs(&.{ "--format=esm", "--platform=node" }),
    }
    for (ts_sources) |f| run.addFileInput(b.path(f));
    return run.addPrefixedOutputFileArg("--outfile=", out_name);
}

/// Every TypeScript file a bundle may reach.
const ts_sources = [_][]const u8{ "main.ts", "geography.ts", "orders.ts", "roadgraph.ts", "solver.ts", "map_view.ts", "timeline.ts", "wasm_check.ts", "wasm_bench.ts" };

/// The Roc the solver is built from: an archive for each target, from
/// `roc_inputs` (src/roc_seam.zig is its seam).
const RocTarget = enum { x64musl, wasm32 };
const RocLib = std.EnumArray(RocTarget, std.Build.LazyPath);
const roc_inputs = [_][]const u8{
    "roc/Build.roc",
    "roc/Gold.roc",
    "roc/Houses.roc",
    "roc/Improve.roc",
    "roc/JsonOut.roc",
    "roc/Orders.roc",
    "roc/Pain.roc",
    "roc/PlanJson.roc",
    "roc/Replay.roc",
    "roc/RoadGraph.roc",
    "roc/Route.roc",
    "roc/Seattle.roc",
    "roc/SlotSearch.roc",
    "roc/Solve.roc",
    "roc/Stop.roc",
    "roc/delivery.roc",
    "roc/platform/main.roc",
};

/// The file that names roc-apps' Roc, one nightly for the whole repository,
/// from this build's root.
const pin_file = "../roc-version";

fn rocPin(b: *std.Build) []const u8 {
    const path = pathFromRoot(b, pin_file);
    const said = std.Io.Dir.cwd().readFileAlloc(b.graph.io, path, b.allocator, .limited(256)) catch |e|
        std.process.fatal("Seattle Delivery's solver is built by the Roc roc-apps pins, and {s} does not read ({t}): build from a roc-apps checkout", .{ path, e });
    return std.mem.trim(u8, said, " \n");
}

/// The Roc compiler: -Droc=<path> when given; else `~/tools/roc-<pin>/roc`;
/// else `roc` on the PATH. Every build needs one, and the pinned one: with
/// none, or another, the build stops here, while it is configured, saying so.
fn rocCompiler(b: *std.Build) []const u8 {
    const pin = rocPin(b);
    const named = b.option([]const u8, "roc", "the Roc compiler (default: ~/tools/roc-<pin>/roc, else `roc` on the PATH); every build needs one, the version ../roc-version pins");
    const none = "Seattle Delivery's solver is built from Roc {s} (../roc-version), and there is no Roc compiler at {s}: install it at ~/tools/roc-{s}/roc, or name it with -Droc=<path>";
    const io = b.graph.io;
    const found = if (named) |n|
        (if (std.mem.indexOfScalar(u8, n, '/') == null)
            b.findProgram(.{ .names = &.{n} }) orelse std.process.fatal(none, .{ pin, b.fmt("`{s}` on the PATH", .{n}), pin })
        else
            b.root.root_dir.handle.realPathFileAlloc(io, n, b.allocator) catch std.process.fatal(none, .{ pin, b.fmt("`{s}`", .{n}), pin }))
    else blk: {
        const home = b.graph.environ_map.get("HOME") orelse std.process.fatal("Seattle Delivery's solver needs Roc {s}, and there is no HOME to find ~/tools/roc-{s}/roc in: name it with -Droc=<path>", .{ pin, pin });
        const pinned = b.fmt("{s}/tools/roc-{s}/roc", .{ home, pin });
        break :blk b.root.root_dir.handle.realPathFileAlloc(io, pinned, b.allocator) catch
            b.findProgram(.{ .names = &.{"roc"} }) orelse std.process.fatal(none, .{ pin, b.fmt("{s}, nor `roc` on the PATH", .{pinned}), pin });
    };
    const said = std.mem.trim(u8, b.run(&.{ found, "version" }), " \n");
    const version = if (std.mem.lastIndexOfScalar(u8, said, ' ')) |i| said[i + 1 ..] else said;
    if (!std.mem.eql(u8, version, pin)) std.process.fatal("Seattle Delivery's solver is pinned to Roc {s} (../roc-version), and `{s}` is {s}: install the pinned one at ~/tools/roc-{s}/roc, or name it with -Droc=<path>", .{ pin, found, version, pin });
    return found;
}

/// The solver's Roc built for each target, into the cache. The compiler is
/// an input too, so a new Roc builds them again.
fn rocArchives(b: *std.Build, roc: []const u8, opt: RocOpt) RocLib {
    var lib: RocLib = undefined;
    for (std.enums.values(RocTarget)) |t| {
        const build_roc = b.addSystemCommand(&.{ roc, "build", "roc/delivery.roc", b.fmt("--target={t}", .{t}), b.fmt("--opt={t}", .{opt}) });
        build_roc.setCwd(b.path("."));
        build_roc.addFileInput(.{ .cwd_relative = roc });
        for (roc_inputs) |f| build_roc.addFileInput(b.path(f));
        lib.set(t, build_roc.addPrefixedOutputFileArg("--output=", b.fmt("delivery-{t}.a", .{t})));
    }
    return lib;
}

/// Links the solver's Roc for `m`'s target.
fn linkRoc(lib: RocLib, m: *std.Build.Module) void {
    const r = m.resolved_target.?.result;
    const t: RocTarget = if (r.cpu.arch.isWasm())
        .wasm32
    else if (r.cpu.arch == .x86_64 and r.os.tag != .freestanding)
        .x64musl
    else
        std.process.fatal("the solver's Roc: no archive for {t} {t} (it is built for x86-64 Linux and wasm32)", .{ r.cpu.arch, r.os.tag });
    m.addObjectFile(lib.get(t));
}

/// `builder`'s build root as an absolute path.
fn rootOf(builder: *std.Build) []const u8 {
    return builder.root.root_dir.handle.realPathFileAlloc(builder.graph.io, builder.root.subPathOrDot(), builder.allocator) catch |e|
        std.debug.panic("the build root {f}: {t}", .{ builder.root, e });
}

fn pathFromRoot(b: *std.Build, sub: []const u8) []const u8 {
    return b.pathJoin(&.{ rootOf(b), sub });
}
