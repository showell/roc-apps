## This module builds a book. A book is a small app on the book platform:
## its `main!` names the book's settings, among them its fence hooks, and
## hands them to `Builder.build!` with the platform's `Book.read_file!`.
##
## `build!` reads what the settings name (the manuscript, each file an include
## quotes, the index's terms, the negatives lint's words and table) and gives
## them to `book_text`, which is pure. The build's gates come before any page: an
## include that can't be expanded, a reference to no chapter, a negative
## sentence the lint's table doesn't keep, a numbered chapter over the word
## limit, a fence its hook refuses, and two hooks for one language. Every
## problem a gate finds is in the answer, one a line.
##
## The answer is every page, each after a line `<!-- book page: FILE -->`,
## then a report after `<!-- book report -->`: each page's words of prose,
## and the lint's counts when it ran.
import md.Md
import BookText
import Fences
import Includes
import Manuscript
import Negatives
import Pages
import References
import TermIndex
import WordCount

Builder := [].{

	## Everything a book chooses. Paths are the book folder's.
	Settings : {
		## The manuscript, `book.md` unless named.
		manuscript : Str,

		## The most words of prose a numbered chapter may hold.
		word_limit : U64,

		## The terms file of the `{{index}}` line's index, if the book has one.
		index_terms : [NoIndex, IndexTerms(Str)],

		## The negatives lint's words file and its table of kept sentences.
		negatives : [NoLint, Lint({ words : Str, table : Str })],

		## What a fence of each of the book's own languages becomes.
		fence_hooks : List(Fences.Hook),

		## How code is colored.
		colorer : Fences.Colorer,

		## Each included file's fence language, by its extension.
		include_languages : List(Includes.Language),

		## Whether a chapter's title, as its heading spells it, makes it back
		## matter, which has no number, no word limit and no place in the
		## index.
		is_back_matter : Str -> Bool,

		## How the pages look beyond what the manuscript says: the book's name,
		## the chapters' slugs and dividers, and the book's own HTML on every
		## page.
		look : Pages.Look,

		## The includes a pre-step of the book's own expands, as
		## Includes.expanded_lines describes.
		prepared : Includes.Prepared,

		## Which chapters the book's pages hold: all of them, or the first N
		## numbered chapters and all the back matter, for a quick look at the
		## start of a long book.
		chapters : Builder.Extent,
	}

	## Every chapter, or the first N numbered ones and the back matter. The
	## gates read the whole manuscript either way, and the index is built from
	## every chapter, so a book cut short stops on what the whole book would.
	## Only its pages hold less. A reference to a chapter it leaves out, in
	## prose or in the index, is the chapter's title or number as plain text,
	## and a slug or a divider of a chapter left out has no page to be on.
	Extent : [AllChapters, FirstChapters(U64)]

	## The settings of a book that names only its own.
	default_settings : Builder.Settings
	default_settings = {
		manuscript: "book.md",
		word_limit: 900,
		index_terms: NoIndex,
		negatives: NoLint,
		fence_hooks: [],
		colorer: Fences.no_color,
		include_languages: Includes.default_languages,
		is_back_matter: |title| title.starts_with("Appendix") or title == "Credits",
		look: Pages.default_look,
		prepared: NoPrepared,
		chapters: AllChapters,
	}

	## A text the build read, and its path.
	Named : { name : Str, text : Str }

	## Everything the build reads, as the settings name it.
	Sources : {
		manuscript : Str,
		includes : List(Includes.FileRead),
		index_terms : [NoIndex, IndexTerms(Builder.Named)],
		negatives : [NoLint, Lint({ words : Builder.Named, table : Builder.Named })],
	}

	## The book built: its pages and its report, or every problem found, one
	## a line.
	build! : Builder.Settings, (Str => Try(Str, Includes.ReadProblem)) => Try(Str, Str)
	build! = |settings, read_file!| {
		read_named! = |path| match read_file!(path) {
			Ok(text) => Ok({ name: path, text })
			Err(problem) => Err("${path} ${Includes.read_problem_text(problem)}\n")
		}
		manuscript = read_named!(settings.manuscript)?
		wanted =
			match Manuscript.lines(manuscript.text) {
				Ok(lines) => Includes.paths_wanted(lines, settings.prepared)
				Err(UnclosedFence(_)) => []
			}
		var $includes = []
		for path in wanted {
			$includes = $includes.append({ path, text: read_file!(path) })
		}
		index_terms =
			match settings.index_terms {
				NoIndex => NoIndex
				IndexTerms(path) => IndexTerms(read_named!(path)?)
			}
		negatives =
			match settings.negatives {
				NoLint => NoLint
				Lint({ words, table }) => Lint({
					words: read_named!(words)?,
					table: read_named!(table)?,
				})
			}
		sources = {
			manuscript: manuscript.text,
			includes: $includes,
			index_terms,
			negatives,
		}
		Builder.book_text(settings, sources).map_err(
			|problems| Str.join_with(problems.map(|problem| "${problem}\n"), ""),
		)
	}

	## The book built from what was read: its pages and report, or every
	## problem found.
	book_text : Builder.Settings, Builder.Sources -> Try(Str, List(Str))
	book_text = |settings, sources| {
		name = settings.manuscript
		lines = Manuscript.lines(sources.manuscript) ? |UnclosedFence(at)| ["${name}:${at.to_str()}: a fence opens here and never closes"]
		gates = [
			Fences.twice_claimed_languages(settings.fence_hooks).map(|language| "book: two fence hooks claim the language `${language}`"),
			citation_problems(lines, name),
		].join()
		lint = lint_verdict(lines, { name, negatives: sources.negatives })
		lint_problems =
			match lint {
				Ok(NotRun) => []
				Ok(Ran({ findings, summary })) =>
					if findings.is_empty() {
						[]
					} else {
						findings.append(summary)
					}
				Err(problem) => [problem]
			}
		expanded =
			Includes.expanded_lines(
				lines,
				{
					manuscript: name,
					files: sources.includes,
					languages: settings.include_languages,
					prepared: settings.prepared,
				},
			)
				? |problems| List.concat(List.concat(problems, gates), lint_problems)
		indexed = lines_with_index(expanded, { settings, terms: sources.index_terms })
		book = Manuscript.pages(indexed.lines)
		front_words = WordCount.prose_words(book.front.source_lines)
		counted = List.map2(
			book.chapters,
			chapter_numbers(book.chapters, settings),
			|chapter, number| {
				chapter,
				number,
				count: WordCount.prose_words(chapter.source_lines),
			},
		)
		over = counted.keep_oks(
			|{ chapter, number, count }| limit_problem(chapter, { settings, number, count }),
		)
		fence_problems = List.concat([book.front], book.chapters)
			.map(
				|page| Fences.refusals(
					page.source_lines,
					{
						manuscript: name,
						hooks: settings.fence_hooks,
						colorer: settings.colorer,
					},
				),
			)
			.join()
		before_render = [gates, lint_problems, indexed.problems, over, fence_problems].join()
		if !before_render.is_empty() {
			Err(before_render)
		} else {
			options = {
				fence: Fences.renderer_hook({
					hooks: settings.fence_hooks,
					colorer: settings.colorer,
				}),
				images: AsLinks,
			}
			render = |page| Md.render_document(page.markdown.to_utf8(), options)
			held = counted.keep_if(|{ number, .. }| is_held(number, settings.chapters))
			made = Pages.pages({
				front: render(book.front),
				chapters: held.map(|{ chapter, number, .. }| { page: render(chapter), number }),
				left_out_chapters: counted.drop_if(
					|{ number, .. }| is_held(number, settings.chapters),
				).map(|{ chapter, number, .. }| { page: render(heading_page(chapter)), number }),
				look: settings.look,
			})?
			forged = made
				.keep_if(|page| page.html.contains(page_mark) or page.html.contains(report_mark))
				.map(|page| "book: ${page.file} holds the text of a page mark, which would cut the book there")
			if !forged.is_empty() {
				Err(forged)
			} else {
				pages_text = Str.join_with(
					made.map(|page| "${page_mark}${page.file} -->\n${page.html}\n"),
					"",
				)
				counts = List.map2(
					made,
					List.concat([front_words], held.map(|chapter| chapter.count)),
					|page, count| "${page.file}: ${count.to_str()} words of prose\n",
				)
				lint_line =
					match lint {
						Ok(Ran({ summary, .. })) => "${summary}\n"
						_ => ""
					}
				Ok("${pages_text}${report_mark}\n${Str.join_with(counts, "")}${lint_line}")
			}
		}
	}
}

