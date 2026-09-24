# roc-closure-captures-list
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/roc-closure-captures-list.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     3

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# RocClosureCapturesList -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

lam_0 : List(I64), I64 -> List(I64)
lam_0 = |xs, _ignored| xs

# --- Entry ---

main! = |_args| {
	({
		xs : List(I64)
		xs = [1, 2]
		f = ({
			dev__1 = xs
			|dev__2| lam_0(dev__1, dev__2)
		})
		result : List(I64)
		result = f(0)
		line!(CceText.printed(CceText.show_int(((List.get(result, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) + (List.get(result, I64.to_u64_wrap(1)) ?? crash("list-at out of range"))))))
	})
	Ok({})
}
