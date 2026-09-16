//! The floor's host for the browser: core.zig's memory, screen, GPU, block
//! device and clock, and the exports the page calls. A crash, in the program or
//! the host, keeps its message for the page and stops the instance; the page
//! reads the message after the trap.
//!
//! The page gives a drive its image by asking for a buffer (`driveBuffer`),
//! writing the bytes into the host's memory at `drivePtr`, and the run's writes
//! land in that same buffer -- so the page can read the image back afterwards
//! and show what the program did to it.

const std = @import("std");
const core = @import("core.zig");

pub const allocator = std.heap.wasm_allocator;

const crash_cap: usize = 4096;
var crash_buf: [crash_cap]u8 = undefined;
var crash_len: usize = 0;

pub fn stop(msg: []const u8) noreturn {
    core.keep(&crash_buf, &crash_len, msg);
    @trap();
}

pub const panic = std.debug.FullPanic(panicImpl);
fn panicImpl(msg: []const u8, _: ?usize) noreturn {
    stop(msg);
}

comptime {
    core.exportSymbols();
}

/// The page's runner, told that a GPU flush ended a frame. It may read the
/// pixels, and it may throw to end the run there.
extern "env" fn frameFlushed() void;

pub fn flushed() void {
    frameFlushed();
}

/// The page's runner, asked for the file at a path: the size of what it found,
/// or -1 for nothing. It keeps the bytes until they are read.
extern "env" fn assetSize(path: [*]const u8, len: u32) i32;
/// The bytes the last assetSize found, into `dest`.
extern "env" fn assetRead(dest: [*]u8) void;

var asset_buf: []u8 = &.{};

/// The bytes of the file at `path`, as the runner finds it; null when there is
/// none. They are the host's until the next asset.
pub fn asset(path: []const u8) ?[]const u8 {
    const n = assetSize(path.ptr, @intCast(path.len));
    if (n < 0) return null;
    if (asset_buf.len > 0) allocator.free(asset_buf);
    asset_buf = allocator.alloc(u8, @intCast(n)) catch stop("no memory for an asset");
    assetRead(asset_buf.ptr);
    return asset_buf;
}

/// The wall clock in a page is the runner's, which hands it over before a run;
/// without one the virtual clock is all there is. A page that asks for the wall
/// clock has to keep `wallNs` moving.
pub export fn wallClock(on: u32, ns: u64) void {
    core.wall_clock = on != 0;
    wall_ns = ns;
}

var wall_ns: u64 = 0;

pub fn nowNs() u64 {
    return wall_ns;
}

/// A page cannot block, so a wall-clock wait in the browser does not sleep: it
/// answers the time it already reads, and the runner moves the clock between
/// runs. A program that needs to wait inside one run wants the virtual clock.
pub fn sleepNs(_: u64) void {}

// ---- the drives ----------------------------------------------------------

/// A buffer of `len` bytes for drive `p` (0 the master, 1 the slave), zeroed,
/// which the page fills in place at `drivePtr`. Answers where it is, or 0.
pub export fn driveBuffer(p: u32, len: u32) u32 {
    const buf = allocator.alloc(u8, len) catch return 0;
    @memset(buf, 0);
    if (!core.attach(p, buf)) {
        allocator.free(buf);
        return 0;
    }
    return @intCast(@intFromPtr(buf.ptr));
}

/// Drive `p`'s image as it stands, which is what the run left in it.
pub export fn drivePtr(p: u32) u32 {
    const d = core.image(p) orelse return 0;
    return @intCast(@intFromPtr(d.ptr));
}

pub export fn driveLen(p: u32) u32 {
    const d = core.image(p) orelse return 0;
    return @intCast(d.len);
}

// ---- the faults ----------------------------------------------------------

/// The fault plan for the next run: 0 none, 1 refuse-read, 2 refuse-write,
/// 3 tear-write; `every` transfers between bites, and `lba` a sector to confine
/// it to (`has_lba` says whether to).
pub export fn fault(kind: u32, every: u32, has_lba: u32, lba: u32) void {
    core.fault_kind = switch (kind) {
        1 => .refuse_read,
        2 => .refuse_write,
        3 => .tear_write,
        else => .none,
    };
    core.fault_every = if (every == 0) 1 else every;
    core.fault_lba = if (has_lba != 0) lba else null;
}

pub export fn faultsBitten() u32 {
    return @intCast(core.faults_bitten);
}

// ---- the run -------------------------------------------------------------

/// A scancode for the program's keyboard controller.
pub export fn key(scancode: u32) void {
    core.keyPush(@truncate(scancode));
}

/// The mouse at a screen position with these buttons down.
pub export fn mouse(x: u32, y: u32, buttons: u32) void {
    core.mousePush(x, y, buttons);
}

/// Runs the program once, from the memory the last run left. Answers its exit
/// code.
pub export fn run() i32 {
    crash_len = 0;
    core.startClock();
    return core.run();
}

/// A screen for the program (core.screen); 0 when the host cannot give it.
pub export fn screen(width: u32, height: u32, stride: u32) u32 {
    return if (core.screen(width, height, stride)) 1 else 0;
}

pub export fn clock(ms: u32) void {
    core.clock(ms);
}

/// The visible pixels, red, green, blue, opaque, and where they are.
pub export fn present() u32 {
    return @intCast(@intFromPtr(core.present().ptr));
}

pub export fn pagesMade() u32 {
    return core.pages_made;
}

pub export fn heapLoads() u32 {
    return @intCast(core.heap_loads);
}

pub export fn heapStores() u32 {
    return @intCast(core.heap_stores);
}

pub export fn sectorsRead() u32 {
    return @intCast(core.sectors_read);
}

pub export fn sectorsWritten() u32 {
    return @intCast(core.sectors_written);
}

pub export fn consolePtr() u32 {
    return @intCast(@intFromPtr(core.console().ptr));
}

pub export fn consoleLen() u32 {
    return @intCast(core.console().len);
}

pub export fn crashPtr() u32 {
    return @intCast(@intFromPtr(&crash_buf));
}

pub export fn crashLen() u32 {
    return @intCast(crash_len);
}
