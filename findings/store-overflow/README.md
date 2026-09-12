# A record update that overflows the stack

**Not reduced, not reported.** Found in `basic/roc/Basic.roc`'s `store`, which
puts a READ datum or an INPUT reply into an array element.

`repro.sh` runs `10 READ A(1) / 20 DATA 9 / 30 PRINT A(1) / 40 END` twice
on the nightly compiler (`~/build/roc-nightly/roc`):

    direct: exit 1, output ''  overflowed its stack memory
    fresh:  exit 0, output ' 9 '

The only difference is the machine handed to `set_arr`: in `direct` it is the
value `ensure_arr` just returned; in `fresh` it is `{ ..ready, steps:
ready.steps }`. Nothing on that path recurses except `arr_index`, bounded by
the number of arrays.

What the bisection established, each on the same program:

| change to `store`                                        | result     |
|----------------------------------------------------------|------------|
| subscripts only, nothing stored                          | runs       |
| subscripts and `ensure_arr`, nothing stored              | runs       |
| a `crash` just before `set_arr`                          | crash seen |
| a `crash` just after `set_arr` returns                   | overflow   |
| store a constant, skip parsing the datum, literal name   | overflow   |
| the two calls split into bindings                        | overflow   |
| `set_arr`'s body written out in `store`                  | overflow   |
| `set_arr` given `{ ..ready, steps: ready.steps }`        | runs       |

`LET A(1)=9` makes the same two calls and runs: its machine passes through
the expression evaluator between `ensure_arr` and `set_arr`.

To reduce: shrink the machine record and the call chain while `repro.sh`'s
`direct` still overflows, and check at each step that `fresh` still runs.

## A second site: `dim` replacing an array

The same shape overflowed in `dim` when control reached a DIM for an array
that already existed: `{ ..m, arr: List.set(m.arr, at, fresh) ?? crash("dim") }`.
On roc-apps master `122bf35` this listing overflows:

    10 LET T=1 / 20 DIM B(12) / 30 IF T<>1 THEN 60 / 40 LET T=2
    50 GOTO 20 / 60 PRINT T / 70 END

That branch is gone: a DIM is a declaration and does not replace anything.
To reproduce, check out `122bf35`.
