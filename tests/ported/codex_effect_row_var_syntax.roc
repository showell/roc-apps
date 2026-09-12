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

app [main!] {}

# EffectRowVarSyntax -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

apply_row : (I64 -> I64), I64 -> I64
apply_row = |f, x| f(x)

logged_apply : (I64 => I64), I64 => I64
logged_apply = |f, x| f(x)

double : I64 -> I64
double = |n| (n * 2)

shout : I64 => I64
shout = |n| ({
	line!(Str.concat("shout ", I64.to_str(n)))
	(n * 2)
})

# --- Entry ---

main! = |_args| {
	line!(Str.concat("pure ", I64.to_str(apply_row(double, 21))))
	r = logged_apply(shout, 21)
	line!(Str.concat("logged ", I64.to_str(r)))
	Ok({})
}
