//! The Roc solver against the gold corpus, natively. For every shift in
//! solver_gold.json it asks the Roc for two answers and compares each, as
//! JSON values, with the gold the TypeScript reference minted:
//!
//! - `roc_gold(seed)`: the fleet, the race's variant labels and the road
//!   graph (its edges, every pair's minutes and path), then the shift's
//!   demand, each race variant's pain, the winner, and the winning plan's
//!   routes with each one's pain. All of it integers and structure, held to
//!   strict equality.
//! - `roc_plan(seed)`, the page's own plan: its routes' stops against
//!   solver_gold.json, and its display numbers and solve-replay frames
//!   against solver_frames_gold.json. Strings and integers strict; the
//!   display minutes, which pass through ring trigonometry, at ULP scale.
//!
//! It prints a line a shift and exits 1 on any difference, naming where.
//!
//!   zig build gold     (in delivery/; it runs here, beside the gold files)

const std = @import("std");
const seam = @import("roc_seam.zig");

const Value = std.json.Value;

var fail_count: usize = 0;

fn fail(comptime fmt: []const u8, args: anytype) void {
    fail_count += 1;
    if (fail_count <= 40) std.debug.print("  FAIL " ++ fmt ++ "\n", args);
}

/// How two numbers agree: integers and structure exactly; a float (a
/// display minute) within ULP scale of the gold's.
const Floats = enum { exact, ulp };

fn numOf(v: Value) ?f64 {
    return switch (v) {
        .integer => |i| @floatFromInt(i),
        .float => |f| f,
        else => null,
    };
}

/// Compares `got` with `gold` whole, naming the first difference under
/// `where`. Objects must have the same keys; arrays the same length.
fn same(where: []const u8, got: Value, gold: Value, floats: Floats) bool {
    switch (gold) {
        .integer => |g| {
            if (got == .integer and got.integer == g) return true;
            if (floats == .ulp) if (numOf(got)) |f| if (close(@floatFromInt(g), f)) return true;
        },
        .float => |g| {
            if (floats == .ulp) if (numOf(got)) |f| if (close(g, f)) return true;
            if (got == .float and got.float == g) return true;
        },
        .string => |g| if (got == .string and std.mem.eql(u8, got.string, g)) return true,
        .bool => |g| if (got == .bool and got.bool == g) return true,
        .null => if (got == .null) return true,
        .array => |g| {
            if (got != .array) {
                fail("{s}: not an array", .{where});
                return false;
            }
            if (got.array.items.len != g.items.len) {
                fail("{s}: {d} items, gold {d}", .{ where, got.array.items.len, g.items.len });
                return false;
            }
            for (g.items, got.array.items, 0..) |gi, oi, i| {
                var buf: [256]u8 = undefined;
                const at = std.fmt.bufPrint(&buf, "{s}[{d}]", .{ where, i }) catch where;
                if (!same(at, oi, gi, floats)) return false;
            }
            return true;
        },
        .object => |g| {
            if (got != .object) {
                fail("{s}: not an object", .{where});
                return false;
            }
            if (got.object.count() != g.count()) {
                fail("{s}: {d} keys, gold {d}", .{ where, got.object.count(), g.count() });
                return false;
            }
            var it = g.iterator();
            while (it.next()) |e| {
                var buf: [256]u8 = undefined;
                const at = std.fmt.bufPrint(&buf, "{s}.{s}", .{ where, e.key_ptr.* }) catch where;
                const o = got.object.get(e.key_ptr.*) orelse {
                    fail("{s}: missing", .{at});
                    return false;
                };
                if (!same(at, o, e.value_ptr.*, floats)) return false;
            }
            return true;
        },
        .number_string => {},
    }
    fail("{s}: differs from the gold", .{where});
    return false;
}

fn close(gold: f64, got: f64) bool {
    return @abs(gold - got) <= 1e-9 + @abs(gold) * 1e-12;
}

fn field(v: Value, key: []const u8) Value {
    return v.object.get(key) orelse std.debug.panic("gold_check: no `{s}` in an answer", .{key});
}

