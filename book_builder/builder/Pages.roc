## This module turns a book's rendered pages into its HTML pages, with the
## book's navigation around each. The front page holds the contents: each
## chapter with its sections. A chapter's page has the list of chapters beside
## it, its own sections open, and links to the pages before and after it. The
## sections come from the render's own headings, and each section's heading
## gets a link to itself.
##
## A chapter's page is named for its heading's id, the front page is
## `index.html`, and two pages with one name stop the build. So does a page
## that isn't one top heading with only sections under it.
import md.MdDocument
import BookText
import References

Pages := [].{

	## One page of the book, ready to write.
	Page : { file : Str, html : Str }

	## A page as the renderer gave it back, with its chapter's number.
	Rendered : { page : MdDocument.Page, number : [Numbered(U64), Unnumbered] }

	## The front page, then each chapter's, or every problem found.
	pages : { front : MdDocument.Page, chapters : List(Pages.Rendered) } -> Try(List(Pages.Page), List(Str))
	pages = |{ front, chapters }| {
		front_chapter = chapter_of({ page: front, number: Unnumbered }) ? |problem| [problem]
		book_name = front_chapter.title
		made = chapters.map(chapter_of)
		shaped = made.keep_oks(|chapter| chapter)
		files = [front_file].concat(shaped.map(|chapter| chapter.file))
		problems =
			made
				.keep_oks(problem_of)
				.concat(repeated_files(files).map(|file| "book: two pages are named ${file}"))
		if !problems.is_empty() {
			Err(problems)
		} else {
			reference_chapters = shaped.map(|chapter| { title: chapter.title, file: chapter.file, number: chapter.number })
			linked = [front_chapter].concat(shaped).map(|chapter| References.linked(chapter.body, reference_chapters).map_ok(|body| { ..chapter, body }))
			link_problems = linked.keep_oks(problem_list).join()
			if !link_problems.is_empty() {
				Err(link_problems)
			} else {
				match linked.keep_oks(|chapter| chapter) {
					[linked_front, .. as linked_chapters] => {
						front_page = { file: front_file, html: front_html(linked_front, { book_name, chapters: linked_chapters }) }
						chapter_pages = linked_chapters.map_with_index(
							|chapter, i| {
								{ previous, next } = neighbours(linked_chapters, i)
								{
									file: chapter.file,
									html: chapter_html(
										chapter,
										{
											book_name,
											chapters: linked_chapters,
											previous,
											next,
										},
									),
								}
							},
						)
						Ok([front_page].concat(chapter_pages))
					}
					[] => crash "Pages.pages: the front is always among the linked"
				}
			}
		}
	}
}

front_file : Str
front_file = "index.html"

Section : { id : Str, title : Str }

Chapter : {
	file : Str,
	title : Str,
	number : [Numbered(U64), Unnumbered],
	body : Str,
	sections : List(Section),
}

problem_of : Try(Chapter, Str) -> Try(Str, [NoProblem])
problem_of = |made| match made {
	Ok(_) => Err(NoProblem)
	Err(problem) => Ok(problem)
}

problem_list : Try(Chapter, List(Str)) -> Try(List(Str), [NoProblem])
problem_list = |made| match made {
	Ok(_) => Err(NoProblem)
	Err(problems) => Ok(problems)
}

## A page has one top heading, and the rest of its headings are its sections.
chapter_of : Pages.Rendered -> Try(Chapter, Str)
chapter_of = |{ page, number }| {
	html = BookText.text_from_bytes(page.html)
	match page.headings {
		[top, .. as rest] if top.level == 1 and rest.all(|heading| heading.level == 2) =>
			Ok({
				file: "${BookText.text_from_bytes(top.id)}.html",
				title: BookText.text_from_bytes(top.text),
				number,
				body: with_section_links(html),
				sections: rest.map(section_of),
			})
		headings => {
			titles = Str.join_with(headings.map(|heading| BookText.text_from_bytes(heading.text)), ", ")
			Err("book: a page needs one top heading and only sections under it: ${titles}")
		}
	}
}

