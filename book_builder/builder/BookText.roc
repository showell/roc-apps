## This module is where the builder's bytes become text. The renderer speaks
## in bytes, and a book's pages are built as text. It also holds the small
## pieces of text work the other modules share, and a book's own modules use:
## escaping, a split and rejoin around a marker, a text's lines, and a line of
## Markdown made a caption.
import md.Md

BookText := [].{

	## The text of bytes the builder made or took from the renderer, which
	## are UTF-8 by construction, so other bytes are the builder's bug.
	text_from_bytes : List(U8) -> Str
	text_from_bytes = |bytes| match Str.from_utf8(bytes) {
		Ok(text) => text
		Err(BadUtf8({ index, .. })) => crash "book: text that isn't UTF-8 at byte ${index.to_str()}"
	}

	## Text made safe for a page, an element's content or an attribute's
	## value, by the renderer's own escape.
	escaped_text : Str -> Str
	escaped_text = |text| BookText.text_from_bytes(Md.escape(text.to_utf8()))

	## The text split at each `opening`, each piece after the first rewritten,
	## and joined back together with the `opening`s where they were.
	rewritten_after : Str, { opening : Str, rewrite : Str -> Str } -> Str
	rewritten_after = |text, { opening, rewrite }| match text.split_on(opening) {
		[before_any, .. as pieces] => Str.join_with(
			List.concat([before_any], pieces.map(rewrite)),
			opening,
		)
		[] => crash "book: Str.split_on answered no pieces"
	}

	## The lines of a text, without the empty one after its last newline.
	text_lines : Str -> List(Str)
	text_lines = |text| {
		pieces = text.split_on("\n")
		match pieces.last() {
			Ok("") => pieces.drop_last(1)
			_ => pieces
		}
	}

	## The text with each run between backticks, the backticks too, as one
	## space. An unclosed backtick and what follows it stay.
	without_code_spans : Str -> Str
	without_code_spans = |text| match text.split_on("`") {
		[before_any, .. as pieces] => {
			var $out = before_any
			var $rest = pieces
			while $rest.len() >= 2 {
				after = $rest.get(1) ?? crash "BookText.without_code_spans: two pieces left, and no second"
				$out = "${$out} ${after}"
				$rest = $rest.drop_first(2)
			}
			match $rest {
				[open] => "${$out}`${open}"
				_ => $out
			}
		}
		[] => crash "book: Str.split_on answered no pieces"
	}

	## A line of Markdown as HTML that can sit inside a caption, so without the
	## paragraph the renderer puts around it, or why text that renders as
	## anything but one paragraph can't.
	inline_html : Str -> Try(Str, Str)
	inline_html = |text| {
		rendered = Md.render_document(text.to_utf8(), { fence: |_| Pass, images: AsLinks })
		html = BookText.text_from_bytes(rendered.html).trim()
		one_paragraph = match html.split_on("<p>") {
			["", opened] => opened.split_on("</p>")
			_ => []
		}
		match one_paragraph {
			[inside, ""] => Ok(inside.trim())
			_ => Err("a caption isn't one paragraph of Markdown: ${text}")
		}
	}

	## Whether a byte is an ASCII letter or digit.
	is_letter_or_digit : U8 -> Bool
	is_letter_or_digit = |byte|
		(byte >= 'a' and byte <= 'z')
			or (byte >= 'A' and byte <= 'Z')
			or (byte >= '0' and byte <= '9')
}

expect BookText.text_from_bytes([97]) == "a"
expect BookText.escaped_text("a <b> \"c\" & 'd'") == "a &lt;b&gt; &quot;c&quot; &amp; &#39;d&#39;"
expect BookText.rewritten_after(
	"no marks",
	{ opening: "<b>", rewrite: |piece| "x${piece}" },
) == "no marks"
expect BookText.rewritten_after(
	"a<b>c<b>d",
	{ opening: "<b>", rewrite: |piece| "x${piece}" },
) == "a<b>xc<b>xd"
expect BookText.text_lines("a\nb\n") == ["a", "b"]
expect BookText.text_lines("a\nb") == ["a", "b"]
expect BookText.text_lines("") == []
expect BookText.text_lines("\n\n") == ["", ""]
expect BookText.without_code_spans("a `b` c `d`") == "a   c  "
expect BookText.without_code_spans("no code") == "no code"
expect BookText.without_code_spans("a `open") == "a `open"
expect BookText.without_code_spans("`x` y `z") == "  y `z"
expect BookText.inline_html("plain") == Ok("plain")
expect BookText.inline_html("around `Sky` & <b>") == Ok("around <code>Sky</code> &amp; &lt;b&gt;")
expect BookText.inline_html("one\n\ntwo") == Err("a caption isn't one paragraph of Markdown: one\n\ntwo")
expect ['a', 'z', 'A', 'Z', '0', '9'].all(BookText.is_letter_or_digit)
expect ['-', '_', ' ', '`', 0xC3].all(|byte| !BookText.is_letter_or_digit(byte))
