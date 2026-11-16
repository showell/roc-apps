//! The physics' text: a tick's checked lines written in their one
//! canonical form, and a park's entries written and parsed back to the
//! same integers, every other spelling of them refused.

const std = @import("std");
const physics = @import("physics.zig");
const wire = @import("physics_wire.zig");
const testing = std.testing;
const Text = wire.Text;
const fuzz = @import("test_options").fuzz;

fn written(line: wire.Line, buf: []u8) []const u8 {
    var w: Text = .{ .buf = buf };
    wire.write(&w, line) catch unreachable;
    return w.bytes();
}

/// The one entry a park's line holds, read on the largest level's world.
fn entryOf(text: []const u8) wire.ParseError!wire.Entry {
    var e = wire.Entries.of(physics.room, text);
    const one = (try e.next()) orelse return error.Malformed;
    if (try e.next() != null) return error.Malformed;
    return one;
}

fn refused(text: []const u8) !void {
    if (entryOf(text)) |_| {
        std.debug.print("read, and should not have been: \"{s}\"\n", .{text});
        return error.TestUnexpectedResult;
    } else |_| {}
}

test "the canonical numbers: d80.40 is 3456.25 px; 0.00" {
    var buf: [64]u8 = undefined;
    var w: Text = .{ .buf = &buf };
    try w.hexPoint(3456 * 256 + 64);
    try w.char(' ');
    try w.hexPoint(0);
    try w.char(' ');
    try w.pos(.{ .x = 255, .y = 256 });
    try testing.expectEqualStrings("d80.40 0.00 0.ff,1.00", w.bytes());
    try testing.expectEqual(@as(u32, 3456 * 256 + 64), try wire.parseHexPoint("d80.40", std.math.maxInt(u32)));
    try testing.expectEqual(@as(u32, 0), try wire.parseHexPoint("0.00", 0));
    try testing.expectError(error.Malformed, wire.parseHexPoint("1.00", 255));
}

test "every kind of line, in its one form: a tick's checked lines, and a report's header, from, grab and t lines" {
    var buf: [256]u8 = undefined;
    var drag: physics.Capped = .{};
    drag.list[0] = .{ .dx = -256, .dy = 0, .ms = 3 };
    drag.list[1] = .{ .dx = physics.cap, .dy = -1, .ms = 0 };
    drag.len = 2;
    for ([_]struct { wire.Line, []const u8 }{
        .{ .{ .header = .{ .language = wire.language, .physics = 0x5e0c91a2, .epoch = .{ .ms = 1791935990000, .count = 3 }, .req = 4 } }, "dogpark 2 physics 5e0c91a2 page 1791935990000.3 req 4\n" },
        .{ .{ .header = .{ .language = 1, .physics = 1, .epoch = .{ .ms = 1, .count = 1 }, .req = 1 } }, "dogpark 1 physics 00000001 page 1.1 req 1\n" },
        .{ .{ .from = .{ .tick = 1040, .wall = 1791936000000 } }, "from 1040 wall 1791936000000\n" },
        .{ .{ .from = .{ .tick = 0, .wall = null } }, "from 0\n" },
        .{ .{ .grab = 7 }, "grab 7\n" },
        .{ .{ .t = .{ .tick = 1041, .ms = 0, .drag = drag } }, "t 1041 +0 drag -1.00,0@3 +64.00,-0.01@0\n" },
        .{ .{ .t = .{ .tick = 1042, .ms = 63, .drag = .{} } }, "t 1042 +63\n" },
        .{ .{ .critter = .{ .who = .of(.dog, 23), .before = .{ .x = 0x45100, .y = 0x3e800 }, .after = .{ .x = 0x450f0, .y = 0x3e800 } } }, " dog 23 451.00,3e8.00 > 450.f0,3e8.00\n" },
        .{ .{ .critter = .{ .who = .of(.cow, 7), .before = .{ .x = 0, .y = 1 }, .after = .{ .x = 1, .y = 255 } } }, " cow 7 0.00,0.01 > 0.01,0.ff\n" },
        .{ .{ .poop = .{ .n = 12, .at = .{ .x = 0x10080, .y = 0x200 } } }, " poop 12 100.80,2.00\n" },
        .{ .{ .eaten = 2047 }, " eaten 2047\n" },
        .{ .{ .bump = .{ .tick = 5, .who = .{ .critter = .of(.cow, 0) } } }, "bump 5 cow 0\n" },
        .{ .{ .bump = .{ .tick = 6, .who = .{ .poop = 2047 } } }, "bump 6 poop 2047\n" },
        .{ .{ .release = .{ .tick = 1121, .dog = 49 } }, "release 1121 49\n" },
        .{ .{ .rest = 9 }, "rest 9\n" },
    }) |case| try testing.expectEqualStrings(case[1], written(case[0], &buf));
}