section_open : Str
section_open = "<h2 id=\""

## Each section's heading with a link to itself, for a reader to copy.
with_section_links : Str -> Str
with_section_links = |html| BookText.rewritten_after(
	html,
	{ opening: section_open, rewrite: section_with_link },
)

## One piece after a heading's opening: its id, the heading, and what follows.
section_with_link : Str -> Str
section_with_link = |piece| match piece.split_first("\">") {
	Ok({ before: id, after }) => match after.split_first("</h2>") {
		Ok({ before: heading, after: rest }) => {
			link = "<a class=\"section-link\" href=\"#${id}\" aria-label=\"Link to this section\">§</a>"
			"${id}\">${heading} ${link}</h2>${rest}"
		}
		Err(NotFound) => crash "book: a section heading with no end: ${piece}"
	}
	Err(NotFound) => crash "book: a section heading with no id: ${piece}"
}

section_of : MdDocument.Heading -> Section
section_of = |heading| {
	title = BookText.text_from_bytes(heading.text)
	{ id: BookText.text_from_bytes(heading.id), title }
}

## Each file named more than once, once.
repeated_files : List(Str) -> List(Str)
repeated_files = |files| files.fold(
	[],
	|repeated, file|
		if files.count_if(|other| other == file) > 1 and !repeated.contains(file) {
			repeated.append(file)
		} else {
			repeated
		},
)

## The page a chapter's turn link goes to on one side.
Neighbour : [Front, Chapter(Chapter), NoChapter]

## The pages on either side of chapter `i`: the front comes before the first
## chapter, and nothing comes after the last.
neighbours : List(Chapter), U64 -> { previous : Neighbour, next : Neighbour }
neighbours = |chapters, i| {
	previous = if i == 0 {
		Front
	} else {
		neighbour_at(chapters, i - 1)
	}
	{ previous, next: neighbour_at(chapters, i + 1) }
}

neighbour_at : List(Chapter), U64 -> Neighbour
neighbour_at = |chapters, i| match chapters.get(i) {
	Ok(chapter) => Chapter(chapter)
	Err(OutOfBounds) => NoChapter
}

front_html : Chapter, { book_name : Str, chapters : List(Chapter) } -> Str
front_html = |front, { book_name, chapters }| {
	contents = Str.join_with(chapters.map(contents_entry), "\n")
	main =
		\\<main>
		\\<article>
		\\${front.body}
		\\<h2 id="contents">Contents</h2>
		\\<ol class="contents">
		\\${contents}
		\\</ol>
		\\</article>
		\\</main>
	page_html({
		title: BookText.escaped_text(book_name),
		body_class: "front",
		nav: "",
		main,
	})
}

contents_entry : Chapter -> Str
contents_entry = |chapter| "<li>${chapter_link(chapter)}${sections_html(chapter)}</li>"

chapter_html :
	Chapter,
	{
		book_name : Str,
		chapters : List(Chapter),
		previous : Neighbour,
		next : Neighbour,
	} -> Str
chapter_html = |chapter, { book_name, chapters, previous, next }| {
	label = match chapter.number {
		Numbered(n) => "<p class=\"chapter-number\">Chapter ${n.to_str()}</p>\n"
		Unnumbered => ""
	}
	safe_name = BookText.escaped_text(book_name)
	back = turn_link(previous, { rel: "prev", word: "Previous" })
	forward = turn_link(next, { rel: "next", word: "Next" })
	main =
		\\<main>
		\\<p class="book-bar"><a href="${front_file}">${safe_name}</a> <a href="#chapters">Chapters</a></p>
		\\<article>
		\\${label}${chapter.body}
		\\</article>
		\\<nav class="turn-page" aria-label="Previous and next chapter">
		\\${back}
		\\${forward}
		\\</nav>
		\\</main>
	page_html({
		title: "${BookText.escaped_text(chapter.title)} · ${safe_name}",
		body_class: "chapter",
		nav: book_nav(chapters, { here: chapter, safe_name }),
		main,
	})
}

