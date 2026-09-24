# forewords@foreword-date-time
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@foreword-date-time.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     Foreword/DateTime OK

app [main!] { cdx: "./codex/main.roc" }

import cdx.DateTime
import cdx.Text

# FwdDateTimeTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

nanoStamp : I64 -> DateTime.Timestamp
nanoStamp = |fv| fv

timestamp_to_NanoStamp : DateTime.Timestamp -> I64
timestamp_to_NanoStamp = |fv| fv

microStamp : I64 -> DateTime.Timestamp
microStamp = |fv| (fv * 1000)

timestamp_to_MicroStamp : DateTime.Timestamp -> I64
timestamp_to_MicroStamp = |fv| I64.div_trunc_by(fv, 1000)

milliStamp : I64 -> DateTime.Timestamp
milliStamp = |fv| (fv * 1000000)

timestamp_to_MilliStamp : DateTime.Timestamp -> I64
timestamp_to_MilliStamp = |fv| I64.div_trunc_by(fv, 1000000)

secondStamp : I64 -> DateTime.Timestamp
secondStamp = |fv| (fv * 1000000000)

timestamp_to_SecondStamp : DateTime.Timestamp -> I64
timestamp_to_SecondStamp = |fv| I64.div_trunc_by(fv, 1000000000)

nanoElapsed : I64 -> DateTime.Elapsed
nanoElapsed = |fv| fv

elapsed_to_NanoElapsed : DateTime.Elapsed -> I64
elapsed_to_NanoElapsed = |fv| fv

microElapsed : I64 -> DateTime.Elapsed
microElapsed = |fv| (fv * 1000)

elapsed_to_MicroElapsed : DateTime.Elapsed -> I64
elapsed_to_MicroElapsed = |fv| I64.div_trunc_by(fv, 1000)

milliElapsed : I64 -> DateTime.Elapsed
milliElapsed = |fv| (fv * 1000000)

elapsed_to_MilliElapsed : DateTime.Elapsed -> I64
elapsed_to_MilliElapsed = |fv| I64.div_trunc_by(fv, 1000000)

secondElapsed : I64 -> DateTime.Elapsed
secondElapsed = |fv| (fv * 1000000000)

elapsed_to_SecondElapsed : DateTime.Elapsed -> I64
elapsed_to_SecondElapsed = |fv| I64.div_trunc_by(fv, 1000000000)

# --- Entry ---

main! = |_args| {
	line!(Text.printed("Foreword/DateTime OK"))
	Ok({})
}
