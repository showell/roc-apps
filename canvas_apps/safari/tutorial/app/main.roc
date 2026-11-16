## This app builds the Safari Ride book on the book platform, with the book
## builder, from the tutorial's folder. Its pre-step, build_next.shale, does
## what needs a program: it expands the includes that quote the game's code
## through Roc's parser, runs `roc check` on the failing examples, draws the
## diagrams with Graphviz, and lists the widgets' folders, each into
## `build/prepared/`. This app reads those results through the platform, and a
## missing one stops the build, named.
app [main!] {
	bb: "../../../../book_builder/builder/main.roc",
	md: "../../../../../roc-markdown/package/main.roc",
	pf: platform "../../../../book_builder/platform/main.roc",
	sc: "../../../../syntax_color/package/main.roc",
}

import pf.Book
import bb.Builder
import Diagrams
import QuotedColor
import SafariFences
import SafariLook

main! : Str => Try(Str, Str)
main! = |_folder| {
	folders = folder_lines(read_prepared!(widgets_path)?)
	manuscript = Diagrams.found({ name: manuscript_path, text: read_prepared!(manuscript_path)? }) ? |problems| Str.join_with(problems.map(|problem| "${problem}\n"), "")
	var $drawn = []
	for diagram in manuscript.diagrams {
		source = read_prepared!(Diagrams.dot_path(diagram.id))?
		if source != diagram.source {
			return Err("${Diagrams.dot_path(diagram.id)} is not the source of ${diagram.id} in ${manuscript_path}: run build_next.shale, whose pre-step draws it\n")
		}
		svg = read_prepared!(Diagrams.svg_path(diagram.id))?
		$drawn = $drawn.append({ id: diagram.id, title: diagram.title, svg })
	}
	notes = QuotedColor.notes_of(read_prepared!(blocks_path)?) ? |why| "${why}\n"
	var $sources = []
	for note in notes {
		if !$sources.contains(note.source) {
			$sources = $sources.append(note.source)
		}
	}
	var $colored = []
	for source in $sources {
		text = read_prepared!("build/prepared/${source}")?
		blocks = QuotedColor.colored({ text, notes: notes.keep_if(|note| note.source == source) }) ? |why| "${why}\n"
		$colored = $colored.concat(blocks)
	}
	settings = {
		..base_settings,
		fence_hooks: [SafariFences.widget(folders), SafariFences.dot($drawn)],
		colorer: QuotedColor.colorer($colored),
	}
	Builder.build!(
		settings,
		|path|
			if path == manuscript_path {
				Ok(manuscript.manuscript)
			} else {
				Book.read_file!(path)
			},
	)
}

manuscript_path : Str
manuscript_path = "tutorial.md"

## The widgets' folders, one a line, as the pre-step finds them beside the
## game.
widgets_path : Str
widgets_path = "build/prepared/widgets.txt"

## The pre-step's note of which lines of which file each quoted Roc block
## shows, for its coloring.
blocks_path : Str
blocks_path = "build/prepared/blocks.txt"

## The settings, but for the fence hooks and the colorer, which need what the
## pre-step left.
base_settings : Builder.Settings
base_settings = {
	..Builder.default_settings,
	manuscript: manuscript_path,
	index_terms: IndexTerms("index_terms.txt"),
	look: SafariLook.look,
	prepared: Prepared({ folder: "build/prepared", kinds: ["code", "expect", "fails", "module", "proof", "signatures", "types"] }),
}

## A file of the book's folder, or the build's stop naming it.
read_prepared! : Str => Try(Str, Str)
read_prepared! = |path| match Book.read_file!(path) {
	Ok(text) => Ok(text)
	Err(NotFound) => Err("${path} is not there: run build_next.shale, whose pre-step writes it\n")
	Err(NotAFile) => Err("${path} is not a file\n")
	Err(NotUtf8) => Err("${path} is not UTF-8 text\n")
	Err(OutsideTheBook) => Err("${path} is outside the book's folder\n")
	Err(ReadFailed) => Err("${path} could not be read\n")
}

## The lines of a text, without the empty one after its last newline.
folder_lines : Str -> List(Str)
folder_lines = |text| text.split_on("\n").drop_if(|line| line.is_empty())