book_nav : List(Chapter), { here : Chapter, safe_name : Str } -> Str
book_nav = |chapters, { here, safe_name }| {
	entries = Str.join_with(chapters.map(|chapter| nav_entry(chapter, here)), "\n")
	nav =
		\\<nav class="book-nav" id="chapters" aria-label="Chapters">
		\\<a class="book-name" href="${front_file}">${safe_name}</a>
		\\<ol>
		\\${entries}
		\\</ol>
		\\</nav>
	nav
}

## Only the chapter being read opens to show its sections.
nav_entry : Chapter, Chapter -> Str
nav_entry = |chapter, here|
	if chapter.file == here.file {
		"<li class=\"here\">${chapter_link(chapter)}${sections_html(chapter)}</li>"
	} else {
		"<li>${chapter_link(chapter)}</li>"
	}

chapter_link : Chapter -> Str
chapter_link = |chapter| {
	number = match chapter.number {
		Numbered(n) => "<span class=\"number\">${n.to_str()}</span>"
		Unnumbered => ""
	}
	"<a href=\"${chapter.file}\">${number}${BookText.escaped_text(chapter.title)}</a>"
}

sections_html : Chapter -> Str
sections_html = |chapter|
	if chapter.sections.is_empty() {
		""
	} else {
		joined = Str.join_with(chapter.sections.map(|section| section_entry(chapter, section)), "")
		"<ol class=\"sections\">${joined}</ol>"
	}

section_entry : Chapter, Section -> Str
section_entry = |chapter, section| {
	title = BookText.escaped_text(section.title)
	"<li><a href=\"${chapter.file}#${section.id}\">${title}</a></li>"
}

## The link out of a chapter on one side. With no chapter there it's an empty
## span, which keeps the other link on its own side.
turn_link : Neighbour, { rel : Str, word : Str } -> Str
turn_link = |neighbour, { rel, word }| match neighbour {
	Front => "<a rel=\"${rel}\" href=\"${front_file}\"><small>${word}</small>Contents</a>"
	Chapter(chapter) => "<a rel=\"${rel}\" href=\"${chapter.file}\"><small>${word}</small>${BookText.escaped_text(chapter.title)}</a>"
	NoChapter => "<span></span>"
}

page_html :
	{
		title : Str,
		body_class : Str,
		nav : Str,
		main : Str,
	} -> Str
page_html = |{ title, body_class, nav, main }| {
	page =
		\\<!doctype html>
		\\<html lang="en">
		\\<head>
		\\<meta charset="utf-8">
		\\<meta name="viewport" content="width=device-width, initial-scale=1">
		\\<title>${title}</title>
		\\<link rel="icon" href="data:,">
		\\<link rel="stylesheet" href="book.css">
		\\</head>
		\\<body class="${body_class}">
		\\${nav}
		\\${main}
		\\</body>
		\\</html>
	page
}

one_section : Chapter
one_section = {
	file: "a.html",
	title: "A",
	number: Unnumbered,
	body: "",
	sections: [{ id: "s", title: "S" }],
}

other_section : Chapter
other_section = { ..one_section, file: "b.html", title: "B" }

heading : { level : U64, id : Str, text : Str } -> MdDocument.Heading
heading = |{ level, id, text }| { level, id: id.to_utf8(), text: text.to_utf8() }

rendered : Str, List(MdDocument.Heading) -> MdDocument.Page
rendered = |html, headings| { html: html.to_utf8(), headings }

front_page : MdDocument.Page
front_page = rendered("<h1 id=\"b\">B &amp; c</h1>\n<p>Hi.</p>\n", [heading({ level: 1, id: "b", text: "B & c" })])

