//! **THE PHYSICS ON THE PAGE** (`physics.wasm`, docs/PHYSICS.md): the
//! park's board and its tick, compiled to wasm32, behind exports the page's
//! engine (web/engine.js) calls; and the park written as text and read back
//! (`writePark`, `readPark`), which the page keeps in the browser.
//!
//! **ONE BOARD**, the park the page ticks and draws, on the level `reset`
//! names.
//!
//! **MEMORY THE PAGE SHARES:** `inBuf` (a park's text, written by the
//! page), `outBuf` (a line or a park, written here; each writer starts it
//! afresh and answers its length), `ints` (a drag's displacements, both
//! ways), and the board's critters and poops (`crittersAt`,
//! `crittersKnown`, every kind's by `kindBase` and `kindSize`; `poopsAt`,
//! `poopKnown`: x, y pairs of `i32` in 256ths, and one byte each, 1 when
//! the board has it).
//!
//! Ticks cross as `f64` (JavaScript's numbers; a tick fits in 2^53).

const std = @import("std");
const physics = @import("physics.zig");
const wire = @import("physics_wire.zig");
const tiles = @import("tiles.zig");
const Text = wire.Text;
const Tick = physics.Tick;
const Board = physics.Board;

var board: Board = Board.emptyAt(physics.last_level);
var begun: physics.Begun = .{};

/// A park's text is at most a line for every critter and every poop slot,
/// about 60 KiB; each buffer holds twice that.
var in_buf: [128 * 1024]u8 = undefined;
var out_buf: [128 * 1024]u8 = undefined;
/// Room for 4096 displacements (dx, dy, ms).
var ints_buf: [3 * 4096]i32 = undefined;
/// The tick a park read back named.
var park_tick: Tick = 0;
/// The last tick's flags and its displacements as merged and capped.
var flags: u32 = 0;
var capped_len: u32 = 0;
/// The last tick's walk: the critters it moved, by index among all, in
/// visit order (the page labels them 1 to `walk_most`).
var walk: [physics.walk_most]u16 = @splat(0);
var walk_len: u32 = 0;

pub const Flag = struct {
    pub const bump: u32 = 1;
    pub const rest: u32 = 2;
    pub const release: u32 = 4;
    pub const moved: u32 = 8;
};

fn tickOf(t: f64) Tick {
    return @intFromFloat(t);
}

// ── memory ──────────────────────────────────────────────────────────────────

/// The physics' clock: the page ticks every 1000 / this ms.
export fn ticksPerSecond() u32 {
    return physics.ticks_per_second;
}
export fn inBuf() [*]u8 {
    return &in_buf;
}
export fn inCap() u32 {
    return in_buf.len;
}
export fn outBuf() [*]u8 {
    return &out_buf;
}
export fn ints() [*]i32 {
    return &ints_buf;
}
export fn intsCap() u32 {
    return ints_buf.len;
}
export fn tilePx() u32 {
    return tiles.tile_px;
}
export fn worldTiles() u32 {
    return @intCast(board.geometry().world_tiles);
}
export fn poopPx() u32 {
    return physics.poop_px;
}
export fn breeds() u32 {
    return physics.breeds;
}
/// **THE CRITTERS, KIND-BLIND**: how many kinds; each kind's count, square
/// and where its critters begin among all; and every critter's point (x,
/// y) and whether the board has it, by index among all (physics.zig's
/// `critterIndex`): the page reads its kinds from here and world.js, and
/// names none.
export fn kindCount() u32 {
    return physics.kind_count;
}
export fn kindSize(k: u32) u32 {
    return physics.counts[k];
}
export fn kindBase(k: u32) u32 {
    return physics.bases[k];
}
export fn kindPx(k: u32) u32 {
    return physics.kinds[k].px;
}
export fn critterCount() u32 {
    return physics.critter_count;
}
export fn crittersAt() [*]i32 {
    return @ptrCast(&board.points);
}
export fn crittersKnown() [*]u8 {
    return @ptrCast(&board.known_at);
}
export fn poopCount() u32 {
    return physics.poop_count;
}
export fn poopsAt() [*]i32 {
    return @ptrCast(&board.poops);
}
export fn poopKnown() [*]u8 {
    return @ptrCast(&board.poop_known);
}

