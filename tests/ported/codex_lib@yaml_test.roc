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

import cdx.Text
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
					line!(Text.printed(Text.concat("name=", Yaml.yaml_get_str(v, "name", "?"))))
					line!(Text.printed(Text.concat("version=", Text.show_int(Yaml.yaml_get_int(v, "version", 0)))))
					({
						emitted = Yaml.yaml_emit(v)
						line!(Text.printed(Text.concat("emit-len=", Text.show_int(Text.len(emitted)))))
					})
				})
				None => line!(Text.printed("parse=fail"))
			})
			({
				list_input = "- alpha\n- beta\n- gamma\n"
				({
					(match Yaml.yaml_parse(list_input) {
						Just(v) => (match v {
							YamlList(items) => line!(Text.printed(Text.concat("list-len=", Text.show_int(U64.to_i64_wrap(List.len(items))))))
							_ => line!(Text.printed("list=fail:type"))
						})
						None => line!(Text.printed("list=fail"))
					})
					line!(Text.printed(Text.concat("null=", (match Yaml.yaml_parse("x: null\n") {
						Just(v) => Yaml.yaml_get_str(v, "x", "null-ok")
						None => "fail"
					}))))
				})
			})
		})
	})
	Ok({})
}
