//! The machine's batch host for the browser. An emitted Codex program's `main!`
//! runs to its end in one call. The page asks for a buffer per drive and loads
//! an image into it, writes the command line, runs the program, and reads back
//! the console, the drives as the program left them, and a crash's message.
//!
//! The drives answer as the native host's files do: 255 in every byte from a
//! position with no buffer, zeros for a sector past the end, and a write past
//! the end changes nothing.

const std = @import("std");
const builtins = @import("builtins");
const host_alloc = @import("host_alloc");

const RocOps = builtins.host_abi.RocOps;
const RocList = builtins.list.RocList;
const RocStr = builtins.str.RocStr;

fn noDec(_: ?*anyopaque, _: ?[*]u8) callconv(.c) void {}

const wasm_allocator = std.heap.wasm_allocator;

// ---- what the page reads back --------------------------------------------

const console_cap: usize = 1 << 20;
var console_buf: [console_cap]u8 = undefined;
var console_len: usize = 0;

const crash_cap: usize = 4096;
var crash_buf: [crash_cap]u8 = undefined;
var crash_len: usize = 0;

/// The frames that crossed the wire, in order: a byte for the direction (0
/// sent by the program, 1 answered by the network), the length as four bytes
/// low first, then the frame. A frame that does not fit is dropped.
const wire_cap: usize = 1 << 20;
var wire_buf: [wire_cap]u8 = undefined;
var wire_len: usize = 0;

/// The screen a run left, if it drew on one: its geometry, and the
/// framebuffer's bytes, stride pixels a row, four bytes a pixel.
var screen: ?[]u8 = null;
var screen_width: u32 = 0;
var screen_height: u32 = 0;
var screen_stride: u32 = 0;

/// Appends what fits; a console past its capacity keeps its first megabyte.
fn keep(buf: []u8, len: *usize, bytes: []const u8) void {
    const n = @min(bytes.len, buf.len - len.*);
    @memcpy(buf[len.*..][0..n], bytes[0..n]);
    len.* += n;
}

/// A panic in the host, like a crash in the program, keeps its message for the
/// page and stops the instance; the page reads the message after the trap.
pub const panic = std.debug.FullPanic(panicImpl);
fn panicImpl(msg: []const u8, _: ?usize) noreturn {
    keep(&crash_buf, &crash_len, msg);
    @trap();
}

fn roc_alloc(length: usize, alignment: usize) callconv(.c) ?*anyopaque {
    return host_alloc.alloc(wasm_allocator, length, alignment);
}
fn roc_dealloc(ptr: *anyopaque, alignment: usize) callconv(.c) void {
    host_alloc.dealloc(wasm_allocator, ptr, alignment);
}
fn roc_realloc(ptr: *anyopaque, new_length: usize, alignment: usize) callconv(.c) ?*anyopaque {
    return host_alloc.realloc(wasm_allocator, ptr, new_length, alignment);
}
fn roc_dbg(_: [*]const u8, _: usize) callconv(.c) void {}
fn roc_expect_failed(_: [*]const u8, _: usize) callconv(.c) void {}
fn roc_crashed(bytes: [*]const u8, len: usize) callconv(.c) void {
    keep(&crash_buf, &crash_len, bytes[0..len]);
    @trap();
}

fn rocOpsAlloc(_: *RocOps, length: usize, alignment: usize) callconv(.c) ?*anyopaque {
    return roc_alloc(length, alignment);
}
fn rocOpsDealloc(_: *RocOps, ptr: *anyopaque, alignment: usize) callconv(.c) void {
    roc_dealloc(ptr, alignment);
}
fn rocOpsRealloc(_: *RocOps, ptr: *anyopaque, new_length: usize, alignment: usize) callconv(.c) ?*anyopaque {
    return roc_realloc(ptr, new_length, alignment);
}
fn rocOpsDbg(_: *RocOps, bytes: [*]const u8, len: usize) callconv(.c) void {
    roc_dbg(bytes, len);
}
fn rocOpsExpectFailed(_: *RocOps, bytes: [*]const u8, len: usize) callconv(.c) void {
    roc_expect_failed(bytes, len);
}
fn rocOpsCrashed(_: *RocOps, bytes: [*]const u8, len: usize) callconv(.c) void {
    roc_crashed(bytes, len);
}