// ── the board ───────────────────────────────────────────────────────────────

/// A new game of level `level` (Level One is 0): its first layout,
/// nothing leashed.
export fn reset(level: u32) void {
    if (level >= physics.level_count) @panic("reset: no such level");
    board = Board.laidOutAt(@intCast(level));
    begun = .{};
}

/// The leashed dog, or -1.
export fn leashedDog() i32 {
    return if (board.leashedDog()) |d| d else -1;
}

/// The drag: -1 with nothing leashed, -2 while it is on, or the tick it
/// ended.
export fn dragOf() f64 {
    return switch (board.hold) {
        .none => -1,
        .leashed => |l| switch (l.drag) {
            .on => -2,
            .ended => |e| @floatFromInt(e),
        },
    };
}

fn out() Text {
    return .{ .buf = &out_buf };
}

/// The human's kinds of input, as the page names them.
pub const HumanKind = enum(u32) { release = 0, leash = 1, grab = 2, letgo = 3 };

fn humanOf(kind: u32, dog: u32) physics.Human {
    return switch (@as(HumanKind, @fromBackingInt(@intCast(kind)))) {
        .release => .{ .release = @intCast(dog) },
        .leash => .{ .leash = @intCast(dog) },
        .grab => .grab,
        .letgo => .letgo,
    };
}

/// **ONE OF THE HUMAN'S INPUTS** for the next tick, applied to the board
/// (its inputs begun): 0, or -1 less the refusal (physics.Refusal) when
/// its precondition fails, the board unchanged.
export fn human(kind: u32, dog: u32) i32 {
    const h = humanOf(kind, dog);
    if (h != .grab and h != .letgo and dog >= physics.countOf(physics.leashed_kind)) return -1 - @as(i32, @backingInt(physics.Refusal.leash_no_such_dog));
    if (physics.input(&board, &begun, h)) |r| return -1 - @as(i32, @backingInt(r));
    return 0;
}

/// The displacements in `ints`, `n` triples (dx, dy in 256ths, `@ms`).
var raw_disps: [4096]physics.Disp = undefined;

fn disps(n: u32) physics.Capped {
    const raw = &raw_disps;
    const m = @min(n, raw.len);
    for (0..m) |i| raw[i] = .{ .dx = ints_buf[3 * i], .dy = ints_buf[3 * i + 1], .ms = @intCast(@max(0, ints_buf[3 * i + 2])) };
    return physics.mergeAndCap(raw[0..m]);
}

/// A tick's checked lines (kept here, not on the stack: they hold room for
/// every poop slot).
var tick_lines: physics.Lines = .{};

/// **ONE TICK**: its inputs are those begun; the drag is the `n`
/// displacements in `ints` (dx, dy, ms triples, as the pointer made them),
/// merged and capped here and written back to `ints` (`cappedLen` of
/// them). Writes the tick's checked lines and answers their length;
/// `tickFlags` says what happened.
export fn tick(t: f64, n: u32) u32 {
    const drag = disps(n);
    const tk = tickOf(t);
    physics.run(&board, tk, begun, drag.slice(), &tick_lines);
    begun = .{};
    walk_len = @intCast(tick_lines.walk_len);
    @memcpy(walk[0..tick_lines.walk_len], tick_lines.walk[0..tick_lines.walk_len]);
    flags = 0;
    var o = out();
    for (tick_lines.slice()) |c| {
        switch (c) {
            .critter, .poop, .eaten => flags |= Flag.moved,
            .bump => flags |= Flag.bump,
            .release => flags |= Flag.release,
            .rest => flags |= Flag.rest,
        }
        wire.write(&o, wire.checkedLine(tk, c)) catch unreachable;
    }
    for (drag.slice(), 0..) |d, i| {
        ints_buf[3 * i] = d.dx;
        ints_buf[3 * i + 1] = d.dy;
        ints_buf[3 * i + 2] = @intCast(d.ms);
    }
    capped_len = @intCast(drag.len);
    return @intCast(o.len);
}

