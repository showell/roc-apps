## This module says what each fenced block of a book becomes. A book names a
## hook for each language of its own, such as a widget or a diagram, and the
## hook answers the fence's markup, or why the build stops. A fence with no
## hook is code: a listing with a title over it when its opening line has
## words after the language, as an include writes one, and the renderer's own
## code block when it has none. Code is colored by the book's coloring hook,
## and left as escaped text when that answers `Plain`.
##
## The renderer's hook can't fail, so the build scans each page's fences
## first, by the same rule, and stops on every refusal before the render.
import md.MdDocument
import BookText
import Manuscript

Fences := [].{

	## A fence as a hook sees it: the words after its language on the
	## opening line, and its body, each of its lines with its newline.
	Fence : { words : Str, body : Str }

	## A book's own kind of fence. What `html_of` answers goes into the page
	## as it is, unescaped.
	Hook : { language : Str, html_of : Fences.Fence -> [Html(Str), Refused(Str)] }

	## How a book colors code: the code as HTML, every character of it
	## escaped, or `Plain` for the code as escaped text.
	Colorer : { language : Str, code : Str } -> [Colored(Str), Plain]

	## The coloring of a book that colors nothing.
	no_color : Fences.Colorer
	no_color = |_| Plain

	## What a fence becomes in a book with these hooks and this coloring.
	answer : Fences.Fence, { language : Str, hooks : List(Fences.Hook), colorer : Fences.Colorer } -> [Html(Str), Refused(Str), Pass]
	answer = |fence, { language, hooks, colorer }|
		match hooks.find_first(|hook| hook.language == language) {
			Ok(hook) =>
				match (hook.html_of)(fence) {
					Html(html) => Html(html)
					Refused(why) => Refused(why)
				}
			Err(NotFound) => {
				colored = colorer({ language, code: fence.body })
				if fence.words.is_empty() {
					match colored {
						Plain => Pass
						Colored(code) => Html("${code_block_open(language)}${code}</code></pre>\n")
					}
				} else {
					Html(listing_html({ language, title: fence.words, code: code_html(colored, fence.body) }))
				}
			}
		}

	## The renderer's hook for a book.
	renderer_hook : { hooks : List(Fences.Hook), colorer : Fences.Colorer } -> MdDocument.FenceHook
	renderer_hook = |{ hooks, colorer }| |{ tag, args, body }| {
		language = BookText.text_from_bytes(tag)
		fence = { words: BookText.text_from_bytes(args), body: BookText.text_from_bytes(body) }
		match Fences.answer(fence, { language, hooks, colorer }) {
			Html(html) => Html(html.to_utf8())
			Pass => Pass
			Refused(why) => crash "book: a fence the scan let through refused at the render: ${why}"
		}
	}

	## Every refusal among a page's fences, each naming the fence's line.
	refusals : List(Manuscript.Line), { manuscript : Str, hooks : List(Fences.Hook), colorer : Fences.Colorer } -> List(Str)
	refusals = |lines, { manuscript, hooks, colorer }|
		fences_of(lines).keep_oks(
			|{ opening, fence, language }|
				match Fences.answer(fence, { language, hooks, colorer }) {
					Refused(why) => Ok("${manuscript}:${opening.number.to_str()}: ${opening.text}: ${why}")
					Html(_) | Pass => Err(NoRefusal)
				},
		)

	## Every language that more than one hook claims.
	languages_claimed_twice : List(Fences.Hook) -> List(Str)
	languages_claimed_twice = |hooks| {
		languages = hooks.map(|hook| hook.language)
		languages.fold(
			[],
			|twice, language|
				if languages.count_if(|other| other == language) > 1 and !twice.contains(language) {
					twice.append(language)
				} else {
					twice
				},
		)
	}
}

## The renderer's own code block's opening, its language as a class.
code_block_open : Str -> Str
code_block_open = |language|
	if language.is_empty() {
		"<pre><code>"
	} else {
		"<pre><code class=\"language-${BookText.escaped_text(language)}\">"
	}

code_html : [Colored(Str), Plain], Str -> Str
code_html = |colored, code| match colored {
	Colored(html) => html
	Plain => BookText.escaped_text(code)
}

