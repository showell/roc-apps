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
	line!(Text.printed(Path.path_join("codex", "Emit")))
	line!(Text.printed(Path.path_join("codex/", "Emit")))
	line!(Text.printed(Path.path_join("", "Emit")))
	line!(Text.printed(Path.path_join("codex", "")))
	line!(Text.printed(Path.path_parent("codex/Emit/X86_64.codex")))
	line!(Text.printed(Path.path_filename("codex/Emit/X86_64.codex")))
	line!(Text.printed(Path.path_stem("codex/Emit/X86_64.codex")))
	line!(Text.printed(Path.path_extension("codex/Emit/X86_64.codex")))
	line!(Text.printed(Path.path_extension("Makefile")))
	line!(Text.printed(Path.path_normalize("codex/./Emit/../Emit/X86_64.codex")))
	line!(Text.printed((if Path.path_is_absolute("/boot/efi") { "abs" } else { "rel" })))
	line!(Text.printed((if Path.path_is_absolute("codex/Emit") { "abs" } else { "rel" })))
	line!(Text.printed((if Path.path_has_extension("foo.codex", "codex") { "yes" } else { "no" })))
	line!(Text.printed(Text.concat("segs=", Text.show_int(U64.to_i64_wrap(List.len(Path.path_segments("codex/Emit/X86_64.codex")))))))
	Ok({})
}
