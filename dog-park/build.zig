const std = @import("std");

/// How many samples the seeded fuzz loops take: `fast`, a tenth, for every
/// edit; `full` for the slow tier (`zig build slow`, or -Dfuzz=full).
const Fuzz = enum { fast, full };

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const fuzz = b.option(Fuzz, "fuzz", "the seeded fuzz loops' size: fast (a tenth, the default) or full") orelse .fast;
    // **THE PHYSICS' ROC, BUILT BY EVERY BUILD** (`rocArchives`): an
    // archive for each of the physics' targets, built into the cache from
    // roc/*.roc and linked wherever the physics is (`linkRoc`); nothing
    // built from Roc is checked in. So every build needs Roc, and without
    // it the build stops while it is configured, saying so (`rocCompiler`).
    const roc = rocCompiler(b);
    const roc_lib = rocArchives(b, roc);

    // **-Dwalk-judge**: every walk run beside src/walk_reference.zig and
    // compared (`zig build walk-judge`); off by default.
    const walk_judge = b.option(bool, "walk-judge", "judge every Roc walk against the plain Zig reference (walk_reference.zig), panicking at a difference") orelse false;
    const physics_mod = physicsOptions(b, walk_judge);

    const wasm32 = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .freestanding });
    const wasi = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .wasi });

    // **THE PHYSICS FOR THE PAGE** (docs/PHYSICS.md): physics_page.zig's
    // exports over the board and the tick, compiled to wasm32 in
    // ReleaseSafe. Installed to zig-out/web/physics.wasm, which the page
    // loads beside its scripts.
    const physics_page_wasm = pageWasm(b, wasm32, .safe, physics_mod, roc_lib);
    const page_wasm_install = b.addInstallArtifact(physics_page_wasm, .{ .dest_dir = .{ .override = .{ .custom = "web" } } });
    b.getInstallStep().dependOn(&page_wasm_install.step);
    // The same in Debug, for the fast tier alone: nothing there needs the
    // served build's speed, and it compiles in about a third of the time.
    // zig-out/web-debug/physics.wasm; `check` and `slow` test the served one.
    const debug_page_wasm = pageWasm(b, wasm32, .Debug, physics_mod, roc_lib);
    const debug_wasm_install = b.addInstallArtifact(debug_page_wasm, .{ .dest_dir = .{ .override = .{ .custom = "web-debug" } } });

    // ── the tests ───────────────────────────────────────────────────────────

    const units = struct {
        b: *std.Build,
        target: std.Build.ResolvedTarget,
        optimize: std.builtin.OptimizeMode,
        physics_mod: *std.Build.Module,
        roc_lib: RocLib,

        /// The physics' tests (physics_all_tests.zig), natively. They run
        /// every time, never cached, so every summary says how many ran.
        fn physics(u: @This(), size: Fuzz) *std.Build.Step {
            const m = u.module("src/physics_all_tests.zig", u.target, u.optimize, size);
            const run = u.b.addRunArtifact(u.b.addTest(.{ .root_module = m, .test_runner = testRunner(u.b) }));
            run.has_side_effects = true;
            return &run.step;
        }

        /// The physics' tests compiled to wasm32-wasi and run under node,
        /// so the page's architecture gives the native answers; and a
        /// compile probe of the physics for wasm32-freestanding.
        fn onWasm(u: @This(), wasi_target: std.Build.ResolvedTarget, freestanding: std.Build.ResolvedTarget, opt: std.builtin.OptimizeMode, size: Fuzz, step: *std.Build.Step) void {
            const probe = u.b.addExecutable(.{ .name = "physics_probe", .root_module = u.b.createModule(.{
                .root_source_file = u.b.path("src/physics_wasm_probe.zig"),
                .target = freestanding,
                .optimize = opt,
                .strip = true,
                .imports = &.{.{ .name = "physics_options", .module = u.physics_mod }},
            }) });
            linkRoc(u.roc_lib, probe.root_module);
            probe.entry = .disabled;
            probe.rdynamic = true;
            step.dependOn(&probe.step);
            const tests = u.b.addTest(.{ .root_module = u.module("src/physics_all_tests.zig", wasi_target, opt, size), .test_runner = testRunner(u.b) });
            const run = nodeCommand(u.b);
            // WASI is experimental in node, and says so on every run: that
            // one warning, by its exact words, is passed over
            // (tools/lib/warnings_fail.mjs); any other fails the run.
            run.addFileArg(u.b.path("tools/run_wasi.mjs"));
            run.addArtifactArg(tests);
            // "All N tests passed.": the runner (tools/test_runner.zig)
            // fails a skip, and a binary with no tests, on its exit code.
            run.expectStdErrMatch(" tests passed.");
            run.expectExitCode(0);
            run.has_side_effects = true;
            step.dependOn(&run.step);
        }

        fn module(u: @This(), root: []const u8, t: std.Build.ResolvedTarget, opt: std.builtin.OptimizeMode, size: Fuzz) *std.Build.Module {
            const test_options = u.b.addOptions();
            test_options.addOption(Fuzz, "fuzz", size);
            const m = u.b.createModule(.{
                .root_source_file = u.b.path(root),
                .target = t,
                .optimize = opt,
                .imports = &.{
                    .{ .name = "physics_options", .module = u.physics_mod },
                    .{ .name = "test_options", .module = test_options.createModule() },
                },
            });
            linkRoc(u.roc_lib, m);
            return m;
        }
    }{ .b = b, .target = target, .optimize = optimize, .physics_mod = physics_mod, .roc_lib = roc_lib };

    // **THE PAGE'S OWN TESTS** (node): each file its own process, its exit
    // code and its summary the verdict; on the Debug wasm in the fast tier
    // (DOGPARK_WASM names it to tools/lib/page_rig.mjs), on the served one
    // in `check` and `slow`.
    const node_tests = [_][]const u8{ "tools/test_page_modules.mjs", "tools/test_engine.mjs" };
    const check_node = b.step("check-node", "The page's node tests, on the Debug wasm");
    for (node_tests) |f| {
        const run = nodeRun(b, f);
        run.setEnvironmentVariable("DOGPARK_WASM", "zig-out/web-debug/physics.wasm");
        run.step.dependOn(&debug_wasm_install.step);
        check_node.dependOn(&run.step);
    }

    // **THE TIERS** (README): `test` after every edit; `check` before a
    // commit; `slow` for the full fuzz and the wasm as it is served.
    const test_step = b.step("test", "Fast tier: the physics' tests natively (the fuzz a tenth) and the page's node tests");
    test_step.dependOn(units.physics(fuzz));
    test_step.dependOn(check_node);

    const physics_test = b.step("physics-test", "The physics' tests alone, natively");
    physics_test.dependOn(units.physics(fuzz));

    const physics_wasm = b.step("physics-wasm", "The physics' tests on wasm32 in Debug, under node, and its freestanding compile probe");
    units.onWasm(wasi, wasm32, .Debug, fuzz, physics_wasm);

    // **THE ZIG AND ZON ARE AS `zig fmt` LAYS THEM OUT**, in `test`: the
    // generated .zon too (src/world.zon, rules.zon), so a printer in roc/
    // must print what `zig fmt` would.
    const zig_fmt = b.addFmt(.{ .paths = &.{ b.path("build.zig"), b.path("build.zig.zon"), b.path("src"), b.path("tools") }, .check = true });
    b.step("fmt", "`zig fmt --check` over every .zig and .zon, the generated ones too (in `test`)").dependOn(&zig_fmt.step);
    test_step.dependOn(&zig_fmt.step);

    const check = b.step("check", "Before a commit: test, physics-wasm (Debug), the page's tests on the served wasm, roc-test and roc-fresh");
    check.dependOn(test_step);
    check.dependOn(physics_wasm);
    for (node_tests) |f| check.dependOn(nodeTest(b, f));

    const slow = b.step("slow", "The slow tier: the full fuzz natively, the physics' tests on wasm32 in ReleaseSafe (as served) with the full fuzz, the page's tests");
    slow.dependOn(units.physics(.full));
    units.onWasm(wasi, wasm32, .safe, .full, slow);
    for (node_tests) |f| slow.dependOn(nodeTest(b, f));

    // ── the benches (no tier runs them) ─────────────────────────────────────

    // How long a tick takes natively (ReleaseSafe).
    const physics_bench = b.addExecutable(.{ .name = "physics_bench", .root_module = b.createModule(.{
        .root_source_file = b.path("src/physics_bench.zig"),
        .target = target,
        .optimize = .safe,
        .imports = &.{.{ .name = "physics_options", .module = physics_mod }},
    }) });
    linkRoc(roc_lib, physics_bench.root_module);
    const physics_bench_run = b.addRunArtifact(physics_bench);
    // `zig build physics-bench -- herd` (or `busiest`, `strewn`):
    // one of the bench's ticks alone, a fixed number of runs, for a
    // profiler; `-- lines`: every line of its drags, in the wire's text.
    physics_bench_run.addPassthruArgs();
    b.step("physics-bench", "Time a physics tick natively (ReleaseSafe); -- herd, busiest or strewn: that one alone, for a profiler; -- lines: every line of its drags").dependOn(&physics_bench_run.step);

    // **THE WALK'S JUDGE**: the bench's `-- judge` (its `lines` workload:
    // every dog leashed in turn on two parks, the strewn drag, the packed
    // herd; then again under a drag of uneven length) with every walk judged
    // against walk_reference.zig; its output discarded, it passes only if
    // nothing differed (a difference panics).
    const judged_bench = b.addExecutable(.{ .name = "physics_bench_judged", .root_module = b.createModule(.{
        .root_source_file = b.path("src/physics_bench.zig"),
        .target = target,
        .optimize = .safe,
        .imports = &.{.{ .name = "physics_options", .module = physicsOptions(b, true) }},
    }) });
    linkRoc(roc_lib, judged_bench.root_module);
    const judged_run = b.addRunArtifact(judged_bench);
    judged_run.addArg("judge");
    _ = judged_run.captureStdOut(.{});
    judged_run.expectExitCode(0);
    // It runs every time, never cached: a pass is a run that judged.
    judged_run.has_side_effects = true;
    b.step("walk-judge", "Run the bench's `-- lines` with every Roc walk judged against the plain Zig reference (src/walk_reference.zig)").dependOn(&judged_run.step);

    // **THE WORLD AND ITS RULES, FROM ROC** (src/world.zig, src/rules.zig):
    // roc/print_world.roc, roc/print_rules.roc and roc/print_page.roc run
    // with the pinned Roc (`rocCompiler`), what they print written to the
    // files the physics imports (world.zon, rules.zon) and the page reads
    // (web/world.js, web/words.js, web/look.js). Not in any tier: only a
    // change to a .roc file needs it; the tests hold the checked-in files
    // to the original world, rules and physics (layout.zig, rules.zig,
    // physics_golden_test.zig) and to each other (test_page_modules.mjs)
    // either way.
    //
    // **WHAT IS CHECKED IN IS WHAT THE ROC MAKES** (`roc-fresh`, in
    // `check`): each file this writes, made again and compared byte for
    // byte with the checked-in one, so none is left stale by a .roc change.
    const roc_write = b.addUpdateSourceFiles();
    const roc_fresh = b.step("roc-fresh", "Each file `zig build roc` writes, made again and compared with the checked-in one");
    for ([_][3][]const u8{
        .{ "roc/print_world.roc", "zon", "src/world.zon" },
        .{ "roc/print_world.roc", "js", "web/world.js" },
        .{ "roc/print_rules.roc", "zon", "src/rules.zon" },
        .{ "roc/print_page.roc", "words", "web/words.js" },
        .{ "roc/print_page.roc", "look", "web/look.js" },
    }) |out| {
        // The word goes bare: `roc app.roc -- w` hands the app `--` too.
        const roc_run = b.addSystemCommand(&.{ roc, out[0], out[1] });
        roc_run.setCwd(b.path("."));
        roc_run.addFileInput(b.path(out[0]));
        // Every module a printer may import: a printer's own list drifted
        // (print_world.roc reads Layout.roc and Wish.roc too).
        for (printed_from) |m| roc_run.addFileInput(b.path(m));
        const made = roc_run.captureStdOut(.{});
        roc_write.addCopyFileToSource(made, out[2]);
        roc_fresh.dependOn(fresh(b, made, out[2]));
    }
    b.step("roc", "Print the world, its rules and the page's words and look again from roc/*.roc into src/world.zon, src/rules.zon, web/world.js, web/words.js and web/look.js").dependOn(&roc_write.step);
    // **A NEW KIND, IN ROC ALONE**: the test of the sheep world, a copy of
    // this folder with test/new_kind/sheep.patch (roc/*.roc only) applied
    // and its world printed there by `zig build roc` (tools/new_kind.shale
    // makes it). The test alone, in this world, does not compile: it has
    // no sheep.
    const new_kind_test = b.step("new-kind-test", "The new kind's test, in the sheep world tools/new_kind.shale makes (in this world, with no sheep, it does not compile, saying so)");
    // Its own test alone: the physics' tests it imports belong to this
    // world, and the golden runs fail in the sheep world, as they should.
    // `--tests=1`: the filter picks out that one named test, and a filter
    // that matches none, or more, fails (tools/test_runner.zig).
    const new_kind_run = b.addRunArtifact(b.addTest(.{
        .root_module = units.module("src/new_kind_test.zig", target, optimize, fuzz),
        .filters = &.{"a new kind, made in Roc alone"},
        .test_runner = testRunner(b),
    }));
    new_kind_run.addArg("--tests=1");
    new_kind_test.dependOn(&new_kind_run.step);
    // Roc's own tests of the world, the rules, the wish, the walk and the
    // page's words and look (`expect`s), in `check`. `roc test` runs the
    // expects of the modules a file imports too, so print_page.roc carries
    // Words.roc's and Look.roc's.
    const roc_test_step = b.step("roc-test", "Roc's own tests: roc/print_world.roc, roc/Rules.roc, roc/Wish.roc, roc/Walk.roc and roc/print_page.roc's expects, with those of the modules they import; and `roc fmt --check roc`");
    for (roc_tested) |f| {
        const run = b.addSystemCommand(&.{ roc, "test", f });
        run.setCwd(b.path("."));
        run.addFileInput(b.path(f));
        run.has_side_effects = true;
        roc_test_step.dependOn(&run.step);
    }
    // **THE ROC IS AS `roc fmt` LAYS IT OUT**, in `check` and `roc-test`. A
    // long line is broken by a trailing comma after its last item, which
    // `roc fmt` lays out one item a line (shale's cookbook/roc/wrap_long_lines.shale
    // does it), never by hand: `roc fmt` joins those back.
    const roc_fmt = b.addSystemCommand(&.{ roc, "fmt", "--check", "roc" });
    roc_fmt.setCwd(b.path("."));
    roc_fmt.has_side_effects = true;
    roc_test_step.dependOn(&roc_fmt.step);
    check.dependOn(roc_test_step);
    check.dependOn(roc_fresh);
}

