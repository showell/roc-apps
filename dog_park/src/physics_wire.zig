//! **THE PHYSICS' TEXT** (docs/PHYSICS.md, "The lines"): the one canonical
//! form of a tick's checked lines and of a park's entries, written here (the
//! page's JavaScript never formats a number of them), and the entries
//! parsed here, strictly: every other spelling is refused, and every field
//! is bounded as it is parsed.
//!
//! - **Positions** are hex with a point, in 256ths: the whole pixels in
//!   lower case with no leading zeros (`0` for none), a point, then exactly
//!   two hex digits: `d80.40`.
//! - **Displacements** add a sign, `+1.00`, `-2.80`, and are `0` when zero.
//! - **Everything else is decimal** with no leading zeros: ticks, `+ms`,
//!   `@ms`, critter and poop numbers.
//!
//! Besides a tick's lines, a run can be written as the report the page
//! once sent its server (a header, `from`, and each tick's `t` line and
//! inputs before its lines): `zig build physics-bench -- lines` ends with
//! one, so the drags as merged and capped are held byte for byte too.
//!
//! Lines are separated by `\n`. A critter line is indented one space.
//! No allocator: a `Text` writes into a caller's buffer.

const std = @import("std");
const physics = @import("physics.zig");
const Point = physics.Point;
const Critter = physics.Critter;
const Tick = physics.Tick;

/// The report's version, in its header.
pub const language = 2;

/// A caller's buffer, written into.
pub const Text = struct {
    buf: []u8,
    len: usize = 0,

    pub const Error = error{NoSpace};

    pub fn bytes(self: *const Text) []const u8 {
        return self.buf[0..self.len];
    }
    pub fn str(self: *Text, s: []const u8) Error!void {
        if (self.len + s.len > self.buf.len) return error.NoSpace;
        @memcpy(self.buf[self.len..][0..s.len], s);
        self.len += s.len;
    }
    pub fn char(self: *Text, c: u8) Error!void {
        return self.str(&.{c});
    }
    pub fn dec(self: *Text, v: u64) Error!void {
        var tmp: [20]u8 = undefined;
        var i: usize = tmp.len;
        var n = v;
        while (true) {
            i -= 1;
            tmp[i] = '0' + @as(u8, @intCast(n % 10));
            n /= 10;
            if (n == 0) break;
        }
        return self.str(tmp[i..]);
    }
    fn hexDigits(self: *Text, v: u64, min_digits: usize) Error!void {
        var tmp: [16]u8 = undefined;
        var i: usize = tmp.len;
        var n = v;
        while (n != 0 or tmp.len - i < min_digits) {
            i -= 1;
            tmp[i] = "0123456789abcdef"[@intCast(n & 15)];
            n >>= 4;
        }
        return self.str(tmp[i..]);
    }
    /// A non-negative count of 256ths: `d80.40`.
    pub fn hexPoint(self: *Text, v: u32) Error!void {
        try self.hexDigits(v >> 8, 1);
        try self.char('.');
        try self.hexDigits(v & 255, 2);
    }
    pub fn pos(self: *Text, p: Point) Error!void {
        try self.hexPoint(@intCast(p.x));
        try self.char(',');
        try self.hexPoint(@intCast(p.y));
    }
    /// A displacement: `0`, or a sign and a hex point.
    pub fn disp(self: *Text, v: i32) Error!void {
        if (v == 0) return self.char('0');
        try self.char(if (v < 0) '-' else '+');
        try self.hexPoint(@intCast(physics.mag(v)));
    }
    pub fn hash(self: *Text, h: u32) Error!void {
        return self.hexDigits(h, 8);
    }
    pub fn critter(self: *Text, c: Critter) Error!void {
        try self.str(@tagName(c.kind));
        try self.str(" ");
        try self.dec(c.n);
    }
};

/// A report's first line: the language, the physics, the page's epoch (a
/// start in Unix ms, a point, a count) and the request's number.
pub const Header = struct { language: u64, physics: u32, epoch: struct { ms: u64, count: u64 }, req: u64 };

/// One of a tick's checked lines, or of a report's other lines.
pub const Line = union(enum) {
    header: Header,
    from: struct { tick: Tick, wall: ?u64 },
    grab: Tick,
    t: struct { tick: Tick, ms: u64, drag: physics.Capped },
    release: struct { tick: Tick, dog: u16 },
    critter: physics.CritterLine,
    poop: physics.PoopLine,
    eaten: u16,
    bump: struct { tick: Tick, who: physics.Bumped },
    rest: Tick,
};