page_mark : Str
page_mark = "<!-- book page: "

report_mark : Str
report_mark = "<!-- book report -->"

## Every reference in the manuscript to a title no chapter's heading has.
citation_problems : List(Manuscript.Line), Str -> List(Str)
citation_problems = |lines, name| {
	titles = lines.keep_oks(Manuscript.chapter_title)
	lines.map(
		|line| References.citations(line.text)
			.map(References.cited_title)
			.drop_if(|title| titles.contains(title))
			.map(|title| "${name}:${line.number.to_str()}: ${line.text}: no chapter is titled ${title}"),
	).join()
}

## The lint's verdict, when the book runs it.
lint_verdict :
	List(Manuscript.Line),
	{
		name : Str,
		negatives : [NoLint, Lint({ words : Builder.Named, table : Builder.Named })],
	} -> Try([NotRun, Ran({ findings : List(Str), summary : Str })], Str)
lint_verdict = |lines, { name, negatives }| match negatives {
	NoLint => Ok(NotRun)
	Lint({ words, table }) => Negatives.verdict({
		manuscript: name,
		lines,
		words,
		table,
	}).map_ok(|verdict| Ran(verdict))
}

## A chapter's title as its `##` heading line spells it.
heading_title : Manuscript.PageSource -> Str
heading_title = |page| match page.source_lines.first() {
	Ok(line) => Manuscript.chapter_title(line) ?? crash "Builder.heading_title: a chapter's first line is its heading"
	Err(ListWasEmpty) => crash "Builder.heading_title: a chapter has its heading line"
}

