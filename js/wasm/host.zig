//! The JavaScript subset's wasm host: the page's door onto the Roc
//! interpreter (../roc/JsApp.roc on platform/main.roc), and the memory and
//! crash functions the Roc calls.
//!
//! The page writes a program's bytes where `sourcePtr(n)` says, calls
//! `run()`, and reads the transcript `run()` answers the length of at
//! `transcriptPtr()`. The transcript lasts until the next `sourcePtr`.
//!
//! Memory is the wasm allocator's, freed as the Roc frees it: each
//! allocation carries its size in the sixteen bytes before what Roc is
//! given, for `roc_dealloc` and `roc_realloc`.

const std = @import("std");

/// Roc's `List(U8)`: its bytes, how many, and its capacity.
const RocBytes = extern struct { bytes: ?[*]u8, length: usize, capacity_or_alloc_ptr: usize };

extern fn roc_buffer(n: u32) callconv(.c) RocBytes;
extern fn roc_run(src: RocBytes) callconv(.c) RocBytes;
extern fn roc_drop(transcript: RocBytes) callconv(.c) void;

const empty: RocBytes = .{ .bytes = null, .length = 0, .capacity_or_alloc_ptr = 0 };

var source: RocBytes = empty;
var transcript: RocBytes = empty;
var holds_transcript = false;

/// Where the page writes a program of `n` bytes. The last run's transcript
/// is dropped first.
pub export fn sourcePtr(n: u32) u32 {
    if (holds_transcript) roc_drop(transcript);
    holds_transcript = false;
    source = roc_buffer(n);
    const p = source.bytes orelse return 0;
    return @intCast(@intFromPtr(p));
}

/// Runs the program written at `sourcePtr`, and answers its transcript's
/// length: a byte that says how the run ended, then the text.
pub export fn run() u32 {
    transcript = roc_run(source);
    source = empty;
    holds_transcript = true;
    return @intCast(transcript.length);
}

pub export fn transcriptPtr() u32 {
    const p = transcript.bytes orelse return 0;
    return @intCast(@intFromPtr(p));
}

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
/// what the Roc said.
var crash_message: [512]u8 = undefined;
var crash_length: usize = 0;

fn roc_crashed(bytes: [*]const u8, len: usize) callconv(.c) void {
    crash_length = @min(len, crash_message.len);
    @memcpy(crash_message[0..crash_length], bytes[0..crash_length]);
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
    @export(&roc_alloc, .{ .name = "roc_alloc" });
    @export(&roc_realloc, .{ .name = "roc_realloc" });
    @export(&roc_dealloc, .{ .name = "roc_dealloc" });
    @export(&roc_crashed, .{ .name = "roc_crashed" });
    @export(&roc_dbg, .{ .name = "roc_dbg" });
    @export(&roc_expect_failed, .{ .name = "roc_expect_failed" });
}
