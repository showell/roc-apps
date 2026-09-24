Dev backend: "overflowed its stack memory" on nightly 2026-09-23 in a small program that 09-22 runs

```roc
M : { num : List(F64), scr : List(U8), out : List(Str), pc : U64 }
R : { m : M, v : F64, at : U64 }

eval : M, List(U8), U64 -> M
eval = |m, b, i|
	if i >= List.len(b) { m } else { eval(m, b, i + 1) }

spin : M, List(U8), U64, U64 -> M
spin = |m, b, i, n|
	if i >= n {
		m
	} else {
		m1 = eval(m, b, 0)
		spin({ ..m1, num: List.set(m1.num, 7, 1.0) ?? crash("oob"), pc: i }, b, i + 1, n)
	}

main! = |args| {
	n = 10000 + List.len(args)
	m0 = { num: List.repeat(0.0, 286), scr: List.repeat(32.U8, 1000), out: [], pc: 0 }
	final = spin(m0, Str.to_utf8("X=X+1 AND SOME MORE TEXT"), 0, n)
	echo!(F64.to_str(List.get(final.num, 7) ?? 0.0))
	Ok({})
}
```

`roc build App.roc --opt=dev && ./App` prints `1` on `nightly-2026-09-19-d025939` and `2026-09-22-e494788`; on `2026-09-23-c7852fd` it stops with "Roc application overflowed its stack memory". `--opt=speed` prints `1` on all three.

It is not depth: with `n = 0` (no call to `eval`) it prints `0`, and with `n = 1` -- one `eval` over 24 bytes -- it already overflows. `eval` alone, called once on the same four-field record, does not reproduce it; it takes `spin`'s record update of what `eval` returned.

Between the two nightlies is a merge of `issue-11448/dev-stack-slot-reuse` (#11448), which may or may not be related.

x86-64 Linux, the release tarballs from roc-lang/nightlies.

**Where we hit it.** Retesting an older finding of ours (a copy per write in a threaded record) on the new nightly.

---

Reported by Claude (Anthropic's Claude Code), working with @showell. The file is https://github.com/showell/roc-apps/tree/master/findings/dev-stack-overflow-0923.
