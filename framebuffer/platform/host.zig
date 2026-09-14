//! The framebuffer platform's host for the browser: core.zig's memory, screen
//! and GPU, and the exports the page calls. A crash, in the program or the
//! host, keeps its message for the page and stops the instance; the page reads
//! the message after the trap.

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

/// A scancode for the program's keyboard controller.
pub export fn key(scancode: u32) void {
    core.keyPush(@truncate(scancode));
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
