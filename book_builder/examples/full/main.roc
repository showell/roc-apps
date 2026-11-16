## This app is the book builder's example of most of what it does: a front
## page and chapters, includes, chapter references, an index, the negatives
## lint and one fence hook of its own, `shout`.
app [main!] { bb: "../../builder/main.roc", pf: platform "../../platform/main.roc" }

import pf.Book
import bb.Builder
import bb.Fences

main! : Str => Try(Str, Str)
main! = |_folder| Builder.build!(settings, Book.read_file!)

settings : Builder.Settings
settings = {
	..Builder.default_settings,
	index_terms: IndexTerms("terms.txt"),
	negatives: Lint({ words: "negative_words.txt", table: "negatives.txt" }),
	fence_hooks: [shout],
}

## A ```shout fence is its words and its body in capitals, in a paragraph of
## its own. One with nothing to shout stops the build.
shout : Fences.Hook
shout = {
	language: "shout",
	html_of: |{ words, body }|
		if body.trim().is_empty() {
			Refused("a shout needs something to shout")
		} else {
			Html("<p class=\"shout\">${escaped(words)}: ${escaped(body.trim().with_ascii_uppercased())}</p>")
		},
}

escaped : Str -> Str
escaped = |text|
	text
		.replace_each("&", "&amp;")
		.replace_each("<", "&lt;")
		.replace_each(">", "&gt;")
		.replace_each("\"", "&quot;")

expect (shout.html_of)({
	words: "Hey",
	body: "a <b>\n",
}) == Html("<p class=\"shout\">Hey: A &lt;B&gt;</p>")
expect (shout.html_of)({ words: "Hey", body: " \n" }) == Refused("a shout needs something to shout")
