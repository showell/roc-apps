## This module handles a chapter's references to other chapters. A line of
## prose may cite a chapter by its title, `{{chapter Title}}`, or by its number,
## `{{number 5 Title}}`. Before the render, every cited title must be a
## chapter's, as its `##` heading spells it. After the render, each reference
## becomes a link to the chapter's page: the title in quotation marks, or the
## number, which must be the chapter's own. A book cut short leaves some
## chapters out, and a reference to one is its title or number as plain text.
import BookText

References := [].{

	## A reference as the source writes it.
	Citation : [ByTitle(Str), ByNumber({ number : Str, title : Str })]

	## The references in a line of prose, in order.
	citations : Str -> List(References.Citation)
	citations = |line| match line.split_on("{{") {
		[_, .. as pieces] => pieces.keep_oks(citation_of)
		[] => crash "book: Str.split_on answered no pieces"
	}

	## The line with every reference taken out, so what's left of `{{` is
	## something else.
	without_citations : Str -> Str
	without_citations = |line| match line.split_on("{{") {
		[before_any, .. as pieces] => {
			kept = pieces.map(
				|piece| match citation_end(piece) {
					Ok(after) => after
					Err(NotACitation) => "{{${piece}"
				},
			)
			Str.join_with([before_any].concat(kept), "")
		}
		[] => crash "book: Str.split_on answered no pieces"
	}

	## The title a citation names.
	cited_title : References.Citation -> Str
	cited_title = |citation| match citation {
		ByTitle(title) => title
		ByNumber({ title, .. }) => title
	}

	## A chapter as a reference finds it: its title, its page, and its number.
	Target : {
		title : Str,
		file : Str,
		number : [Numbered(U64), Unnumbered],
	}

	## A chapter the book leaves out, which has no page: its title and number.
	LeftOut : { title : Str, number : [Numbered(U64), Unnumbered] }

	## The chapters a reference can name: those with a page, and those left out.
	Chapters : { chapters : List(References.Target), left_out_chapters : List(References.LeftOut) }

	## The rendered page with each reference written out as a link, or what is
	## wrong with the references that can't be.
	linked_html : Str, References.Chapters -> Try(Str, List(Str))
	linked_html = |html, chapters| {
		titled = rewritten_page(
			html,
			{ opening: "{{chapter ", write: |reference| title_link(reference, chapters) },
		)
		numbered = rewritten_page(
			titled.html,
			{ opening: "{{number ", write: |reference| number_link(reference, chapters) },
		)
		problems = titled.problems.concat(numbered.problems)
		if problems.is_empty() {
			Ok(numbered.html)
		} else {
			Err(problems)
		}
	}
}

## A citation, from the text after its `{{`.
citation_of : Str -> Try(References.Citation, [NotACitation])
citation_of = |piece| {
	inside = (piece.split_first("}}") ? |_| NotACitation).before
	if inside.contains("{") or inside.contains("}") {
		Err(NotACitation)
	} else {
		match inside.split_first(" ") {
			Ok({ before: "chapter", after: title }) if !title.is_empty() => Ok(ByTitle(title))
			Ok({ before: "number", after }) => number_citation(after)
			_ => Err(NotACitation)
		}
	}
}

## `N Title`, a number of digits and a title.
number_citation : Str -> Try(References.Citation, [NotACitation])
number_citation = |text| match text.split_first(" ") {
	Ok(
		{ before: number, after: title },
	) if is_digits(number) and !title.is_empty() => Ok(ByNumber({ number, title }))
	_ => Err(NotACitation)
}

is_digits : Str -> Bool
is_digits = |text| {
	bytes = text.to_utf8()
	!bytes.is_empty() and bytes.all(|byte| byte >= '0' and byte <= '9')
}

## What follows a citation in the text after its `{{`.
citation_end : Str -> Try(Str, [NotACitation])
citation_end = |piece| {
	_ = citation_of(piece)?
	match piece.split_first("}}") {
		Ok({ after, .. }) => Ok(after)
		Err(NotFound) => Err(NotACitation)
	}
}

## The page rewritten at each `opening`, and what went wrong.
rewritten_page : Str,
{
	opening : Str,
	write : Str -> Try(Str, Str),
} -> { html : Str, problems : List(Str) }

rewritten_page = |html, { opening, write }| match html.split_on(opening) {
	[before_any, .. as pieces] => {
		var $out = before_any
		var $problems = []
		for piece in pieces {
			match piece.split_first("}}") {
				Ok({ before: reference, after }) =>
					match write(reference) {
						Ok(link) => {
							$out = "${$out}${link}${after}"
						}
						Err(problem) => {
							$problems = $problems.append(problem)
							$out = "${$out}${opening}${piece}"
						}
					}
				Err(NotFound) => {
					$problems = $problems.append("book: a reference with no end: ${opening}${piece}")
					$out = "${$out}${opening}${piece}"
				}
			}
		}
		{ html: $out, problems: $problems }
	}
	[] => crash "book: Str.split_on answered no pieces"
}

## A cited chapter: its number, and its page or that the book leaves it out.
Cited : { number : [Numbered(U64), Unnumbered], page : [OnPage(Str), LeftOut] }

## The chapter whose title, escaped as the renderer escapes it, is `title`.
chapter_titled : References.Chapters, Str -> Try(Cited, [NoChapter])
chapter_titled = |{ chapters, left_out_chapters }, title| {
	is_cited = |chapter| BookText.escaped_text(chapter.title) == title
	match chapters.find_first(is_cited) {
		Ok(target) => Ok({ number: target.number, page: OnPage(target.file) })
		Err(NotFound) =>
			match left_out_chapters.find_first(is_cited) {
				Ok(chapter) => Ok({ number: chapter.number, page: LeftOut })
				Err(NotFound) => Err(NoChapter)
			}
	}
}