/// The files `roc test` runs, each with the expects of what it imports.
const roc_tested = [_][]const u8{ "roc/print_world.roc", "roc/Rules.roc", "roc/Wish.roc", "roc/Walk.roc", "roc/print_page.roc" };

/// The runner every Zig test is built with: std's, except that a skipped
/// test fails, and so does a binary with no tests (a filter that matches
/// nothing). It speaks the build runner's protocol, so the summary keeps
/// its counts.
fn testRunner(b: *std.Build) std.Build.Step.Compile.TestRunner {
    return .{ .path = b.path("tools/test_runner.zig"), .mode = .server };
}

/// A step that fails, naming `checked_in`, unless it is byte for byte
/// `made`.
fn fresh(b: *std.Build, made: std.Build.LazyPath, checked_in: []const u8) *std.Build.Step {
    const cmp = b.addSystemCommand(&.{ "sh", "-c", "cmp -s \"$1\" \"$2\" || { echo \"$3 is not what the Roc makes: zig build roc, then commit it\" >&2; exit 1; }", "sh" });
    cmp.addFileArg(made);
    cmp.addFileArg(b.path(checked_in));
    cmp.addArg(checked_in);
    return &cmp.step;
}

/// One node test file, after the install (the served wasm), its exit code
/// and its summary the verdict (`nodeRun`).
fn nodeTest(b: *std.Build, file: []const u8) *std.Build.Step {
    const run = nodeRun(b, file);
    run.step.dependOn(b.getInstallStep());
    return &run.step;
}

