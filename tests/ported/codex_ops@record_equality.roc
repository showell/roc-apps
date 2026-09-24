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
Named : { n_name : Text, n_point : Point }
Carrier : { c_items : List(I64), c_tag : Text }
Priced : { pr_name : Text, pr_cost : F64 }

yn : Bool -> Text
yn = |b| (if b { "True" } else { "False" })

mk_point : I64 -> Point
mk_point = |k| { px: k, py: (k + 1) }

mk_named : I64 -> Named
mk_named = |k| { n_name: Text.show_int(k), n_point: mk_point(k) }

mk_carrier : I64 -> Carrier
mk_carrier = |k| { c_items: [k, (k + 1), (k + 2)], c_tag: Text.show_int(k) }

a_plain : Text
a_plain = Text.concat("record equal=", yn((mk_point(3) == mk_point(3))))

a_differs : Text
a_differs = Text.concat("record differs=", yn((mk_point(3) == mk_point(4))))

a_neq : Text
a_neq = Text.concat("record not-equal-operator=", yn((mk_point(3) != mk_point(4))))

a_text_field : Text
a_text_field = Text.concat("record text-field=", yn(({ n_name: Text.show_int(7), n_point: mk_point(1) } == { n_name: Text.show_int(7), n_point: mk_point(1) })))

a_nested : Text
a_nested = Text.concat("record nested=", yn((mk_named(5) == mk_named(5))))

a_nested_differs : Text
a_nested_differs = Text.concat("record nested-differs=", yn((mk_named(5) == mk_named(6))))

a_list_field : Text
a_list_field = Text.concat("record list-field=", yn((mk_carrier(2) == mk_carrier(2))))

a_list_field_differs : Text
a_list_field_differs = Text.concat("record list-field-differs=", yn((mk_carrier(2) == mk_carrier(9))))

a_real_builds : Text
a_real_builds = Text.concat("record real-field-builds=", yn((Text.len({ pr_name: "x", pr_cost: 1.5 }.pr_name) == 1)))

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
