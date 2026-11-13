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
			before: "Things",
			level: Part,
			title: "One frame",
		},
		{
			before: "Grass",
			level: Category,
			title: "Nature",
		},
		{
			before: "The road",
			level: Category,
			title: "Man-made",
		},
		{
			before: "Stills",
			level: Category,
			title: "Critters that stand still",
		},
		{
			before: "A flip book",
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

	## A chapter's page is named for its slug, never for its title, so a
	## published page keeps its address when its chapter is retitled. To retitle
	## a chapter, change its `chapter` here and keep its `slug`.
	Slug : { chapter : Str, slug : Str }

	## The slugs of the published chapters, which are the first chapters.
	slugs : List(Book.Slug)
	slugs = [
		{ chapter: "Introduction", slug: "introduction" },
		{ chapter: "One page", slug: "one-page" },
		{ chapter: "The problem", slug: "the-problem" },
		{ chapter: "Platforms, packages and modules", slug: "platforms-packages-and-modules" },
		{ chapter: "Types", slug: "types" },
		{ chapter: "Functions", slug: "functions" },
		{ chapter: "Things", slug: "things" },
		{ chapter: "Billboard Critters", slug: "billboard-critters" },
		{ chapter: "Shapes", slug: "shapes" },
		{ chapter: "A far tree", slug: "a-far-tree" },
		{ chapter: "Types for places", slug: "types-for-places" },
		{ chapter: "The pipeline", slug: "the-pipeline" },
		{ chapter: "Refused", slug: "refused" },
		{ chapter: "Nature types", slug: "nature-types" },
		{ chapter: "Asking a kind", slug: "asking-a-kind" },
		{ chapter: "Grass", slug: "grass" },
		{ chapter: "The sky", slug: "the-sky" },
		{ chapter: "Mountains", slug: "mountains" },
		{ chapter: "The road", slug: "the-road" },
		{ chapter: "Rails", slug: "rails" },
		{ chapter: "Radio towers", slug: "radio-towers" },
		{ chapter: "Stills", slug: "stills" },
		{ chapter: "Herds", slug: "herds" },
		{ chapter: "A flip book", slug: "a-flip-book" },
	]

	## The dividers and the slugs a book is cut with.
	Outline : { dividers : List(Book.Divider), slugs : List(Book.Slug) }

	## The source's first page is the front of the book and the rest are its
	## chapters, in order. A divider or a slug with no chapter stops the build, so
	## renaming a chapter can't quietly lose one, and so does a slug that isn't
	## plain or two pages with one name.
	pages : Manuscript.Contents, Book.Outline -> List(Book.Page)
	pages = |manuscript, outline| {
		fence = BookFence.fence_hook(manuscript)
		match manuscript.pages.map(|text| chapter_of(text, fence)) {
			[] => crash "book: no pages"
			[front, .. as unnumbered] => {
				numbered = unnumbered.map_with_index(with_number)
				has_its_chapter = |divider| numbered.any(|chapter| chapter.title == divider.before)
				match outline.dividers.find_first(|divider| !has_its_chapter(divider)) {
					Ok(divider) => crash "book: the divider `${divider.title}` stands above `${divider.before}`, a chapter that isn't in the book"
					Err(NotFound) => {}
				}
				naming = { extent: manuscript.extent, slugs: outline.slugs }
				linked = |chapter| linked_to_chapters(chapter, outline.slugs)
				named = named_chapters(numbered, naming)
				chapters = named.map(|chapter| with_opening(linked(chapter), outline.dividers))
				front_page = { file: front_file, html: front_html(linked(front), chapters) }
				chapter_pages = chapters.map_with_index(
					|chapter, i| {
						{ previous, next } = neighbours(chapters, i)
						{
							file: chapter.file,
							html: chapter_html(chapter, { chapters, previous, next }),
						}
					},
				)
				[front_page].concat(chapter_pages)
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

## A chapter's source has one top heading, and the rest of its headings are its
## sections. Anything else means the split went wrong, so it stops the build.
chapter_of : Str, MdDocument.FenceHook -> Chapter
chapter_of = |text, fence| {
	rendered = Md.render_document(text.to_utf8(), { fence, images: AsLinks })
	html = BookText.text_from_bytes(rendered.html)
	match rendered.headings {
		[top, .. as rest] if top.level == 1 and rest.all(|heading| heading.level == 2) => {
			notes_marked = DraftNotes.highlight(html)
			sections_linked = with_section_links(notes_marked)
			{
				file: "${BookText.text_from_bytes(top.id)}.html",
				title: BookText.text_from_bytes(top.text),
				number: Unnumbered,
				body: BookTable.with_break_points(sections_linked),
				sections: rest.map(section_of),
				opening: "",
			}
		}
		headings => {
			titles = Str.join_with(
				headings.map(|heading| BookText.text_from_bytes(heading.text)),
				", ",
			)
			crash "book: a page needs one top heading and only sections under it: ${titles}"
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

## What names the chapters' pages: the slugs, and whether the book is the first
## chapters, which are the ones published.
Naming : { extent : Manuscript.Extent, slugs : List(Book.Slug) }

## The chapters with their pages named for their slugs. A slug that isn't plain
## or has no chapter stops the build, and so do two pages with one name and a
## published chapter with no slug.
named_chapters : List(Chapter), Naming -> List(Chapter)
named_chapters = |chapters, naming| {
	match naming.slugs.find_first(|slug| !is_plain_slug(slug.slug)) {
		Ok(slug) => crash "book: the slug `${slug.slug}` isn't plain: lowercase letters, digits and hyphens"
		Err(NotFound) => {}
	}
	has_its_chapter = |slug| chapters.any(|chapter| chapter.title == slug.chapter)
	match naming.slugs.find_first(|slug| !has_its_chapter(slug)) {
		Ok(slug) => crash "book: the slug `${slug.slug}` names `${slug.chapter}`, a chapter that isn't in the book"
		Err(NotFound) => {}
	}
	named = chapters.map(
		|chapter| match named_for_slug(chapter, naming) {
			Ok(slugged) => slugged
			Err(NoSlug) => crash "book: the chapter `${chapter.title}` is published and has no slug; give it one in Book.slugs"
		},
	)
	match repeated_file([front_file].concat(named.map(|chapter| chapter.file))) {
		Ok(file) => crash "book: two pages are named ${file}"
		Err(NotFound) => {}
	}
	named
}

## The chapter with its page named for its slug. Only the first chapters are
## published, so in the whole book a chapter with no slug keeps the name its
## heading gives it, and in the first chapters it has none.
named_for_slug : Chapter, Naming -> Try(Chapter, [NoSlug])
named_for_slug = |chapter, { extent, slugs }|
	match slugs.find_first(|slug| slug.chapter == chapter.title) {
		Ok(slug) => Ok({ ..chapter, file: slug_file(slug) })
		Err(NotFound) => match extent {
			WholeBook => Ok(chapter)
			FirstChapters => Err(NoSlug)
		}
	}

slug_file : Book.Slug -> Str
slug_file = |{ slug, .. }| "${slug}.html"

chapter_link_open : Str
chapter_link_open = "{{chapter "

## Each `{{chapter Title}}` in a page's HTML as the title in quotation marks,
## linked to the chapter's page when the chapter has a slug in this book.
## build.shale has stopped on a title that no chapter has, so a title with no
## slug here is a chapter this book doesn't hold, and it stays plain text.
with_chapter_links : Str, List(Book.Slug) -> Str
with_chapter_links = |html, slugs| match html.split_on(chapter_link_open) {
	[before_any, .. as pieces] => {
		references = pieces.map(|piece| chapter_reference(piece, slugs))
		Str.join_with([before_any].concat(references), "")
	}
	[] => crash "book: Str.split_on answered no pieces"
}

## The chapter with its body's chapter references written out.
linked_to_chapters : Chapter, List(Book.Slug) -> Chapter
linked_to_chapters = |chapter, slugs| { ..chapter, body: with_chapter_links(chapter.body, slugs) }

## One piece after a `{{chapter `: the title, the `}}`, and the page after it.
## The title is as the renderer escaped it.
chapter_reference : Str, List(Book.Slug) -> Str
chapter_reference = |piece, slugs| match piece.split_first("}}") {
	Ok({ before: title, after }) => {
		quoted = "“${title}”"
		match slugs.find_first(|slug| BookText.escaped_text(slug.chapter) == title) {
			Ok(slug) => "<a class=\"chapter-link\" href=\"${slug_file(slug)}\">${quoted}</a>${after}"
			Err(NotFound) => "${quoted}${after}"
		}
	}
	Err(NotFound) => crash "book: a chapter reference with no end: ${piece}"
}

## A slug is a page's name for good, so it holds only lowercase letters, digits
## and hyphens.
is_plain_slug : Str -> Bool
is_plain_slug = |slug| {
	bytes = slug.to_utf8()
	!bytes.is_empty() and bytes.all(is_slug_byte)
}

## Bytes 97 to 122 are `a` to `z`, 48 to 57 are the digits, and 45 is the hyphen.
is_slug_byte : U8 -> Bool
is_slug_byte = |byte| (byte >= 97 and byte <= 122) or (byte >= 48 and byte <= 57) or byte == 45

## The first file named twice.
repeated_file : List(Str) -> Try(Str, [NotFound])
repeated_file = |files| files.find_first(|file| files.keep_if(|other| other == file).len() > 1)

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
	Front => "<a rel=\"${rel}\" href=\"${front_file}\"><small>${word}</small>Contents</a>"
	Chapter(chapter) => "<a rel=\"${rel}\" href=\"${chapter.file}\"><small>${word}</small>${BookText.escaped_text(chapter.title)}</a>"
	NoChapter => "<span></span>"
}

repo_url : Str
repo_url = "https://github.com/showell/roc-apps"

## The site the book is published on. The link is absolute because the book's
## checker holds every relative link to a page of the book.
site_url : Str
site_url = "https://roc.lynrummy.com/"

## The bar across the top of every page leads back to the site, says the book
## is a draft, and leads to the code the book reads.
top_bar : Str
top_bar =
	\\<header class="top-bar">
	\\<a class="home-link" href="${site_url}">Steve's Roc Apps</a>
	\\<p class="draft-notice">This is an early draft.</p>
	\\<a class="repo-link" href="${repo_url}">roc-apps on GitHub</a>
	\\</header>

page_html :
	{
		title : Str,
		body_class : Str,
		nav : Str,
		main : Str,
	} -> Str
page_html = |{ title, body_class, nav, main }| {
	embed =
		if main.contains("class=\"${BookFence.widget_frame_class}\"") {
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
		\\<script src="book.js" defer></script>
		\\</head>
		\\<body class="${body_class}">
		\\${top_bar}
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

other_section : Chapter
other_section = { ..one_section, file: "b.html", title: "B" }

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
	extent: WholeBook,
}

widget_book : Manuscript.Contents
widget_book = {
	pages: ["# Front\n", "# One\n\n```widget sky\nThe sky.\n```\n"],
	diagrams: [],
	widget_folders: ["sky_widget"],
	extent: WholeBook,
}

## The front refers to a chapter with a slug, and the chapter to one that isn't
## in the book and to one that has no slug. The title holds what the renderer
## escapes, so the link needs Md.escape to escape it alike.
linked_book : Manuscript.Contents
linked_book = {
	pages: [
		"# Front\n\nSee {{chapter Bo's \"one\" & two}}.\n",
		"# Bo's \"one\" & two\n\nSee {{chapter Gone}} and {{chapter Unslugged}}.\n",
		"# Unslugged\n",
	],
	diagrams: [],
	widget_folders: [],
	extent: WholeBook,
}

linked_pages : List(Book.Page)
linked_pages = Book.pages(
	linked_book,
	{ dividers: [], slugs: [{ chapter: "Bo's \"one\" & two", slug: "one" }] },
)

expect linked_pages.map(|page| page.html.contains("<p>See <a class=\"chapter-link\" href=\"one.html\">“Bo&#39;s &quot;one&quot; &amp; two”</a>.</p>")) == [
	Bool.True,
	Bool.False,
	Bool.False,
]
expect linked_pages.map(|page| page.html.contains("<p>See “Gone” and “Unslugged”.</p>")) == [
	Bool.False,
	Bool.True,
	Bool.False,
]
expect linked_pages.all(|page| !page.html.contains("{{chapter"))
expect with_chapter_links("<p>no references {{ here</p>", [slug_a]) == "<p>no references {{ here</p>"
expect
	with_chapter_links("{{chapter A}}, {{chapter B}} and {{chapter A}}", [slug_a])
		== "<a class=\"chapter-link\" href=\"a-slug.html\">“A”</a>, “B” and <a class=\"chapter-link\" href=\"a-slug.html\">“A”</a>"
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
empty_outline : Book.Outline
empty_outline = { dividers: [], slugs: [] }

slug_a : Book.Slug
slug_a = { chapter: "A", slug: "a-slug" }

slug_b : Book.Slug
slug_b = { chapter: "B", slug: "b" }

expect Book.pages(plain_book, empty_outline).map(|page| page.file) == [
	"index.html",
	"one.html",
	"appendix-more.html",
]
expect Book.pages(
	plain_book,
	{ ..empty_outline, slugs: [{ chapter: "One", slug: "first" }] },
).map(|page| page.file) == ["index.html", "first.html", "appendix-more.html"]
expect Book.pages(plain_book, empty_outline).all(|page| page.html.contains(top_bar))
expect Book.pages(plain_book, empty_outline).all(|page| !page.html.contains("embed.js"))
expect Book.pages(widget_book, empty_outline).map(|page| page.html.contains("embed.js")) == [
	Bool.False,
	Bool.True,
]
expect Book.pages(
	plain_book,
	{ ..empty_outline, dividers: [{ ..a_part, before: "One" }] },
).all(|page| page.html.contains("<li class=\"part\">P &amp; Q</li>"))
expect
	named_for_slug(one_section, { extent: FirstChapters, slugs: [slug_a] })
		== Ok({ ..one_section, file: "a-slug.html" })
expect
	named_for_slug(one_section, { extent: WholeBook, slugs: [slug_a] })
		== Ok({ ..one_section, file: "a-slug.html" })
expect named_for_slug(one_section, { extent: WholeBook, slugs: [slug_b] }) == Ok(one_section)
expect named_for_slug(one_section, { extent: FirstChapters, slugs: [slug_b] }) == Err(NoSlug)
expect ["billboard-critters", "a1", "x"].all(is_plain_slug)
expect ["", "Shapes", "two words", "under_score", "a.html", "é"].all(|slug| !is_plain_slug(slug))
expect Book.slugs.all(|slug| is_plain_slug(slug.slug))
expect repeated_file(["index.html", "a.html", "b.html"]) == Err(NotFound)
expect repeated_file(["index.html", "a.html", "index.html"]) == Ok("index.html")
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
expect turn_link(NoChapter, { rel: "next", word: "Next" }) == "<span></span>"
expect turn_link(
	Chapter(one_section),
	{ rel: "next", word: "Next" },
) == "<a rel=\"next\" href=\"a.html\"><small>Next</small>A</a>"
expect turn_link(
	Front,
	{ rel: "prev", word: "Previous" },
) == "<a rel=\"prev\" href=\"index.html\"><small>Previous</small>Contents</a>"
expect neighbours([one_section], 0) == { previous: Front, next: NoChapter }
expect
	neighbours([one_section, other_section, one_section], 1)
		== { previous: Chapter(one_section), next: Chapter(one_section) }
expect neighbours([one_section, other_section], 1) == {
	previous: Chapter(one_section),
	next: NoChapter,
}
expect neighbours([one_section, other_section], 0) == {
	previous: Front,
	next: Chapter(other_section),
}
