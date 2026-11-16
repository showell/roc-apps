## This app is the book platform's smallest book: it reads `book.md` from the
## book's folder and prints it as one HTML page, each paragraph of the
## manuscript as escaped plain text in a `<p>`. Rendering the markdown is a
## later step's job.
app [main!] { pf: platform "../../platform/main.roc" }

import pf.Book

main! : Str => Try(Str, Str)
main! = |book_folder|
	match Book.read_file!("book.md") {
		Ok(manuscript) => Ok(page_of(manuscript))
		Err(problem) => Err("${book_folder}/book.md: ${problem_text(problem)}\n")
	}

## The whole page for `manuscript`: a paragraph is the text between blank
## lines, trimmed, and a paragraph of nothing but space is left out.
page_of : Str -> Str
page_of = |manuscript| {
	paragraphs =
		manuscript
			.split_on("\n\n")
			.map(Str.trim)
			.drop_if(Str.is_empty)
			.map(|paragraph| "<p>${escaped_text(paragraph)}</p>\n")
	"<!doctype html>\n<html>\n<body>\n${Str.join_with(paragraphs, "")}</body>\n</html>\n"
}

## `text` with the four characters that could open markup or end an
## attribute written as entities, `&` first so no entity is escaped twice.
escaped_text : Str -> Str
escaped_text = |text|
	text
		.replace_each("&", "&amp;")
		.replace_each("<", "&lt;")
		.replace_each(">", "&gt;")
		.replace_each("\"", "&quot;")

## What went wrong, in words for the person running the build.
problem_text : [NotAFile, NotFound, NotUtf8, OutsideTheBook, ReadFailed] -> Str
problem_text = |problem|
	match problem {
		NotAFile => "is not a file"
		NotFound => "is not there"
		NotUtf8 => "is not UTF-8 text"
		OutsideTheBook => "is outside the book's folder"
		ReadFailed => "could not be read"
	}

expect escaped_text("a < b & \"c\" > d") == "a &lt; b &amp; &quot;c&quot; &gt; d"
expect escaped_text("&lt;") == "&amp;lt;"
expect escaped_text("plain") == "plain"
expect page_of("") == "<!doctype html>\n<html>\n<body>\n</body>\n</html>\n"
expect page_of("One\nline two.\n\n  \n\nThree") == "<!doctype html>\n<html>\n<body>\n<p>One\nline two.</p>\n<p>Three</p>\n</body>\n</html>\n"
expect
	[
		(NotAFile, "is not a file"),
		(NotFound, "is not there"),
		(NotUtf8, "is not UTF-8 text"),
		(OutsideTheBook, "is outside the book's folder"),
		(ReadFailed, "could not be read"),
	].all(|(problem, text)| problem_text(problem) == text)
