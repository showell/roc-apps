//! What the framebuffer platform's two hosts share: the browser's (host.zig,
//! wasm) and the native checker's (native.zig). A Codex program's memory lives
//! here rather than in Roc: 3 GB of RAM in 1 MB pages, each made and zeroed the
//! first time the program touches it, read and written through the platform's
//! Heap doors.
//!
//! The screen is part of that memory, as a UEFI GOP framebuffer is part of a
//! machine's. The host publishes its geometry where UEFI's GOP protocol keeps
//! it (the cells codex-vm writes), codex-vm's GPU (gpu.zig) draws into it
//! through the Gpu doors, and after a run the host reads the pixels back out.
//!
//! A run is one pass of the program's opening. Memory outlives a run, so a
//! frame starts from what the last one left; the clock cell is what the host
//! writes between them.
//!
//! The root file supplies `allocator`, and `stop`, which ends the run with a
//! message the way that host reports one.

const std = @import("std");
const builtins = @import("builtins");
const host_alloc = @import("host_alloc");
const root = @import("root");
const gpu = @import("gpu.zig");

const RocOps = builtins.host_abi.RocOps;
const RocList = builtins.list.RocList;
const RocStr = builtins.str.RocStr;

/// Appends what fits.
pub fn keep(buf: []u8, len: *usize, bytes: []const u8) void {
    const n = @min(bytes.len, buf.len - len.*);
    @memcpy(buf[len.*..][0..n], bytes[0..n]);
    len.* += n;
}

// ---- the runtime ---------------------------------------------------------

