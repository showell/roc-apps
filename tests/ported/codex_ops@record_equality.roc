# ops@record-equality
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@record-equality.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     record equal=True
#     record differs=False
#     record not-equal-operator=True
#     record text-field=True
#     record nested=True
#     record nested-differs=False
#     record list-field=True
#     record list-field-differs=False
#     record real-field-builds=True

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# RecordEquality -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Point : { px : I64, py : I64 }
Named : { n_name : List(U8), n_point : Point }
Carrier : { c_items : List(I64), c_tag : List(U8) }
Priced : { pr_name : List(U8), pr_cost : F64 }

yn : Bool -> List(U8)
yn = |b| (if b { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] })

mk_point : I64 -> Point
mk_point = |k| { px: k, py: (k + 1) }

mk_named : I64 -> Named
mk_named = |k| { n_name: Text.show_int(k), n_point: mk_point(k) }

mk_carrier : I64 -> Carrier
mk_carrier = |k| { c_items: [k, (k + 1), (k + 2)], c_tag: Text.show_int(k) }

a_plain : List(U8)
a_plain = List.concat([21, 13, 24, 16, 21, 22, 2, 13, 37, 25, 15, 23, 77], yn((mk_point(3) == mk_point(3))))

a_differs : List(U8)
a_differs = List.concat([21, 13, 24, 16, 21, 22, 2, 22, 17, 28, 28, 13, 21, 19, 77], yn((mk_point(3) == mk_point(4))))

a_neq : List(U8)
a_neq = List.concat([21, 13, 24, 16, 21, 22, 2, 18, 16, 14, 73, 13, 37, 25, 15, 23, 73, 16, 31, 13, 21, 15, 14, 16, 21, 77], yn((mk_point(3) != mk_point(4))))

a_text_field : List(U8)
a_text_field = List.concat([21, 13, 24, 16, 21, 22, 2, 14, 13, 36, 14, 73, 28, 17, 13, 23, 22, 77], yn(({ n_name: Text.show_int(7), n_point: mk_point(1) } == { n_name: Text.show_int(7), n_point: mk_point(1) })))

a_nested : List(U8)
a_nested = List.concat([21, 13, 24, 16, 21, 22, 2, 18, 13, 19, 14, 13, 22, 77], yn((mk_named(5) == mk_named(5))))

a_nested_differs : List(U8)
a_nested_differs = List.concat([21, 13, 24, 16, 21, 22, 2, 18, 13, 19, 14, 13, 22, 73, 22, 17, 28, 28, 13, 21, 19, 77], yn((mk_named(5) == mk_named(6))))

a_list_field : List(U8)
a_list_field = List.concat([21, 13, 24, 16, 21, 22, 2, 23, 17, 19, 14, 73, 28, 17, 13, 23, 22, 77], yn((mk_carrier(2) == mk_carrier(2))))

a_list_field_differs : List(U8)
a_list_field_differs = List.concat([21, 13, 24, 16, 21, 22, 2, 23, 17, 19, 14, 73, 28, 17, 13, 23, 22, 73, 22, 17, 28, 28, 13, 21, 19, 77], yn((mk_carrier(2) == mk_carrier(9))))

a_real_builds : List(U8)
a_real_builds = List.concat([21, 13, 24, 16, 21, 22, 2, 21, 13, 15, 23, 73, 28, 17, 13, 23, 22, 73, 32, 25, 17, 23, 22, 19, 77], yn((Text.len({ pr_name: [36], pr_cost: 1.5 }.pr_name) == 1)))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(a_plain))
	line!(Text.printed(a_differs))
	line!(Text.printed(a_neq))
	line!(Text.printed(a_text_field))
	line!(Text.printed(a_nested))
	line!(Text.printed(a_nested_differs))
	line!(Text.printed(a_list_field))
	line!(Text.printed(a_list_field_differs))
	line!(Text.printed(a_real_builds))
	Ok({})
}
