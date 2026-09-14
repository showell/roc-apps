//! The framebuffer platform's host for the browser. A Codex program's memory
//! lives here rather than in Roc: 32 bits of address space in 1 MB pages, each
//! made and zeroed the first time the program touches it, read and written
//! through the platform's Heap doors.
//!
//! The screen is part of that memory, as a UEFI GOP framebuffer is part of a
//! machine's. The page gives it a size, the host publishes the geometry where
//! UEFI's GOP protocol keeps it (the cells codex-vm writes), and after a run
//! the page reads the pixels back out.
//!
//! The page runs the program once per frame. Memory outlives a run, so a frame
//! starts from what the last one left; the clock cell is what the page writes
//! between them.

const std = @import("std");
const builtins = @import("builtins");
const host_alloc = @import("host_alloc");

const RocOps = builtins.host_abi.RocOps;
const RocList = builtins.list.RocList;
const RocStr = builtins.str.RocStr;

const wasm_allocator = std.heap.wasm_allocator;

// ---- what the page reads back --------------------------------------------

const console_cap: usize = 1 << 16;
var console_buf: [console_cap]u8 = undefined;
var console_len: usize = 0;

const crash_cap: usize = 4096;
var crash_buf: [crash_cap]u8 = undefined;
var crash_len: usize = 0;

/// Appends what fits.
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

