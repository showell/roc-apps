# roc-fold-sum
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/roc-fold-sum.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     10

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# RocFoldSum -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

fold_loop : List(I64), I64, (I64, I64 -> I64), I64 -> I64
fold_loop = |xs, acc, step, i| (if (i >= U64.to_i64_wrap(List.len(xs))) { acc } else { fold_loop(xs, step(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))), step, (i + 1)) })

lam_0 : List(I64), I64, (I64, I64 -> I64) -> I64
lam_0 = |xs, base, step| fold_loop(xs, base, step, 0)

lam_1 : I64, I64 -> I64
lam_1 = |acc, x| (acc + x)

# --- Entry ---

main! = |_args| {
	({
		total = lam_0([1, 2, 3, 4], 0, lam_1)
		line!(Text.printed(Text.show_int(total)))
	})
	Ok({})
}
