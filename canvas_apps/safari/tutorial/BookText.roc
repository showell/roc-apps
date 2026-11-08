## This module is where the book's bytes become text. The renderer speaks in
## bytes and the book's pages are built as text.
import md.Md

BookText := [].{

	text_from_bytes : List(U8) -> Str
	text_from_bytes = |bytes| match Str.from_utf8(bytes) {
		Ok(text) => text
		Err(BadUtf8({ index, .. })) => crash "book: text that isn't UTF-8 at byte ${index.to_str()}"
	}

	## Text made safe for a page, an element's content or an attribute's value.
	escaped_text : Str -> Str
	escaped_text = |text| BookText.text_from_bytes(Md.escape(text.to_utf8()))

	## The text split at each `opening`, each piece after the first rewritten,
	## and joined back together with the `opening`s where they were.
	rewritten_after : Str, { opening : Str, rewrite : Str -> Str } -> Str
	rewritten_after = |text, { opening, rewrite }| match text.split_on(opening) {
		[before_any, .. as pieces] => Str.join_with([before_any].concat(pieces.map(rewrite)), opening)
		[] => crash "book: Str.split_on answered no pieces"
	}

	## A line of Markdown as HTML that can sit inside a caption, so without the
	## paragraph the renderer puts around it. Text that renders as anything but
	## one paragraph stops the build.
	inline_html : Str -> Str
	inline_html = |text| {
		rendered = Md.render_document(text.to_utf8(), { fence: |_| Pass, images: AsLinks })
		html = BookText.text_from_bytes(rendered.html).trim()
		one_paragraph = match html.split_on("<p>") {
			["", opened] => opened.split_on("</p>")
			_ => []
		}
		match one_paragraph {
			[inside, ""] => inside.trim()
			_ => crash "book: a caption isn't one paragraph of Markdown: ${text}"
		}
	}
}

expect BookText.text_from_bytes([97]) == "a"
expect BookText.escaped_text("a <b> \"c\"") == "a &lt;b&gt; &quot;c&quot;"
expect BookText.inline_html("plain") == "plain"
expect BookText.inline_html("around `Sky` & <b>") == "around <code>Sky</code> &amp; &lt;b&gt;"
