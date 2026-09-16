# floor

A zig platform under the Roc: the low-level machine in the host, with the Roc
above it free to be an operating system. The essay is
`notes/a-zig-floor-under-a-roc-kernel.md`
(<http://143.244.172.148:9100/notes/a-zig-floor-under-a-roc-kernel.md>).

The machine emulator in `machine/roc` holds every device in one Roc value,
which is how we found out what the doors are. This is the other arrangement:

- **The host owns every mutable byte.** Memory is 3 GB in 1 MB pages, made and
  zeroed the first time the program touches one. The block device's images are
  the host's. The clock is the host's. The Roc value a program threads carries
  the heap's bump pointer and nothing else.
- **A transfer names an address, never a payload.** `Disk.read!(lba, addr)`
  moves 512 bytes from the host's image into the page that address lands on;
  nothing but integers crosses the door. That is what a controller doing DMA
  does, and it is why this platform copies nothing. The Codex builtin already
  had this shape -- `block-read-sector` answers an address -- so the copying in
  `machine/roc` was never the program's idea.
- **The policy stays in Roc.** The capability word is memory, at the address
  x86's kernel keeps it (20536), written by `Machine.boot!` from the effects the
  opening declares and read back by every block door. A program that clears its
  own grant is denied from then on, as on the machine. The host enforces one
  thing: that an address is backed.
- **Every door is loud.** A refusal names the address, the port or the
  position. The Roc side cannot inspect the host's state, so the host has to say
  what it saw.
- **One core, several roots.** `platform/core.zig` is the whole floor; a host
  is a thin root over it that says how this machine reports a crash and where
  its clock comes from. There are two -- the native checker and the browser --
  and a third for a real machine is another compilation and nothing more.

| where | what |
|---|---|
| `platform/main.roc` | the platform: `main!` in Echo's shape and the hosted doors |
| `platform/Heap.roc` | a load and a store of 1, 2, 4 or 8 bytes |
| `platform/Port.roc` | the devices the host answers at an I/O port: codex-vm's GPU at 0x400-0x417 and its keyboard controller at 0x60 and 0x64 |
| `platform/Disk.roc` | the block device: select a position, its sector count, and a transfer naming a sector and an address |
| `platform/Clock.roc` | `now!` and `wait!`, in nanoseconds, on a virtual or a wall clock |
| `platform/Echo.roc` | a line of text |
| `platform/core.zig` | the floor: memory in pages, the screen, the ports, the images, the clock, the faults, and the run |
| `platform/gpu.zig` | codex-vm's GPU over the program's memory |
| `platform/native.zig` | the native root (x86-64 Linux, musl): the flags, the images in and out, each frame's hash, and a run's report |
| `platform/host.zig` | the browser's root (wasm): the exports a page calls, the drives it fills, and a crash kept for the page |
| `roc/Machine.roc` | the floor's side of the state, standing in for the `Machine` rocemit writes, door for door |
| `build.sh` | the host, then each unit emitted and wired to the platform and built natively |
| `run.sh` | one unit, built and run, with a `.disk` beside it attached and the host's flags passed through |
| `page.sh` | each named unit built for wasm into the dev channel, with its image, its screen and the console a clean run must print |
| `web/index.html` | the page: a program, a fault to inflict on it, and what the Roc above did about it |
| `verify.sh`, `verify.tsv` | every row built and run, its console compared with what the row expects |
| `expect/` | the consoles a fault row expects, which the unit's own verdict cannot describe |

    floor/run.sh ~/showell_repos/cobblestone-u61/codex/test/fat16-write.codex -report
    floor/run.sh ~/showell_repos/cobblestone-u61/codex/test/fat16-write.codex -fault tear-write -report
    floor/run.sh ~/showell_repos/cobblestone-u61/codex/test/gpu-panel-border.codex -screen 640 480 640
    floor/verify.sh
    ROC=~/build/roc/fast/bin/roc floor/page.sh <unit.codex>...
    # the dev channel: http://143.244.172.148:9210/floor/

**An image is never written where it was read.** `-disk` reads the file into
the host, which then owns it, and the run's writes land in that copy;
`-disk-out` is the only thing that writes an image back out.

## The faults

The floor can be put in a mode where it breaks its promises on purpose, and the
Roc above has to cope. The plans are deterministic -- a plan counts the
transfers it matches and bites on every `-fault-every`-th one, optionally only
at the sector `-fault-lba` names -- so a run repeats exactly and a fault row in
`verify.tsv` is a regression test.

| kind | what the floor does |
|---|---|
| `refuse-read` | the transfer moves nothing and the buffer is filled with 0xDD |
| `refuse-write` | the transfer moves nothing, and the door answers a failure |
| `tear-write` | half the sector is written and the door answers success |

`refuse-read` poisons its buffer rather than leaving it alone. Hardware may
leave a buffer untouched, and a caller that ignores the error then reads
whatever was there before -- stale bytes that are often still plausible, so the
mistake hides. A fault is allowed to be adversarial where hardware is merely
unlucky.

`tear-write` answers success on purpose: the controller thought it wrote, and
finding out otherwise is the filesystem's problem. That is what makes it the
hard one.

## What fat16-write says under each

Cobblestone's `codex/test/fat16-write.codex`, 2,291 lines of `Fat16` over 171
sector reads and 8 writes. Every row below is in `verify.tsv`.

| run | console | what it shows |
|---|---|---|
| clean | its verdict, exactly | the floor is the machine's answer, not a near one |
| `tear-write` | its verdict, exactly | this workload never reads back the half of a sector the tear drops |
| `refuse-write` | `wrote False` … `bin <none>` | Fat16 reports the failure honestly and stays consistent |
| `refuse-read` | the same | a filesystem that can read nothing writes nothing |
| `refuse-read -fault-every 7` | `wrote-bin True`, then `bin <none>` | **a write reported as a success whose file is not there** |

The last row is the one to look at. `Fat16` does check whether a write landed
-- `fat16-put-entry-and-write` answers True only when `block-write-sector`
answers 0 -- so under `refuse-write` it tells the truth. It has no such
check available for a read, because **`block-read-sector` answers an address
and nothing else**: there is no channel in that builtin for "this sector did
not arrive". With every seventh read poisoned, the program writes data derived
from sectors it never received, reports success, and cannot read the file back.

Nothing in the program could have noticed. That is a gap in the builtin, not a
bug in `Fat16`, and it is an argument for what a Roc kernel on this floor needs
that the machine never offered it: a read door with an outcome.

## The screen

A program gets one only when `-screen` asks for it, so a program that reaches
the disk prints its console and nothing else. With a screen, the host publishes
its geometry where UEFI's GOP protocol and codex-vm publish it, codex-vm's GPU
draws through the Port doors, and every frame's time and the hash of its
visible pixels go out as a line.

Those hashes are the check that matters. `verify.tsv`'s screen rows carry
`framebuffer/verify.tsv`'s hashes -- the images the framebuffer platform and
the machine page's `MachineGpu` both drew -- so a green row means this floor
draws the same picture as the two things that came before it, pixel for pixel.

## What it costs

`fat16-write` against its 16 MB fixture, both natively on the dev backend,
fastest of three, on this box (2026-09-16). The Roc machine is
`machine/native` -- the same emulator, its disk answered by host files rather
than modelled -- so the difference is the memory model and the transfers, not
the compiler.

| | run | RSS |
|---|---|---|
| the Roc machine (`machine/native`) | 0.13 s | 3.2 MB |
| this floor | **0.02 s** | 19 MB |

The floor is about six times faster and holds more: it reads the whole image
into the host at startup, so a 16 MB fixture is 16 MB of RSS, where the Roc
machine reads a sector from the file when it wants one. That is the right trade
at this size and the wrong one at a real disk's; reading on demand, or mapping
the file, is the fix when it matters.

**Crossings, which is the measurement that decides whether the seam is at the
right height.** One clean `fat16-write`:

| door | crossings |
|---|---|
| `Heap.load!` | 21,133 |
| `Heap.store!` | 1,097 |
| `Disk.read!` / `write!` | 171 / 8 |

179 transfer crossings for the whole program, about 124 byte crossings a
sector -- `Fat16` reading a sector's fields out of memory one at a time, which
is the byte rung doing its job. Nothing here is thousands per protocol event,
so the seam is where it should be.

## The device drivers live in gopher-metal

`virtio.zig` and the probe kernel that proved it moved to
`~/showell_repos/gopher-metal` (2026-09-16), which is the machine with no
operating system under it: the boot, the drivers, and eventually the chat
server. This floor is the Roc side — the doors, the FAT16 that runs on them,
and the faults. The two are two implementations of one device set, which is
why the drivers there are written against the doors here.

## What is not here yet

- **The page is new and thin.** It runs one program at a time on the main
  thread, which suits a program that ends its run; a program that draws in a
  loop of its own wants the framebuffer page's Web Worker.
- **A real machine's root.** The Raspberry Pi is the reason the core and the
  roots are separated at all; the root is the small part.
- **A disk larger than memory.** The host reads an image in whole and owns it;
  there is no reading on demand and no mapping yet.
- **`wait!` has no caller.** `Clock` is wired end to end and nothing rocemit
  writes calls it yet. It is here because it is what an operating system above
  this floor is built on, and because a virtual clock is how a run with waiting
  in it still repeats exactly.