comptime {
    host_alloc.exportRuntimeFns(.{
        .alloc = &roc_alloc,
        .dealloc = &roc_dealloc,
        .realloc = &roc_realloc,
        .dbg = &roc_dbg,
        .expect_failed = &roc_expect_failed,
        .crashed = &roc_crashed,
    });
}

var host_context: u8 = 0;
var roc_ops = RocOps{
    .env = @ptrCast(&host_context),
    .roc_alloc = rocOpsAlloc,
    .roc_dealloc = rocOpsDealloc,
    .roc_realloc = rocOpsRealloc,
    .roc_dbg = rocOpsDbg,
    .roc_expect_failed = rocOpsExpectFailed,
    .roc_crashed = rocOpsCrashed,
    .hosted_fns = builtins.host_abi.emptyHostedFunctions(),
};

// ---- the drives ----------------------------------------------------------

var drives: [2]?[]u8 = .{ null, null };

fn drive(p: u64) ?[]u8 {
    return if (p < drives.len) drives[@intCast(p)] else null;
}

/// A buffer of `len` bytes for drive `p` (0 the master, 1 the slave), in place
/// of any it had; answers its address, or 0 for none.
pub export fn driveBuffer(p: u32, len: u32) u32 {
    if (p >= drives.len) return 0;
    if (drives[p]) |old| wasm_allocator.free(old);
    drives[p] = null;
    if (len == 0) return 0;
    const buf = wasm_allocator.alloc(u8, len) catch return 0;
    drives[p] = buf;
    return @intCast(@intFromPtr(buf.ptr));
}

/// Drive `p`'s buffer as the run left it, or 0 for none.
pub export fn drivePtr(p: u32) u32 {
    const d = drive(p) orelse return 0;
    return @intCast(@intFromPtr(d.ptr));
}

pub export fn driveLen(p: u32) u32 {
    const d = drive(p) orelse return 0;
    return @intCast(d.len);
}

fn hostedDriveOpen(p: u64, name: RocStr) callconv(.c) bool {
    defer name.decref(&roc_ops);
    return drive(p) != null;
}

fn hostedDriveSectorCount(p: u64) callconv(.c) u64 {
    const d = drive(p) orelse return 0;
    return d.len / 512;
}

fn hostedDriveRead(p: u64, lba: u64) callconv(.c) RocList {
    var sector: [512]u8 = undefined;
    if (drive(p)) |d| {
        @memset(&sector, 0);
        if (lba < d.len / 512) {
            const at: usize = @intCast(lba * 512);
            @memcpy(&sector, d[at..][0..512]);
        }
    } else {
        @memset(&sector, 255);
    }
    return RocList.fromSlice(u8, &sector, false, &roc_ops);
}

fn hostedDriveWrite(p: u64, lba: u64, bytes: RocList) callconv(.c) void {
    defer bytes.decref(@alignOf(u8), @sizeOf(u8), false, null, noDec, &roc_ops);
    const d = drive(p) orelse return;
    if (lba >= d.len / 512 or bytes.length != 512) return;
    const data = bytes.bytes orelse return;
    const at: usize = @intCast(lba * 512);
    @memcpy(d[at..][0..512], data[0..512]);
}

fn hostedEchoLine(line: RocStr) callconv(.c) void {
    defer line.decref(&roc_ops);
    keep(&console_buf, &console_len, line.asSlice());
}

fn forgetScreen() void {
    if (screen) |old| wasm_allocator.free(old);
    screen = null;
    screen_width = 0;
    screen_height = 0;
    screen_stride = 0;
}