## Whether a chapter with this number has its page in a book of this extent.
## Back matter always does.
is_held : [Numbered(U64), Unnumbered], Builder.Extent -> Bool
is_held = |number, extent| match (number, extent) {
	(_, AllChapters) => Bool.True
	(Unnumbered, FirstChapters(_)) => Bool.True
	(Numbered(chapter_number), FirstChapters(first)) => chapter_number <= first
}

## A chapter left out, as its heading alone, which is all its rendering needs
## to give: its title as the renderer spells it.
heading_page : Manuscript.PageSource -> Manuscript.PageSource
heading_page = |chapter| { ..chapter, markdown: "# ${heading_title(chapter)}\n" }

## Each chapter's number: its place among the chapters that aren't back
## matter, counted from one, or none for back matter.
chapter_numbers : List(Manuscript.PageSource), Builder.Settings -> List([Numbered(U64), Unnumbered])
chapter_numbers = |chapters, settings| {
	var $out = []
	var $count = 0
	for chapter in chapters {
		if (settings.is_back_matter)(heading_title(chapter)) {
			$out = $out.append(Unnumbered)
		} else {
			$count = $count + 1
			$out = $out.append(Numbered($count))
		}
	}
	$out
}

## A numbered chapter over the word limit, as a problem.
limit_problem :
	Manuscript.PageSource,
	{
		settings : Builder.Settings,
		number : [Numbered(U64), Unnumbered],
		count : U64,
	} -> Try(Str, [Within])
limit_problem = |chapter, { settings, number, count }|
	match (number, WordCount.room({ words: count, limit: settings.word_limit })) {
		(
			Numbered(_),
			Over,
		) => Ok("book: the chapter `${heading_title(chapter)}` has ${count.to_str()} words of prose, over the limit of ${settings.word_limit.to_str()}")
		(Numbered(_), Within) | (Unnumbered, _) => Err(Within)
	}

## The lines with the `{{index}}` line's tables in its place, and what kept
## them from being built.
lines_with_index :
	List(Manuscript.Line),
	{
		settings : Builder.Settings,
		terms : [NoIndex, IndexTerms(Builder.Named)],
	} -> { lines : List(Manuscript.Line), problems : List(Str) }