/// `node`, with tools/lib/warnings_fail.mjs preloaded: a warning fails the
/// run.
fn nodeCommand(b: *std.Build) *std.Build.Step.Run {
    const run = b.addSystemCommand(&.{"node"});
    run.addPrefixedFileArg("--import=", b.path("tools/lib/warnings_fail.mjs"));
    return run;
}

/// A node test file (node:test, whose summary is TAP), its exit code the
/// verdict, and a skip or a todo fails it: node:test passes over both with
/// exit code 0. What it needs built first is the caller's to add.
fn nodeRun(b: *std.Build, file: []const u8) *std.Build.Step.Run {
    const run = nodeCommand(b);
    run.addFileArg(b.path(file));
    run.setCwd(b.path("."));
    run.expectStdOutMatch("\n# skipped 0\n");
    run.expectStdOutMatch("\n# todo 0\n");
    run.expectExitCode(0);
    run.has_side_effects = true;
    return run;
}

/// The physics for the page (physics_page.zig's exports), compiled to wasm32.
fn pageWasm(b: *std.Build, wasm32: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, physics_mod: *std.Build.Module, roc_lib: RocLib) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{ .name = "physics", .root_module = b.createModule(.{
        .root_source_file = b.path("src/physics_page.zig"),
        .target = wasm32,
        .optimize = optimize,
        .strip = true,
        .imports = &.{.{ .name = "physics_options", .module = physics_mod }},
    }) });
    linkRoc(roc_lib, exe.root_module);
    exe.entry = .disabled;
    exe.rdynamic = true;
    return exe;
}

