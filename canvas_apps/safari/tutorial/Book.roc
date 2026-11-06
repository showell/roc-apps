## This module turns a manuscript into the book's pages. Each page of source
## becomes one HTML page with the book's navigation around it, and the first
## page also holds the table of contents. The sections come from the render's
## own headings.
import md.Md
import md.MdDocument
import BookFence
import BookTable
import BookText
import DraftNotes
import Manuscript

Book := [].{

	Page : { file : Str, html : Str }

	## A line in the book's lists of chapters, above the chapter titled `before`.
	Divider : {
		before : Str,
		level : [Part, Category],
		title : Str,
	}

	## The book's parts, and the categories inside them.
	dividers : List(Book.Divider)
	dividers = [
		{
			before: "Introduction",
			level: Part,
			title: "The big picture",
		},
		{
			before: "The world",
			level: Part,
			title: "One frame",
		},
		{
			before: "Trees",
			level: Category,
			title: "Nature",
		},
		{
			before: "The road",
			level: Category,
			title: "Man-made",
		},
		{
			before: "Stills: how we draw a critter",
			level: Category,
			title: "Critters that stand still",
		},
		{
			before: "The ride instant",
			level: Part,
			title: "Motion",
		},
		{
			before: "The beacons",
			level: Category,
			title: "The passage of time",
		},
		{
			before: "Stepping through the ride: RideInstant",
			level: Category,
			title: "Vehicles",
		},
		{
			before: "The cat",
			level: Category,
			title: "Critter motion",
		},
		{
			before: "Rehearsal",
			level: Category,
			title: "How the rider steers",
		},
		{
			before: "The math layer",
			level: Part,
			title: "Under the hood",
		},
		{
			before: "Appendix: the patterns",
			level: Part,
			title: "Appendices",
		},
	]

	## The source's first page is the front of the book and the rest are its
	## chapters, in order. A divider with no chapter to stand above stops the
	## build, so renaming a chapter can't quietly lose one.
	pages : Manuscript.Contents, List(Book.Divider) -> List(Book.Page)
	pages = |manuscript, dividers_wanted| {
		fence = BookFence.hook(manuscript)
		match manuscript.pages.map(|text| chapter_of(text, fence)) {
			[] => crash "book: no pages"
			[front, .. as unnumbered] => {
				numbered = unnumbered.map_with_index(with_number)
				has_its_chapter = |divider| numbered.any(|chapter| chapter.title == divider.before)
				if !dividers_wanted.all(has_its_chapter) {
					crash "book: a divider stands above a chapter that isn't in the book"
				}
				chapters = numbered.map(|chapter| with_opening(chapter, dividers_wanted))
				in_order = [{ ..front, file: front_file }].concat(chapters)
				chapter_pages = chapters.map_with_index(
					|chapter, i| {
						file: chapter.file,
						html: chapter_html(
							chapter,
							{
								chapters,
								previous: in_order.get(i),
								next: in_order.get(i + 2),
							},
						),
					},
				)
				[{ file: front_file, html: front_html(front, chapters) }].concat(chapter_pages)
			}
		}
	}
}

book_name : Str
book_name = "Safari Ride"

front_file : Str
front_file = "index.html"

Section : { id : Str, title : Str }

Chapter : {
	file : Str,
	title : Str,
	number : [Numbered(U64), Unnumbered],
	body : Str,
	sections : List(Section),
	opening : Str,
}

Neighbour : Try(Chapter, [OutOfBounds])

## A chapter's source has one top heading, and the rest of its headings are its
## sections. Anything else means the split went wrong, so it stops the build.
chapter_of : Str, MdDocument.FenceHook -> Chapter
chapter_of = |text, fence| {
	rendered = Md.render_document(text.to_utf8(), { fence, images: AsLinks })
	html = BookText.from_bytes(rendered.html)
	match rendered.headings {
		[top, .. as rest] if top.level == 1 and rest.all(|heading| heading.level == 2) => {
			{
				file: "${BookText.from_bytes(top.id)}.html",
				title: BookText.from_bytes(top.text),
				number: Unnumbered,
				body: BookTable.with_break_points(with_section_links(DraftNotes.highlight(html))),
				sections: rest.map(section_of),
				opening: "",
			}
		}
		headings => {
			titles = Str.join_with(headings.map(|heading| BookText.from_bytes(heading.text)), ", ")
			crash "book: a page needs one top heading and only sections under it: ${titles}"
		}
	}
}

