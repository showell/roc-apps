# roc-iter-map
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/roc-iter-map.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     24

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# RocIterMap -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Iter_(a) := { next : (I64 -> Step(a)) }
Step(a) := [One(a, Iter_(a)), Done]

iter_map : Iter_(a), (a -> b) -> Iter_(b)
iter_map = |it, transform| Iter_.{ next: ({
	dev__1 = transform
	dev__2 = it
	|dev__3| lam_0(dev__1, dev__2, dev__3)
}) }

range_to : I64, I64 -> Iter_(I64)
range_to = |start, stop| Iter_.{ next: ({
	dev__1 = start
	dev__2 = stop
	|dev__3| lam_1(dev__1, dev__2, dev__3)
}) }

lam_0 : (a -> b), Iter_(a), I64 -> Step(b)
lam_0 = |transform, it, _ignored| (match (it.next)(0) {
	One(item, rest) => One(transform(item), iter_map(rest, transform))
	Done => Done
})

lam_1 : I64, I64, I64 -> Step(I64)
lam_1 = |start, stop, _ignored| (if (start == stop) { Done } else { One(start, range_to((start + 1), stop)) })

lam_2 : I64 -> I64
lam_2 = |n| (n * 2)

# --- Entry ---

main! = |_args| {
	({
		mapped = iter_map(range_to(1, 3), lam_2)
		(match (mapped.next)(0) {
			One(first, rest) => (match (rest.next)(0) {
				One(second, _ignored) => line!(CceText.printed(CceText.show_int(((first * 10) + second))))
				Done => line!(CceText.printed(CceText.show_int((0 - 2))))
			})
			Done => line!(CceText.printed(CceText.show_int((0 - 1))))
		})
	})
	Ok({})
}