/// The physics' Roc: an archive for each target the physics compiles for,
/// built from `roc_inputs` (src/roc_physics.zig is its seam).
const RocTarget = enum { x64musl, wasm32 };
const RocLib = std.EnumArray(RocTarget, std.Build.LazyPath);
const roc_inputs = [_][]const u8{ "roc/physics.roc", "roc/Wish.roc", "roc/Walk.roc", "roc/World.roc", "roc/Rules.roc", "roc/platform/main.roc" };

/// The file that names roc-apps' Roc, one nightly for the whole repository,
/// from this build's root.
const pin_file = "../roc-version";

/// The Roc the physics is built by: roc-apps' `roc-version`, one line, as
/// `roc version` ends (a nightly's name). Moving it is a decision: a new
/// Roc is new archives, so judge them (physics-bench's `lines`, the walk's
/// judge, the golden runs).
fn rocPin(b: *std.Build) []const u8 {
    const path = pathFromRoot(b, pin_file);
    const said = std.Io.Dir.cwd().readFileAlloc(b.graph.io, path, b.allocator, .limited(256)) catch |e|
        std.process.fatal("Dog Park's physics is built by the Roc roc-apps pins, and {s} does not read ({t}): build from a roc-apps checkout", .{ path, e });
    return std.mem.trim(u8, said, " \n");
}