export fn tickFlags() u32 {
    return flags;
}

export fn walkLen() u32 {
    return walk_len;
}

export fn walkAt() [*]u16 {
    return &walk;
}

export fn cappedLen() u32 {
    return capped_len;
}

// ── the park, kept ──────────────────────────────────────────────────────────

/// The park text's first line. A park of another version does not read.
const park_header = "dogpark park 1";

/// **THE PARK AS TEXT**, into `outBuf`, its length answered: a line each,
/// the header, the level (1-based), tick `t` (the last the page ran), the
/// poops laid since the layout, every present critter in rank order (a
/// dog with its walk), each poop by number, and `end`. The leash is not
/// in it: a park read back has nothing leashed, as a new page load has.
export fn writePark(t: f64) u32 {
    var w = out();
    writeParkText(&w, tickOf(t)) catch unreachable;
    return @intCast(w.len);
}

fn writeParkText(w: *Text, t: Tick) Text.Error!void {
    try w.str(park_header);
    try w.str("\nlevel ");
    try w.dec(@as(u64, board.level) + 1);
    try w.str("\ntick ");
    try w.dec(t);
    try w.str("\nlaid ");
    try w.dec(board.laid);
    try w.char('\n');
    for (physics.ranked) |c| {
        if (board.known(c) != .present) continue;
        try wire.entry(w, &board, c);
        try w.char('\n');
    }
    for (board.poops, board.poop_known, 0..) |p, k, i| {
        if (k != .present) continue;
        try wire.poopAt(w, @intCast(i), p);
        try w.char('\n');
    }
    try w.str("end\n");
}

/// Why a park's text is not taken.
pub const ParkRefusal = enum(u32) {
    /// Not a park as `writePark` writes it.
    unreadable = 0,
    /// A park of another level than the board's.
    other_level = 1,
    /// Not the critters the level lays out: a park of another world.
    other_critters = 2,
    /// Two critters overlap, or one stands on a poop: never so in play.
    overlapping = 3,
};

/// **A PARK READ BACK** from the `len` bytes in `inBuf`, onto the board's
/// level: 0, the board now that park with nothing leashed and its tick in
/// `parkTick`; or -1 less the refusal (ParkRefusal), the board unchanged.
export fn readPark(len: u32) i32 {
    const text = in_buf[0..@min(len, in_buf.len)];
    const read = parkOf(text, board.level) catch |e| return -1 - @as(i32, @intCast(@backingInt(refusalOf(e))));
    board = read.board;
    begun = .{};
    park_tick = read.tick;
    return 0;
}

export fn parkTick() f64 {
    return @floatFromInt(park_tick);
}

const ParkError = error{ Unreadable, OtherLevel, OtherCritters, Overlapping };

fn refusalOf(e: ParkError) ParkRefusal {
    return switch (e) {
        error.Unreadable => .unreadable,
        error.OtherLevel => .other_level,
        error.OtherCritters => .other_critters,
        error.Overlapping => .overlapping,
    };
}

const Park = struct { board: Board, tick: Tick };