fn stop(msg: []const u8) noreturn {
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
    stop(bytes[0..len]);
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

// ---- memory --------------------------------------------------------------

const page_bits = 20;
const page_size: usize = 1 << page_bits;
const page_mask: u64 = (1 << page_bits) - 1;
const page_count: usize = 1 << (32 - page_bits);

/// Page `i` holds the addresses from `i << 20` on; null until something
/// touches it.
var pages: [page_count]?[*]u8 = [_]?[*]u8{null} ** page_count;
var pages_made: u32 = 0;

fn page(addr: u64) [*]u8 {
    if (addr >> 32 != 0) {
        var msg: [96]u8 = undefined;
        stop(std.fmt.bufPrint(&msg, "memory: address 0x{X} is past the platform's 4 GB", .{addr}) catch "memory: an address past 4 GB");
    }
    const i: usize = @intCast(addr >> page_bits);
    if (pages[i]) |p| return p;
    const p = wasm_allocator.alloc(u8, page_size) catch stop("memory: the host has no room for another page");
    @memset(p, 0);
    pages[i] = p.ptr;
    pages_made += 1;
    return p.ptr;
}

/// The `width` bytes at `addr`, low byte first; a word that crosses a page is
/// read a byte at a time.
fn load(addr: u64, width: u64) u64 {
    const off: usize = @intCast(addr & page_mask);
    if (off + width <= page_size) {
        const p = page(addr)[off..];
        switch (width) {
            1 => return p[0],
            2 => return std.mem.readInt(u16, p[0..2], .little),
            4 => return std.mem.readInt(u32, p[0..4], .little),
            8 => return std.mem.readInt(u64, p[0..8], .little),
            else => {},
        }
    }
    var v: u64 = 0;
    var j: u64 = @min(width, 8);
    while (j > 0) : (j -= 1) {
        const a = addr +% (j - 1);
        v = (v << 8) | page(a)[@intCast(a & page_mask)];
    }
    return v;
}

/// The low `width` bytes of `value` at `addr`, low byte first.
fn store(addr: u64, value: u64, width: u64) void {
    const off: usize = @intCast(addr & page_mask);
    if (off + width <= page_size) {
        const p = page(addr)[off..];
        switch (width) {
            1 => {
                p[0] = @truncate(value);
                return;
            },
            2 => return std.mem.writeInt(u16, p[0..2], @truncate(value), .little),
            4 => return std.mem.writeInt(u32, p[0..4], @truncate(value), .little),
            8 => return std.mem.writeInt(u64, p[0..8], value, .little),
            else => {},
        }
    }
    var v = value;
    var j: u64 = 0;
    while (j < @min(width, 8)) : (j += 1) {
        const a = addr +% j;
        page(a)[@intCast(a & page_mask)] = @truncate(v);
        v >>= 8;
    }
}

fn hostedHeapLoad(addr: u64, width: u64) callconv(.c) u64 {
    return load(addr, width);
}

fn hostedHeapStore(addr: u64, value: u64, width: u64) callconv(.c) void {
    store(addr, value, width);
}

fn hostedEchoLine(line: RocStr) callconv(.c) void {
    defer line.decref(&roc_ops);
    keep(&console_buf, &console_len, line.asSlice());
}

comptime {
    @export(&hostedEchoLine, .{ .name = "roc_echo_line", .visibility = .hidden });
    @export(&hostedHeapLoad, .{ .name = "roc_heap_load", .visibility = .hidden });
    @export(&hostedHeapStore, .{ .name = "roc_heap_store", .visibility = .hidden });
}

/// How many 1 MB pages the program has touched.
pub export fn pagesMade() u32 {
    return pages_made;
}

// ---- the screen ----------------------------------------------------------

/// Where codex-vm maps the GOP framebuffer, and where UEFI's mode block says
/// it is.
const fb_base: u64 = 0xBF000000;

/// The frame's clock, in milliseconds. This cell is the framebuffer
/// platform's own, just past the GOP mode block; UEFI and codex-vm write
/// nothing there, so on the machine it reads 0.
const clock_cell: u64 = 0x7F0;

var screen_width: usize = 0;
var screen_height: usize = 0;
var screen_stride: usize = 0;

/// The visible pixels as the page draws them: red, green, blue, opaque.
var pixels: []u8 = &.{};

/// Gives the program a screen `width` by `height` pixels, with rows `stride`
/// pixels long in memory, published as UEFI's GOP protocol and codex-vm
/// publish it: the framebuffer's base and size at 0x798 and 0x7A0, and the
/// resolution, the pixel format (1, blue-green-red) and the stride at 0x7C4,
/// 0x7C8, 0x7CC and 0x7E0. Answers 0 for a size the host cannot hold.
pub export fn screen(width: u32, height: u32, stride: u32) u32 {
    if (width == 0 or height == 0 or stride < width) return 0;
    const bytes = @as(u64, stride) * height * 4;
    if (bytes > (1 << 32) - fb_base) return 0;
    if (pixels.len > 0) wasm_allocator.free(pixels);
    pixels = &.{};
    pixels = wasm_allocator.alloc(u8, @as(usize, width) * height * 4) catch return 0;
    screen_width = width;
    screen_height = height;
    screen_stride = stride;
    store(0x798, fb_base, 8);
    store(0x7A0, bytes, 8);
    store(0x7C4, width, 4);
    store(0x7C8, height, 4);
    store(0x7CC, 1, 4);
    store(0x7E0, stride, 4);
    return 1;
}

pub export fn clock(ms: u32) void {
    store(clock_cell, ms, 4);
}

/// Copies the visible part of the framebuffer out of memory for the page: the
/// first `width` pixels of each row, each 0x00RRGGBB word as red, green, blue
/// and an opaque alpha. Answers where the copy is.
pub export fn present() u32 {
    var y: usize = 0;
    while (y < screen_height) : (y += 1) {
        var x: usize = 0;
        while (x < screen_width) : (x += 1) {
            const v = load(fb_base + (@as(u64, y) * screen_stride + x) * 4, 4);
            const d = (y * screen_width + x) * 4;
            pixels[d] = @truncate(v >> 16);
            pixels[d + 1] = @truncate(v >> 8);
            pixels[d + 2] = @truncate(v);
            pixels[d + 3] = 255;
        }
    }
    return @intCast(@intFromPtr(pixels.ptr));
}

// ---- the run -------------------------------------------------------------

extern fn roc_main(args: RocList) callconv(.c) i8;

/// Runs the program once, from the memory the last run left, with an empty
/// command line. Answers its exit code.
pub export fn run() i32 {
    console_len = 0;
    crash_len = 0;
    return roc_main(RocList.empty());
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