/// The Roc compiler: -Droc=<path> (from the build root) when given; else
/// `~/tools/roc-<pin>/roc`; else `roc` on the PATH. **Every build needs
/// one, and the pinned one** (`rocPin`): with none, or another, the build
/// stops here, while it is configured, saying so. The PATH's `roc` is never
/// trusted for being there.
fn rocCompiler(b: *std.Build) []const u8 {
    const pin = rocPin(b);
    const named = b.option([]const u8, "roc", "the Roc compiler (default: ~/tools/roc-<pin>/roc, else `roc` on the PATH); every build needs one, the version ../roc-version pins");
    const none = "Dog Park's physics is built from Roc {s} (../roc-version), and there is no Roc compiler at {s}: install it at ~/tools/roc-{s}/roc (roc-apps' README, \"The compiler\"), or name it with -Droc=<path>";
    const io = b.graph.io;
    const found = if (named) |n|
        (if (std.mem.indexOfScalar(u8, n, '/') == null)
            b.findProgram(.{ .names = &.{n} }) orelse std.process.fatal(none, .{ pin, b.fmt("`{s}` on the PATH", .{n}), pin })
        else
            b.root.root_dir.handle.realPathFileAlloc(io, n, b.allocator) catch std.process.fatal(none, .{ pin, b.fmt("`{s}`", .{n}), pin }))
    else blk: {
        const home = b.graph.environ_map.get("HOME") orelse std.process.fatal("Dog Park's physics needs Roc {s}, and there is no HOME to find ~/tools/roc-{s}/roc in: name it with -Droc=<path>", .{ pin, pin });
        const pinned = b.fmt("{s}/tools/roc-{s}/roc", .{ home, pin });
        break :blk b.root.root_dir.handle.realPathFileAlloc(io, pinned, b.allocator) catch
            b.findProgram(.{ .names = &.{"roc"} }) orelse std.process.fatal(none, .{ pin, b.fmt("{s}, nor `roc` on the PATH", .{pinned}), pin });
    };
    const said = std.mem.trim(u8, b.run(&.{ found, "version" }), " \n");
    const version = if (std.mem.lastIndexOfScalar(u8, said, ' ')) |i| said[i + 1 ..] else said;
    if (!std.mem.eql(u8, version, pin)) std.process.fatal("Dog Park's physics is pinned to Roc {s} (../roc-version), and `{s}` is {s}: install the pinned one at ~/tools/roc-{s}/roc, which every build finds itself, or name it with -Droc=<path>", .{ pin, found, version, pin });
    return found;
}

