# machine

A machine emulator in Roc: one value holding simulated devices, the ones
codex-vm models for upstream's tests. The plan is in the essays
`notes/codex-devices-in-roc.md` and `notes/roc-machine-emulator.md`.

Two programs drive it:

- **Codex, emitted by rocemit.** A unit that reaches a port builtin threads
  `Machine` through every definition that touches memory or ports, and its
  opening boots the machine from the command line (`Machine.boot`). The
  ladder copies these modules in beside the emitted ones and passes the test's
  `.vmargs` as that command line, so a batch run is
  `tests/ladder.sh pci-bridge-cap`.
- **The page's app**, which builds a machine with a disk image and steps it.

| path | what it is |
|---|---|
| `roc/Machine.roc` | the machine record, `boot` from codex-vm flags, and the doors: Codex's memory and port builtins, the block device, keys, the console, a step clock |
| `roc/MachineMem.roc` | the address space, a persistent trie (the module rocemit writes as `Mem` for units without ports) |
| `roc/MachinePci.roc` | PCI configuration space as codex-vm models it: the 0xCF8 latch, the ten-device table with its bridge chain, command and BAR writes |
| `roc/MachineDisk.roc` | drives as image bytes; zeros past the end |
| `roc/MachineApp.roc` | the program the page runs: a PCI bus-0 scan, sector 0 into memory, a key echo |
| `wasm/platform/` | the platform (`main.roc`) and its host (`host.zig`): `newMachine`, `step`, `key`, `view` |
| `web/machine.html` | the page: console, PCI table, the memory a block read landed on |
| `build.sh` | host, app, page and disk image into the preview, `http://<box>:9203/machine/machine.html` |
| `wasm/smoke.mjs` | the same doors from Node, no browser |

    machine/build.sh
    node machine/wasm/smoke.mjs ~/build/roc-apps/next/machine

The disk image is upstream's `codex/test/block-select-drives.disk` (128
sectors), copied from the checkout at build time.
