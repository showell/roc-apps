## This app builds the books book, Building a Book with Claude, on the book
## platform with the book builder. Its folder is the roc-apps checkout's root,
## so an include quotes the builder's code or the Safari tutorial's files by
## its path in the repository. Its pre-step, book.shale, does what needs a
## program, each into `building-books/build/prepared/`: it runs each Shale
## script a `{{stops PATH}}` include quotes, and draws the diagrams with
## Graphviz. This app reads those results through the platform, and a missing
## one stops the build, named.
app [main!] {
	bb: "../../book_builder/builder/main.roc",
	pf: platform "../../book_builder/platform/main.roc",
	sc: "../../../roc-syntax-color/package/main.roc",
}

import pf.Book
import bb.Builder
import bb.Diagrams
import bb.Fences
import bb.Includes
import bb.Pages
import sc.SyntaxColor

main! : Str => Try(Str, Str)
main! = |_folder| {
	found = Diagrams.found({
		name: manuscript_path,
		text: read_text!(manuscript_path)?,
	}) ? |problems| Str.join_with(problems.map(|problem| "${problem}\n"), "")
	drawn = Diagrams.drawn_diagrams!(
		{
			diagrams: found.diagrams,
			folder: prepared_folder,
			manuscript: manuscript_path,
		},
		read_text!,
	)?
	Builder.build!(
		{ ..settings, fence_hooks: [Diagrams.hook(drawn)] },
		|path|
			if path == manuscript_path {
				Ok(found.manuscript)
			} else {
				Book.read_file!(path)
			},
	)
}

manuscript_path : Str
manuscript_path = "building-books/book.md"

## Where the pre-step leaves what it prepared.
prepared_folder : Str
prepared_folder = "building-books/build/prepared"

## Everything this book chooses, but its fence hook, which needs the drawings.
## Every path is the roc-apps checkout's: the book's read root is the
## checkout itself, since a book about the builder quotes the builder's code
## and the Safari book's files.
settings : Builder.Settings
settings = {
	..Builder.default_settings,
	manuscript: manuscript_path,
	word_limit: 900,
	index_terms: IndexTerms("building-books/index_terms.txt"),
	negatives: Lint({
		words: "building-books/negative_words.txt",
		table: "building-books/negatives.txt",
	}),
	colorer: colored_code,
	is_back_matter: |title| title == "Index",
	look: { ..Pages.default_look, slugs: [{ chapter: "Index", slug: "terms" }] },
	prepared: Prepared({ folder: prepared_folder, kinds: ["stops"] }),
}

## Roc, Shale, JavaScript and Zig colored by roc-syntax-color, and any other
## language left as escaped text.
colored_code : Fences.Colorer
colored_code = |{ language, code }|
	match syntax_of(language) {
		Ok(syntax) => Colored(SyntaxColor.html(syntax, code))
		Err(Uncolored) => Plain
	}

## The colorer of a fence's language, as an include names it.
syntax_of : Str -> Try(SyntaxColor.Language, [Uncolored])
syntax_of = |language| match language {
	"roc" => Ok(SyntaxColor.roc)
	"shale" => Ok(SyntaxColor.shale)
	"javascript" => Ok(SyntaxColor.js)
	"zig" => Ok(SyntaxColor.zig)
	_ => Err(Uncolored)
}

## A file of the book's folder, or the build's stop naming it.
read_text! : Str => Try(Str, Str)
read_text! = |path| Book.read_file!(path).map_err(|problem| "${path} ${Includes.read_problem_text(problem)}\n")

## A sample that each of the four languages reads its own way: `#` opens a
## comment in Roc, `--` in Shale, and `//` in JavaScript and Zig, and `fn` is
## a keyword in Zig alone.
sample : Str
sample = "fn x # a\n-- b\n// c\n"

expect
	[
		("roc", SyntaxColor.roc),
		("shale", SyntaxColor.shale),
		("javascript", SyntaxColor.js),
		("zig", SyntaxColor.zig),
	].all(|(language, syntax)| colored_code({ language, code: sample }) == Colored(SyntaxColor.html(syntax, sample)))
expect {
	answers = [SyntaxColor.roc, SyntaxColor.shale, SyntaxColor.js, SyntaxColor.zig].map(|syntax| SyntaxColor.html(syntax, sample))
	answers.all(|answer| answers.count_if(|other| other == answer) == 1)
}
expect ["text", "markdown", "dot", "js", ""].all(|language| colored_code({ language, code: "a < b" }) == Plain)
expect (settings.is_back_matter)("Index") and !(settings.is_back_matter)("Appendix: index")
