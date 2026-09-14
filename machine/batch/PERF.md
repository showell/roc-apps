# The machine's screen, and what it costs

A running record of what the screen programs cost, where the time goes, and
what changed it. Every number here was measured; each says what ran it, on
which build, and how.

## The instruments

- **Node, the page's own build.** `machine/batch/build.sh` builds a unit for
  wasm32 on the dev backend; a run is timed around the host's `run` export,
  the fastest of three fresh instances.
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
