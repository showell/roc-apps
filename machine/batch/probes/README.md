# probes

The small programs behind `../PERF.md`'s numbers. Each builds with the Roc
nightly on `--opt=dev` and writes its binary and logs under
`~/build/roc-apps/gen/probes/`, never here.

| probe | what it measures |
|---|---|
| `time.mjs <wasm> <word>...` | a batch unit's run in Node, fastest of three fresh instances, and whether a screen came back |
| `gpu-frame/run.sh [clear]` | `MachineGpu`'s whole frame at three widths: time and allocations, flat if the planes are written in place |
| `record-copy/run.sh` | a one-field update of a record beside a 512-byte record stored inline, in a list of one, or in a `Box` |
| `device-write/run.sh` | writing a devices record held in a list of one against one in a `Box`: a scalar field and a byte of a 32 KB list |

The allocation counts come from `strace -c -e trace=mmap` on Roc's default
platform, which maps pages for every allocation.