/// The park a text holds, on `level`: every line as `writeParkText` writes
/// it, each present critter once, in rank order, then the poops by rising
/// number; exactly the critters the level lays out, none overlapping
/// another or a poop.
fn parkOf(text: []const u8, level: physics.Level) ParkError!Park {
    var lines: wire.Lines = .{ .rest = text };
    if (!std.mem.eql(u8, lines.next() orelse "", park_header)) return error.Unreadable;
    const named = try decAfter(lines.next(), "level ", physics.level_count);
    if (named == 0) return error.Unreadable;
    if (named - 1 != level) return error.OtherLevel;
    var b = Board.emptyAt(level);
    const t = try decAfter(lines.next(), "tick ", std.math.maxInt(u32));
    b.laid = @intCast(try decAfter(lines.next(), "laid ", std.math.maxInt(u32)));
    var last_rank: ?u32 = null;
    var last_poop: ?u16 = null;
    while (true) {
        const line = lines.next() orelse return error.Unreadable;
        if (std.mem.eql(u8, line, "end")) break;
        var e = wire.Entries.of(b.geometry(), line);
        const one = (e.next() catch return error.Unreadable) orelse return error.Unreadable;
        if ((e.next() catch return error.Unreadable) != null) return error.Unreadable;
        switch (one) {
            .critter => |cr| {
                const r = physics.rank(null, cr.who);
                if (last_poop != null or (last_rank != null and r <= last_rank.?)) return error.Unreadable;
                last_rank = r;
                b.place(cr.who, cr.at);
                if (cr.who.kind == physics.leashed_kind) b.walked[cr.who.n] = cr.walked;
            },
            .poop => |p| {
                if (last_poop != null and p.n <= last_poop.?) return error.Unreadable;
                last_poop = p.n;
                b.poops[p.n] = p.at;
                b.poop_known[p.n] = .present;
            },
        }
    }
    if (lines.next() != null) return error.Unreadable;
    const laid_out = Board.laidOutAt(level);
    if (!std.mem.eql(physics.Known, &b.known_at, &laid_out.known_at)) return error.OtherCritters;
    if (overlapping(&b)) return error.Overlapping;
    return .{ .board = b, .tick = t };
}

fn decAfter(line: ?[]const u8, word: []const u8, most: u64) ParkError!u64 {
    const l = line orelse return error.Unreadable;
    if (!std.mem.startsWith(u8, l, word)) return error.Unreadable;
    return wire.parseDec(l[word.len..], most) catch error.Unreadable;
}

/// Whether any two of the board's critters overlap, or one stands on a
/// poop: `physics.overlaps`, which sees the critters from a leashed dog
/// (the region is the whole world, wherever it stands), so the first dog
/// is leashed for the look and the board left as it was.
fn overlapping(b: *Board) bool {
    const dog = for (b.knownOf(physics.leashed_kind), 0..) |k, i| {
        if (k == .present) break i;
    } else return false;
    b.hold = .{ .leashed = .{ .dog = @intCast(dog), .drag = .on } };
    defer b.hold = .none;
    var found: [1][2]physics.Critter = undefined;
    return physics.overlaps(b, &found) > 0;
}

// ── tests ───────────────────────────────────────────────────────────────────

const testing = std.testing;

/// A park's text into `inBuf`, as the page writes it there.
fn putPark(text: []const u8) u32 {
    @memcpy(in_buf[0..text.len], text);
    return @intCast(text.len);
}

const the_dog: u16 = 25;

/// Dog `dog` leashed on Level Two's layout and dragged `n` ticks, `dx` px
/// east a tick, then let go and left until the leash comes off: a park
/// with poops laid, dogs walked and chickens moved.
fn playedPark(dog: u16, n: u32, dx: i32) Tick {
    reset(physics.last_level);
    _ = human(@backingInt(HumanKind.leash), dog);
    var t: Tick = 1;
    while (t <= n) : (t += 1) {
        // A bump ends the drag: the dog is grabbed again, as a player would.
        if (board.hold == .leashed and board.hold.leashed.drag != .on) _ = human(@backingInt(HumanKind.grab), 0);
        ints_buf[0] = physics.px(dx);
        ints_buf[1] = physics.px(1);
        ints_buf[2] = 5;
        _ = tick(@floatFromInt(t), 1);
    }
    _ = human(@backingInt(HumanKind.letgo), 0);
    while (board.hold != .none) : (t += 1) _ = tick(@floatFromInt(t), 0);
    return t - 1;
}

fn parkText(t: Tick) []const u8 {
    return out_buf[0..writePark(@floatFromInt(t))];
}

test "reset lays out the level, nothing leashed; each level's own critters" {
    reset(0);
    try testing.expectEqualDeep(Board.laidOutAt(0), board);
    try testing.expectEqual(@as(i32, -1), leashedDog());
    try testing.expectEqual(@as(f64, -1), dragOf());
    reset(physics.last_level);
    try testing.expectEqualDeep(Board.laidOut(), board);
    try testing.expect(!std.mem.eql(physics.Known, &Board.laidOutAt(0).known_at, &board.known_at));
}

