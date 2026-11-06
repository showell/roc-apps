## This module is where the book's bytes become text. The renderer speaks in
## bytes and the book's pages are built as text.
import md.Md

BookText := [].{

	text_from_bytes : List(U8) -> Str
	text_from_bytes = |bytes| match Str.from_utf8(bytes) {
		Ok(text) => text
		Err(_) => crash "book: text that isn't UTF-8"
	}

	## Text made safe for a page, an element's content or an attribute's value.
	escaped_text : Str -> Str
	escaped_text = |text| BookText.text_from_bytes(Md.escape(text.to_utf8()))

	## A line of Markdown as HTML that can sit inside a caption, so without the
	## paragraph the renderer puts around it.
	inline_html : Str -> Str
	inline_html = |text| {
		rendered = Md.render_document(text.to_utf8(), { fence: |_| Pass, images: AsLinks })
		BookText.text_from_bytes(rendered.html).replace_each("<p>", "").replace_each(
			"</p>",
			"",
		).trim()
	}
}

expect BookText.text_from_bytes([97]) == "a"
expect BookText.escaped_text("a <b> \"c\"") == "a &lt;b&gt; &quot;c&quot;"
expect BookText.inline_html("plain") == "plain"
expect BookText.inline_html("around `Sky` & <b>") == "around <code>Sky</code> &amp; &lt;b&gt;"
