## This module reads a manuscript's lines, tells prose from fenced code, and
## cuts the manuscript into pages. A fence opens at a line of prose that starts
## with three backticks and closes at the first line after it that is exactly
## three backticks, so every other module asks this one which lines are prose.
##
## The manuscript's `#` heading and the text under it are the front page. Each
## `##` heading starts a chapter, whose `###` headings are its sections. A page
## is written for the renderer one level up, so its own title is its one `#`
## heading and its sections are `##`.
import BookText

Manuscript := [].{

	## One line of a manuscript, numbered from one, and whether it is prose or
	## part of a fence (its opening and closing lines included).
	Line : {
		number : U64,
		text : Str,
		place : [Prose, Fenced],
	}

	## The lines of `text`, each placed. A fence that never closes is an
	## error naming the line that opens it.
	lines : Str -> Try(List(Manuscript.Line), [UnclosedFence(U64)])
	lines = |text| {
		var $out = []
		var $open_at = 0
		var $number = 0
		for line in BookText.text_lines(text) {
			$number = $number + 1
			if $open_at == 0 {
				if line.starts_with(fence_mark) {
					$open_at = $number
					$out = $out.append({ number: $number, text: line, place: Fenced })
				} else {
					$out = $out.append({ number: $number, text: line, place: Prose })
				}
			} else {
				if line == fence_mark {
					$open_at = 0
				}
				$out = $out.append({ number: $number, text: line, place: Fenced })
			}
		}
		if $open_at == 0 {
			Ok($out)
		} else {
			Err(UnclosedFence($open_at))
		}
	}

	## The manuscript's text again, from its lines.
	text_of : List(Manuscript.Line) -> Str
	text_of = |lines_given| Str.join_with(lines_given.map(|line| "${line.text}\n"), "")

	## One page's source: its lines as the manuscript has them, and its text
	## with each heading one level up, for the renderer.
	PageSource : { source_lines : List(Manuscript.Line), markdown : Str }

	## The front page, then each chapter in order.
	pages : List(Manuscript.Line) -> { front : Manuscript.PageSource, chapters : List(Manuscript.PageSource) }
	pages = |lines_given| {
		var $done = []
		var $now = []
		for line in lines_given {
			if line.place == Prose and line.text.starts_with("## ") {
				$done = $done.append($now)
				$now = [line]
			} else {
				$now = $now.append(line)
			}
		}
		all = $done.append($now).map(page_source)
		match all {
			[front, .. as chapters] => { front, chapters }
			[] => crash "Manuscript.pages: the front page is always there"
		}
	}

	## The title of a chapter's `##` heading line, as the manuscript spells it.
	chapter_title : Manuscript.Line -> Try(Str, [NotAChapter])
	chapter_title = |line|
		if line.place == Prose {
			line.text.drop_prefix("## ") |> chapter_title_of(line.text)
		} else {
			Err(NotAChapter)
		}
}

fence_mark : Str
fence_mark = "```"

## The `##` title, when dropping the prefix took something off.
chapter_title_of : Str, Str -> Try(Str, [NotAChapter])
chapter_title_of = |dropped, text|
	if dropped == text {
		Err(NotAChapter)
	} else {
		Ok(dropped)
	}

page_source : List(Manuscript.Line) -> Manuscript.PageSource
page_source = |lines_given| {
	shifted = lines_given.map(
		|line|
			if line.place == Prose and line.text.starts_with("##") {
				line.text.drop_prefix("#")
			} else {
				line.text
			},
	)
	{ source_lines: lines_given, markdown: Str.join_with(shifted.map(|text| "${text}\n"), "") }
}

expect
	Manuscript.lines("a\n```roc x\n## in code\n```\n## b\n")
		== Ok([
			{ number: 1, text: "a", place: Prose },
			{ number: 2, text: "```roc x", place: Fenced },
			{ number: 3, text: "## in code", place: Fenced },
			{ number: 4, text: "```", place: Fenced },
			{ number: 5, text: "## b", place: Prose },
		])
expect Manuscript.lines("a\n```\nb\n``` \n") == Err(UnclosedFence(2))
expect Manuscript.lines("```\n```") == Ok([{ number: 1, text: "```", place: Fenced }, { number: 2, text: "```", place: Fenced }])
expect Manuscript.lines("") == Ok([])
expect
	match Manuscript.lines("a\n\n```\nb\n```\n") {
		Ok(lines) => Manuscript.text_of(lines) == "a\n\n```\nb\n```\n"
		Err(_) => Bool.False
	}

book_lines : List(Manuscript.Line)
book_lines = match Manuscript.lines("# Book\nfront\n### Aside\n## One\ntext\n### Part\n```\n## not a chapter\n### nor a section\n```\n## Two\n") {
	Ok(lines) => lines
	Err(_) => crash "the test book has closed fences"
}

expect
	Manuscript.pages(book_lines).front.markdown == "# Book\nfront\n## Aside\n"
expect
	Manuscript.pages(book_lines).chapters.map(|page| page.markdown)
		== [
			"# One\ntext\n## Part\n```\n## not a chapter\n### nor a section\n```\n",
			"# Two\n",
		]
expect Manuscript.pages(book_lines).chapters.map(|page| page.source_lines.map(|line| line.number)) == [[4, 5, 6, 7, 8, 9, 10], [11]]
expect Manuscript.pages([]).front.markdown == ""
expect Manuscript.pages([]).chapters == []
expect Manuscript.chapter_title({ number: 1, text: "## A title", place: Prose }) == Ok("A title")
expect Manuscript.chapter_title({ number: 1, text: "## A title", place: Fenced }) == Err(NotAChapter)
expect Manuscript.chapter_title({ number: 1, text: "### A section", place: Prose }) == Err(NotAChapter)
expect Manuscript.chapter_title({ number: 1, text: "# The book", place: Prose }) == Err(NotAChapter)
