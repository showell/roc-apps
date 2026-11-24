## This app builds the JavaScript book, A JavaScript Interpreter in Roc, on
## the book platform with the book builder. Its folder is the roc-apps
## checkout's root, so an include quotes the interpreter's code in js/ by its
## path in the repository. Its pre-step, book.shale, draws the diagrams with
## Graphviz into `js-book/build/prepared/`, and this app reads the drawings
## through the platform, and a missing one stops the build, named.
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
manuscript_path = "js-book/book.md"

## Where the pre-step leaves the drawings.
prepared_folder : Str
prepared_folder = "js-book/build/prepared"

## Everything this book chooses, but its fence hook, which needs the drawings.
## Every path is the roc-apps checkout's: the book's read root is the
## checkout itself, since the book quotes the interpreter's code in js/.
settings : Builder.Settings
settings = {
	..Builder.default_settings,
	manuscript: manuscript_path,
	negatives: Lint({
		words: "js-book/negative_words.txt",
		table: "js-book/negatives.txt",
	}),
	colorer: colored_code,
}

## Roc, JavaScript and Shale colored by roc-syntax-color, and any other
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
	"javascript" => Ok(SyntaxColor.js)
	"shale" => Ok(SyntaxColor.shale)
	_ => Err(Uncolored)
}

## A file of the book's folder, or the build's stop naming it.
read_text! : Str => Try(Str, Str)
read_text! = |path| Book.read_file!(path).map_err(|problem| "${path} ${Includes.read_problem_text(problem)}\n")

## A sample that each of the three languages reads its own way: `#` opens a
## comment in Roc, `--` in Shale, and `//` in JavaScript.
sample : Str
sample = "x # a\n-- b\n// c\n"

expect
	[
		("roc", SyntaxColor.roc),
		("javascript", SyntaxColor.js),
		("shale", SyntaxColor.shale),
	].all(|(language, syntax)| colored_code({ language, code: sample }) == Colored(SyntaxColor.html(syntax, sample)))
expect {
	answers = [SyntaxColor.roc, SyntaxColor.js, SyntaxColor.shale].map(|syntax| SyntaxColor.html(syntax, sample))
	answers.all(|answer| answers.count_if(|other| other == answer) == 1)
}
expect ["text", "markdown", "dot", "js", ""].all(|language| colored_code({ language, code: "a < b" }) == Plain)
