## SyntaxColor colors source code for a web page: code text in, HTML out, with
## a span around each run a language's lexer gives a class. The text between
## the spans is escaped as the spans' insides are, so the HTML with its spans
## taken away is the text, escaped.
##
## A language is a value of `Language`: its name and its lexer, a function from
## the text to spans that cover every byte once. Each language's lexer is a
## module of its own (RocSyntax, ShaleSyntax, JsSyntax), and another language plugs in
## as one more module and one more value here.
import Span
import JsSyntax
import RocSyntax
import ShaleSyntax

SyntaxColor :: [].{

	## A language that can be colored: its name, and its lexer.
	Language : { name : Str, spans : Str -> List(Span) }

	## Roc, as the Safari book colors it.
	roc : SyntaxColor.Language
	roc = { name: "roc", spans: RocSyntax.spans }

	## Shale, as the Shale cookbook's color_shale.shale colors it.
	shale : SyntaxColor.Language
	shale = { name: "shale", spans: ShaleSyntax.spans }

	## JavaScript, with the classes the other two use.
	js : SyntaxColor.Language
	js = { name: "js", spans: JsSyntax.spans }

	## The spans of `text` in `language`, covering every byte once, in order.
	spans : SyntaxColor.Language, Str -> List(Span)
	spans = |language, text| (language.spans)(text)

	## The whole of `text` in `language`, as HTML.
	html : SyntaxColor.Language, Str -> Str
	html = |language, text| {
		end = text.count_utf8_bytes()
		SyntaxColor.range_html(
			text,
			{
				spans: SyntaxColor.spans(language, text),
				start: 0,
				end,
			},
		)
	}

	## The bytes of `text` from `start` up to `end` as HTML, from the spans the
	## whole text has: a span the range cuts is cut with it. A caller that shows
	## part of a file colors the file once and takes the ranges it shows, so
	## each part is colored as it reads in its file.
	range_html : Str,
	{
		spans : List(Span),
		start : U64,
		end : U64,
	} -> Str
	range_html = |text, range| {
		bytes = text.to_utf8()
		start = range.start
		stop = range.end.min(bytes.len())
		covering = range.spans
		var $out = List.with_capacity(stop - start.min(stop))
		var $at = first_span_at(covering, start)
		while $at < covering.len() {
			span = covering.get($at) ?? crash "SyntaxColor.range_html: the index is below the length"
			from = span.start.max(start)
			to = span.end.min(stop)
			if span.start >= stop {
				$at = covering.len()
			} else {
				$out = html_onto($out, { bytes, class: span.class, from, to })
				$at = $at + 1
			}
		}
		Str.from_utf8($out) ?? crash "SyntaxColor.range_html: a span ends inside a character"
	}

	## The text with its five HTML specials escaped, as the spans' text is.
	escaped_text : Str -> Str
	escaped_text = |text| {
		escaped = text.to_utf8().fold([], |out, byte| escaped_onto(out, byte))
		Str.from_utf8(escaped) ?? crash "SyntaxColor.escaped_text: escaping keeps every character whole"
	}
}

## The index of the first span that ends past `start`, found by halving: the
## spans are in order and touch, so their ends rise.
first_span_at : List(Span), U64 -> U64
first_span_at = |spans, start| {
	var $low = 0
	var $high = spans.len()
	while $low < $high {
		middle = ($low + $high) // 2
		span = spans.get(middle) ?? crash "SyntaxColor.first_span_at: the middle is below the length"
		if span.end <= start {
			$low = middle + 1
		} else {
			$high = middle
		}
	}
	$low
}

## The HTML of bytes `from` up to `to`, in the span its class makes, onto `out`.
html_onto : List(U8),
{
	bytes : List(U8),
	class : Span.Class,
	from : U64,
	to : U64,
} -> List(U8)
html_onto = |out, { bytes, class, from, to }|
	if to <= from {
		out
	} else {
		inside = bytes.sublist({ start: from, len: to - from })
		match Span.css_class(class) {
			Err(Plain) => inside.fold(out, |so_far, byte| escaped_onto(so_far, byte))
			Ok(css) => {
				opened = out.concat("<span class=\"${css}\">".to_utf8())
				inside.fold(
					opened,
					|so_far, byte| escaped_onto(so_far, byte),
				).concat("</span>".to_utf8())
			}
		}
	}

## One byte onto `out`, escaped if HTML gives it a meaning.
escaped_onto : List(U8), U8 -> List(U8)
escaped_onto = |out, byte| match byte {
	'&' => out.concat("&amp;".to_utf8())
	'<' => out.concat("&lt;".to_utf8())
	'>' => out.concat("&gt;".to_utf8())
	'"' => out.concat("&quot;".to_utf8())
	'\'' => out.concat("&#39;".to_utf8())
	_ => out.append(byte)
}

