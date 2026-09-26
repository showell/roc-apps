# ops@record-generic-eq
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@record-generic-eq.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     box text equal=True
#     box text differs=False
#     box int equal=True
#     box int differs=False
#     box not-equal=True
#     nested equal=True
#     nested differs=False
#     hamt equal=True
#     hamt differs=False

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Hamt

# RecordGenericEq -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Box_(a) : { item : a, tag : I64 }
Pair(a) : { left : Box_(a), right : List(a) }

yn : Bool -> CceText
yn = |b| (if b { "True" } else { "False" })

box_text : CceText -> Box_(CceText)
box_text = |s| { item: s, tag: 1 }

box_int : I64 -> Box_(I64)
box_int = |n| { item: n, tag: 2 }

pair_of : I64, I64 -> Pair(I64)
pair_of = |a, b| { left: box_int(a), right: [a, b] }

map_of : I64 -> Hamt.HamtMap(I64)
map_of = |n| Hamt.hamt_set(Hamt.hamt_set(Hamt.hamt_empty, "a", 1), "b", n)

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("box text equal=", yn((box_text(CceText.show_int(12)) == box_text(CceText.show_int(12)))))))
	line!(CceText.printed(CceText.concat("box text differs=", yn((box_text("x") == box_text("y"))))))
	line!(CceText.printed(CceText.concat("box int equal=", yn((box_int(7) == box_int(7))))))
	line!(CceText.printed(CceText.concat("box int differs=", yn((box_int(7) == box_int(8))))))
	line!(CceText.printed(CceText.concat("box not-equal=", yn((if (box_int(7) == box_int(8)) { False } else { True })))))
	line!(CceText.printed(CceText.concat("nested equal=", yn((pair_of(3, 4) == pair_of(3, 4))))))
	line!(CceText.printed(CceText.concat("nested differs=", yn((pair_of(3, 4) == pair_of(3, 5))))))
	line!(CceText.printed(CceText.concat("hamt equal=", yn((map_of(2) == map_of(2))))))
	line!(CceText.printed(CceText.concat("hamt differs=", yn((map_of(2) == map_of(3))))))
	Ok({})
}
