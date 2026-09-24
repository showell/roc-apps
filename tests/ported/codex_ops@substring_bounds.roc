# ops@substring-bounds
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@substring-bounds.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#      0,0=[] 0,1=[a] 0,2=[ab] 0,3=[abc] 0,4=[abcd] 0,5=[abcde] 1,0=[] 1,1=[b] 1,2=[bc] 1,3=[bcd] 1,4=[bcde] 2,0=[] 2,1=[c] 2,2=[cd] 2,3=[cde] 3,0=[] 3,1=[d] 3,2=[de] 4,0=[] 4,1=[e] 5,0=[]
#     len=5
#     empty-at-end=0

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# SubstringBounds -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

s : CceText
s = "abcde"

row : I64, I64 -> CceText
row = |start, len| ({
	r = CceText.substring(s, start, len)
	CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(" ", CceText.show_int(start)), ","), CceText.show_int(len)), "=["), r), "]")
})

from_start : I64, I64, I64, CceText -> CceText
from_start = |start, len, room, acc| (if (len > room) { acc } else { from_start(start, (len + 1), room, CceText.concat(acc, row(start, len))) })

walk : I64, I64, CceText -> CceText
walk = |start, n, acc| (if (start > n) { acc } else { walk((start + 1), n, CceText.concat(acc, from_start(start, 0, (n - start), ""))) })

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(walk(0, CceText.len(s), "")))
	line!(CceText.printed(CceText.concat("len=", CceText.show_int(CceText.len(CceText.substring(s, 0, 5))))))
	line!(CceText.printed(CceText.concat("empty-at-end=", CceText.show_int(CceText.len(CceText.substring(s, 5, 0))))))
	Ok({})
}