section_open : Str
section_open = "<h2 id=\""

## Each section's heading with a link to itself, for a reader to copy.
with_section_links : Str -> Str
with_section_links = |html| match html.split_on(section_open) {
	[before_any, .. as sections] => {
		Str.join_with([before_any].concat(sections.map(section_with_link)), section_open)
	}
	[] => html
}

## One piece after a heading's opening: its id, the heading, and what follows.
section_with_link : Str -> Str
section_with_link = |piece| match piece.split_first("\">") {
	Ok({ before: id, after }) => match after.split_first("</h2>") {
		Ok({ before: heading, after: rest }) => {
			link = "<a class=\"section-link\" href=\"#${id}\" aria-label=\"Link to this section\">§</a>"
			"${id}\">${heading} ${link}</h2>${rest}"
		}
		Err(_) => crash "book: a section heading with no end: ${piece}"
	}
	Err(_) => crash "book: a section heading with no id: ${piece}"
}

section_of : MdDocument.Heading -> Section
section_of = |heading| {
	title = BookText.from_bytes(heading.text)
	{ id: BookText.from_bytes(heading.id), title }
}

## The chapters count from one. An appendix and the credits have no number.
with_number : Chapter, U64 -> Chapter
with_number = |chapter, i|
	if chapter.title.starts_with("Appendix") or chapter.title == "Credits" {
		chapter
	} else {
		{ ..chapter, number: Numbered(i + 1) }
	}

## The chapter with the list items of the dividers above it.
with_opening : Chapter, List(Book.Divider) -> Chapter
with_opening = |chapter, dividers_wanted| {
	above = dividers_wanted.keep_if(|divider| divider.before == chapter.title)
	{ ..chapter, opening: Str.join_with(above.map(divider_html), "\n") }
}

divider_html : Book.Divider -> Str
divider_html = |divider| {
	class = match divider.level {
		Part => "part"
		Category => "category"
	}
	"<li class=\"${class}\">${BookText.escaped_text(divider.title)}</li>"
}

front_html : Chapter, List(Chapter) -> Str
front_html = |front, chapters| {
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
		title: book_name,
		body_class: "front",
		nav: "",
		main,
	})
}

contents_entry : Chapter -> Str
contents_entry = |chapter| "${chapter.opening}<li>${chapter_link(chapter)}${sections_html(chapter)}</li>"

chapter_html :
	Chapter,
	{
		chapters : List(Chapter),
		previous : Neighbour,
		next : Neighbour,
	} -> Str
chapter_html = |chapter, { chapters, previous, next }| {
	label = match chapter.number {
		Numbered(n) => "<p class=\"chapter-number\">Chapter ${n.to_str()}</p>\n"
		Unnumbered => ""
	}
	back = turn_link(previous, { rel: "prev", word: "Previous" })
	forward = turn_link(next, { rel: "next", word: "Next" })
	main =
		\\<main>
		\\<p class="book-bar"><a href="${front_file}">${book_name}</a> <a href="#chapters">Chapters</a></p>
		\\<article>
		\\${label}${chapter.body}
		\\</article>
		\\<nav class="turn-page" aria-label="Previous and next chapter">
		\\${back}
		\\${forward}
		\\</nav>
		\\</main>
	page_html({
		title: "${BookText.escaped_text(chapter.title)} · ${book_name}",
		body_class: "chapter",
		nav: book_nav(chapters, chapter),
		main,
	})
}

