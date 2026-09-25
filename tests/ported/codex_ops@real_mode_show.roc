# ops@real-mode-show
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/ops@real-mode-show.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     plain:      2.5
#     approx:     2.5
#     trapping:   2.5
#     saturating: 2.5
#     trap-neg:   -2.5
#     sat-neg:    -2.5

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Prelude

# RealModeShow -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(CceText.printed(CceText.concat("plain:      ", CceText.of_str(Prelude.real_to_str(2.5)))))
	line!(CceText.printed(CceText.concat("approx:     ", CceText.of_str(Prelude.real_to_str(F32.to_f64(F64.to_f32_wrap(2.5)))))))
	line!(CceText.printed(CceText.concat("trapping:   ", CceText.of_str(Prelude.real_to_str(2.5)))))
	line!(CceText.printed(CceText.concat("saturating: ", CceText.of_str(Prelude.real_to_str(2.5)))))
	line!(CceText.printed(CceText.concat("trap-neg:   ", CceText.of_str(Prelude.real_to_str((0.0 - 2.5))))))
	line!(CceText.printed(CceText.concat("sat-neg:    ", CceText.of_str(Prelude.real_to_str((0.0 - 2.5))))))
	Ok({})
}