lines_with_index = |lines, { settings, terms }| {
	index_lines = lines.keep_if(is_index_line)
	match (terms, index_lines) {
		(NoIndex, []) => { lines, problems: [] }
		(NoIndex, [first, ..]) => {
			lines,
			problems: ["${settings.manuscript}:${first.number.to_str()}: {{index}}: the book's settings name no index terms"],
		}
		(IndexTerms(named), []) => {
			lines,
			problems: ["book: the settings name the index terms ${named.name}, and no line of the book is {{index}}"],
		}
		(IndexTerms(named), [_, ..]) => {
			book = Manuscript.pages(lines)
			chapters = List.map2(
				book.chapters,
				chapter_numbers(book.chapters, settings),
				|chapter, number| match number {
					Numbered(chapter_number) => Ok({
						number: chapter_number,
						title: heading_title(chapter),
						prose_lines: index_prose_lines(chapter),
					})
					Unnumbered => Err(Unnumbered)
				},
			).keep_oks(|chapter| chapter)
			match TermIndex.tables({ terms: named, chapters }) {
				Ok(tables) => {
					table_lines = BookText.text_lines(tables)
					{
						lines: lines
							.map(
								|line|
									if is_index_line(line) {
										table_lines.map(
											|text| { number: line.number, text, place: Prose },
										)
									} else {
										[line]
									},
							)
							.join(),
						problems: [],
					}
				}
				Err(problem) => { lines, problems: [problem] }
			}
		}
	}
}

is_index_line : Manuscript.Line -> Bool
is_index_line = |line| line.place == Prose and line.text == "{{index}}"

## A chapter's prose as the index reads it: each line outside a fence but its
## heading, lowercased.
index_prose_lines : Manuscript.PageSource -> List(Str)
index_prose_lines = |chapter| chapter.source_lines
	.drop_first(1)
	.keep_if(|line| line.place == Prose)
	.map(|line| line.text.with_ascii_lowercased())

sources_of : Str -> Builder.Sources
sources_of = |manuscript| {
	manuscript,
	includes: [],
	index_terms: NoIndex,
	negatives: NoLint,
}

built_of : Str -> Try(Str, List(Str))
built_of = |manuscript| Builder.book_text(Builder.default_settings, sources_of(manuscript))

## A book whose one chapter has `count` words of prose, its one-word title
## among them.
book_of_words : {
	front : U64,
	chapter : Str,
	count : U64,
} -> Str
book_of_words = |{ front, chapter, count }| {
	front_words = Str.join_with(List.repeat("front", front), " ")
	chapter_words = Str.join_with(List.repeat("word", count - 1), " ")
	"# B\n\n${front_words}\n\n## ${chapter}\n\n${chapter_words}\n"
}

expect built_of(
	book_of_words({
		front: 0,
		chapter: "One",
		count: 900,
	}),
).is_ok()
expect built_of(
	book_of_words({
		front: 0,
		chapter: "One",
		count: 901,
	}),
) == Err(["book: the chapter `One` has 901 words of prose, over the limit of 900"])
expect built_of(
	book_of_words({
		front: 0,
		chapter: "Appendix",
		count: 901,
	}),
).is_ok()
expect built_of(
	book_of_words({
		front: 1000,
		chapter: "One",
		count: 2,
	}),
).is_ok()
expect
	Builder.book_text(
		{ ..Builder.default_settings, word_limit: 3 },
		sources_of(
			book_of_words({
				front: 0,
				chapter: "One",
				count: 4,
			}),
		),
	)
		== Err(["book: the chapter `One` has 4 words of prose, over the limit of 3"])
expect
	Builder.book_text(
		{ ..Builder.default_settings, is_back_matter: |_| Bool.False },
		sources_of(
			book_of_words({
				front: 0,
				chapter: "Appendix",
				count: 901,
			}),
		),
	)
		== Err(["book: the chapter `Appendix` has 901 words of prose, over the limit of 900"])

