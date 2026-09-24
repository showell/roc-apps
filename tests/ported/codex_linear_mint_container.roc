# linear-mint-container
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/linear-mint-container.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     1

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# LinearMintContainer -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bus_acquire : I64 -> I64
bus_acquire = |n| n

stash_arg : I64 -> I64
stash_arg = |n| ({
	g : I64
	g = bus_acquire(n)
	U64.to_i64_wrap(List.len([g]))
})

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.show_int(stash_arg(7))))
	Ok({})
}
