//! The page's solver.wasm: the Roc solver under a two-export door, the one
//! main.ts has always called. `solveShift(seed)` solves the shift and
//! answers the length of its plan's JSON; `outPtr()` is where those bytes
//! sit in the module's memory, until the next `solveShift`.

const seam = @import("roc_seam.zig");

var last: seam.RocBytes = .{ .bytes = null, .length = 0, .capacity_or_alloc_ptr = 0 };

pub export fn solveShift(seed: u32) u32 {
    seam.release(last);
    last = seam.plan(seed);
    return @intCast(last.length);
}

pub export fn outPtr() u32 {
    const p = last.bytes orelse return 0;
    return @intCast(@intFromPtr(p));
}