test "a park written and read back is the board it was, with its tick, its poops and each dog's walk; a leashed dog is let go" {
    const t = playedPark(the_dog, 150, 8);
    try testing.expect(board.laid > 0);
    try testing.expect(board.walked[the_dog] != 0);
    const was = board;
    const text = try testing.allocator.dupe(u8, parkText(t));
    defer testing.allocator.free(text);
    try testing.expect(std.mem.startsWith(u8, text, "dogpark park 1\nlevel 2\ntick "));
    try testing.expect(std.mem.endsWith(u8, text, "\nend\n"));
    reset(physics.last_level);
    try testing.expectEqual(@as(i32, 0), readPark(putPark(text)));
    try testing.expectEqualDeep(was, board);
    try testing.expectEqual(@as(f64, @floatFromInt(t)), parkTick());
    // Written again, the same bytes.
    try testing.expectEqualStrings(text, parkText(t));

    // Written while a dog is leashed and dragged: read back, nothing is.
    _ = human(@backingInt(HumanKind.leash), 3);
    ints_buf[0] = physics.px(4);
    ints_buf[1] = 0;
    ints_buf[2] = 0;
    _ = tick(@floatFromInt(t + 1), 1);
    try testing.expectEqual(@as(i32, 3), leashedDog());
    var leashed = board;
    const held = try testing.allocator.dupe(u8, parkText(t + 1));
    defer testing.allocator.free(held);
    reset(physics.last_level);
    try testing.expectEqual(@as(i32, 0), readPark(putPark(held)));
    try testing.expectEqual(@as(i32, -1), leashedDog());
    leashed.hold = .none;
    try testing.expectEqualDeep(leashed, board);
}

test "a park read back plays on as the board it was written from: the same lines, tick by tick" {
    const t = playedPark(7, 60, -4);
    const was = board;
    const text = try testing.allocator.dupe(u8, parkText(t));
    defer testing.allocator.free(text);
    var lines: [2]std.ArrayList(u8) = .{ .empty, .empty };
    defer for (&lines) |*l| l.deinit(testing.allocator);
    for (&lines, 0..) |*l, side| {
        if (side == 0) board = was else {
            reset(physics.last_level);
            try testing.expectEqual(@as(i32, 0), readPark(putPark(text)));
        }
        _ = human(@backingInt(HumanKind.leash), 7);
        for (1..80) |k| {
            ints_buf[0] = physics.px(5);
            ints_buf[1] = physics.px(-2);
            ints_buf[2] = 0;
            try l.appendSlice(testing.allocator, out_buf[0..tick(@floatFromInt(t + k), 1)]);
        }
    }
    try testing.expect(lines[0].items.len > 1000);
    try testing.expectEqualStrings(lines[0].items, lines[1].items);
}