pub fn main() !void {
    const alloc = std.heap.smp_allocator;
    var threaded = std.Io.Threaded.init(alloc, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const raw = try std.Io.Dir.cwd().readFileAlloc(io, "solver_gold.json", alloc, .unlimited);
    const raw_frames = try std.Io.Dir.cwd().readFileAlloc(io, "solver_frames_gold.json", alloc, .unlimited);
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const a = arena.allocator();
    const gold = (try std.json.parseFromSlice(Value, a, raw, .{})).value;
    const frames_gold = (try std.json.parseFromSlice(Value, a, raw_frames, .{})).value;
    const shifts = field(gold, "shifts").array.items;
    const frames_shifts = field(frames_gold, "shifts").array.items;
    if (shifts.len != frames_shifts.len or shifts.len == 0) std.debug.panic("gold_check: {d} shifts in solver_gold.json, {d} in the frames gold", .{ shifts.len, frames_shifts.len });

    var map_checked = false;
    var frames_checked: usize = 0;
    for (shifts, frames_shifts) |gshift, fshift| {
        const before = fail_count;
        const shift_no = field(gshift, "shift").integer;
        const seed: u32 = @intCast(field(gshift, "seed").integer);
        if (field(fshift, "seed").integer != seed) std.debug.panic("gold_check: the two gold files' shifts are out of step", .{});

        const g_bytes = seam.gold(seed);
        const got = (try std.json.parseFromSlice(Value, a, seam.slice(g_bytes), .{ .allocate = .alloc_always })).value;
        if (!map_checked) {
            _ = same("fleet", field(got, "fleet"), field(gold, "fleet"), .exact);
            _ = same("raceVariants", field(got, "raceVariants"), field(gold, "raceVariants"), .exact);
            _ = same("substrate", field(got, "substrate"), field(gold, "substrate"), .exact);
            std.debug.print("map: fleet, race variants, substrate {s}\n", .{if (fail_count == before) "OK" else "DIVERGED"});
            map_checked = true;
        }
        const gs = field(got, "shift");
        var buf: [32]u8 = undefined;
        const tag = std.fmt.bufPrint(&buf, "S{d}", .{shift_no}) catch unreachable;
        for ([_][]const u8{ "seed", "demand", "race", "routes", "totalPain" }) |k| {
            var kb: [64]u8 = undefined;
            _ = same(std.fmt.bufPrint(&kb, "{s}.{s}", .{ tag, k }) catch unreachable, field(gs, k), field(gshift, k), .exact);
        }
        if (gs.object.count() != 5) fail("{s}: the Roc's gold has {d} keys, not 5", .{ tag, gs.object.count() });

        const p_bytes = seam.plan(seed);
        const plan = (try std.json.parseFromSlice(Value, a, seam.slice(p_bytes), .{ .allocate = .alloc_always })).value;
        const proutes = field(plan, "routes").array.items;
        const groutes = field(gshift, "routes").array.items;
        const froutes = field(fshift, "routes").array.items;
        if (proutes.len != groutes.len or proutes.len != froutes.len) {
            fail("{s}: the plan has {d} routes, gold {d}", .{ tag, proutes.len, groutes.len });
        } else for (proutes, groutes, froutes, 0..) |pr, gr, fr, i| {
            var kb: [64]u8 = undefined;
            // The page's stops carry `orders`; the core gold's don't.
            for (field(pr, "stops").array.items, 0..) |s, si| {
                var stop = try s.object.clone(a);
                _ = stop.orderedRemove("orders");
                const gstops = field(gr, "stops").array.items;
                if (si >= gstops.len) break;
                _ = same(std.fmt.bufPrint(&kb, "{s}.plan.routes[{d}].stops[{d}]", .{ tag, i, si }) catch unreachable, .{ .object = stop }, gstops[si], .exact);
            }
            if (field(pr, "stops").array.items.len != field(gr, "stops").array.items.len) fail("{s}: plan truck {d} stops differ in number", .{ tag, i + 1 });
            for ([_][]const u8{ "orders", "travel", "time" }) |k| {
                _ = same(std.fmt.bufPrint(&kb, "{s}.plan.routes[{d}].{s}", .{ tag, i, k }) catch unreachable, field(pr, k), field(fr, k), if (std.mem.eql(u8, k, "time")) .ulp else .exact);
            }
        }
        for ([_][]const u8{ "travel", "service" }) |k| {
            var kb: [64]u8 = undefined;
            _ = same(std.fmt.bufPrint(&kb, "{s}.plan.{s}", .{ tag, k }) catch unreachable, field(plan, k), field(fshift, k), .exact);
        }
        for ([_][]const u8{ "totalTime", "local", "spread" }) |k| {
            var kb: [64]u8 = undefined;
            _ = same(std.fmt.bufPrint(&kb, "{s}.plan.{s}", .{ tag, k }) catch unreachable, field(plan, k), field(fshift, k), .ulp);
        }
        var fb: [64]u8 = undefined;
        if (same(std.fmt.bufPrint(&fb, "{s}.plan.frames", .{tag}) catch unreachable, field(plan, "frames"), field(fshift, "frames"), .exact)) {
            frames_checked += field(fshift, "frames").array.items.len;
        }
        if (field(plan, "unrouted").array.items.len != 0) fail("{s}: the plan leaves stops unrouted", .{tag});
        if (field(plan, "log").array.items.len != 0) fail("{s}: the plan's log is not empty", .{tag});

        std.debug.print("{s} (seed {d}): {s}\n", .{ tag, seed, if (fail_count == before) "OK" else "DIVERGED" });
    }

    if (fail_count > 0) {
        std.debug.print("\n{d} DIVERGENCE(S) from the gold corpus\n", .{fail_count});
        std.process.exit(1);
    }
    std.debug.print("\nGOLD: {d}/{d} shifts match, {d} frames, substrate and fleet\n", .{ shifts.len, shifts.len, frames_checked });
}
