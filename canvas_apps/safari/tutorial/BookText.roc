## This module is where the book's bytes become text. The renderer speaks in
## bytes and the book's pages are built as text.
import md.Md

BookText := [].{

	from_bytes : List(U8) -> Str
	from_bytes = |bytes| match Str.from_utf8(bytes) {
		Ok(text) => text
		Err(_) => crash "book: text that isn't UTF-8"
	}

	## Text made safe for a page, an element's content or an attribute's value.
	escaped_text : Str -> Str
	escaped_text = |text| BookText.from_bytes(Md.escape(text.to_utf8()))
}

expect BookText.from_bytes([97]) == "a"
expect BookText.escaped_text("a <b> \"c\"") == "a &lt;b&gt; &quot;c&quot;"
