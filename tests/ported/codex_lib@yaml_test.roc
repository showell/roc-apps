# lib@yaml-test
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lib@yaml-test.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     name=Codex
#     version=42
#     emit-len=37
#     list-len=3
#     null=null-ok

app [main!] { cdx: "./codex/main.roc" }

import cdx.CceText
import cdx.Yaml

# YamlTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |_args| {
	({
		input = "name: Codex\nversion: 42\nenabled: true\n"
		({
			(match Yaml.yaml_parse(input) {
				Just(v) => ({
					line!(CceText.printed(CceText.concat("name=", Yaml.yaml_get_str(v, "name", "?"))))
					line!(CceText.printed(CceText.concat("version=", CceText.show_int(Yaml.yaml_get_int(v, "version", 0)))))
					({
						emitted = Yaml.yaml_emit(v)
						line!(CceText.printed(CceText.concat("emit-len=", CceText.show_int(CceText.len(emitted)))))
					})
				})
				None => line!(CceText.printed("parse=fail"))
			})
			({
				list_input = "- alpha\n- beta\n- gamma\n"
				({
					(match Yaml.yaml_parse(list_input) {
						Just(v) => (match v {
							YamlList(items) => line!(CceText.printed(CceText.concat("list-len=", CceText.show_int(U64.to_i64_wrap(List.len(items))))))
							_ => line!(CceText.printed("list=fail:type"))
						})
						None => line!(CceText.printed("list=fail"))
					})
					line!(CceText.printed(CceText.concat("null=", (match Yaml.yaml_parse("x: null\n") {
						Just(v) => Yaml.yaml_get_str(v, "x", "null-ok")
						None => "fail"
					}))))
				})
			})
		})
	})
	Ok({})
}