one_page : MdDocument.Page
one_page = rendered("<h1 id=\"one\">One</h1>\n<h2 id=\"s\">S</h2>\n<p>See {{chapter Two}}.</p>\n", [heading({ level: 1, id: "one", text: "One" }), heading({ level: 2, id: "s", text: "S" })])

two_page : MdDocument.Page
two_page = rendered("<h1 id=\"two\">Two</h1>\n<p>Back to {{number 1 One}}.</p>\n", [heading({ level: 1, id: "two", text: "Two" })])

expect
	Pages.pages({ front: front_page, chapters: [{ page: one_page, number: Numbered(1) }, { page: two_page, number: Unnumbered }] }).map_ok(|made| made.map(|page| page.file))
		== Ok(["index.html", "one.html", "two.html"])
expect
	match Pages.pages({ front: front_page, chapters: [{ page: one_page, number: Numbered(1) }, { page: two_page, number: Unnumbered }] }) {
		Ok([front, one, two]) =>
			front.html.contains("<title>B &amp; c</title>")
				and front.html.contains("<ol class=\"contents\">\n<li><a href=\"one.html\"><span class=\"number\">1</span>One</a><ol class=\"sections\"><li><a href=\"one.html#s\">S</a></li></ol></li>\n<li><a href=\"two.html\">Two</a></li>\n</ol>")
				and one.html.contains("<p>See <a class=\"chapter-link\" href=\"two.html\">“Two”</a>.</p>")
				and one.html.contains("<p class=\"chapter-number\">Chapter 1</p>")
				and one.html.contains("<title>One · B &amp; c</title>")
				and one.html.contains("<h2 id=\"s\">S <a class=\"section-link\" href=\"#s\" aria-label=\"Link to this section\">§</a></h2>")
				and one.html.contains("<a rel=\"prev\" href=\"index.html\"><small>Previous</small>Contents</a>\n<a rel=\"next\" href=\"two.html\"><small>Next</small>Two</a>")
				and two.html.contains("<p>Back to <a class=\"chapter-link\" href=\"one.html\">1</a>.</p>")
				and !two.html.contains("chapter-number")
				and two.html.contains("<a rel=\"prev\" href=\"one.html\"><small>Previous</small>One</a>\n<span></span>")
		_ => Bool.False
	}
expect
	Pages.pages({ front: front_page, chapters: [{ page: one_page, number: Numbered(1) }, { page: one_page, number: Numbered(2) }] })
		== Err(["book: two pages are named one.html"])
expect
	Pages.pages({ front: rendered("<p>no heading</p>", []), chapters: [] })
		== Err(["book: a page needs one top heading and only sections under it: "])
expect
	Pages.pages({ front: front_page, chapters: [{ page: rendered("", [heading({ level: 1, id: "x", text: "X" }), heading({ level: 3, id: "y", text: "Y" })]), number: Unnumbered }, { page: two_page, number: Unnumbered }] })
		== Err(["book: a page needs one top heading and only sections under it: X, Y"])
expect
	Pages.pages({ front: front_page, chapters: [{ page: two_page, number: Unnumbered }] })
		== Err(["book: {{number 1 One}} names no chapter of the book"])
expect nav_entry(one_section, one_section) == "<li class=\"here\"><a href=\"a.html\">A</a><ol class=\"sections\"><li><a href=\"a.html#s\">S</a></li></ol></li>"
expect nav_entry(one_section, other_section) == "<li><a href=\"a.html\">A</a></li>"
expect with_section_links("<p>no sections</p>") == "<p>no sections</p>"
expect turn_link(NoChapter, { rel: "next", word: "Next" }) == "<span></span>"
expect neighbours([one_section], 0) == { previous: Front, next: NoChapter }
expect neighbours([one_section, other_section, one_section], 1) == { previous: Chapter(one_section), next: Chapter(one_section) }
expect neighbours([one_section, other_section], 1) == { previous: Chapter(one_section), next: NoChapter }
expect repeated_files(["a", "b", "a", "a", "c", "c"]) == ["a", "c"]
expect repeated_files(["a", "b"]) == []
