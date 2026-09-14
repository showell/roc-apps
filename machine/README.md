# machine

A machine emulator in Roc: one value holding simulated devices, the ones
codex-vm models for upstream's tests. The plan is in the essays
`notes/codex-devices-in-roc.md` and `notes/roc-machine-emulator.md`.

Two programs drive it:

- **Codex, emitted by rocemit.** A unit that reaches a port, block or
  process builtin threads `Machine` through every definition that touches
  memory or a device, and its opening boots the machine (`Machine.boot!`) with
  the effects it declares, which grant the boot process its capabilities. The
  ladder copies these modules in beside the emitted ones, passes the test's
  `.vmargs` as the command line, and links its `.disk` and `.disk2` in as the
  primary master and slave, imported by a `MachineMedia.roc` it writes. A
  batch run is `tests/ladder.sh fat16-list`.
- **The page's app**, which builds a machine with a disk image and steps it.
- **A real device.** On the native platform the block doors are answered by
  the host, from the files codex-vm's `-disk` and `-disk2` name, written in
  place: `machine/native/run.sh fat16-write.codex -disk copy.img`. The block
  doors end in `!` for that reason, and `MachineDisk` is either the model
  (`roc/`, what the ladder runs) or the host's files (`native/`).

| path | what it is |
|---|---|
| `roc/Machine.roc` | the machine record, `boot!` from codex-vm flags, the address map (RAM below 3 GB, board windows under `-board-mmio`, the device windows, and a named stop anywhere else), the doors for Codex's memory, MMIO, port, block and process builtins, keys, the console, and the machine's clock |
| `roc/MachineCaps.roc` | the boot process's capability word: the grant x86's boot writes from the opening's effects, through `Capability.codex`'s table, which the block doors check |
| `roc/MachineMem.roc` | memory, a persistent trie over 2^36 bytes, taken from the `Mem` rocemit writes for units without devices, which covers 2^31 |
| `roc/MachinePorts.roc` | codex-vm's I/O port map below PCI's: the PIT and the speaker gate, modelled on the machine's clock; the CMOS index; a port another codex-vm device claims stops the run by name; an unclaimed port reads 0xFF |
| `roc/MachinePci.roc` | PCI configuration space as codex-vm models it: the 0xCF8 latch, the ten-device table with its bridge chain, command and BAR writes |
| `roc/MachineE1000.roc` | Intel gigabit Ethernet as codex-vm models it: the register window at 0xFE400000 behind `peek-32`/`poke-32`, the PHY through MDIC, the I219's K1, ULP and MDIO semaphore, the rings in memory, and the fault flags (`-e1000*`, `-i219*`, `-nic-bme-clear`) |
| `roc/MachineHpet.roc` | the HPET at 0xFED00000, counting the machine's own clock, which every device register access moves 100 µs (`Machine.access_cost`) |
| `roc/MachineDisk.roc` | the modelled disk: the primary channel's master and slave, each an image or nothing, as codex-vm's IDE model answers: 255 from an empty position, zeros past the end, writes in an overlay of sectors |
| `roc/MachineMedia.roc` | what a run brings with it: the images the modelled disk attaches and the keystrokes typed, none here; the ladder writes one per unit from its `.disk`, `.disk2` and `.keys` |
| `roc/MachineApp.roc` | the program the page runs: a PCI bus-0 scan, sector 0 into memory, a key echo |
| `wasm/platform/` | the page's platform (`main.roc`) and its host (`host.zig`): `newMachine`, `step`, `key`, `view` |
| `native/platform/` | the native platform: Echo's shape plus a hosted `Drive` (`open!`, `sector_count!`, `read!`, `write!`) over files, and its host (`host.zig`, x86_64-linux-musl) |
| `native/MachineDisk.roc` | the host's disk: the same doors as the model, answered by `Drive` |
| `native/build.sh` | the host library into `platform/targets/x64musl/`, beside the fx test platform's musl runtime |
| `native/run.sh` | a Codex unit emitted by rocemit, wired to the native platform and run with codex-vm's flags |
| `native/probe.roc` | the platform alone: open a file, read a sector, read the empty slave |
| `web/machine.html` | the page: console, PCI table, the memory a block read landed on |
| `build.sh` | host, app, page and disk image into the preview, `http://<box>:9203/machine/machine.html` |
| `wasm/smoke.mjs` | the same doors from Node, no browser |

    machine/build.sh
    node machine/wasm/smoke.mjs ~/build/roc-apps/next/machine

The disk image is upstream's `codex/test/block-select-drives.disk` (128
sectors), copied from the checkout at build time.