title_link : Str, References.Chapters -> Try(Str, Str)
title_link = |title, chapters| match chapter_titled(chapters, title) {
	Ok(
		{ page: OnPage(file), .. },
	) => Ok("<a class=\"chapter-link\" href=\"${file}\">“${title}”</a>")
	Ok({ page: LeftOut, .. }) => Ok("“${title}”")
	Err(NoChapter) => Err("book: {{chapter ${title}}} names no chapter of the book")
}

number_link : Str, References.Chapters -> Try(Str, Str)
number_link = |reference, chapters| match reference.split_first(" ") {
	Ok({ before: number, after: title }) =>
		match chapter_titled(chapters, title) {
			Ok(
				{ number: Numbered(held), page },
			) if held.to_str() == number => Ok(number_written(number, page))
			Ok(
				{ number: Numbered(held), .. },
			) => Err("book: {{number ${reference}}} names chapter ${held.to_str()}")
			Ok(
				{ number: Unnumbered, .. },
			) => Err("book: {{number ${reference}}} names a chapter with no number")
			Err(NoChapter) => Err("book: {{number ${reference}}} names no chapter of the book")
		}
	Err(NotFound) => Err("book: a chapter number with no title: {{number ${reference}}}")
}

## A chapter's number as a link to its page, or plain for one left out.
number_written : Str, [OnPage(Str), LeftOut] -> Str
number_written = |number, page| match page {
	OnPage(file) => "<a class=\"chapter-link\" href=\"${file}\">${number}</a>"
	LeftOut => number
}

expect References.citations("See {{chapter A far tree}} and {{number 5 The road}}.") == [
	ByTitle("A far tree"),
	ByNumber({ number: "5", title: "The road" }),
]
expect References.citations("no references {{ here") == []
expect References.citations("{{chapter }} {{number x Y}} {{number 5}} {{index}} {{chapter a{b}}") == []
expect References.without_citations("See {{chapter A}}, {{number 2 B}} and {{lines x}}.") == "See ,  and {{lines x}}."
expect References.without_citations("plain") == "plain"
expect References.cited_title(ByTitle("A")) == "A"
expect References.cited_title(ByNumber({ number: "3", title: "B" })) == "B"

chapters : References.Chapters
chapters = {
	chapters: [
		{
			title: "Bo's \"one\" & two",
			file: "bo.html",
			number: Numbered(1),
		},
		{
			title: "Back",
			file: "back.html",
			number: Unnumbered,
		},
	],
	left_out_chapters: [],
}

cut_short : References.Chapters
cut_short = {
	chapters: [
		{
			title: "One",
			file: "one.html",
			number: Numbered(1),
		},
	],
	left_out_chapters: [
		{ title: "Two & three", number: Numbered(2) },
		{ title: "Credits", number: Unnumbered },
	],
}

expect
	References.linked_html(
		"<p>{{chapter Bo&#39;s &quot;one&quot; &amp; two}} and {{number 1 Bo&#39;s &quot;one&quot; &amp; two}}</p>",
		chapters,
	)
		== Ok("<p><a class=\"chapter-link\" href=\"bo.html\">“Bo&#39;s &quot;one&quot; &amp; two”</a> and <a class=\"chapter-link\" href=\"bo.html\">1</a></p>")
expect References.linked_html("<p>none {{ here</p>", chapters) == Ok("<p>none {{ here</p>")
expect References.linked_html(
	"{{chapter Gone}}",
	chapters,
) == Err(["book: {{chapter Gone}} names no chapter of the book"])
expect References.linked_html(
	"{{number 2 Bo&#39;s &quot;one&quot; &amp; two}}",
	chapters,
) == Err(["book: {{number 2 Bo&#39;s &quot;one&quot; &amp; two}} names chapter 1"])
expect References.linked_html(
	"{{number 4 Back}}",
	chapters,
) == Err(["book: {{number 4 Back}} names a chapter with no number"])
expect References.linked_html("{{number 4 Gone}} {{chapter Back", chapters) == Err([
	"book: a reference with no end: {{chapter Back",
	"book: {{number 4 Gone}} names no chapter of the book",
])
expect References.linked_html(
	"{{number 4}}",
	chapters,
) == Err(["book: a chapter number with no title: {{number 4}}"])
expect
	References.linked_html(
		"<p>{{chapter Two &amp; three}}, {{number 2 Two &amp; three}} and {{number 1 One}}</p>",
		cut_short,
	)
		== Ok("<p>“Two &amp; three”, 2 and <a class=\"chapter-link\" href=\"one.html\">1</a></p>")
expect References.linked_html("{{chapter Credits}}", cut_short) == Ok("“Credits”")
expect References.linked_html(
	"{{number 3 Two &amp; three}}",
	cut_short,
) == Err(["book: {{number 3 Two &amp; three}} names chapter 2"])
expect References.linked_html(
	"{{number 4 Credits}}",
	cut_short,
) == Err(["book: {{number 4 Credits}} names a chapter with no number"])
expect References.linked_html("{{chapter Gone}} {{number 5 Gone}}", cut_short) == Err([
	"book: {{chapter Gone}} names no chapter of the book",
	"book: {{number 5 Gone}} names no chapter of the book",
])