/// **WRITES A LINE**, canonically, with its `\n`.
pub fn write(w: *Text, line: Line) Text.Error!void {
    switch (line) {
        .header => |h| {
            try w.str("dogpark ");
            try w.dec(h.language);
            try w.str(" physics ");
            try w.hash(h.physics);
            try w.str(" page ");
            try w.dec(h.epoch.ms);
            try w.char('.');
            try w.dec(h.epoch.count);
            try w.str(" req ");
            try w.dec(h.req);
        },
        .from => |f| {
            try w.str("from ");
            try w.dec(f.tick);
            if (f.wall) |wall| {
                try w.str(" wall ");
                try w.dec(wall);
            }
        },
        .grab => |t| try tickOnly(w, "grab ", t),
        .t => |t| {
            try tickOnly(w, "t ", t.tick);
            try w.str(" +");
            try w.dec(t.ms);
            if (t.drag.len > 0) {
                try w.str(" drag");
                for (t.drag.slice()) |d| {
                    try w.char(' ');
                    try w.disp(d.dx);
                    try w.char(',');
                    try w.disp(d.dy);
                    try w.char('@');
                    try w.dec(d.ms);
                }
            }
        },
        .release => |r| try tickAndDog(w, "release ", r.tick, r.dog),
        .rest => |t| try tickOnly(w, "rest ", t),
        .critter => |c| {
            try w.char(' ');
            try critterMove(w, c);
        },
        .poop => |p| {
            try w.char(' ');
            try poopAt(w, p.n, p.at);
        },
        .eaten => |n| {
            try w.str(" eaten ");
            try w.dec(n);
        },
        .bump => |b| {
            try tickOnly(w, "bump ", b.tick);
            try w.char(' ');
            switch (b.who) {
                .critter => |c| try w.critter(c),
                .poop => |n| {
                    try w.str("poop ");
                    try w.dec(n);
                },
            }
        },
    }
    try w.char('\n');
}

/// `dog N a > b`, unindented.
pub fn critterMove(w: *Text, c: physics.CritterLine) Text.Error!void {
    try w.critter(c.who);
    try w.char(' ');
    try w.pos(c.before);
    try w.str(" > ");
    try w.pos(c.after);
}

/// `poop N x,y`, unindented: a line's, and a park's entry.
pub fn poopAt(w: *Text, n: u16, at: Point) Text.Error!void {
    try w.str("poop ");
    try w.dec(n);
    try w.char(' ');
    try w.pos(at);
}

/// A critter as a park's entry, unindented: `kind N x,y`, and a dog's walk
/// when it has walked (`walked H`, hex with a point).
pub fn entry(w: *Text, b: *const physics.Board, c: Critter) Text.Error!void {
    try w.critter(c);
    try w.char(' ');
    try w.pos(b.at(c));
    if (c.kind == physics.leashed_kind and b.walked[c.n] != 0) {
        try w.str(" walked ");
        try w.hexPoint(b.walked[c.n]);
    }
}

fn tickOnly(w: *Text, word: []const u8, t: Tick) Text.Error!void {
    try w.str(word);
    try w.dec(t);
}

fn tickAndDog(w: *Text, word: []const u8, t: Tick, dog: u16) Text.Error!void {
    try tickOnly(w, word, t);
    try w.char(' ');
    try w.dec(dog);
}

/// A tick's checked line as a line to write.
pub fn checkedLine(t: Tick, c: physics.Checked) Line {
    return switch (c) {
        .critter => |l| .{ .critter = l },
        .poop => |p| .{ .poop = p },
        .eaten => |n| .{ .eaten = n },
        .bump => |who| .{ .bump = .{ .tick = t, .who = who } },
        .release => |d| .{ .release = .{ .tick = t, .dog = d } },
        .rest => .{ .rest = t },
    };
}

// ---------------------------------------------------------------- parsing

pub const ParseError = error{Malformed};

/// The first `c` in `s`, byte by byte: a line's words are a few bytes to a
/// few dozen, where `std.mem.indexOfScalar`'s vector set-up costs more than
/// the scan.
fn find(s: []const u8, c: u8) ?usize {
    for (s, 0..) |b, i| if (b == c) return i;
    return null;
}

/// The words of a line, split on single spaces: an empty word (two spaces,
/// a leading or trailing one) is malformed.
const Words = struct {
    rest: []const u8,
    done: bool = false,

    fn next(self: *Words) ParseError![]const u8 {
        if (self.done) return error.Malformed;
        const at = find(self.rest, ' ');
        const word = if (at) |i| self.rest[0..i] else self.rest;
        if (at) |i| self.rest = self.rest[i + 1 ..] else self.done = true;
        if (word.len == 0) return error.Malformed;
        return word;
    }
    fn more(self: *const Words) bool {
        return !self.done;
    }
};

