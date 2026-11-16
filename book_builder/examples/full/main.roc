## This app is the book builder's example of most of what it does: a front
## page and chapters, includes, chapter references, an index, the negatives
## lint, a diagram and one fence hook of its own, `shout`. A book's pre-step
## draws its diagrams with Graphviz; this one's drawing is checked in, in
## `drawings/`, beside the source it stands for.
app [main!] { bb: "../../builder/main.roc", pf: platform "../../platform/main.roc" }

import pf.Book
import bb.Builder
import bb.Diagrams
import bb.Fences
import bb.Includes

main! : Str => Try(Str, Str)
main! = |_folder| {
	found = Diagrams.found({
		name: settings.manuscript,
		text: read_text!(settings.manuscript)?,
	}) ? |problems| Str.join_with(problems.map(|problem| "${problem}\n"), "")
	drawn = Diagrams.drawn!(
		{
			diagrams: found.diagrams,
			folder: "drawings",
			manuscript: settings.manuscript,
		},
		read_text!,
	)?
	Builder.build!(
		{ ..settings, fence_hooks: [shout, Diagrams.hook(drawn)] },
		|path|
			if path == settings.manuscript {
				Ok(found.manuscript)
			} else {
				Book.read_file!(path)
			},
	)
}

settings : Builder.Settings
settings = {
	..Builder.default_settings,
	index_terms: IndexTerms("terms.txt"),
	negatives: Lint({ words: "negative_words.txt", table: "negatives.txt" }),
}

## A file of the book's folder, or the build's stop naming it.
read_text! : Str => Try(Str, Str)
read_text! = |path| Book.read_file!(path).map_err(|problem| "${path} ${Includes.read_problem_text(problem)}\n")

## A ```shout fence is its words and its body in capitals, in a paragraph of
## its own. One with nothing to shout stops the build.
shout : Fences.Hook
shout = {
	language: "shout",
	html_of: |{ words, body }|
		if body.trim().is_empty() {
			Refused("a shout needs something to shout")
		} else {
			Html("<p class=\"shout\">${escaped_text(words)}: ${escaped_text(body.trim().with_ascii_uppercased())}</p>")
		},
}

escaped_text : Str -> Str
escaped_text = |text|
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
