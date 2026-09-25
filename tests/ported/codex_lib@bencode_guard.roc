# lib@bencode-guard
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lib@bencode-guard.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     int pos=4 int 42
#     neg pos=4 int -7
#     zero pos=3 int 0
#     max pos=21 int 9223372036854775807
#     str pos=6 str [spam]
#     empty-str pos=2 str []
#     list pos=12 list 2
#     dict pos=22 dict 2
#     deep-200 pos=400 list 1
#     junk-int refused
#     empty-int refused
#     leading-zero refused
#     neg-zero refused
#     junk-len refused
#     trailing refused
#     short-str refused
#     big-int refused
#     huge-int refused
#     neg-len refused
#     lz-len refused
#     open-list refused
#     deep-300 refused
#     empty refused

app [main!] { cdx: "./codex/main.roc" }

import cdx.Bencode
import cdx.CceText

# BencodeGuard -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

describe : Bencode.BenValue -> CceText
describe = |v| (match v {
	BenInt(n) => CceText.concat("int ", CceText.show_int(n))
	BenStr(s) => CceText.concat(CceText.concat("str [", s), "]")
	BenList(items) => CceText.concat("list ", CceText.show_int(U64.to_i64_wrap(List.len(items))))
	BenDict(ps) => CceText.concat("dict ", CceText.show_int(U64.to_i64_wrap(List.len(ps))))
})

arm : CceText, CceText -> CceText
arm = |name, s| ({
	r = Bencode.ben_decode(s)
	(if r.ben_ok { CceText.concat(CceText.concat(CceText.concat(CceText.concat(name, " pos="), CceText.show_int(r.ben_pos)), " "), describe(r.ben_value)) } else { CceText.concat(name, " refused") })
})

repeat : CceText, I64, CceText -> CceText
repeat = |t, n, acc| (if (n <= 0) { acc } else { repeat(t, (n - 1), CceText.concat(acc, t)) })

nested : I64 -> CceText
nested = |n| CceText.concat(repeat("l", n, ""), repeat("e", n, ""))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(arm("int", "i42e")))
	line!(CceText.printed(arm("neg", "i-7e")))
	line!(CceText.printed(arm("zero", "i0e")))
	line!(CceText.printed(arm("max", "i9223372036854775807e")))
	line!(CceText.printed(arm("str", "4:spam")))
	line!(CceText.printed(arm("empty-str", "0:")))
	line!(CceText.printed(arm("list", "l4:spami42ee")))
	line!(CceText.printed(arm("dict", "d3:bar4:spam3:fooi42ee")))
	line!(CceText.printed(arm("deep-200", nested(200))))
	line!(CceText.printed(arm("junk-int", "i12abce")))
	line!(CceText.printed(arm("empty-int", "ie")))
	line!(CceText.printed(arm("leading-zero", "i03e")))
	line!(CceText.printed(arm("neg-zero", "i-0e")))
	line!(CceText.printed(arm("junk-len", "x:")))
	line!(CceText.printed(arm("trailing", "i1ei2e")))
	line!(CceText.printed(arm("short-str", "5:ab")))
	line!(CceText.printed(arm("big-int", "i9223372036854775808e")))
	line!(CceText.printed(arm("huge-int", "i99999999999999999999e")))
	line!(CceText.printed(arm("neg-len", "-3:abc")))
	line!(CceText.printed(arm("lz-len", "03:abc")))
	line!(CceText.printed(arm("open-list", "li1e")))
	line!(CceText.printed(arm("deep-300", nested(300))))
	line!(CceText.printed(arm("empty", "")))
	Ok({})
}