/// A canonical decimal: digits, no leading zero but `0` itself, at most
/// `most`.
pub fn parseDec(s: []const u8, most: u64) ParseError!u64 {
    if (s.len == 0 or s.len > 19) return error.Malformed;
    if (s[0] == '0' and s.len > 1) return error.Malformed;
    var v: u64 = 0;
    for (s) |c| {
        if (c < '0' or c > '9') return error.Malformed;
        v = v * 10 + (c - '0');
    }
    if (v > most) return error.Malformed;
    return v;
}

fn hexDigit(c: u8) ParseError!u32 {
    return switch (c) {
        '0'...'9' => c - '0',
        'a'...'f' => c - 'a' + 10,
        else => error.Malformed,
    };
}

/// A canonical hex point: `d80.40`, at most `most` 256ths.
pub fn parseHexPoint(s: []const u8, most: u32) ParseError!u32 {
    const dot = find(s, '.') orelse return error.Malformed;
    const whole = s[0..dot];
    const frac = s[dot + 1 ..];
    if (whole.len == 0 or whole.len > 6 or frac.len != 2) return error.Malformed;
    if (whole[0] == '0' and whole.len > 1) return error.Malformed;
    var v: u64 = 0;
    for (whole) |c| v = v * 16 + try hexDigit(c);
    for (frac) |c| v = v * 16 + try hexDigit(c);
    if (v > most) return error.Malformed;
    return @intCast(v);
}

/// A position in the board's level's world (`g`): `x,y`, each 0 to the
/// world's side, less 1/256.
pub fn parsePos(g: physics.Geometry, s: []const u8) ParseError!Point {
    const comma = find(s, ',') orelse return error.Malformed;
    const most: u32 = @intCast(g.world - 1);
    return .{ .x = @intCast(try parseHexPoint(s[0..comma], most)), .y = @intCast(try parseHexPoint(s[comma + 1 ..], most)) };
}

fn parseCritter(kind: []const u8, n: []const u8) ParseError!Critter {
    const k = std.meta.stringToEnum(physics.Kind, kind) orelse return error.Malformed;
    return .of(k, try parseNumber(n, physics.countOf(k)));
}

/// A critter's number among `count` of its kind: `0` to `count` - 1, and
/// none when there are none.
pub fn parseNumber(n: []const u8, count: u16) ParseError!u16 {
    if (count == 0) return error.Malformed;
    return @intCast(try parseDec(n, count - 1));
}

pub fn parsePoopNumber(n: []const u8) ParseError!u16 {
    return @intCast(try parseDec(n, physics.poop_count - 1));
}

/// A park's entry: a critter where it stands (and a dog's walk), or a poop.
pub const Entry = union(enum) {
    critter: struct { who: Critter, at: Point, walked: u32 },
    poop: struct { n: u16, at: Point },
};

/// The entries on the rest of a line, as `entry` and `poopAt` write them,
/// separated by single spaces.
pub const Entries = struct {
    w: Words,
    /// The board's level's geometry, which bounds the positions.
    g: physics.Geometry,

    pub fn of(g: physics.Geometry, rest: []const u8) Entries {
        return .{ .w = .{ .rest = rest, .done = rest.len == 0 }, .g = g };
    }
    pub fn next(self: *Entries) ParseError!?Entry {
        if (!self.w.more()) return null;
        const kind = try self.w.next();
        const n = try self.w.next();
        if (std.mem.eql(u8, kind, "poop")) return .{ .poop = .{ .n = try parsePoopNumber(n), .at = try parsePos(self.g, try self.w.next()) } };
        const who = try parseCritter(kind, n);
        const at = try parsePos(self.g, try self.w.next());
        var walked: u32 = 0;
        if (who.kind == physics.leashed_kind and self.w.more() and std.mem.startsWith(u8, self.w.rest, "walked ")) {
            _ = try self.w.next();
            walked = try parseHexPoint(try self.w.next(), std.math.maxInt(u32));
            if (walked == 0) return error.Malformed;
        }
        return .{ .critter = .{ .who = who, .at = at, .walked = walked } };
    }
};

/// The lines of a text, split on `\n`; a last line without one is still a
/// line, an empty line is malformed (`next` returns it for the caller to
/// refuse).
pub const Lines = struct {
    rest: []const u8,

    pub fn next(self: *Lines) ?[]const u8 {
        if (self.rest.len == 0) return null;
        const at = find(self.rest, '\n');
        const line = if (at) |i| self.rest[0..i] else self.rest;
        self.rest = if (at) |i| self.rest[i + 1 ..] else self.rest[self.rest.len..];
        return line;
    }
};

test {
    _ = @import("physics_wire_test.zig");
}
