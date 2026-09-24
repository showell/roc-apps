`--opt=speed`: a `while $next != $d` loop whose pass is a local closure stops after one pass (wrong result, no crash)

This program relaxes distances along a chain until a pass changes nothing. Each pass moves a value one step, so it should take ten passes. The dev backend does; the LLVM build stops after one and prints a wrong answer:

```roc
answer : U64 -> Str
answer = |n| {
	# Edges highest first, so a pass moves a value one step.
	edges = List.map_with_index(List.repeat(0, n - 1), |_, i| { from: n - 1 - i, to: n - 2 - i, cost: 1 })
	relax = |d|
		List.fold(
			edges,
			d,
			|acc, e| {
				via = (List.get(acc, e.to) ?? 1000) + e.cost
				if via < (List.get(acc, e.from) ?? 1000) {
					List.set(acc, e.from, via) ?? crash("relax: out of range")
				} else {
					acc
				}
			},
		)
	start = List.set(List.repeat(1000, n), 0, 0) ?? crash("start")
	var $d = start
	var $next = relax(start)
	var $passes = 1
	while $next != $d {
		$d = $next
		$next = relax($d)
		$passes = $passes + 1
	}
	"passes ${U64.to_str($passes)}: ${Str.join_with(List.map($d, I64.to_str), " ")}"
}

main! = |args| {
	echo!(answer(10 + List.len(args)))
	Ok({})
}
```

```
$ roc build App.roc --opt=dev   --output=app-dev   && ./app-dev
passes 10: 0 1 2 3 4 5 6 7 8 9
$ roc build App.roc --opt=speed --output=app-speed && ./app-speed
passes 1: 0 1 1000 1000 1000 1000 1000 1000 1000 1000
```

The same on `nightly-2026-09-07-14d9829`, `2026-09-19-d025939`, `2026-09-22-e494788` and `2026-09-23-c7852fd` (release tarballs, x86-64 Linux, each with a fresh cache). The wasm32 LLVM build of the same code stops after two passes.

It looks as though `relax` writes into the list `$d` still names, so after the first pass `$next` and `$d` are the same list and compare equal. Having the pass return whether it changed anything, instead of comparing the lists, gives the right answer on both backends.

**Where we hit it.** A board game's distance tables came out all "far" in the LLVM build and right in the dev build, which is how we noticed: a tuning experiment tied exactly.

---

Reported by Claude (Anthropic's Claude Code), working with @showell. The files are in https://github.com/showell/roc-apps/tree/master/findings/llvm-closure-loop-alias (`run.sh` builds and runs both).
