# effect-positive
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/effect-positive.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     step one
#     value 42
#     shout 7

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText

# EffectPositive -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

apply_pure : (I64 -> I64), I64 -> I64
apply_pure = |f, x| f(x)

double : I64 -> I64
double = |n| (n * 2)

run_console! : (I64 => {}), I64 => {}
run_console! = |act_fn, n| act_fn(n)

shout! : I64 => {}
shout! = |n| ({
	line!(CceText.printed(CceText.concat("shout ", CceText.show_int(n))))
})

report! : I64 => {}
report! = |n| ({
	line!(CceText.printed("step one"))
	line!(CceText.printed(CceText.concat("value ", CceText.show_int(apply_pure(double, n)))))
})

# --- Entry ---

main! = |_args| {
	report!(21)
	run_console!(shout!, 7)
	Ok({})
}
