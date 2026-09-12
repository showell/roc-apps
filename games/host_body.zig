
pub const panic = std.debug.FullPanic(panicImpl);
fn panicImpl(_: []const u8, _: ?usize) noreturn {
    @trap();
}

const wasm_allocator = std.heap.wasm_allocator;

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
fn roc_crashed(_: [*]const u8, _: usize) callconv(.c) void {
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

fn noDec(_: ?*anyopaque, _: ?[*]u8) callconv(.c) void {}

/// A reference for a call that keeps nothing: Roc's decrement restores ours.
fn borrowed(m: Model) Model {
    builtins.utils.increfDataPtrC(m, 1, &roc_ops);
    return m;
}

// ---- the page's door: one model -------------------------------------------

var current: Model = null;
// The last view's words, owned until the next view replaces them.
var frame: RocList = RocList.empty();

pub export fn newGame(seed: i32) void {
    if (current != null) roc_drop(current);
    current = roc_init(seed);
}
pub export fn step(msg: i32) void {
    if (current == null) current = roc_init(1);
    current = roc_step(current, msg);
}
pub export fn view() u32 {
    if (current == null) current = roc_init(1);
    frame.decref(@alignOf(u32), @sizeOf(u32), false, null, noDec, &roc_ops);
    frame = roc_view(borrowed(current));
    return @intCast(frame.length * 4);
}
pub export fn bufPtr() u32 {
    return @intCast(@intFromPtr(frame.bytes orelse return 0));
}

// ---- the grader's door: handles ---------------------------------------------

var table: std.ArrayList(Model) = .empty;

fn push(m: Model) i32 {
    table.append(wasm_allocator, m) catch @trap();
    return @intCast(table.items.len - 1);
}
fn at(h: i32) Model {
    if (h < 0 or @as(usize, @intCast(h)) >= table.items.len) @trap();
    return table.items[@intCast(h)];
}

