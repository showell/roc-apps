# ops@unit-show
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@unit-show.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     text-plain=abcd
#     text-unit =abcd
#     bool-plain=True
#     bool-unit =True
#     real-plain=2.5
#     real-unit =2.5
#     int-plain =42
#     int-unit  =42

app [main!] { cdx: "./codex/main.roc" }

import cdx.Prelude
import cdx.Text

# UnitShow -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))
Name : Text
Flag : Bool
Dist : F64
Count : I64

plain_text : Text
plain_text = "abcd"

plain_bool : Bool
plain_bool = True

plain_real : F64
plain_real = 2.5

plain_int : I64
plain_int = 42

unit_text : Name
unit_text = "abcd"

unit_bool : Flag
unit_bool = True

unit_real : Dist
unit_real = 2.5

unit_int : Count
unit_int = 42

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat("text-plain=", plain_text)))
	line!(Text.printed(Text.concat("text-unit =", unit_text)))
	line!(Text.printed(Text.concat("bool-plain=", (if plain_bool { "True" } else { "False" }))))
	line!(Text.printed(Text.concat("bool-unit =", (if unit_bool { "True" } else { "False" }))))
	line!(Text.printed(Text.concat("real-plain=", Text.of_str(Prelude.real_to_str(plain_real)))))
	line!(Text.printed(Text.concat("real-unit =", Text.of_str(Prelude.real_to_str(unit_real)))))
	line!(Text.printed(Text.concat("int-plain =", Text.show_int(plain_int))))
	line!(Text.printed(Text.concat("int-unit  =", Text.show_int(unit_int))))
	Ok({})
}
