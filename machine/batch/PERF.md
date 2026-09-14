# The machine's screen, and what it costs

A running record of what the screen programs cost, where the time goes, and
what changed it. Every number here was measured; each says what ran it, on
which build, and how.

## The instruments

- **Node, the page's own build.** `machine/batch/build.sh` builds a unit for
  wasm32 on the dev backend; a run is timed around the host's `run` export,
  the fastest of three fresh instances (`probes/time.mjs`).
- **The probes** in `probes/`, each a small Roc program and a script (its
  README lists them).
- **`strace -c` on Roc's default platform.** Its runtime maps and unmaps pages
  for every allocation, so the count of `mmap` calls is the count of
  allocations, and a buffer copied per write shows up as one `mmap` per write.
- **The native platform** (`machine/native`, whose host allocates with the C
  allocator) for time and `perf` without that system call on every allocation.
- **The size slope** (`tests/copycheck.sh`): hold the writes fixed and vary the
  size of what is written into. Flat is in place; linear is a copy.

## 2026-09-14: the framebuffer read is not where the time goes

`gop-padded-stride` (320x240, stride 512) and `scene-on-screen` (320x240), in
Node on the wasm dev build. "No screen" is the same program built with the
ladder's `MachineScreen`, which never reads the framebuffer.

| program | with the screen read | without | the read |
|---|---|---|---|
| gop-padded-stride | 3,800 ms | 3,713 ms | about 90 ms |
| scene-on-screen | 4,850 ms | 4,314 ms | about 540 ms |

The time is the programs' own work: a `poke-32` or `peek-32` per pixel,
through the machine's doors and its memory trie.

## 2026-09-14: Roc's default platform spends it in the kernel

`gop-padded-stride`, dev build, run natively with the same flags:

| platform | run | `mmap` calls | `munmap` calls |
|---|---|---|---|
| Roc's default (the ladder's) | 22.37 s | 1,940,357 | 1,940,356 |
| `machine/native` (C allocator) | 3.06 s | 2,896 | 2,895 |

On the default platform 22.6 s of the run is those two system calls. The
ladder runs every unit on that platform.

## 2026-09-14: one walk down the trie for a multi-byte access

`MachineMem.read` and `MachineMem.write` walk the trie once for a span that
stays inside a 64-byte leaf, rather than once a byte
(`machine/roc/MachineMemTests.roc` covers both paths). Node, wasm dev build:

| program | before | after |
|---|---|---|
| gop-padded-stride | 3,800 ms | 2,970 ms |
| scene-on-screen | 4,850 ms | 3,383 ms |

On the ladder, `net-driver-seam-bound` went from TIMEOUT (120 s) to PASS with
nothing else changed: the unit was never wrong, only slower than the limit.
Ladder 765.

## 2026-09-14: MachineGpu writes its planes in place

`MachineGpu` keeps the depth buffer and the framebuffer in one `List(U32)`,
read only inside the record update that writes it back. A probe app
(`probes/gpu-frame`, built `--opt=dev`, run natively on Roc's default platform) runs
a whole frame at a width from its command line: clear, clear the depth buffer,
two triangles covering the screen written a word at a time into the command
buffer, flush with the glow. The `mmap` count is the allocation count.

| width | pixels | clear only: mmap, time | whole frame: mmap, time |
|---|---|---|---|
| 160 | 19,200 | 4, 0.00 s | 7, 0.02 s |
| 320 | 76,800 | 4, 0.01 s | 7, 0.09 s |
| 640 | 307,200 | 4, 0.06 s | 7, 0.37 s |

Flat allocations at every size, so nothing is copied per pixel; a whole
640x480 frame is about 1.2 microseconds a pixel natively on the dev build.

## 2026-09-14: the framebuffer in the GPU's flat planes

With a screen, the machine keeps the command buffer, depth buffer and
framebuffer in `MachineGpu` instead of the memory trie, and `halt!` hands the
framebuffer plane over without reading it back (roc-apps 54d6617). Fastest of
three runs each:

| program | wasm dev (page), trie | wasm dev (page), GPU planes | native dev, `machine/native` |
|---|---|---|---|
| gop-padded-stride | 2,970 ms | 1,506 ms | 1.14 s |
| scene-on-screen | 3,383 ms | 2,662 ms | 1.99 s |

This is the baseline for splitting the machine record into the fields a pixel
touches and the devices behind one reference.

## 2026-09-14: does a one-field update copy a sub-record beside it?

`probes/record-copy`: 20,000,000 updates of one `U64` field, natively on
the dev backend, fastest of three. The field sits alone, beside a 64-field
(512-byte) record stored inline, beside the same record in a list of one, or
beside it in a `Box`; the update is either a call to a function that answers
`{ ..r, hot: r.hot + 1 }`, or that expression inline in the loop.

| shape | through a call | inline |
|---|---|---|
| the field alone | 0.13 s | 0.15 s |
| beside a 512-byte record, inline | 2.19 s | 1.83 s |
| beside it in a list of one | 0.21 s | 0.19 s |
| beside it in a `Box` | 0.15 s | 0.15 s |

On the dev backend the update copies the inline record, about 100 ns for the
512 bytes, with or without a call. Behind a reference it does not. The LLVM
backend was not measured.

## 2026-09-14: the machine record split

`Machine` is `{ mem, gpu, clock, devices }`, the other devices in one
`Devices` record held in a list of one; a door that changes a device takes it
out of the list and puts it back. Wasm dev build, the page's, fastest of three:

| program | before the split | after |
|---|---|---|
| gop-padded-stride | 1,506 ms | 716 ms |
| scene-on-screen | 2,662 ms | 1,413 ms |

Four ladder units built natively from the ladder's own directories, on Roc's
default platform (the ladder's), fastest of three, with the `mmap` count:

| unit | before: time, mmap | after: time, mmap |
|---|---|---|
| e1000-tx-deadline | 10.18 s, 31 | 3.92 s, 32 |
| gop-padded-stride | 5.61 s, 542,592 | 4.83 s, 542,593 |
| fat16-write | 0.32 s, 14,902 | 0.26 s, 14,911 |
| dhcp-acquire | 0.20 s, 13,023 | 0.20 s, 13,025 |

The allocation counts barely move, so taking the devices out of their list and
putting them back allocates nothing per door. e1000-tx-deadline, a million
memory reads with almost no allocation, is 2.6 times faster; gop-padded-stride
is still mostly the default platform's `mmap` per allocation. The ladder is
unchanged at 779.

## 2026-09-14: writing a device, in a list of one or a Box

`probes/device-write`: 200,000 writes to a devices record of 64 `U64`
fields and a 32,768-byte list, natively on the dev backend on Roc's default
platform, fastest of three. The list of one is taken out and put back as
`Machine.open` and `Machine.close` do; the `Box` is unboxed, updated and boxed
again.

| write | list of one: time, mmap | `Box`: time, mmap |
|---|---|---|
| a scalar field | 0.15 s, 4 | 1.69 s, 200,004 |
| a byte of the 32 KB list | 0.21 s, 4 | 2.04 s, 200,004 |

Boxing again allocates on every write (one `mmap` a write here), while the
list of one writes in place with no allocation at all; neither copies the
32 KB list. Carried untouched, a `Box` costs what a list of one does (the
record-copy table above), so a `Box` suits a part of the machine that is never
written after it is made, and the list of one suits the devices.
