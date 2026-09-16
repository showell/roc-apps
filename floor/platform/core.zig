//! What the floor's hosts share. A Codex program's memory lives here rather
//! than in Roc: 3 GB of RAM in 1 MB pages, each made and zeroed the first time
//! the program touches it, read and written through the platform's Heap doors.
//! The block device's images live here too, and so does the clock.
//!
//! **A TRANSFER NAMES AN ADDRESS, NEVER A PAYLOAD.** `Disk.read!` takes a
//! sector and an address and moves the 512 bytes from one host-owned buffer to
//! another; nothing but integers crosses the door. That is what a controller
//! doing DMA actually does, and it is why the Roc above can stay pure.
//!
//! **EVERY DOOR IS LOUD.** A refusal names the address, the position or the
//! sector, and says what was expected. The Roc side cannot inspect the host's
//! state, so the host has to say what it saw.
//!
//! The faults (`fault`) are the beginning of the other half of the idea: the
//! floor can be put in a mode where it breaks its promises on purpose -- a
//! write refused, a write torn in half -- and the Roc above has to cope. They
//! are deterministic, counted, and reported at the end of a run.
//!
//! The root file supplies `allocator`, and `stop`, which ends the run with a
//! message the way that host reports one.
//!
//! The page table here is the framebuffer platform's (framebuffer/platform/
//! core.zig), which holds the same 1 MB pages under the same 3 GB. The two
//! converge when the screen arrives on this floor; until then the duplication
//! is deliberate and dated (2026-09-16).

const std = @import("std");
const builtins = @import("builtins");
const host_alloc = @import("host_alloc");
const root = @import("root");

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
/// `Machine.ram_size`). Above it a machine keeps device registers, and this
/// floor has none yet, so a read or write there stops the run rather than
/// finding memory.
const ram_top: u64 = 0xC0000000;

/// Page `i` holds the addresses from `i << 20` on; null until something
/// touches it.
var pages: [page_count]?[*]u8 = [_]?[*]u8{null} ** page_count;

/// How many 1 MB pages the host holds for the program's memory.
pub var pages_made: u32 = 0;

var fault_msg: [160]u8 = undefined;

