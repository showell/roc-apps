# lib@path-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lib@path-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     codex/Emit
#     codex/Emit
#     Emit
#     codex
#     codex/Emit
#     X86_64.codex
#     X86_64
#     codex
#     
#     codex/Emit/X86_64.codex
#     abs
#     rel
#     yes
#     segs=3

app [main!] { cdx: "./codex/main.roc" }

import cdx.Path
import cdx.Text

# PathTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Path.path_join([24, 16, 22, 13, 36], [39, 26, 17, 14])))
	line!(Text.printed(Path.path_join([24, 16, 22, 13, 36, 81], [39, 26, 17, 14])))
	line!(Text.printed(Path.path_join([], [39, 26, 17, 14])))
	line!(Text.printed(Path.path_join([24, 16, 22, 13, 36], [])))
	line!(Text.printed(Path.path_parent([24, 16, 22, 13, 36, 81, 39, 26, 17, 14, 81, 62, 11, 9, 85, 9, 7, 65, 24, 16, 22, 13, 36])))
	line!(Text.printed(Path.path_filename([24, 16, 22, 13, 36, 81, 39, 26, 17, 14, 81, 62, 11, 9, 85, 9, 7, 65, 24, 16, 22, 13, 36])))
	line!(Text.printed(Path.path_stem([24, 16, 22, 13, 36, 81, 39, 26, 17, 14, 81, 62, 11, 9, 85, 9, 7, 65, 24, 16, 22, 13, 36])))
	line!(Text.printed(Path.path_extension([24, 16, 22, 13, 36, 81, 39, 26, 17, 14, 81, 62, 11, 9, 85, 9, 7, 65, 24, 16, 22, 13, 36])))
	line!(Text.printed(Path.path_extension([52, 15, 34, 13, 28, 17, 23, 13])))
	line!(Text.printed(Path.path_normalize([24, 16, 22, 13, 36, 81, 65, 81, 39, 26, 17, 14, 81, 65, 65, 81, 39, 26, 17, 14, 81, 62, 11, 9, 85, 9, 7, 65, 24, 16, 22, 13, 36])))
	line!(Text.printed((if Path.path_is_absolute([81, 32, 16, 16, 14, 81, 13, 28, 17]) { [15, 32, 19] } else { [21, 13, 23] })))
	line!(Text.printed((if Path.path_is_absolute([24, 16, 22, 13, 36, 81, 39, 26, 17, 14]) { [15, 32, 19] } else { [21, 13, 23] })))
	line!(Text.printed((if Path.path_has_extension([28, 16, 16, 65, 24, 16, 22, 13, 36], [24, 16, 22, 13, 36]) { [30, 13, 19] } else { [18, 16] })))
	line!(Text.printed(List.concat([19, 13, 29, 19, 77], Text.show_int(U64.to_i64_wrap(List.len(Path.path_segments([24, 16, 22, 13, 36, 81, 39, 26, 17, 14, 81, 62, 11, 9, 85, 9, 7, 65, 24, 16, 22, 13, 36])))))))
	Ok({})
}
