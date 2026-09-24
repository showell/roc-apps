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

import cdx.CceText
import cdx.Toml

# TomlTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	({
		input : CceText
		input = "title = \"My Config\"\nport = 8080\ndebug = true\n"
		(match Toml.toml_parse(input) {
			Just(v) => ({
				line!(CceText.printed(CceText.concat("title=", Toml.toml_get_str(v, "title", "?"))))
				line!(CceText.printed(CceText.concat("port=", CceText.show_int(Toml.toml_get_int(v, "port", 0)))))
				line!(CceText.printed(CceText.concat("debug=", (if Toml.toml_get_bool(v, "debug", False) { "true" } else { "false" }))))
				line!(CceText.printed(CceText.concat("missing=", Toml.toml_get_str(v, "nope", "default"))))
				({
					emitted : CceText
					emitted = Toml.toml_emit(v)
					line!(CceText.printed(CceText.concat("emit-ok=", (if (CceText.len(emitted) > 0) { "yes" } else { "no" }))))
				})
			})
			None => line!(CceText.printed("parse=fail"))
		})
	})
	Ok({})
}
