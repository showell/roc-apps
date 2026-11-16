//! Times a shift's solve natively, the Zig reference solver (zig/) against
//! the Roc, over the 20 gold seeds, each solved `rounds` times (the first
//! argument, 3 unset), and prints both totals and their ratio. Each side
//! does what the page's solveShift does: the day's draw and the race with
//! its replay recorded. The Zig side leaves out the JSON the Roc's answer
//! includes, which costs it well under a millisecond.
//!
//!   zig build bench [-- rounds]

const std = @import("std");
const reference = @import("reference");
const seam = @import("roc_seam.zig");

const seeds = [_]u32{ 49, 1095465948, 3105482123, 1590164846, 2068751861, 175767248, 1115145199, 1995186306, 2282907129, 1867536132, 1704130195, 125766358, 1259979837, 2061711480, 2251334007, 836472938, 1517913281, 911775532, 242624667, 62899518 };

var rec: reference.solver.Recorder = undefined;

fn nowNs(io: std.Io) i96 {
    return std.Io.Clock.awake.now(io).nanoseconds;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var args = init.minimal.args.iterate();
    _ = args.next();
    const rounds: usize = if (args.next()) |a| try std.fmt.parseInt(usize, a, 10) else 3;

    const sub = reference.roadgraph.buildSubstrate();
    var zig_ns: i96 = 0;
    var roc_ns: i96 = 0;
    var check: i64 = 0;
    for (0..rounds) |_| {
        for (seeds) |seed| {
            const z0 = nowNs(io);
            const demand = reference.orders.chooseOrders(seed, reference.geography.ORDERS);
            const result = reference.solver.race(&sub, &demand, &rec);
            const z1 = nowNs(io);
            check +%= result.best.pain(&sub);
            const r0 = nowNs(io);
            const plan = seam.plan(seed);
            const r1 = nowNs(io);
            check +%= @intCast(plan.length);
            seam.release(plan);
            zig_ns += z1 - z0;
            roc_ns += r1 - r0;
        }
    }
    const n: f64 = @floatFromInt(rounds * seeds.len);
    const zig_ms = @as(f64, @floatFromInt(zig_ns)) / 1e6 / n;
    const roc_ms = @as(f64, @floatFromInt(roc_ns)) / 1e6 / n;
    std.debug.print("native, {d} solves each: Zig {d:.1} ms a shift, Roc {d:.1} ms a shift, Roc/Zig {d:.2}x (check {d})\n", .{ rounds * seeds.len, zig_ms, roc_ms, roc_ms / zig_ms, check });
}
