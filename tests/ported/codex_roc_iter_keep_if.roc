# roc-iter-keep-if
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/roc-iter-keep-if.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     2

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# RocIterKeepIf -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Iter_(a) := { next : (I64 -> Step(a)) }
Step(a) := [One(a, Iter_(a)), Done]

iter_keep_if : Iter_(a), (a -> Bool) -> Iter_(a)
iter_keep_if = |it, pred| { next: ({
	dev__1 = it
	dev__2 = pred
	|dev__3| lam_0(dev__1, dev__2, dev__3)
}) }

range_to : I64, I64 -> Iter_(I64)
range_to = |start, stop| { next: ({
	dev__1 = start
	dev__2 = stop
	|dev__3| lam_1(dev__1, dev__2, dev__3)
}) }

lam_0 : Iter_(a), (a -> Bool), I64 -> Step(a)
lam_0 = |it, pred, _ignored| (match (it.next)(0) {
	One(item, rest) => (if pred(item) { One(item, iter_keep_if(rest, pred)) } else { (iter_keep_if(rest, pred).next)(0) })
	Done => Done
})

lam_1 : I64, I64, I64 -> Step(I64)
lam_1 = |start, stop, _ignored| (if (start == stop) { Done } else { One(start, range_to((start + 1), stop)) })

lam_2 : I64 -> Bool
lam_2 = |item| (item == 2)

# --- Entry ---

main! = |_args| {
	({
		kept = iter_keep_if(range_to(1, 4), lam_2)
		(match (kept.next)(0) {
			One(item, _rest) => line!(Text.printed(Text.show_int(item)))
			Done => line!(Text.printed(Text.show_int((0 - 1))))
		})
	})
	Ok({})
}
