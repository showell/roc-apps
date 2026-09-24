# when-bool-pattern
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/when-bool-pattern.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     bare-true: 1
#     bare-false: 1
#     computed: 1
#     both-arms-named: 9
#     if-control: 1
#     int-control: 1
#     char-control: 1

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# WhenBoolPattern -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

bare_true : I64
bare_true = (match True {
	True => 1
	_ => 0
})

bare_false : I64
bare_false = (match False {
	False => 1
	_ => 0
})

computed : I64
computed = (match ((5 + 0) == (5 + 0)) {
	True => 1
	_ => 0
})

both_arms_named : I64
both_arms_named = (match False {
	True => 7
	False => 9
})

if_control : I64
if_control = (if ((5 + 0) == (5 + 0)) { 1 } else { 0 })

int_control : I64
int_control = (match (5 + 0) {
	5 => 1
	_ => 0
})

char_control : I64
char_control = (match 15 {
	15 => 1
	_ => 0
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Text.concat("bare-true: ", Text.show_int(bare_true))))
	line!(Text.printed(Text.concat("bare-false: ", Text.show_int(bare_false))))
	line!(Text.printed(Text.concat("computed: ", Text.show_int(computed))))
	line!(Text.printed(Text.concat("both-arms-named: ", Text.show_int(both_arms_named))))
	line!(Text.printed(Text.concat("if-control: ", Text.show_int(if_control))))
	line!(Text.printed(Text.concat("int-control: ", Text.show_int(int_control))))
	line!(Text.printed(Text.concat("char-control: ", Text.show_int(char_control))))
	Ok({})
}
