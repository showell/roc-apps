# The default platform's allocator makes one `mmap` per heap value, and one `munmap` per free

`src/default_platform/linux_runtime.zig`'s `rocAlloc` calls `linux.mmap`
for every allocation and `rocDealloc` calls `linux.munmap` for every free,
so a program that allocates a small list in a loop spends its time in the
kernel and rounds every value up to a page.

```roc
app [main!] {}

# Allocate a small list and drop it, n times. n comes from the command
# line so the compiler cannot evaluate the loop at compile time.
step : I64, I64 -> I64
step = |n, total| if n <= 0 { total } else { step(n - 1, total + U64.to_i64_wrap(List.len(List.repeat(0, 16)))) }

main! = |args| {
	n = I64.from_str(List.get(args, 0) ?? "100000") ?? 100000
	echo!(Str.concat(I64.to_str(step(n, 0)), "\n"))
	Ok({})
}
```

    $ roc build churn.roc --output=churn
    $ strace -c -f ./churn 100000
    % time     seconds  usecs/call     calls    errors syscall
     57.93    0.630960           6    100001           munmap
     42.07    0.458198           4    100002           mmap

    $ /usr/bin/time -f "%e s wall, %U user, %S sys" ./churn 100000
    0.80 s wall, 0.06 user, 0.68 sys

One `mmap` and one `munmap` per iteration, exactly, and eleven times as
much kernel time as user time. At 10,000 iterations it is 10,001 of each,
so it is one per allocation rather than a growth step.

A 16-element `List(I64)` is 128 bytes and gets a 4096-byte mapping, since
`rocAlloc` page-aligns `prefix + length`.

## Where we met it

A Bloom filter test of ours, 100 inserts and 500 queries over 1024 bits,
runs in 240 ms: 33,801 `mmap`/`munmap` pairs, 0.02 s user and 0.25 s sys.
Every other program in the same corpus runs in 2-3 ms. The work it does is
a few thousand bit operations.

## Scope

This is the build-only default platform, which is what `roc build` and
`roc run` give a platformless app, so it is the path a quick program and
much of the test suite take. A program on another platform uses that
platform's `roc_alloc` instead.

**Version.** `nightly-2026-09-11-793f9d8`, the release tarball from
roc-lang/nightlies (`roc_nightly-linux_x86_64-2026-09-11-793f9d8`),
x86-64 Linux, 8 GB, otherwise idle.
