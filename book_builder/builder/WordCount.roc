## This module counts a page's words of prose, which the book holds to a limit
## so that a chapter stays short. Prose is every line outside a fence and
## outside a table: headings, paragraphs, lists and captions. A table is for
## skimming, so its rows don't count against the limit, any more than code
## does. A word is a run of characters between spaces with an ASCII letter or
## digit in it, so a lone `-` is no word.
import BookText
import Manuscript

WordCount := [].{

	## The words of prose in some lines of a manuscript.
	prose_words : List(Manuscript.Line) -> U64
	prose_words = |lines| lines
		.keep_if(|line| line.place == Prose and !is_table_row(line.text))
		.map(|line| line_words(line.text))
		.sum()

	## Whether a page of `words` words of prose is within a `limit`.
	room : { words : U64, limit : U64 } -> [Within, Over]
	room = |{ words, limit }|
		if words > limit {
			Over
		} else {
			Within
		}
}

## A table's row, its rule included: a line that starts with `|`, once trimmed.
is_table_row : Str -> Bool
is_table_row = |text| text.trim().starts_with("|")

line_words : Str -> U64
line_words = |text| text
	.split_on(" ")
	.count_if(|word| word.to_utf8().any(BookText.is_letter_or_digit))

lines_of : Str -> List(Manuscript.Line)
lines_of = |text| match Manuscript.lines(text) {
	Ok(lines) => lines
	Err(_) => crash "the test text's fences close"
}

expect WordCount.prose_words(lines_of("# A title\n\nOne two, three.\n")) == 5
expect WordCount.prose_words(lines_of("- a list item\n> a quote — with a dash\n")) == 8
expect WordCount.prose_words(lines_of("| Term | Main |\n|---|:---:|\n| a b | `c` |\n")) == 0
expect WordCount.prose_words(lines_of("Before.\n\n| a b |\n|---|\n\nAfter it.\n")) == 3
expect WordCount.prose_words(lines_of("words\n```roc a title\nnot counted here\n```\nmore\n")) == 2
expect WordCount.prose_words(lines_of("  spaced   out  \n\t\n")) == 2
expect WordCount.prose_words(lines_of("")) == 0
expect WordCount.prose_words(lines_of("café 2026 x86_64 -- ...\n")) == 3
expect ["|---|", " | - | ", "| x |", "|a"].all(is_table_row)
expect ["", "a | b", ":--", "-", "x |"].all(|text| !is_table_row(text))
expect WordCount.room({ words: 899, limit: 900 }) == Within
expect WordCount.room({ words: 900, limit: 900 }) == Within
expect WordCount.room({ words: 901, limit: 900 }) == Over
expect WordCount.room({ words: 0, limit: 0 }) == Within
