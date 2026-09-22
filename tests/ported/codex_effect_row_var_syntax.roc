# effect-row-var-syntax
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/effect-row-var-syntax.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     pure 42
#     shout 21
#     logged 42

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# EffectRowVarSyntax -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

apply_row : (I64 -> I64), I64 -> I64
apply_row = |f, x| f(x)

logged_apply! : (I64 => I64), I64 => I64
logged_apply! = |f, x| f(x)

double : I64 -> I64
double = |n| (n * 2)

shout! : I64 => I64
shout! = |n| ({
	line!(Text.printed(List.concat([19, 20, 16, 25, 14, 2], Text.show_int(n))))
	(n * 2)
})

# --- Entry ---

main! = |_args| {
	line!(Text.printed(List.concat([31, 25, 21, 13, 2], Text.show_int(apply_row(double, 21)))))
	r = logged_apply!(shout!, 21)
	line!(Text.printed(List.concat([23, 16, 29, 29, 13, 22, 2], Text.show_int(r))))
	Ok({})
}