fn roc_alloc(length: usize, alignment: usize) callconv(.c) ?*anyopaque {
    return host_alloc.alloc(root.allocator, length, alignment);
}
fn roc_dealloc(ptr: *anyopaque, alignment: usize) callconv(.c) void {
    host_alloc.dealloc(root.allocator, ptr, alignment);
}
fn roc_realloc(ptr: *anyopaque, new_length: usize, alignment: usize) callconv(.c) ?*anyopaque {
    return host_alloc.realloc(root.allocator, ptr, new_length, alignment);
}
fn roc_dbg(_: [*]const u8, _: usize) callconv(.c) void {}
fn roc_expect_failed(_: [*]const u8, _: usize) callconv(.c) void {}
fn roc_crashed(bytes: [*]const u8, len: usize) callconv(.c) void {
    root.stop(bytes[0..len]);
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

// ---- the console ---------------------------------------------------------

const console_cap: usize = 1 << 16;
var console_buf: [console_cap]u8 = undefined;
var console_len: usize = 0;

/// What the program printed in the last run.
pub fn console() []const u8 {
    return console_buf[0..console_len];
}

fn hostedEchoLine(line: RocStr) callconv(.c) void {
    defer line.decref(&roc_ops);
    keep(&console_buf, &console_len, line.asSlice());
}

// ---- memory --------------------------------------------------------------

const page_bits = 20;
const page_size: usize = 1 << page_bits;
const page_mask: u64 = (1 << page_bits) - 1;
const page_count: usize = 1 << (32 - page_bits);

/// RAM ends at 3 GB, where it ends on the machine (machine/roc's
/// `Machine.ram_size`). Above it a machine keeps device registers, the HPET's,
/// the APICs', a network card's, and this platform has none, so a read or
/// write there stops the run rather than finding memory.
const ram_top: u64 = 0xC0000000;

/// Page `i` holds the addresses from `i << 20` on; null until something
/// touches it.
var pages: [page_count]?[*]u8 = [_]?[*]u8{null} ** page_count;

/// How many 1 MB pages the host holds for the program's memory: those it has
/// touched, and the GPU's.
pub var pages_made: u32 = 0;

var fault_msg: [128]u8 = undefined;

fn page(addr: u64) [*]u8 {
    if (addr >= ram_top) {
        root.stop(std.fmt.bufPrint(&fault_msg, "memory: address 0x{X} is past 3 GB, where a machine keeps its devices, and this platform has none", .{addr}) catch "memory: an address past 3 GB, where a machine keeps its devices");
    }
    const i: usize = @intCast(addr >> page_bits);
    if (pages[i]) |p| return p;
    const p = root.allocator.alloc(u8, page_size) catch root.stop("memory: the host has no room for another page");
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

// ---- the screen and the GPU ----------------------------------------------

const fb_base = gpu.fb_base;

/// The frame's clock, in milliseconds. This cell is the framebuffer
/// platform's own, just past the GOP mode block; UEFI and codex-vm write
/// nothing there, so on the machine it reads 0.
const clock_cell: u64 = 0x7F0;

var screen_width: usize = 0;
var screen_height: usize = 0;
var screen_stride: usize = 0;

/// The visible pixels as a page draws them: red, green, blue, opaque.
var pixels: []u8 = &.{};

/// The GPU, from the moment the program has a screen.
var the_gpu: ?gpu.Gpu = null;
var gpu_msg: [160]u8 = undefined;

/// `n_words` zeroed words at `base`, whole pages of them in place of whatever
/// the page table held: the GPU reads and writes its buffers as words, and the
/// program reaches the same bytes through Heap.
fn region(base: u64, n_words: usize) ?[]u32 {
    const words_per_page = page_size / 4;
    const n_pages = (n_words + words_per_page - 1) / words_per_page;
    const words = root.allocator.alloc(u32, n_pages * words_per_page) catch return null;
    @memset(words, 0);
    const bytes = std.mem.sliceAsBytes(words);
    const first: usize = @intCast(base >> page_bits);
    for (0..n_pages) |k| {
        pages[first + k] = bytes.ptr + k * page_size;
        pages_made += 1;
    }
    return words[0..n_words];
}

fn hostedGpuOut(port: u64, value: u64) callconv(.c) void {
    if (the_gpu) |*g| {
        if (g.portOut(port, @truncate(value), &gpu_msg)) |why| root.stop(why);
    } else {
        root.stop("gpu: a GPU port written before the program has a screen");
    }
}

fn hostedGpuIn(port: u64) callconv(.c) u64 {
    if (the_gpu == null) root.stop("gpu: a GPU port read before the program has a screen");
    return gpu.Gpu.portIn(port) orelse
        root.stop(std.fmt.bufPrint(&gpu_msg, "gpu: port-in-32 from GPU port 0x{X}, which this platform does not model", .{port}) catch "gpu: port-in-32 from a GPU port this platform does not model");
}

/// Gives the program a screen `width` by `height` pixels, with rows `stride`
/// pixels long in memory, published as UEFI's GOP protocol and codex-vm
/// publish it: the framebuffer's base and size at 0x798 and 0x7A0, and the
/// resolution, the pixel format (1, blue-green-red) and the stride at 0x7C4,
/// 0x7C8, 0x7CC and 0x7E0. The GPU's command buffer, depth buffer and
/// framebuffer are made then, as whole pages at 0xBE000000, 0xBE800000 and
/// 0xBF000000. False for a size the host cannot hold, or a second screen.
pub fn screen(width: u32, height: u32, stride: u32) bool {
    if (the_gpu != null) return false;
    if (width == 0 or height == 0 or stride < width) return false;
    const w: usize = width;
    const h: usize = height;
    const s: usize = stride;
    const bytes = @as(u64, s) * h * 4;
    if (bytes > ram_top - fb_base) return false;
    if (@as(u64, w) * h * 4 > gpu.fb_base - gpu.depth_base) return false;
    const cmd = region(gpu.cmd_base, gpu.max_tris * 18) orelse return false;
    const db = region(gpu.depth_base, w * h) orelse return false;
    const fb = region(gpu.fb_base, s * h) orelse return false;
    const glow = root.allocator.alloc(u8, w * h) catch return false;
    pixels = root.allocator.alloc(u8, w * h * 4) catch return false;
    the_gpu = .{ .w = w, .h = h, .stride = s, .fb = fb, .db = db, .cmd = cmd, .glow = glow };
    screen_width = w;
    screen_height = h;
    screen_stride = s;
    store(0x798, fb_base, 8);
    store(0x7A0, bytes, 8);
    store(0x7C4, width, 4);
    store(0x7C8, height, 4);
    store(0x7CC, 1, 4);
    store(0x7E0, stride, 4);
    return true;
}

pub fn clock(ms: u32) void {
    store(clock_cell, ms, 4);
}

/// Copies the visible part of the framebuffer out of memory: the first `width`
/// pixels of each row, each 0x00RRGGBB word as red, green, blue and an opaque
/// alpha.
pub fn present() []u8 {
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
    return pixels;
}

/// FNV-1a over the bytes: the hash frames.mjs and machine/batch/screenhash.mjs
/// print for an image.
pub fn hash(bytes: []const u8) u32 {
    var h: u32 = 0x811c9dc5;
    for (bytes) |b| h = (h ^ b) *% 0x01000193;
    return h;
}

// ---- the run -------------------------------------------------------------

extern fn roc_main(args: RocList) callconv(.c) i8;

/// Runs the program once, from the memory the last run left, with an empty
/// command line. Answers its exit code.
pub fn run() i32 {
    console_len = 0;
    return roc_main(RocList.empty());
}

/// The symbols the Roc program links against. Call from the root's `comptime`.
pub fn exportSymbols() void {
    host_alloc.exportRuntimeFns(.{
        .alloc = &roc_alloc,
        .dealloc = &roc_dealloc,
        .realloc = &roc_realloc,
        .dbg = &roc_dbg,
        .expect_failed = &roc_expect_failed,
        .crashed = &roc_crashed,
    });
    @export(&hostedEchoLine, .{ .name = "roc_echo_line", .visibility = .hidden });
    @export(&hostedGpuIn, .{ .name = "roc_gpu_in", .visibility = .hidden });
    @export(&hostedGpuOut, .{ .name = "roc_gpu_out", .visibility = .hidden });
    @export(&hostedHeapLoad, .{ .name = "roc_heap_load", .visibility = .hidden });
    @export(&hostedHeapStore, .{ .name = "roc_heap_store", .visibility = .hidden });
}