test "a park's entries, written and read back the same: critters (a dog with its walk) and poops, seeded" {
    var prng: std.Random.DefaultPrng = .init(29);
    const rand = prng.random();
    var b = physics.Board.empty();
    // A tenth on every edit; all of it in the slow tier.
    for (0..@as(usize, switch (fuzz) {
        .fast => 500,
        .full => 5000,
    })) |_| {
        const p = struct {
            fn any(r: std.Random) physics.Point {
                return .{ .x = r.intRangeLessThan(i32, 0, physics.room.world), .y = r.intRangeLessThan(i32, 0, physics.room.world) };
            }
        };
        const kind: physics.Kind = @fromBackingInt(@intCast(rand.uintLessThan(u32, physics.kind_count)));
        const who: physics.Critter = .of(kind, rand.uintLessThan(u16, physics.countOf(kind)));
        const at = p.any(rand);
        b.place(who, at);
        const walked: u32 = if (kind == physics.leashed_kind) rand.uintAtMost(u32, 1 << 24) else 0;
        if (kind == physics.leashed_kind) b.walked[who.n] = walked;
        var buf: [128]u8 = undefined;
        var w: Text = .{ .buf = &buf };
        try wire.entry(&w, &b, who);
        const back = try entryOf(w.bytes());
        try testing.expectEqual(who, back.critter.who);
        try testing.expectEqual(at, back.critter.at);
        try testing.expectEqual(walked, back.critter.walked);
        try testing.expectEqual(walked != 0, std.mem.indexOf(u8, w.bytes(), " walked ") != null);

        const n = rand.uintLessThan(u16, physics.poop_count);
        const there = p.any(rand);
        var pw: Text = .{ .buf = &buf };
        try wire.poopAt(&pw, n, there);
        const poop = try entryOf(pw.bytes());
        try testing.expectEqual(n, poop.poop.n);
        try testing.expectEqual(there, poop.poop.at);
    }
}

test "every other spelling of an entry is refused: padding, upper case, short or long fractions, stray spaces, leading zeros, past the world or the kind" {
    // The near miss: the canonical form reads.
    _ = try entryOf("dog 23 42d.00,46d.00 walked 3.00");
    _ = try entryOf("poop 3 0.00,0.00");
    for ([_][]const u8{
        "dog 23 042d.00,46d.00",
        "dog 23 42D.00,46d.00",
        "dog 23 42d.0,46d.00",
        "dog 23 42d.000,46d.00",
        "dog 23 42d,46d.00",
        "dog 23 .00,46d.00",
        "dog 23 00.00,46d.00",
        "dog 23 -1.00,46d.00",
        "dog 23 7d00.00,46d.00",
        "dog 23 42d.00 46d.00",
        "dog 23 42d.00,46d.00 ",
        " dog 23 42d.00,46d.00",
        "dog  23 42d.00,46d.00",
        "dog 023 42d.00,46d.00",
        "Dog 23 42d.00,46d.00",
        "horse 1 42d.00,46d.00",
        "dog 23",
        "dog 23 42d.00,46d.00 walked 0.00",
        "dog 23 42d.00,46d.00 walked",
        "dog 23 42d.00,46d.00 walked 03.00",
        "cow 1 42d.00,46d.00 walked 3.00",
        std.fmt.comptimePrint("dog {d} 42d.00,46d.00", .{physics.countOf(.dog)}),
        std.fmt.comptimePrint("cow {d} 42d.00,46d.00", .{physics.countOf(.cow)}),
        std.fmt.comptimePrint("poop {d} 0.00,0.00", .{physics.poop_count}),
        "poop 3 0.00",
        "poop 03 0.00,0.00",
        "",
    }) |text| try refused(text);
}

test "the lines of a text: split on \\n, a last line without one still a line, an empty line returned for the caller to refuse" {
    var it: wire.Lines = .{ .rest = "a\n\nb" };
    try testing.expectEqualStrings("a", it.next().?);
    try testing.expectEqualStrings("", it.next().?);
    try testing.expectEqualStrings("b", it.next().?);
    try testing.expectEqual(@as(?[]const u8, null), it.next());
}
