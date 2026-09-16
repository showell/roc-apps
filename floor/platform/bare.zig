//! The floor's third root: no operating system at all. The same core.zig as
//! the native checker and the browser, over a machine QEMU boots with
//! `-kernel`.
//!
//! **THE POINT OF THIS FILE IS THAT IT IS SMALL.** Everything a Codex program
//! on this floor does -- memory, the screen, the disk, the clock -- is already
//! written once in core.zig. A machine differs only in where those bytes
//! physically are and how a crash gets reported, which is what a root says.
//!
//! What this root has to answer, and how it does on this machine:
//!
//! - `allocator`: a bump allocator over physical RAM above the kernel. Nothing
//!   is ever freed, which is what core.zig's page table wants anyway: a page is
//!   made once and lives as long as the run.
//! - `stop`: the message out the first serial port, then QEMU's isa-debug-exit.
//! - `nowNs`: the timestamp counter, scaled by a rate the PIT measures once.
//! - `flushed`, `asset`: nothing yet. No program with a screen or an asset load
//!   runs here.
//!
//! The harness is cobblestone-qemu's, unchanged: `-kernel` loads this,
//! `-serial` carries what it prints, and a write to port 0xF4 ends the guest
//! with a code. The RAM size arrives at physical 0xFE8, where that harness's
//! `-device loader` puts it, because QEMU does not write it and codex-vm does.

const std = @import("std");
const core = @import("core.zig");

// ---- the multiboot header ------------------------------------------------

/// QEMU's `-kernel` takes a Linux image or a multiboot one. This is the
/// second: the magic, flags asking for nothing, and the checksum that has to
/// make the three sum to zero. The linker script puts this section first, so it
/// lands inside the first 8 KB where the loader looks for it.
const MULTIBOOT_MAGIC: u32 = 0x1BADB002;
const MULTIBOOT_FLAGS: u32 = 0;

export const multiboot_header linksection(".multiboot") = [_]u32{
    MULTIBOOT_MAGIC,
    MULTIBOOT_FLAGS,
    ~(MULTIBOOT_MAGIC +% MULTIBOOT_FLAGS) +% 1,
};

// ---- the serial port -----------------------------------------------------

const com1: u16 = 0x3F8;

fn outb(port: u16, value: u8) void {
    asm volatile ("outb %[v], %[p]"
        :
        : [v] "{al}" (value),
          [p] "N{dx}" (port),
    );
}

fn inb(port: u16) u8 {
    return asm volatile ("inb %[p], %[r]"
        : [r] "={al}" (-> u8),
        : [p] "N{dx}" (port),
    );
}

fn serialInit() void {
    outb(com1 + 1, 0x00); // no interrupts
    outb(com1 + 3, 0x80); // the divisor latch
    outb(com1 + 0, 0x01); // 115200 baud
    outb(com1 + 1, 0x00);
    outb(com1 + 3, 0x03); // 8N1
    outb(com1 + 2, 0xC7); // the FIFO, cleared
    outb(com1 + 4, 0x03);
}

fn serialWrite(bytes: []const u8) void {
    for (bytes) |b| {
        while (inb(com1 + 5) & 0x20 == 0) {}
        outb(com1, b);
    }
}

// ---- what the root owes core.zig -----------------------------------------

/// Where the harness leaves the guest's RAM size, because QEMU does not write
/// it and codex-vm does (cobblestone-qemu's `-device loader,addr=0xfe8`).
const ram_size_cell: usize = 0xFE8;

/// The kernel is loaded at 1 MB, as codex-vm loads a Codex one. Everything
/// above 16 MB is the program's, which leaves room for a kernel far larger
/// than this one.
const heap_base: usize = 16 << 20;

var heap_at: usize = heap_base;
var heap_end: usize = heap_base;

fn bumpAlloc(_: *anyopaque, len: usize, alignment: std.mem.Alignment, _: usize) ?[*]u8 {
    const at = alignment.forward(heap_at);
    if (at + len > heap_end) return null;
    heap_at = at + len;
    return @ptrFromInt(at);
}

fn bumpResize(_: *anyopaque, _: []u8, _: std.mem.Alignment, _: usize, _: usize) bool {
    return false;
}

fn bumpRemap(_: *anyopaque, _: []u8, _: std.mem.Alignment, _: usize, _: usize) ?[*]u8 {
    return null;
}

fn bumpFree(_: *anyopaque, _: []u8, _: std.mem.Alignment, _: usize) void {}

const bump_vtable = std.mem.Allocator.VTable{
    .alloc = bumpAlloc,
    .resize = bumpResize,
    .remap = bumpRemap,
    .free = bumpFree,
};

var bump_context: u8 = 0;

/// **NOTHING IS EVER FREED.** A page core.zig makes lives as long as the run,
/// and a run here is the whole life of the machine, so a bump pointer is the
/// whole allocator. Roc's own refcounting frees into this and the memory stays
/// spent; a program that churns will run the machine out, and it will say so.
pub const allocator = std.mem.Allocator{ .ptr = @ptrCast(&bump_context), .vtable = &bump_vtable };

/// QEMU's isa-debug-exit: a write of `code` to 0xF4 ends the guest with
/// `code << 1 | 1`, which is how the harness tells a verdict from a crash.
fn exitQemu(code: u8) noreturn {
    outb(0xF4, code);
    // The device always exits, so this is only for a machine without it.
    while (true) asm volatile ("hlt");
}

pub fn stop(msg: []const u8) noreturn {
    serialWrite(core.console());
    serialWrite("\nstopped: ");
    serialWrite(msg);
    serialWrite("\n");
    exitQemu(1);
}

pub const panic = std.debug.FullPanic(panicImpl);
fn panicImpl(msg: []const u8, _: ?usize) noreturn {
    stop(msg);
}

/// The timestamp counter. Its rate is not known without measuring it against
/// something, and nothing here waits yet, so this is the counter itself: a
/// clock that moves forward and never claims a unit it has not earned.
pub fn nowNs() u64 {
    var hi: u32 = undefined;
    var lo: u32 = undefined;
    asm volatile ("rdtsc"
        : [lo] "={eax}" (lo),
          [hi] "={edx}" (hi),
    );
    return (@as(u64, hi) << 32) | lo;
}

pub fn sleepNs(_: u64) void {}

pub fn flushed() void {}

pub fn asset(_: []const u8) ?[]const u8 {
    return null;
}

comptime {
    core.exportSymbols();
}

// ---- the boot ------------------------------------------------------------

/// The stack. Multiboot hands control over with no usable one.
var stack: [64 * 1024]u8 align(16) = undefined;

extern fn roc_main(args: builtins_list.RocList) callconv(.c) i8;
const builtins_list = @import("builtins").list;

fn boot() callconv(.c) noreturn {
    serialInit();
    const ram: u64 = @as(*const u32, @ptrFromInt(ram_size_cell)).*;
    heap_end = if (ram > heap_base) @intCast(ram) else heap_base + (64 << 20);

    const code = core.run();
    serialWrite(core.console());
    exitQemu(if (code == 0) 0 else 1);
}

/// Multiboot leaves the machine in 32-bit protected mode with paging off, and
/// this kernel is 64-bit, so the real entry has long mode to set up before it
/// can call `boot`. That stub is not written yet: this entry is what the link
/// needs, and what a machine needs is the next step.
export fn _start() callconv(.naked) noreturn {
    asm volatile (
        \\ leaq %[stack_top], %%rsp
        \\ call %[boot:P]
        :
        : [stack_top] "m" (@as([*]u8, @ptrCast(&stack))[stack.len - 16]),
          [boot] "X" (&boot),
    );
}