expect
	match built_of("# B\n\nFront.\n\n## One\n\nSee {{chapter Two}}.\n\n## Appendix: a\n\n## Two\n\nBack to {{number 1 One}}.\n") {
		Ok(text) =>
			text.starts_with("<!-- book page: index.html -->\n<!doctype html>\n")
				and text.contains("</html>\n<!-- book page: one.html -->\n")
				and text.contains("<p class=\"chapter-number\">Chapter 2</p>\n<h1 id=\"two\">Two</h1>")
				and text.contains("<a href=\"appendix-a.html\">Appendix: a</a>")
				and text.ends_with("</html>\n<!-- book report -->\nindex.html: 2 words of prose\none.html: 4 words of prose\nappendix-a.html: 2 words of prose\ntwo.html: 6 words of prose\n")
		Err(_) => Bool.False
	}
expect
	built_of("# B\n\n## One\n\nSee {{chapter Gone}}, then\n{{number 2 One}}.\n")
		== Err(["book.md:5: See {{chapter Gone}}, then: no chapter is titled Gone"])
expect
	built_of("# B\n\n## One\n\nSee {{number 2 One}}.\n")
		== Err(["book: {{number 2 One}} names chapter 1"])
expect built_of("# B\n\n```\ncode\n") == Err(["book.md:3: a fence opens here and never closes"])
expect built_of("# B\n\n## One\n\n{{index}}\n") == Err(["book.md:5: {{index}}: the book's settings name no index terms"])
expect
	Builder.book_text(
		Builder.default_settings,
		{
			..sources_of("# B\n\n## One\n"),
			index_terms: IndexTerms({ name: "terms.txt", text: "## A\nOne\n" }),
		},
	)
		== Err(["book: the settings name the index terms terms.txt, and no line of the book is {{index}}"])
expect
	Builder.book_text(
		Builder.default_settings,
		{
			..sources_of("# B\n\n## One\n\nOne word.\n\n## Appendix: index\n\n{{index}}\n"),
			index_terms: IndexTerms({ name: "terms.txt", text: "Word\n" }),
		},
	)
		== Err(["index: terms.txt:1: a term before any `## Category`"])
expect
	match Builder.book_text(
		Builder.default_settings,
		{
			..sources_of("# B\n\n## One\n\nOne word.\n\n## Appendix: index\n\n{{index}}\n"),
			index_terms: IndexTerms({ name: "terms.txt", text: "## A\nWord\n" }),
		},
	) {
		Ok(text) => text.contains("<td>Word</td>\n<td><a class=\"chapter-link\" href=\"one.html\">“One”</a></td>")
		Err(_) => Bool.False
	}
expect built_of("# B\n\n## One\n\n## One\n") == Err(["book: two pages are named one.html"])
expect built_of("No title.\n\n## One\n") == Err(["book: a page needs one top heading and only sections under it: "])

refusing : Fences.Hook
refusing = {
	language: "never",
	html_of: |{ words, .. }|
		if words == "mark" {
			Html("<!-- book page: forged.html -->")
		} else {
			Refused("no ${words}")
		},
}

expect
	Builder.book_text(
		{ ..Builder.default_settings, fence_hooks: [refusing, refusing] },
		sources_of("# B\n\n```never a\n```\n\n## One\n\n```never b\n```\n"),
	)
		== Err([
			"book: two fence hooks claim the language `never`",
			"book.md:3: ```never a: no a",
			"book.md:8: ```never b: no b",
		])
expect
	Builder.book_text(
		{ ..Builder.default_settings, fence_hooks: [refusing] },
		sources_of("# B\n\n```never mark\n```\n"),
	)
		== Err(["book: index.html holds the text of a page mark, which would cut the book there"])
expect
	Builder.book_text(
		Builder.default_settings,
		{
			..sources_of("# B\n\nIt is not here.\n\n{{file gone.txt}}\n{{chapter Gone}}\n"),
			includes: [{ path: "gone.txt", text: Err(NotFound) }],
			negatives: Lint({
				words: { name: "w.txt", text: "not\n" },
				table: { name: "t.txt", text: "# keep a: x\n" },
			}),
		},
	)
		== Err([
			"book.md:5: {{file gone.txt}}: gone.txt is not there",
			"book.md:6: {{chapter Gone}}: no chapter is titled Gone",
			"book.md:3: negative [(before the first chapter)] not: It is not here.",
			"negatives: negative 1, unused_exception 0, 1 negative sentences of 2 read, 0 kept in the table",
		])
