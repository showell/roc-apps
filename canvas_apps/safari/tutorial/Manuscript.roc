## A manuscript is everything book.shale hands this program. The program runs
## on Roc's echo platform, which gives it its arguments and a way to print and
## nothing else, so the script reads the files and passes their text.
Manuscript := [].{

	## One diagram, already drawn. Its id is the argument on its ```dot fence, and
	## its title is a line of Markdown.
	Diagram : {
		id : Str,
		title : Str,
		svg : Str,
	}

	Contents : {
		pages : List(Str),
		diagrams : List(Diagram),
		widget_folders : List(Str),
	}

	## The arguments are a run of `page TEXT`, `diagram ID TITLE SVG` and
	## `widget FOLDER`, in any order, though pages keep theirs.
	read : List(Str) -> Contents
	read = |args| contents_of(args, { pages: [], diagrams: [], widget_folders: [] })
}

contents_of : List(Str), Manuscript.Contents -> Manuscript.Contents
contents_of = |args, so_far| match args {
	[] => so_far
	["page", text, .. as rest] => contents_of(rest, { ..so_far, pages: so_far.pages.append(text) })
	[
		"diagram",
		id,
		title,
		svg,
		.. as rest,
	] => {
		contents_of(rest, { ..so_far, diagrams: so_far.diagrams.append({ id, title, svg }) })
	}
	["widget", folder, .. as rest] => {
		contents_of(rest, { ..so_far, widget_folders: so_far.widget_folders.append(folder) })
	}
	[stray, ..] => crash "book: an argument that isn't a page, a diagram or a widget: ${stray}"
}

expect Manuscript.read([]) == { pages: [], diagrams: [], widget_folders: [] }
expect Manuscript.read([
	"page",
	"a",
	"diagram",
	"d1",
	"A title",
	"<svg>",
	"page",
	"b",
	"widget",
	"sky_widget",
]) == {
	pages: ["a", "b"],
	diagrams: [
		{
			id: "d1",
			title: "A title",
			svg: "<svg>",
		},
	],
	widget_folders: ["sky_widget"],
}
