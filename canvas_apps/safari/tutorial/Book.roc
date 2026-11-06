## This module turns a manuscript into the book's pages. Each page of source
## becomes one HTML page with the book's navigation around it, and the first
## page also holds the table of contents. The sections come from the render's
## own headings.
import md.Md
import md.MdDocument
import BookFence
import DraftNotes
import Manuscript

Book := [].{

	Page : {
		file : Str,
		html : Str,
	}

	## The source's first page is the front of the book and the rest are its
	## chapters, in order.
	pages : Manuscript.Contents -> List(Book.Page)
	pages = |manuscript| {
		fence = BookFence.hook(manuscript)
		match manuscript.pages.map(|text| chapter_of(text, fence)) {
			[] => crash "book: no pages"
			[front, .. as unnumbered] => {
				chapters = unnumbered.map_with_index(with_number)
				in_order = [{ ..front, file: front_file }].concat(chapters)
				chapter_pages = chapters.map_with_index(
					|chapter, i| {
						file: chapter.file,
						html: chapter_html(chapter, { chapters, previous: in_order.get(i), next: in_order.get(i + 2) }),
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
}

Neighbour : Try(Chapter, [OutOfBounds])

## A chapter's source has one top heading, and the rest of its headings are its
## sections. Anything else means the split went wrong, so it stops the build.
chapter_of : Str, MdDocument.FenceHook -> Chapter
chapter_of = |text, fence| {
	rendered = Md.render_document(text.to_utf8(), { fence: fence })
	match rendered.headings {
		[top, .. as rest] if top.level == 1 and rest.all(|heading| heading.level == 2) => {
			{
				file: "${text_of(top.id)}.html",
				title: text_of(top.text),
				number: Unnumbered,
				body: DraftNotes.highlight(text_of(rendered.html)),
				sections: rest.map(|heading| { id: text_of(heading.id), title: text_of(heading.text) }),
			}
		}
		_ => crash "book: a page needs one top heading, with only sections under it: ${text.split_on("\n").first() ?? ""}"
	}
}

## The chapters count from one. An appendix and the credits have no number.
with_number : Chapter, U64 -> Chapter
with_number = |chapter, i|
	if chapter.title.starts_with("Appendix") or chapter.title == "Credits" {
		chapter
	} else {
		{ ..chapter, number: Numbered(i + 1) }
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
	page_html({ title: book_name, body_class: "front", nav: "", main })
}

contents_entry : Chapter -> Str
contents_entry = |chapter| "<li>${chapter_link(chapter)}${sections_html(chapter)}</li>"

chapter_html : Chapter, { chapters : List(Chapter), previous : Neighbour, next : Neighbour } -> Str
chapter_html = |chapter, { chapters, previous, next }| {
	label = match chapter.number {
		Numbered(n) => "<p class=\"chapter-number\">Chapter ${n.to_str()}</p>\n"
		Unnumbered => ""
	}
	back = turn_link(previous, { rel: "prev", word: "Previous" })
	forward = turn_link(next, { rel: "next", word: "Next" })
	main =
		\\<main>
		\\<article>
		\\${label}${chapter.body}
		\\</article>
		\\<nav class="turn-page" aria-label="Previous and next chapter">
		\\${back}
		\\${forward}
		\\</nav>
		\\</main>
	page_html({ title: "${escaped(chapter.title)} · ${book_name}", body_class: "chapter", nav: book_nav(chapters, chapter), main })
}

book_nav : List(Chapter), Chapter -> Str
book_nav = |chapters, here| {
	entries = Str.join_with(chapters.map(|chapter| nav_entry(chapter, chapter.file == here.file)), "\n")
	nav =
		\\<nav class="book-nav" aria-label="Chapters">
		\\<a class="book-name" href="${front_file}">${book_name}</a>
		\\<ol>
		\\${entries}
		\\</ol>
		\\</nav>
	nav
}

nav_entry : Chapter, Bool -> Str
nav_entry = |chapter, is_here|
	if is_here {
		"<li class=\"here\">${chapter_link(chapter)}${sections_html(chapter)}</li>"
	} else {
		"<li>${chapter_link(chapter)}</li>"
	}

chapter_link : Chapter -> Str
chapter_link = |chapter| {
	number = match chapter.number {
		Numbered(n) => "<span class=\"number\">${n.to_str()}</span> "
		Unnumbered => ""
	}
	"<a href=\"${chapter.file}\">${number}${escaped(chapter.title)}</a>"
}

sections_html : Chapter -> Str
sections_html = |chapter|
	if chapter.sections.is_empty() {
		""
	} else {
		entries = chapter.sections.map(|section| "<li><a href=\"${chapter.file}#${section.id}\">${escaped(section.title)}</a></li>")
		joined = Str.join_with(entries, "")
		"<ol class=\"sections\">${joined}</ol>"
	}

## The link out of a chapter on one side. With no chapter there it's an empty
## span, which keeps the other link on its own side.
turn_link : Neighbour, { rel : Str, word : Str } -> Str
turn_link = |neighbour, { rel, word }| match neighbour {
	Ok(chapter) if chapter.file == front_file => "<a rel=\"${rel}\" href=\"${front_file}\"><small>${word}</small>Contents</a>"
	Ok(chapter) => "<a rel=\"${rel}\" href=\"${chapter.file}\"><small>${word}</small>${escaped(chapter.title)}</a>"
	Err(_) => "<span></span>"
}

page_html : { title : Str, body_class : Str, nav : Str, main : Str } -> Str
page_html = |{ title, body_class, nav, main }| {
	embed = if (main.contains("class=\"canvas-app\"")) "<script src=\"embed.js\"></script>" else ""
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

escaped : Str -> Str
escaped = |text| text_of(Md.escape(text.to_utf8()))

text_of : List(U8) -> Str
text_of = |bytes| match Str.from_utf8(bytes) {
	Ok(text) => text
	Err(_) => crash "book: a page that isn't UTF-8"
}