expect
	Builder.book_text(
		Builder.default_settings,
		{
			..sources_of("# B\n\nA.\n"),
			negatives: Lint({
				words: { name: "w.txt", text: "not\n" },
				table: { name: "t.txt", text: "" },
			}),
		},
	)
		== Err(["negatives: t.txt defines no kinds"])
expect
	match Builder.book_text(
		Builder.default_settings,
		{
			..sources_of("# B\n\nA.\n"),
			negatives: Lint({
				words: { name: "w.txt", text: "not\n" },
				table: { name: "t.txt", text: "# keep a: x\n" },
			}),
		},
	) {
		Ok(text) => text.ends_with("<!-- book report -->\nindex.html: 2 words of prose\nnegatives: negative 0, unused_exception 0, 0 negative sentences of 2 read, 0 kept in the table\n")
		Err(_) => Bool.False
	}
expect
	match Manuscript.lines("## One\n\n## Appendix: a\n\n## Two\n") {
		Ok(lines) => chapter_numbers(
			Manuscript.pages(lines).chapters,
			Builder.default_settings,
		) == [Numbered(1), Unnumbered, Numbered(2)]
		Err(_) => Bool.False
	}

## A book of two numbered chapters, back matter between them, and references
## both ways, for cutting short.
two_chapters : Str
two_chapters = "# B\n\nFront.\n\n## One\n\nSee {{chapter Two}} and {{number 2 Two}}.\n\n## Appendix: a\n\n## Two\n\nBack to {{number 1 One}}.\n"

first_chapters : U64 -> Try(Str, List(Str))
first_chapters = |count| Builder.book_text(
	{ ..Builder.default_settings, chapters: FirstChapters(count) },
	sources_of(two_chapters),
)

expect
	match first_chapters(1) {
		Ok(text) =>
			text.contains("<!-- book page: one.html -->\n")
				and text.contains("<p>See “Two” and 2.</p>")
				and text.contains("<!-- book page: appendix-a.html -->\n")
				and !text.contains("two.html")
				and text.contains("<a rel=\"next\" href=\"appendix-a.html\"><small>Next</small>Appendix: a</a>")
				and text.ends_with("<!-- book report -->\nindex.html: 2 words of prose\none.html: 8 words of prose\nappendix-a.html: 2 words of prose\n")
		Err(_) => Bool.False
	}
expect
	match first_chapters(0) {
		Ok(text) => !text.contains("one.html") and text.ends_with("<!-- book report -->\nindex.html: 2 words of prose\nappendix-a.html: 2 words of prose\n")
		Err(_) => Bool.False
	}
expect
	match (first_chapters(2), built_of(two_chapters)) {
		(Ok(cut), Ok(whole)) => cut == whole
		_ => Bool.False
	}
expect
	Builder.book_text(
		{
			..Builder.default_settings,
			chapters: FirstChapters(1),
			word_limit: 5,
		},
		sources_of(two_chapters),
	)
		== Err([
			"book: the chapter `One` has 8 words of prose, over the limit of 5",
			"book: the chapter `Two` has 6 words of prose, over the limit of 5",
		])
expect
	Builder.book_text(
		{ ..Builder.default_settings, chapters: FirstChapters(1) },
		sources_of("# B\n\n## One\n\n## Two\n\nSee {{chapter Gone}}.\n"),
	)
		== Err(["book.md:7: See {{chapter Gone}}.: no chapter is titled Gone"])
expect [Numbered(3), Unnumbered].all(|number| is_held(number, FirstChapters(3))) and !is_held(
	Numbered(4),
	FirstChapters(3),
)
expect is_held(Numbered(4), AllChapters)
expect ["Appendix: a", "Appendix", "Credits"].all(Builder.default_settings.is_back_matter)
expect [
	"Credits and more",
	"An appendix",
	"credits",
].all(|title| !(Builder.default_settings.is_back_matter)(title))