fn hostedScreenPresent(width: u64, height: u64, stride: u64, pixels: RocList) callconv(.c) void {
    defer pixels.decref(@alignOf(u32), @sizeOf(u32), false, null, noDec, &roc_ops);
    forgetScreen();
    const bytes = pixels.bytes orelse return;
    const n = pixels.length * 4;
    const buf = wasm_allocator.alloc(u8, n) catch return;
    @memcpy(buf, bytes[0..n]);
    screen = buf;
    screen_width = @intCast(width);
    screen_height = @intCast(height);
    screen_stride = @intCast(stride);
}

fn hostedWireFrame(direction: u64, frame: RocList) callconv(.c) void {
    defer frame.decref(@alignOf(u8), @sizeOf(u8), false, null, noDec, &roc_ops);
    const bytes = frame.bytes orelse return;
    const n = frame.length;
    if (wire_len + 5 + n > wire_cap) return;
    wire_buf[wire_len] = @intCast(direction & 1);
    std.mem.writeInt(u32, wire_buf[wire_len + 1 ..][0..4], @intCast(n), .little);
    @memcpy(wire_buf[wire_len + 5 ..][0..n], bytes[0..n]);
    wire_len += 5 + n;
}

comptime {
    @export(&hostedDriveOpen, .{ .name = "roc_drive_open", .visibility = .hidden });
    @export(&hostedDriveRead, .{ .name = "roc_drive_read", .visibility = .hidden });
    @export(&hostedDriveSectorCount, .{ .name = "roc_drive_sector_count", .visibility = .hidden });
    @export(&hostedDriveWrite, .{ .name = "roc_drive_write", .visibility = .hidden });
    @export(&hostedEchoLine, .{ .name = "roc_echo_line", .visibility = .hidden });
    @export(&hostedScreenPresent, .{ .name = "roc_screen_present", .visibility = .hidden });
    @export(&hostedWireFrame, .{ .name = "roc_wire_frame", .visibility = .hidden });
}

// ---- the run -------------------------------------------------------------

const args_cap: usize = 4096;
var args_buf: [args_cap]u8 = undefined;

pub export fn argsBuffer() u32 {
    return @intCast(@intFromPtr(&args_buf));
}

pub export fn argsCapacity() u32 {
    return @intCast(args_cap);
}

extern fn roc_main(args: RocList) callconv(.c) i8;

/// Runs the program over the command line in the argument buffer: `len` bytes
/// of words, each ended by a zero byte. Answers the program's exit code.
pub export fn run(len: u32) i32 {
    console_len = 0;
    crash_len = 0;
    wire_len = 0;
    forgetScreen();
    if (len > args_cap) @trap();
    const words = args_buf[0..len];
    var count: usize = 0;
    for (words) |b| {
        if (b == 0) count += 1;
    }
    const strs = wasm_allocator.alloc(RocStr, count) catch @trap();
    defer wasm_allocator.free(strs);
    var start: usize = 0;
    var i: usize = 0;
    for (words, 0..) |b, at| {
        if (b != 0) continue;
        strs[i] = RocStr.fromSlice(words[start..at], &roc_ops);
        i += 1;
        start = at + 1;
    }
    return roc_main(RocList.fromSlice(RocStr, strs, true, &roc_ops));
}

pub export fn consolePtr() u32 {
    return @intCast(@intFromPtr(&console_buf));
}

pub export fn consoleLen() u32 {
    return @intCast(console_len);
}

pub export fn crashPtr() u32 {
    return @intCast(@intFromPtr(&crash_buf));
}

pub export fn crashLen() u32 {
    return @intCast(crash_len);
}

pub export fn wirePtr() u32 {
    return @intCast(@intFromPtr(&wire_buf));
}

pub export fn wireLen() u32 {
    return @intCast(wire_len);
}

pub export fn screenPtr() u32 {
    const s = screen orelse return 0;
    return @intCast(@intFromPtr(s.ptr));
}

pub export fn screenLen() u32 {
    const s = screen orelse return 0;
    return @intCast(s.len);
}

pub export fn screenWidth() u32 {
    return screen_width;
}

pub export fn screenHeight() u32 {
    return screen_height;
}

pub export fn screenStride() u32 {
    return screen_stride;
}
