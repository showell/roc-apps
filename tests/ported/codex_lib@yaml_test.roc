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
		input = [18, 15, 26, 13, 69, 2, 50, 16, 22, 13, 36, 1, 33, 13, 21, 19, 17, 16, 18, 69, 2, 7, 5, 1, 13, 18, 15, 32, 23, 13, 22, 69, 2, 14, 21, 25, 13, 1]
		({
			(match Yaml.yaml_parse(input) {
				Just(v) => ({
					line!(Text.printed(List.concat([18, 15, 26, 13, 77], Yaml.yaml_get_str(v, [18, 15, 26, 13], [68]))))
					line!(Text.printed(List.concat([33, 13, 21, 19, 17, 16, 18, 77], Text.show_int(Yaml.yaml_get_int(v, [33, 13, 21, 19, 17, 16, 18], 0)))))
					({
						emitted = Yaml.yaml_emit(v)
						line!(Text.printed(List.concat([13, 26, 17, 14, 73, 23, 13, 18, 77], Text.show_int(Text.len(emitted)))))
					})
				})
				None => line!(Text.printed([31, 15, 21, 19, 13, 77, 28, 15, 17, 23]))
			})
			({
				list_input = [73, 2, 15, 23, 31, 20, 15, 1, 73, 2, 32, 13, 14, 15, 1, 73, 2, 29, 15, 26, 26, 15, 1]
				({
					(match Yaml.yaml_parse(list_input) {
						Just(v) => (match v {
							YamlList(items) => line!(Text.printed(List.concat([23, 17, 19, 14, 73, 23, 13, 18, 77], Text.show_int(U64.to_i64_wrap(List.len(items))))))
							_ => line!(Text.printed([23, 17, 19, 14, 77, 28, 15, 17, 23, 69, 14, 30, 31, 13]))
						})
						None => line!(Text.printed([23, 17, 19, 14, 77, 28, 15, 17, 23]))
					})
					line!(Text.printed(List.concat([18, 25, 23, 23, 77], (match Yaml.yaml_parse([36, 69, 2, 18, 25, 23, 23, 1]) {
						Just(v) => Yaml.yaml_get_str(v, [36], [18, 25, 23, 23, 73, 16, 34])
						None => [28, 15, 17, 23]
					}))))
				})
			})
		})
	})
	Ok({})
}