## The HTML with our spans taken out, so what is left is the escaped text: what
## the expects below hold the coloring to.
without_spans : Str -> Str
without_spans = |html| {
	closed = Str.join_with(html.split_on("</span>"), "")
	pieces = closed.split_on("<span class=\"")
	after_opening = |piece| piece.split_first("\">").map_ok(|parts| parts.after) ?? crash "SyntaxColor.without_spans: an opened span has its `\">`"
	rest = pieces.drop_first(1).map(after_opening)
	Str.join_with(pieces.take_first(1).concat(rest), "")
}

expect SyntaxColor.html(SyntaxColor.roc, "") == ""
expect SyntaxColor.html(SyntaxColor.shale, "") == ""
expect SyntaxColor.escaped_text("a&b<c>d\"e'f") == "a&amp;b&lt;c&gt;d&quot;e&#39;f"

# Each special escaped in plain text and inside a span alike.
expect SyntaxColor.html(
	SyntaxColor.roc,
	"a < b # <&>\"'",
) == "a &lt; b <span class=\"syn-comment\"># &lt;&amp;&gt;&quot;&#39;</span>"
expect SyntaxColor.html(
	SyntaxColor.shale,
	"x = '<a href=\"&\">'",
) == "x = <span class=\"syn-string\">&#39;&lt;a href=&quot;&amp;&quot;&gt;&#39;</span>"

# Text that looks like our own span is text.
expect SyntaxColor.html(
	SyntaxColor.shale,
	"-- </span>",
) == "<span class=\"syn-comment\">-- &lt;/span&gt;</span>"

# A range cuts the spans it crosses, and stops at the text's end.
expect {
	text = "x = 1 # one"
	spans = SyntaxColor.spans(SyntaxColor.roc, text)
	SyntaxColor.range_html(
		text,
		{ spans, start: 2, end: 9 },
	) == "= <span class=\"syn-number\">1</span> <span class=\"syn-comment\"># o</span>"
}
expect {
	text = "x = 1"
	spans = SyntaxColor.spans(SyntaxColor.roc, text)
	SyntaxColor.range_html(
		text,
		{ spans, start: 0, end: 99 },
	) == SyntaxColor.html(SyntaxColor.roc, text)
}
expect {
	text = "x = 1"
	spans = SyntaxColor.spans(SyntaxColor.roc, text)
	SyntaxColor.range_html(text, { spans, start: 3, end: 3 }) == ""
}

# A span crossing lines stays one span, as Shale's long strings do.
expect SyntaxColor.html(
	SyntaxColor.shale,
	"[=[a\nb]=]",
) == "<span class=\"syn-string\">[=[a\nb]=]</span>"

## Pieces of text that start, end or break a token in one language or the
## other, and bytes that aren't ASCII.
hostile_pieces : List(Str)
hostile_pieces = [
	"\"",
	"'",
	"`",
	"/",
	"/*",
	"*/",
	"//",
	"1e",
	".5",
	"\${",
	"}",
	"\\\\",
	"\\",
	"#",
	"--",
	"[=[",
	"]=]",
	"[",
	"]",
	"|",
	"(",
	")",
	"{",
	"-1",
	"0x",
	"é",
	"\n",
	"\r",
	"\u(0)",
	"a",
	"A.",
	".(",
	"&<>",
	" ",
	"=",
	":",
	"function",
]

## Every text of two hostile pieces, and some longer ones.
hostile_texts : List(Str)
hostile_texts = {
	pairs = hostile_pieces.join_map(|first| hostile_pieces.map(|second| Str.concat(first, second)))
	pairs.concat([
		"\"\${\"\${\"\${",
		"\"\${x}\"\${y",
		"}}}}))))]]]]||||",
		"x = \"é\${'é'}é\" # é\n\\\\é \${é}",
		"--[=[ é ]==] [==[ ]=]",
		"A.B.C.(é).d!",
		"\u(0)\u(1)\u(7f)\u(80)\u(10ffff)",
		Str.repeat("{", 300),
		Str.repeat("\"\${", 100),
	])
}

## Whether `language` colors `text` without loss: its spans cover every byte
## once, and its HTML without the spans is the escaped text.
is_faithful : SyntaxColor.Language, Str -> Bool
is_faithful = |language, text|
	Span.is_cover(SyntaxColor.spans(language, text), text.count_utf8_bytes())
		and without_spans(SyntaxColor.html(language, text)) == SyntaxColor.escaped_text(text)

expect hostile_texts.len() == 1378
expect hostile_texts.all(|text| is_faithful(SyntaxColor.roc, text))
expect hostile_texts.all(|text| is_faithful(SyntaxColor.shale, text))
expect hostile_texts.all(|text| is_faithful(SyntaxColor.js, text))
