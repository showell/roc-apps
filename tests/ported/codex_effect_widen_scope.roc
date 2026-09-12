# effect-widen-scope
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/effect-widen-scope.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     widened

app [main!] {}

# EffectWidenScope -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

scoped_print : Str => {}
scoped_print = |t| ({
	line!(t)
})

apply_it : (Str => {}), Str => {}
apply_it = |f, t| ({
	f(t)
})

# --- Entry ---

main! = |_args| {
	apply_it(scoped_print, "widened")
	Ok({})
}