fn page(addr: u64) [*]u8 {
    if (addr >= ram_top) {
        root.stop(std.fmt.bufPrint(&fault_msg, "memory: address 0x{X} is past 3 GB, where a machine keeps its devices, and this floor has none", .{addr}) catch "memory: an address past 3 GB, where a machine keeps its devices");
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

/// `bytes` into memory from `addr`, a page at a time.
fn copyIn(addr: u64, bytes: []const u8) void {
    var done: usize = 0;
    while (done < bytes.len) {
        const a = addr + done;
        const off: usize = @intCast(a & page_mask);
        const n = @min(page_size - off, bytes.len - done);
        @memcpy(page(a)[off..][0..n], bytes[done..][0..n]);
        done += n;
    }
}

/// `len` bytes of memory from `addr` into `out`, a page at a time.
fn copyOut(addr: u64, out: []u8) void {
    var done: usize = 0;
    while (done < out.len) {
        const a = addr + done;
        const off: usize = @intCast(a & page_mask);
        const n = @min(page_size - off, out.len - done);
        @memcpy(out[done..][0..n], page(a)[off..][0..n]);
        done += n;
    }
}

/// A byte at a time, for the one byte `fill` needs.
fn fill(addr: u64, byte: u8, len: usize) void {
    var done: usize = 0;
    while (done < len) {
        const a = addr + done;
        const off: usize = @intCast(a & page_mask);
        const n = @min(page_size - off, len - done);
        @memset(page(a)[off..][0..n], byte);
        done += n;
    }
}

fn hostedHeapLoad(addr: u64, width: u64) callconv(.c) u64 {
    return load(addr, width);
}

fn hostedHeapStore(addr: u64, value: u64, width: u64) callconv(.c) void {
    store(addr, value, width);
}

// ---- the clock -----------------------------------------------------------

/// The virtual clock moves only where `wait!` asks it to, so a run repeats
/// exactly; the wall clock follows the host's monotonic time and sleeps. The
/// root supplies `nowNs` and `sleepNs` for the wall clock.
pub var wall_clock: bool = false;

var virtual_ns: u64 = 0;
var wall_base: u64 = 0;

pub fn startClock() void {
    if (wall_clock) wall_base = root.nowNs();
}

fn nowNs() u64 {
    return if (wall_clock) root.nowNs() - wall_base else virtual_ns;
}

/// How long the program has spent waiting, and how many times it asked.
pub var waited_ns: u64 = 0;
pub var waits: u64 = 0;

fn hostedClockNow() callconv(.c) u64 {
    return nowNs();
}

/// Waits until the clock reads at least `deadline`, and answers what it reads
/// then. A deadline already past is not a wait.
fn hostedClockWait(deadline: u64) callconv(.c) u64 {
    const at = nowNs();
    if (deadline <= at) return at;
    waits += 1;
    waited_ns += deadline - at;
    if (wall_clock) {
        root.sleepNs(deadline - at);
        return nowNs();
    }
    virtual_ns = deadline;
    return virtual_ns;
}

// ---- the block device ----------------------------------------------------

/// A position on the primary channel: an image the host owns, or nothing.
/// codex-vm claims only that channel, so position 2 and above has nothing.
const drive_count = 2;
var drives: [drive_count]?[]u8 = .{ null, null };
var selected: u64 = 0;

/// Every sector the program wrote, in order, so a run can be checked without
/// reading the image back.
pub var sectors_read: u64 = 0;
pub var sectors_written: u64 = 0;

var disk_msg: [192]u8 = undefined;

/// Gives position `p` an image of `bytes`, which the host then owns. The image
/// is a whole number of sectors; a tail shorter than a sector is refused,
/// because a controller cannot address it.
pub fn attach(p: u64, bytes: []u8) bool {
    if (p >= drive_count) return false;
    if (bytes.len % 512 != 0) return false;
    if (drives[p]) |old| root.allocator.free(old);
    drives[p] = bytes;
    return true;
}

/// Position `p`'s image as it stands, for a host that writes it back out.
pub fn image(p: u64) ?[]u8 {
    return if (p < drive_count) drives[p] else null;
}

fn drive() ?[]u8 {
    return if (selected < drive_count) drives[@intCast(selected)] else null;
}

/// What a transfer did. The Roc side reads these as integers; `Disk.roc` names
/// them.
const Outcome = enum(u64) { done = 0, absent = 1, past_end = 2, refused = 3, torn = 4 };

fn hostedDiskSelect(p: u64) callconv(.c) void {
    selected = p;
}

fn hostedDiskSectorCount() callconv(.c) u64 {
    const d = drive() orelse return 0;
    return d.len / 512;
}

/// The sector at `lba` into the 512 bytes at `addr`. A position with nothing
/// on it reads the floating bus, 255 in every byte, and a sector past the end
/// of an image reads zeros, as codex-vm's IDE model answers both.
fn hostedDiskRead(lba: u64, addr: u64) callconv(.c) u64 {
    sectors_read += 1;
    const d = drive() orelse {
        fill(addr, 255, 512);
        return @intFromEnum(Outcome.absent);
    };
    if (faulted(.read, lba)) {
        return @intFromEnum(Outcome.refused);
    }
    if (lba >= d.len / 512) {
        fill(addr, 0, 512);
        return @intFromEnum(Outcome.past_end);
    }
    copyIn(addr, d[@intCast(lba * 512)..][0..512]);
    return @intFromEnum(Outcome.done);
}

/// The 512 bytes at `addr` become the sector at `lba`. A write to a position
/// with nothing on it, or past the end of an image, changes nothing.
fn hostedDiskWrite(lba: u64, addr: u64) callconv(.c) u64 {
    sectors_written += 1;
    const d = drive() orelse return @intFromEnum(Outcome.absent);
    if (lba >= d.len / 512) return @intFromEnum(Outcome.past_end);
    if (faulted(.write, lba)) {
        return @intFromEnum(Outcome.refused);
    }
    const dest = d[@intCast(lba * 512)..][0..512];
    if (torn(lba)) {
        copyOut(addr, dest[0..256]);
        return @intFromEnum(Outcome.torn);
    }
    copyOut(addr, dest);
    return @intFromEnum(Outcome.done);
}

// ---- the faults ----------------------------------------------------------

/// The floor breaking its promises on purpose, so the Roc above has to cope.
/// A plan counts the transfers it matches and bites on every `every`-th one,
/// which makes a run repeat exactly: the same program over the same image
/// fails in the same place.
pub const Fault = enum { none, refuse_read, refuse_write, tear_write };

pub var fault_kind: Fault = .none;
/// Bite on every `fault_every`-th matching transfer (1 is all of them).
pub var fault_every: u64 = 1;
/// Only transfers of this sector count, when it is not null.
pub var fault_lba: ?u64 = null;

var fault_seen: u64 = 0;
/// How many times a fault actually bit, which a run reports.
pub var faults_bitten: u64 = 0;

const Access = enum { read, write };

fn matches(access: Access, lba: u64) bool {
    if (fault_lba) |want| {
        if (lba != want) return false;
    }
    return switch (fault_kind) {
        .none => false,
        .refuse_read => access == .read,
        .refuse_write, .tear_write => access == .write,
    };
}

/// Whether this transfer is the one the plan bites on. Counting happens here,
/// so a plan that names a sector counts only that sector's transfers.
fn bites(access: Access, lba: u64) bool {
    if (!matches(access, lba)) return false;
    fault_seen += 1;
    if (fault_every == 0 or fault_seen % fault_every != 0) return false;
    faults_bitten += 1;
    return true;
}

fn faulted(access: Access, lba: u64) bool {
    return switch (fault_kind) {
        .refuse_read, .refuse_write => bites(access, lba),
        else => false,
    };
}

fn torn(lba: u64) bool {
    return fault_kind == .tear_write and bites(.write, lba);
}

/// The name a host prints for the plan it ran.
pub fn faultName() []const u8 {
    return switch (fault_kind) {
        .none => "none",
        .refuse_read => "refuse-read",
        .refuse_write => "refuse-write",
        .tear_write => "tear-write",
    };
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
    @export(&hostedHeapLoad, .{ .name = "roc_heap_load", .visibility = .hidden });
    @export(&hostedHeapStore, .{ .name = "roc_heap_store", .visibility = .hidden });
    @export(&hostedDiskSelect, .{ .name = "roc_disk_select", .visibility = .hidden });
    @export(&hostedDiskSectorCount, .{ .name = "roc_disk_sector_count", .visibility = .hidden });
    @export(&hostedDiskRead, .{ .name = "roc_disk_read", .visibility = .hidden });
    @export(&hostedDiskWrite, .{ .name = "roc_disk_write", .visibility = .hidden });
    @export(&hostedClockNow, .{ .name = "roc_clock_now", .visibility = .hidden });
    @export(&hostedClockWait, .{ .name = "roc_clock_wait", .visibility = .hidden });
}
