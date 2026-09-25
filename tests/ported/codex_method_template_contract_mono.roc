# method-template-contract-mono
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/method-template-contract-mono.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     10
#     20

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# MethodTemplateContractMono -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
MonoContractDict(a) : { mono_value_impl : (a -> I64) }

monoContract_dict_Integer : MonoContractDict(I64)
monoContract_dict_Integer = { mono_value_impl: lam_0 }

mono_value_Integer : I64 -> I64
mono_value_Integer = |x| (x + 1)

mono_value : I64 -> I64
mono_value = |x| (x + 1)

lam_0 : I64 -> I64
lam_0 = |x| (x + 1)

# --- Entry ---

main! = |_args| {
	({
		d = monoContract_dict_Integer
		({
			line!(CceText.printed(CceText.show_int((d.mono_value_impl)(9))))
			line!(CceText.printed(CceText.show_int(mono_value(19))))
		})
	})
	Ok({})
}