## A titled listing: the renderer's own markup for code, the title over it.
listing_html : { language : Str, title : Str, code : Str } -> Str
listing_html = |{ language, title, code }| {
	safe_title = BookText.escaped_text(title)
	listing =
		\\<figure class="listing"><figcaption>${safe_title}</figcaption><pre><code class="language-${language}">${code}</code></pre></figure>
	listing
}

## Each fence of some lines: its opening line, its language, and the fence as
## the renderer hands it to the hook.
fences_of : List(Manuscript.Line) -> List({ opening : Manuscript.Line, language : Str, fence : Fences.Fence })
fences_of = |lines| {
	var $found = []
	var $open = NoFence
	for line in lines {
		match $open {
			NoFence =>
				if line.place == Fenced {
					$open = Open({ opening: line, body: [] })
				}
			Open({ opening, body }) =>
				if line.text == "```" {
					info = opening.text.drop_prefix("```").trim()
					{ language, words } =
						match info.split_first(" ") {
							Ok({ before, after }) => { language: before, words: after.trim() }
							Err(NotFound) => { language: info, words: "" }
						}
					text = Str.join_with(body.map(|body_line| "${body_line}\n"), "")
					$found = $found.append({ opening, language, fence: { words, body: text } })
					$open = NoFence
				} else {
					$open = Open({ opening, body: body.append(line.text) })
				}
		}
	}
	$found
}

shout : Fences.Hook
shout = {
	language: "shout",
	html_of: |{ words, body }|
		if body.is_empty() {
			Refused("a shout needs something to shout")
		} else {
			Html("<p class=\"shout\">${BookText.escaped_text(words)}: ${BookText.escaped_text(body.with_ascii_uppercased())}</p>")
		},
}

bold_roc : Fences.Colorer
bold_roc = |{ language, code }|
	if language == "roc" {
		Colored("<b>${BookText.escaped_text(code)}</b>")
	} else {
		Plain
	}

answer_of : { language : Str, words : Str, body : Str }, Fences.Colorer -> [Html(Str), Refused(Str), Pass]
answer_of = |{ language, words, body }, colorer| Fences.answer({ words, body }, { language, hooks: [shout], colorer })

expect answer_of({ language: "shout", words: "hey", body: "a <b>\n" }, Fences.no_color) == Html("<p class=\"shout\">hey: A &lt;B&gt;\n</p>")
expect answer_of({ language: "shout", words: "", body: "" }, Fences.no_color) == Refused("a shout needs something to shout")
expect answer_of({ language: "roc", words: "", body: "x\n" }, Fences.no_color) == Pass
expect answer_of({ language: "roc", words: "", body: "a < b\n" }, bold_roc) == Html("<pre><code class=\"language-roc\"><b>a &lt; b\n</b></code></pre>\n")
expect answer_of({ language: "", words: "", body: "x\n" }, |_| Colored("y")) == Html("<pre><code>y</code></pre>\n")
expect
	answer_of({ language: "roc", words: "A.roc, in b", body: "a < b\n" }, Fences.no_color)
		== Html("<figure class=\"listing\"><figcaption>A.roc, in b</figcaption><pre><code class=\"language-roc\">a &lt; b\n</code></pre></figure>")
expect
	answer_of({ language: "roc", words: "A & B", body: "x\n" }, bold_roc)
		== Html("<figure class=\"listing\"><figcaption>A &amp; B</figcaption><pre><code class=\"language-roc\"><b>x\n</b></code></pre></figure>")
expect
	match Manuscript.lines("a\n```shout\n```\n```roc t\nx\n```\n```\n```\n```shout loud\nwords\n```\n") {
		Ok(lines) => Fences.refusals(lines, { manuscript: "book.md", hooks: [shout], colorer: Fences.no_color }) == ["book.md:2: ```shout: a shout needs something to shout"]
		Err(_) => Bool.False
	}
expect
	match Manuscript.lines("```roc A title  \nx\n\ny\n```\n```\n```\n") {
		Ok(lines) => fences_of(lines).map(|found| (found.language, found.fence)) == [("roc", { words: "A title", body: "x\n\ny\n" }), ("", { words: "", body: "" })]
		Err(_) => Bool.False
	}
expect Fences.languages_claimed_twice([shout, { ..shout, language: "dot" }, shout]) == ["shout"]
expect Fences.languages_claimed_twice([shout, { ..shout, language: "dot" }]) == []