test "a park is refused, the board unchanged, when it is not a park, of another level, of other critters, or has critters overlapping" {
    const t = playedPark(the_dog, 150, 8);
    try testing.expect(board.laid > 0);
    const good = try testing.allocator.dupe(u8, parkText(t));
    defer testing.allocator.free(good);
    const refused = struct {
        fn check(text: []const u8, why: ParkRefusal) !void {
            reset(physics.last_level);
            const before = board;
            try testing.expectEqual(-1 - @as(i32, @intCast(@backingInt(why))), readPark(putPark(text)));
            try testing.expectEqualDeep(before, board);
        }
    };
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(testing.allocator);
    const edited = struct {
        fn of(b: *std.ArrayList(u8), text: []const u8, from: []const u8, to: []const u8) ![]const u8 {
            b.clearRetainingCapacity();
            const at = std.mem.indexOf(u8, text, from) orelse return error.NotInText;
            try b.appendSlice(testing.allocator, text[0..at]);
            try b.appendSlice(testing.allocator, to);
            try b.appendSlice(testing.allocator, text[at + from.len ..]);
            return b.items;
        }
    };
    // The near miss: the text as written reads.
    reset(physics.last_level);
    try testing.expectEqual(@as(i32, 0), readPark(putPark(good)));

    try refused.check("", .unreadable);
    try refused.check("dogpark park 2\n", .unreadable);
    try refused.check(good[0 .. good.len - 4], .unreadable);
    try refused.check(try edited.of(&buf, good, "\nend\n", "\nend\nend\n"), .unreadable);
    try refused.check(try edited.of(&buf, good, "\nlaid ", "\nlaid x"), .unreadable);
    // A critter out of rank order, and a position past the world.
    try refused.check(try edited.of(&buf, good, "dog 0 ", "dog 1 0.00,0.00\ndog 0 "), .unreadable);
    try refused.check(try edited.of(&buf, good, "\ncow 0 ", "\ncow 0 fffff.00,0.00\ncow 9999 "), .unreadable);
    // Level One's park on Level Two's board.
    try refused.check(try edited.of(&buf, good, "level 2", "level 1"), .other_level);
    // A cow missing.
    {
        const at = std.mem.indexOf(u8, good, "\ncow 0 ").? + 1;
        const eol = std.mem.indexOfScalarPos(u8, good, at, '\n').? + 1;
        buf.clearRetainingCapacity();
        try buf.appendSlice(testing.allocator, good[0..at]);
        try buf.appendSlice(testing.allocator, good[eol..]);
        try refused.check(buf.items, .other_critters);
    }
    // Cow 0 where cow 1 stands.
    {
        const c1 = std.mem.indexOf(u8, good, "\ncow 1 ").? + "\ncow 1 ".len;
        const c1_end = std.mem.indexOfAnyPos(u8, good, c1, " \n").?;
        const c0 = std.mem.indexOf(u8, good, "\ncow 0 ").? + "\ncow 0 ".len;
        const c0_end = std.mem.indexOfAnyPos(u8, good, c0, " \n").?;
        buf.clearRetainingCapacity();
        try buf.appendSlice(testing.allocator, good[0..c0]);
        try buf.appendSlice(testing.allocator, good[c1..c1_end]);
        try buf.appendSlice(testing.allocator, good[c0_end..]);
        try refused.check(buf.items, .overlapping);
    }
    // A poop under dog 0.
    {
        const d0 = std.mem.indexOf(u8, good, "\ndog 0 ").? + "\ndog 0 ".len;
        const d0_end = std.mem.indexOfAnyPos(u8, good, d0, " \n").?;
        const poop = std.mem.indexOf(u8, good, "\npoop ").? + 1;
        const n_end = std.mem.indexOfScalarPos(u8, good, poop + "poop ".len, ' ').? + 1;
        const eol = std.mem.indexOfScalarPos(u8, good, n_end, '\n').?;
        buf.clearRetainingCapacity();
        try buf.appendSlice(testing.allocator, good[0..n_end]);
        try buf.appendSlice(testing.allocator, good[d0..d0_end]);
        try buf.appendSlice(testing.allocator, good[eol..]);
        try refused.check(buf.items, .overlapping);
    }
}

test "a refused input leaves the board and writes nothing" {
    reset(physics.last_level);
    try testing.expectEqual(@as(i32, -1 - @as(i32, @backingInt(physics.Refusal.grab_unleashed))), human(@backingInt(HumanKind.grab), 0));
    try testing.expectEqual(@as(i32, 0), human(@backingInt(HumanKind.leash), 4));
    try testing.expectEqual(@as(i32, -1 - @as(i32, @backingInt(physics.Refusal.leash_while_leashed))), human(@backingInt(HumanKind.leash), 5));
    try testing.expectEqual(@as(i32, 4), leashedDog());
    // A dog Level One does not lay out can't be leashed there.
    reset(0);
    const absent = for (board.knownOf(physics.leashed_kind), 0..) |k, i| {
        if (k == .absent) break i;
    } else unreachable;
    try testing.expectEqual(@as(i32, -1 - @as(i32, @backingInt(physics.Refusal.leash_no_such_dog))), human(@backingInt(HumanKind.leash), @intCast(absent)));
    try testing.expectEqual(@as(i32, -1), leashedDog());
}
