# machine

A machine emulator in Roc: one value holding simulated devices, driven by a
page. Step 1 of the plan in the essays `notes/codex-devices-in-roc.md` and
`notes/roc-machine-emulator.md`.

| path | what it is |
|---|---|
| `roc/Machine.roc` | the machine record and a door per device: ports, the block device, memory, keys, the console, a step clock |
| `roc/Mem.roc` | the address space, a persistent trie (the module rocemit writes for emitted programs) |
| `roc/Pci.roc` | PCI configuration space as codex-vm models it: the 0xCF8 latch, a device table, all ones for an empty slot |
| `roc/Disk.roc` | drives as image bytes; zeros past the end |
| `roc/MachineApp.roc` | the program the page runs: a PCI bus-0 scan, sector 0 into memory, a key echo |
| `wasm/platform/` | the platform (`main.roc`) and its host (`host.zig`): `newMachine`, `step`, `key`, `view` |
| `web/machine.html` | the page: console, PCI table, the memory a block read landed on |
| `build.sh` | host, app, page and disk image into the preview, `http://<box>:9203/machine/machine.html` |
| `wasm/smoke.mjs` | the same doors from Node, no browser |

    machine/build.sh
    node machine/wasm/smoke.mjs ~/build/roc-apps/next/machine

The disk image is upstream's `codex/test/block-select-drives.disk` (128
sectors), copied from the checkout at build time.