book_nav : List(Chapter), Chapter -> Str
book_nav = |chapters, here| {
	entries = Str.join_with(chapters.map(|chapter| nav_entry(chapter, here)), "\n")
	nav =
		\\<nav class="book-nav" id="chapters" aria-label="Chapters">
		\\<a class="book-name" href="${front_file}">${book_name}</a>
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
		"${chapter.opening}<li class=\"here\">${chapter_link(chapter)}${sections_html(chapter)}</li>"
	} else {
		"${chapter.opening}<li>${chapter_link(chapter)}</li>"
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
	Ok(chapter) if chapter.file == front_file => "<a rel=\"${rel}\" href=\"${front_file}\"><small>${word}</small>Contents</a>"
	Ok(chapter) => "<a rel=\"${rel}\" href=\"${chapter.file}\"><small>${word}</small>${BookText.escaped_text(chapter.title)}</a>"
	Err(_) => "<span></span>"
}

page_html :
	{
		title : Str,
		body_class : Str,
		nav : Str,
		main : Str,
	} -> Str
page_html = |{ title, body_class, nav, main }| {
	embed =
		if main.contains("class=\"canvas-app\"") {
			"<script src=\"embed.js\"></script>"
		} else {
			""
		}
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
		\\${embed}
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
	opening: "",
}

a_part : Book.Divider
a_part = {
	before: "A",
	level: Part,
	title: "P & Q",
}

a_category : Book.Divider
a_category = {
	before: "A",
	level: Category,
	title: "C",
}

elsewhere : Book.Divider
elsewhere = {
	before: "B",
	level: Part,
	title: "R",
}

plain_book : Manuscript.Contents
plain_book = {
	pages: ["# Front\n", "# One\n\n## Part\n", "# Appendix: more\n"],
	diagrams: [],
	widget_folders: [],
}

expect nav_entry(
	one_section,
	one_section,
) == "<li class=\"here\"><a href=\"a.html\">A</a><ol class=\"sections\"><li><a href=\"a.html#s\">S</a></li></ol></li>"
expect nav_entry(
	one_section,
	{ ..one_section, file: "b.html" },
) == "<li><a href=\"a.html\">A</a></li>"
expect with_number(one_section, 2).number == Numbered(3)
expect with_number({ ..one_section, title: "Appendix: x" }, 2).number == Unnumbered
expect with_number({ ..one_section, title: "Credits" }, 2).number == Unnumbered
expect Book.pages(plain_book, []).map(|page| page.file) == [
	"index.html",
	"one.html",
	"appendix-more.html",
]
expect Book.pages(plain_book, []).all(|page| !page.html.contains("embed.js"))
expect Book.pages(
	plain_book,
	[{ ..a_part, before: "One" }],
).all(|page| page.html.contains("<li class=\"part\">P &amp; Q</li>"))
expect with_opening(one_section, [elsewhere]).opening == ""
expect with_opening(
	one_section,
	[a_part, a_category, elsewhere],
).opening == "<li class=\"part\">P &amp; Q</li>\n<li class=\"category\">C</li>"
expect contents_entry({ ..one_section, opening: "<li>o</li>" }).starts_with("<li>o</li><li><a ")
expect nav_entry(
	{ ..one_section, opening: "<li>o</li>" },
	one_section,
).starts_with("<li>o</li><li class=\"here\">")
expect nav_entry(
	{ ..one_section, opening: "<li>o</li>" },
	{ ..one_section, file: "b.html" },
).starts_with("<li>o</li><li><a ")
expect with_section_links("<p>no sections</p>") == "<p>no sections</p>"
expect
	with_section_links("<h1 id=\"a\">A</h1><h2 id=\"b\">B <code>c</code></h2>d<h2 id=\"e\">E</h2>")
		== "<h1 id=\"a\">A</h1><h2 id=\"b\">B <code>c</code> <a class=\"section-link\" href=\"#b\" aria-label=\"Link to this section\">§</a></h2>d<h2 id=\"e\">E <a class=\"section-link\" href=\"#e\" aria-label=\"Link to this section\">§</a></h2>"
expect turn_link(Err(OutOfBounds), { rel: "next", word: "Next" }) == "<span></span>"
expect turn_link(
	Ok(one_section),
	{ rel: "next", word: "Next" },
) == "<a rel=\"next\" href=\"a.html\"><small>Next</small>A</a>"
expect turn_link(
	Ok({ ..one_section, file: "index.html" }),
	{ rel: "prev", word: "Previous" },
) == "<a rel=\"prev\" href=\"index.html\"><small>Previous</small>Contents</a>"
