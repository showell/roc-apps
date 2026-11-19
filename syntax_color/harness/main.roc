## The harness runs the package on Roc's echo platform for the gate,
## tools/verify.shale, which hands it its samples as arguments and holds what it
## prints to the recorded oracle. The arguments are a run of requests:
##   `roc TEXT`, `shale TEXT`, `js TEXT` and `zig TEXT` print TEXT colored whole;
##   `roc-block FILE SPEC` prints the block SPEC shows of FILE, colored as it
##   reads in FILE. SPEC is a line a block line: `R START END`, the file's bytes
##   from START up to END, or `T TEXT`, a line of its own, colored alone.
## Each answer follows a line `<!-- syntax_color answer -->`, which no answer
## can hold, since its `<` would be escaped.
app [main!] { sc: "../package/main.roc" }

import sc.Span
import sc.SyntaxColor

main! = |requests| {
	for answer in answers(requests) {
		echo!("<!-- syntax_color answer -->\n${answer}")
	}
	Ok({})
}

## The answer to each request, in order.
answers : List(Str) -> List(Str)
answers = |requests| answers_onto([], requests)

answers_onto : List(Str), List(Str) -> List(Str)
answers_onto = |out, requests| match requests {
	[] => out
	["roc", text, .. as rest] => answers_onto(
		out.append(SyntaxColor.html(SyntaxColor.roc, text)),
		rest,
	)
	["js", text, .. as rest] => answers_onto(
		out.append(SyntaxColor.html(SyntaxColor.js, text)),
		rest,
	)
	["shale", text, .. as rest] => answers_onto(
		out.append(SyntaxColor.html(SyntaxColor.shale, text)),
		rest,
	)
	["zig", text, .. as rest] => answers_onto(
		out.append(SyntaxColor.html(SyntaxColor.zig, text)),
		rest,
	)
	["roc-block", file, spec, .. as rest] => answers_onto(out.append(block_html(file, spec)), rest)
	[stray, ..] => crash "harness: a request that isn't roc, shale, js, zig or roc-block: ${stray}"
}

## The block `spec` shows of `file`, a line each, with a newline after the last.
block_html : Str, Str -> Str
block_html = |file, spec| {
	spans = SyntaxColor.spans(SyntaxColor.roc, file)
	shown = spec.split_on("\n").map(|line| block_line_html(file, { spans, line }))
	Str.concat(Str.join_with(shown, "\n"), "\n")
}

block_line_html : Str, { spans : List(Span), line : Str } -> Str
block_line_html = |file, { spans, line }|
	match line.split_first(" ") {
		Ok({ before: "R", after }) =>
			match after.split_on(" ") {
				[start, end] => SyntaxColor.range_html(
					file,
					{
						spans,
						start: number(start),
						end: number(end),
					},
				)
				_ => crash "harness: an R line holds two numbers: ${line}"
			}
		Ok({ before: "T", after }) => SyntaxColor.html(SyntaxColor.roc, after)
		_ => crash "harness: a block line that isn't R or T: ${line}"
	}

number : Str -> U64
number = |digits| U64.from_str(digits) ?? crash "harness: not a number: ${digits}"
