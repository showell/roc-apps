//! Times a shift's solve natively, the Roc, over the 20 gold seeds, each
//! solved `rounds` times (the first argument, 3 unset), and prints the time a
//! shift, summing each seed's fastest solve (the least disturbed by other
//! work on the box). Each solve does what the page's solveShift does: the
//! day's draw, the race with its replay recorded, and the JSON.
//!
//!   zig build bench [-- rounds]

const std = @import("std");
const seam = @import("roc_seam.zig");

const seeds = [_]u32{ 49, 1095465948, 3105482123, 1590164846, 2068751861, 175767248, 1115145199, 1995186306, 2282907129, 1867536132, 1704130195, 125766358, 1259979837, 2061711480, 2251334007, 836472938, 1517913281, 911775532, 242624667, 62899518 };

fn nowNs(io: std.Io) i96 {
    return std.Io.Clock.awake.now(io).nanoseconds;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var args = init.minimal.args.iterate();
    _ = args.next();
    const rounds: usize = if (args.next()) |a| try std.fmt.parseInt(usize, a, 10) else 3;

    var roc_best: [seeds.len]i96 = @splat(std.math.maxInt(i96));
    var check: i64 = 0;
    for (0..rounds) |_| {
        for (seeds, 0..) |seed, i| {
            const r0 = nowNs(io);
            const plan = seam.plan(seed);
            const r1 = nowNs(io);
            check +%= @intCast(plan.length);
            roc_best[i] = @min(roc_best[i], r1 - r0);
        }
    }
    var roc_ns: i96 = 0;
    for (roc_best) |r| roc_ns += r;
    const n: f64 = @floatFromInt(rounds * seeds.len);
    const roc_ms = @as(f64, @floatFromInt(roc_ns)) / 1e6 / seeds.len;
    std.debug.print("native, best of {d} per seed: Roc {d:.1} ms a shift (check {d})\n", .{ rounds, roc_ms, check });
    std.debug.print("the Roc's allocations: {d:.0} a shift, {d:.1} MB a shift\n", .{ @as(f64, @floatFromInt(seam.allocations)) / n, @as(f64, @floatFromInt(seam.allocated_bytes)) / 1e6 / n });
}
