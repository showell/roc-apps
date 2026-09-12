# One `mmap` per heap value

**Filed as [roc-lang/roc#11335](https://github.com/roc-lang/roc/issues/11335),
2026-09-12.** `ISSUE.md` is the text as posted; `churn.roc` is the
reproducer.

`src/default_platform/linux_runtime.zig:239` allocates every Roc heap
value with its own `linux.mmap`, page-aligned, and frees it with
`munmap`. 100,000 allocations of a 128-byte list cost 100,001 of each and
0.68 s of kernel time against 0.06 s of user time.

We met it through `bloom-spread`, the one program in our ported corpus
that does real work at run time: 240 ms, of which 0.25 s is kernel and
0.02 s is compute, over 33,801 mmap pairs. Every other program in the
corpus runs in 2-3 ms, because the compiler has already evaluated them
(see `findings/roc-check-hang`).
