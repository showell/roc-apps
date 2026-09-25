# method-template-contract-bounds-large
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/method-template-contract-bounds-large.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     True

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# MethodTemplateContractBoundLarge -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bound_value_Integer : I64, a -> a
bound_value_Integer = |_x, y| y

bound_value : I64, a -> a
bound_value = |_x, y| y

# --- Entry ---

main! = |_args| {
	line!(CceText.printed((if (List.get((List.get((List.get((List.get(bound_value(1, [[[[True]]]]), I64.to_u64_wrap(0)) ?? crash("list-at out of range")), I64.to_u64_wrap(0)) ?? crash("list-at out of range")), I64.to_u64_wrap(0)) ?? crash("list-at out of range")), I64.to_u64_wrap(0)) ?? crash("list-at out of range")) { "True" } else { "False" })))
	Ok({})
}
