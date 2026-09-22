# forewords@gpu-launch-config
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@gpu-launch-config.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     256

app [main!] { cdx: "./codex/main.roc" }

import cdx.LaunchConfig
import cdx.Text

# FwdGpuLaunchConfigTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	({
		cfg = LaunchConfig.launch_config_for_num_elems(1024)
		line!(Text.printed(Text.show_int(cfg.lc_block_x)))
	})
	Ok({})
}
