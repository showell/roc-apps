# forewords@gpu-device-effect
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@gpu-device-effect.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     Gpu/DeviceEffect OK

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text

# FwdGpuDeviceEffectTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Text.printed([55, 31, 25, 81, 48, 13, 33, 17, 24, 13, 39, 28, 28, 13, 24, 14, 2, 42, 60]))
	Ok({})
}
