# A value threaded through a recursive function makes the caller's next write copy

**Reduced, not reported** (Steve's call). Nightly `2026-09-11-793f9d8`,
default platform, where every heap value is its own `mmap`
([roc-lang/roc#11335](https://github.com/roc-lang/roc/issues/11335)), so a
copy shows up as one `mmap` call.

Each variant writes one cell of a 286-element `List(F64)` inside a machine
record, 10,000 times; they differ only in what happens to the machine before
the write. `run.sh` builds and counts them.

| variant | before each write | `mmap` |
|---|---|---|
| `a_field_then_at` | the machine goes through a recursive `eval` returning `{ m, v, at }`; the write uses `r.m`, then `r.at` | 10,001 |
| `b_bound_first` | the same, fields bound first | 10,001 |
| `c_destructured` | the same, `{ m: m1, v, at } = eval(...)` | 10,001 |
| `d_no_eval` | no `eval` | 2 |
| `e_eval_without_m` | recursive `eval` never takes the machine, returns `{ v, at }` | 2 |
| `f_one_call_record` | one non-recursive call returning `{ m, v, at }` | 2 |
| `g_recursive_updates_m` | recursive `eval` updates `m` each step and returns it in a record | 10,001 |
| `h_recursive_returns_m` | recursive `eval` returns `m` itself | 5,001 |
| `i_recursive_reads_m` | recursive `eval` takes `m`, only reads it, returns `{ v, at }` | 2 |
| `j_mutual_reads_m` | the same across two mutually recursive functions | 2 |

So the copy follows **a value passed down a recursion and handed back**, not
the record around it and not how the result is spelled. Reading the value in
a recursion is free. `h` copying on every other write is not explained.

This is why the BASIC interpreter's writes after an expression copy: its
evaluator threads the machine and returns it. The redesign that follows from
it: http://143.244.172.148:9100/notes/basic-machine-design.md

## Retested on nightly 2026-09-23-c7852fd

The `mmap` count no longer measures copies: roc#11335 is fixed, and the
default platform allocates through a brk allocator, so every variant reads 1.
And a regression: `h_recursive_returns_m` built `--opt=dev` overflows its
stack on 09-23 ("Roc application overflowed its stack memory"), where 09-19's
dev build prints 1; the 09-23 `--opt=speed` build prints 1.
