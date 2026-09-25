# dce-reach
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/dce-reach.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     42
#     42
#     tag5

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# DceReach -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
DceTaggedDict(a) : { dce_show_tag_impl : (I64 -> CceText) }

dce_doubled : I64 -> I64
dce_doubled = |n| (n * 2)

dce_bump : I64 -> I64
dce_bump = |n| (n + 7)

dce_apply_to : (I64 -> I64), I64 -> I64
dce_apply_to = |f, x| f(x)

dceTagged_dict_Integer : DceTaggedDict(I64)
dceTagged_dict_Integer = { dce_show_tag_impl: lam_0 }

dce_show_tag_Integer : I64 -> CceText
dce_show_tag_Integer = |x| CceText.concat("tag", CceText.show_int(x))

dce_show_tag : I64 -> CceText
dce_show_tag = |x| CceText.concat("tag", CceText.show_int(x))

lam_0 : I64 -> CceText
lam_0 = |x| CceText.concat("tag", CceText.show_int(x))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.show_int(dce_apply_to(dce_doubled, 21))))
	line!(CceText.printed(CceText.show_int(dce_apply_to(dce_bump, 35))))
	line!(CceText.printed(dce_show_tag(5)))
	Ok({})
}
