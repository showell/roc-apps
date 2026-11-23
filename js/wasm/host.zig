//! The JavaScript subset's wasm host: the page's door onto the Roc
//! interpreter (../roc/JsApp.roc on platform/main.roc), the page's effects
//! the Roc calls (platform/Host.roc), and the memory and crash functions.
//!
//! The page writes a program's bytes where `sourcePtr(n)` says and calls
//! `start()`, then `frame(t)` for each frame while the last line said
//! `end frame`. While either call runs, each line the Roc emits reaches the
//! page at once, through the page's import `js_emit`, and each read the Roc
//! makes is answered by `js_pointer` or `js_key`: so the page sees a draw, a
//! log and another draw in the order the program made them.
//!
//! The run is one boxed Roc value, kept here between calls: each call
//! consumes it and answers the next, and `sourcePtr` drops it before a new
//! run.
//!
//! Memory is the wasm allocator's, freed as the Roc frees it: each
//! allocation carries its size in the sixteen bytes before what Roc is
//! given, for `roc_dealloc` and `roc_realloc`.

const std = @import("std");

/// Roc's `List(U8)`: its bytes, how many, and its capacity.
const RocBytes = extern struct { bytes: ?[*]u8, length: usize, capacity_or_alloc_ptr: usize };

/// A boxed run: one pointer, which only the Roc reads.
const Model = ?*anyopaque;

extern fn roc_buffer(n: u32) callconv(.c) RocBytes;
extern fn roc_start(src: RocBytes) callconv(.c) Model;
extern fn roc_frame(model: Model, t: f64) callconv(.c) Model;
extern fn roc_drop_model(model: Model) callconv(.c) void;
extern fn roc_drop_bytes(bytes: RocBytes) callconv(.c) void;

extern "env" fn js_emit(ptr: u32, len: u32) void;
extern "env" fn js_pointer(axis: u32) f64;
extern "env" fn js_key(ptr: u32, len: u32) u32;

const empty: RocBytes = .{ .bytes = null, .length = 0, .capacity_or_alloc_ptr = 0 };

var source: RocBytes = empty;
var model: Model = null;

fn address(b: RocBytes) u32 {
    const p = b.bytes orelse return 0;
    return @intCast(@intFromPtr(p));
}

/// Where the page writes a program of `n` bytes. The last run is dropped
/// first.
pub export fn sourcePtr(n: u32) u32 {
    if (model != null) roc_drop_model(model);
    model = null;
    source = roc_buffer(n);
    return address(source);
}

/// Runs the program written at `sourcePtr` to its end.
pub export fn start() void {
    model = roc_start(source);
    source = empty;
}

/// Calls the program's `frame(t)` once.
pub export fn frame(t: f64) void {
    if (model == null) @trap();
    model = roc_frame(model, t);
}

// ---- the effects the Roc calls (platform/Host.roc) ------------------------

fn host_emit(line: RocBytes) callconv(.c) void {
    js_emit(address(line), @intCast(line.length));
    roc_drop_bytes(line);
}

fn host_pointer(axis: u8) callconv(.c) f64 {
    return js_pointer(axis);
}

fn host_key(name: RocBytes) callconv(.c) u8 {
    const state = js_key(address(name), @intCast(name.length));
    roc_drop_bytes(name);
    return if (state == 0) 0 else 1;
}

// ---- memory and crashes -----------------------------------------------------

const header = 16;
const wasm_allocator = std.heap.wasm_allocator;

fn allocate(len: usize, alignment: usize) [*]u8 {
    if (alignment > header) @trap();
    const total = header + len;
    const mem = wasm_allocator.alignedAlloc(u8, .fromByteUnits(header), total) catch @trap();
    const words: [*]usize = @ptrCast(@alignCast(mem.ptr));
    words[0] = total;
    return mem.ptr + header;
}

fn release(ptr: *anyopaque) void {
    const base: [*]u8 = @as([*]u8, @ptrCast(ptr)) - header;
    const words: [*]usize = @ptrCast(@alignCast(base));
    const total = words[0];
    const mem: []align(header) u8 = @alignCast(base[0..total]);
    wasm_allocator.free(mem);
}

fn roc_alloc(len: usize, alignment: usize) callconv(.c) *anyopaque {
    return allocate(len, alignment);
}

fn roc_realloc(ptr: *anyopaque, len: usize, alignment: usize) callconv(.c) *anyopaque {
    const old: [*]u8 = @ptrCast(ptr);
    const words: [*]usize = @ptrCast(@alignCast(old - header));
    const was = words[0] - header;
    const new = allocate(len, alignment);
    @memcpy(new[0..@min(was, len)], old[0..@min(was, len)]);
    release(ptr);
    return new;
}

fn roc_dealloc(ptr: *anyopaque, alignment: usize) callconv(.c) void {
    _ = alignment;
    release(ptr);
}

/// A Roc crash is the interpreter's bug. Its message is kept where
/// `crashPtr` and `crashLen` say, and the call traps, so the page can say
/// what the Roc said. The run is lost with it: the page starts afresh.
var crash_message: [512]u8 = undefined;
var crash_length: usize = 0;

fn roc_crashed(bytes: [*]const u8, len: usize) callconv(.c) void {
    crash_length = @min(len, crash_message.len);
    @memcpy(crash_message[0..crash_length], bytes[0..crash_length]);
    model = null;
    @trap();
}

pub export fn crashPtr() u32 {
    return @intCast(@intFromPtr(&crash_message));
}

pub export fn crashLen() u32 {
    return @intCast(crash_length);
}

fn roc_dbg(bytes: [*]const u8, len: usize) callconv(.c) void {
    _ = .{ bytes, len };
}

fn roc_expect_failed(bytes: [*]const u8, len: usize) callconv(.c) void {
    _ = .{ bytes, len };
}

comptime {
    @export(&host_emit, .{ .name = "host_emit" });
    @export(&host_pointer, .{ .name = "host_pointer" });
    @export(&host_key, .{ .name = "host_key" });
    @export(&roc_alloc, .{ .name = "roc_alloc" });
    @export(&roc_realloc, .{ .name = "roc_realloc" });
    @export(&roc_dealloc, .{ .name = "roc_dealloc" });
    @export(&roc_crashed, .{ .name = "roc_crashed" });
    @export(&roc_dbg, .{ .name = "roc_dbg" });
    @export(&roc_expect_failed, .{ .name = "roc_expect_failed" });
}
