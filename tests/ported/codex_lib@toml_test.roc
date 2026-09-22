# lib@toml-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lib@toml-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     title=My Config
#     port=8080
#     debug=true
#     missing=default
#     emit-ok=yes

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text
import cdx.Toml

# TomlTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	({
		input = [14, 17, 14, 23, 13, 2, 77, 2, 72, 52, 30, 2, 50, 16, 18, 28, 17, 29, 72, 1, 31, 16, 21, 14, 2, 77, 2, 11, 3, 11, 3, 1, 22, 13, 32, 25, 29, 2, 77, 2, 14, 21, 25, 13, 1]
		(match Toml.toml_parse(input) {
			Just(v) => ({
				line!(Text.printed(List.concat([14, 17, 14, 23, 13, 77], Toml.toml_get_str(v, [14, 17, 14, 23, 13], [68]))))
				line!(Text.printed(List.concat([31, 16, 21, 14, 77], Text.show_int(Toml.toml_get_int(v, [31, 16, 21, 14], 0)))))
				line!(Text.printed(List.concat([22, 13, 32, 25, 29, 77], (if Toml.toml_get_bool(v, [22, 13, 32, 25, 29], False) { [14, 21, 25, 13] } else { [28, 15, 23, 19, 13] }))))
				line!(Text.printed(List.concat([26, 17, 19, 19, 17, 18, 29, 77], Toml.toml_get_str(v, [18, 16, 31, 13], [22, 13, 28, 15, 25, 23, 14]))))
				({
					emitted = Toml.toml_emit(v)
					line!(Text.printed(List.concat([13, 26, 17, 14, 73, 16, 34, 77], (if (Text.len(emitted) > 0) { [30, 13, 19] } else { [18, 16] }))))
				})
			})
			None => line!(Text.printed([31, 15, 21, 19, 13, 77, 28, 15, 17, 23]))
		})
	})
	Ok({})
}