/// The physics' Roc built for each target, into the cache. The compiler is
/// an input too, so a new Roc builds them again.
fn rocArchives(b: *std.Build, roc: []const u8) RocLib {
    var lib: RocLib = undefined;
    for (std.enums.values(RocTarget)) |t| {
        const build_roc = b.addSystemCommand(&.{ roc, "build", "roc/physics.roc", b.fmt("--target={t}", .{t}) });
        build_roc.setCwd(b.path("."));
        build_roc.addFileInput(.{ .cwd_relative = roc });
        for (roc_inputs) |f| build_roc.addFileInput(b.path(f));
        lib.set(t, build_roc.addPrefixedOutputFileArg("--output=", b.fmt("physics-{t}.a", .{t})));
    }
    return lib;
}

/// Links the physics' Roc for `m`'s target.
fn linkRoc(lib: RocLib, m: *std.Build.Module) void {
    const r = m.resolved_target.?.result;
    const t: RocTarget = if (r.cpu.arch.isWasm())
        .wasm32
    else if (r.cpu.arch == .x86_64 and r.os.tag != .freestanding)
        .x64musl
    else
        std.process.fatal("the physics' Roc: no archive for {t} {t} (it is built for x86-64 Linux and wasm32)", .{ r.cpu.arch, r.os.tag });
    m.addObjectFile(lib.get(t));
}

/// The modules roc/'s printers import, every one an input of each print:
/// a change to any prints again.
const printed_from = [_][]const u8{ "roc/World.roc", "roc/Rules.roc", "roc/Layout.roc", "roc/Wish.roc", "roc/Words.roc", "roc/Look.roc" };

/// The physics' build options, `physics_options`: whether every walk is
/// judged against the plain Zig reference.
fn physicsOptions(b: *std.Build, walk_judge: bool) *std.Build.Module {
    const options = b.addOptions();
    options.addOption(bool, "walk_judge", walk_judge);
    return options.createModule();
}

/// `builder`'s build root as an absolute path: 0.17's `b.root` may hold a
/// relative one, and these paths are handed to other processes and builds.
fn rootOf(builder: *std.Build) []const u8 {
    return builder.root.root_dir.handle.realPathFileAlloc(builder.graph.io, builder.root.subPathOrDot(), builder.allocator) catch |e|
        std.debug.panic("the build root {f}: {t}", .{ builder.root, e });
}

/// `sub` under this build's root, absolute (0.17 removed `b.pathFromRoot`).
fn pathFromRoot(b: *std.Build, sub: []const u8) []const u8 {
    return b.pathJoin(&.{ rootOf(b), sub });
}
