# forewords@sim-particle-system
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@sim-particle-system.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     Sim/ParticleSystem OK

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# FwdParticleSystemTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Text.printed([45, 17, 26, 81, 57, 15, 21, 14, 17, 24, 23, 13, 45, 30, 19, 14, 13, 26, 2, 42, 60]))
	Ok({})
}
