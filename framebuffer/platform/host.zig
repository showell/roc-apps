//! The framebuffer platform's host for the browser: core.zig's memory, screen
//! and GPU, and the exports the page calls. A crash, in the program or the
//! host, keeps its message for the page and stops the instance; the page reads
//! the message after the trap.

const std = @import("std");
const core = @import("core");

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

/// The floor's clock, which this platform does not use: a page cannot block, so
/// a wall-clock wait here would not sleep, and nothing in a framebuffer program
/// waits. The virtual clock is what a `Clock.wait!` would move.
pub fn nowNs() u64 {
    return 0;
}

pub fn sleepNs(_: u64) void {}

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
