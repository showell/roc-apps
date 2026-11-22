## This app colors code for the site's pages with roc-syntax-color, on Roc's
## echo platform. site/build_roc_on_shale.shale, site/build_chess_code.shale and
## site/build_security_idioms.shale run it: its arguments are pairs, a language (`roc`, `shale` or `js`) and a
## text, and it prints each text colored whole, in order, each after a line
## `<!-- color_code answer -->`. No answer can hold that line, since the
## coloring escapes every `<`.
app [main!] { sc: "../../../roc-syntax-color/package/main.roc" }

import sc.SyntaxColor

main! = |requests| {
	for answer in answers(requests) {
		echo!("<!-- color_code answer -->\n${answer}")
	}
	Ok({})
}

## The answer to each request, in order.
answers : List(Str) -> List(Str)
answers = |requests| answers_onto([], requests)

answers_onto : List(Str), List(Str) -> List(Str)
answers_onto = |out, requests| match requests {
	[] => out
	["roc", text, .. as rest] => answers_onto(out.append(SyntaxColor.html(SyntaxColor.roc, text)), rest)
	["shale", text, .. as rest] => answers_onto(out.append(SyntaxColor.html(SyntaxColor.shale, text)), rest)
	["js", text, .. as rest] => answers_onto(out.append(SyntaxColor.html(SyntaxColor.js, text)), rest)
	[stray, ..] => crash "color_code: a language it doesn't take: ${stray}"
}

expect answers(["roc", "x = 1", "shale", "local y = 2"]) == [
	"<span class=\"syn-name\">x</span> = <span class=\"syn-number\">1</span>",
	"<span class=\"syn-keyword\">local</span> y = <span class=\"syn-number\">2</span>",
]
