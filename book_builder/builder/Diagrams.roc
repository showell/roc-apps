## This module holds a book's diagrams. A diagram is a ```dot fence with its
## title on the line directly above it, and it is drawn by Graphviz in the
## book's pre-step, which can run programs, into `diagram-N.svg` in the book's
## folder of prepared files, N counting the diagrams from one, beside its
## source as `diagram-N.dot` (book_builder/tools/draw_diagrams.shale draws
## them). The book's app finds the diagrams, reads the drawings, and gives
## them to the hook for ```dot fences.
##
## The manuscript the builder reads has each fence named for its drawing,
## ```dot diagram-N, and its title line blank, since the title goes with the
## drawing as its caption. Blanking the line, rather than removing it, keeps
## every line's number, so the builder's problems name the source's lines.
## Fences are found as the builder finds them: one opens at a line that starts
## with three backticks and closes at the first line after it that is exactly
## three backticks.
##
## The hook's drawing goes into the page as it is, so one holding a comment's
## opening is refused: it could close the page early with a forged page mark.
import BookText
import Fences

Diagrams := [].{

	## One diagram as the manuscript has it: its id, its title, and the
	## fence's body, each line with its newline.
	Diagram : {
		id : Str,
		title : Str,
		source : Str,
	}

	## A diagram with its drawing, ready for the page.
	Drawn : {
		id : Str,
		title : Str,
		svg : Str,
	}

	## The manuscript as the builder reads it, and its diagrams in order, or
	## a problem for each ```dot fence with no title line above it, which is
	## no diagram.
	found : { name : Str, text : Str } -> Try(
		{ manuscript : Str, diagrams : List(Diagrams.Diagram) },
		List(Str),
	)
	found = |{ name, text }| {
		var $out = []
		var $diagrams = []
		var $problems = []
		var $open = NoFence
		var $number = 0.U64
		for line in text.split_on("\n") {
			$number = $number + 1
			match $open {
				NoFence =>
					if line == "```dot" {
						id = "diagram-${($diagrams.len() + 1).to_str()}"
						match $out.last() {
							Ok(title) if !title.trim().is_empty() => {
								$diagrams = $diagrams.append({ id, title, source: "" })
								$open = InDot
							}
							_ => {
								$problems = $problems.append("${name}:${$number.to_str()}: ```dot: a diagram needs a title line directly above it")
								$open = InOther
							}
						}
						$out = $out.drop_last(1).append("").append("```dot ${id}")
					} else {
						if line.starts_with("```") {
							$open = InOther
						}
						$out = $out.append(line)
					}
				InDot => {
					if line == "```" {
						$open = NoFence
					} else {
						last = $diagrams.last() ?? crash "Diagrams.found: an open diagram is in the list"
						$diagrams = $diagrams.drop_last(1).append({
							..last,
							source: "${last.source}${line}\n",
						})
					}
					$out = $out.append(line)
				}
				InOther => {
					if line == "```" {
						$open = NoFence
					}
					$out = $out.append(line)
				}
			}
		}
		if $problems.is_empty() {
			Ok({ manuscript: Str.join_with($out, "\n"), diagrams: $diagrams })
		} else {
			Err($problems)
		}
	}

	## Where the pre-step leaves a diagram's drawing, in the book's folder of
	## prepared files.
	svg_path : { folder : Str, id : Str } -> Str
	svg_path = |{ folder, id }| "${folder}/${id}.svg"

	## Where the pre-step leaves the source it drew a diagram from.
	dot_path : { folder : Str, id : Str } -> Str
	dot_path = |{ folder, id }| "${folder}/${id}.dot"

	## Each diagram with its drawing, read through `read!`, which answers a
	## file's text or the build's stop naming it. A source the pre-step drew
	## that differs from the manuscript's stops the build.
	drawn_diagrams! :
		{
			diagrams : List(Diagrams.Diagram),
			folder : Str,
			manuscript : Str,
		},
		(Str => Try(Str, Str)) => Try(List(Diagrams.Drawn), Str)
	drawn_diagrams! = |{ diagrams, folder, manuscript }, read!| {
		var $drawings = []
		for diagram in diagrams {
			source_path = Diagrams.dot_path({ folder, id: diagram.id })
			source = read!(source_path)?
			if source != diagram.source {
				return Err("${source_path} is not the source of ${diagram.id} in ${manuscript}: run the book's pre-step, which draws it\n")
			}
			svg = read!(Diagrams.svg_path({ folder, id: diagram.id }))?
			$drawings = $drawings.append({ id: diagram.id, title: diagram.title, svg })
		}
		Ok($drawings)
	}

	## The hook for ```dot fences, given the drawings.
	hook : List(Diagrams.Drawn) -> Fences.Hook
	hook = |drawings| { language: "dot", html_of: |{ words, .. }| diagram_html(drawings, words) }
}

## The drawing, or a phone's and a desktop's for a wide diagram, over its title.
diagram_html : List(Diagrams.Drawn), Str -> [Html(Str), Refused(Str)]
diagram_html = |drawings, id| match drawings.find_first(|drawn| drawn.id == id) {
	Ok(
		{ svg, .. },
	) if svg.contains("<!--") => Refused("the drawing for the diagram `${id}` holds an HTML comment")
	Ok({ title, svg, .. }) =>
		match BookText.inline_html(title) {
			Err(why) => Refused(why)
			Ok(caption_html) => {
				named = svg.replace_each(
					"role=\"img\"",
					"role=\"img\" aria-label=\"${BookText.escaped_text(title)}\"",
				)
				Html("<figure class=\"diagram\">${named}<figcaption>${caption_html}</figcaption></figure>")
			}
		}
	Err(NotFound) => Refused("no drawing for the diagram `${id}`")
}

drawings : List(Diagrams.Drawn)
drawings = [
	{
		id: "diagram-1",
		title: "Around `Sky`",
		svg: "<svg role=\"img\">",
	},
	{
		id: "diagram-2",
		title: "A note",
		svg: "<svg><!-- x -->",
	},
]

html_of : Fences.Hook, { words : Str, body : Str } -> [Html(Str), Refused(Str)]
html_of = |hook, fence| (hook.html_of)(fence)

expect
	html_of(Diagrams.hook(drawings), { words: "diagram-1", body: "digraph {}\n" })
		== Html("<figure class=\"diagram\"><svg role=\"img\" aria-label=\"Around `Sky`\"><figcaption>Around <code>Sky</code></figcaption></figure>")
expect html_of(
	Diagrams.hook(drawings),
	{ words: "diagram-2", body: "" },
) == Refused("the drawing for the diagram `diagram-2` holds an HTML comment")
expect html_of(
	Diagrams.hook(drawings),
	{ words: "diagram-3", body: "" },
) == Refused("no drawing for the diagram `diagram-3`")

expect
	Diagrams.found({
		name: "t.md",
		text: "a\n\nAround `Sky`\n```dot\ndigraph {\n}\n```\n```text\n```dot\n```\n\nTwo\n```dot\nx\n```\n",
	})
		== Ok({
			manuscript: "a\n\n\n```dot diagram-1\ndigraph {\n}\n```\n```text\n```dot\n```\n\n\n```dot diagram-2\nx\n```\n",
			diagrams: [
				{
					id: "diagram-1",
					title: "Around `Sky`",
					source: "digraph {\n}\n",
				},
				{
					id: "diagram-2",
					title: "Two",
					source: "x\n",
				},
			],
		})
expect Diagrams.found({ name: "t.md", text: "plain\n" }) == Ok({
	manuscript: "plain\n",
	diagrams: [],
})
expect
	Diagrams.found({ name: "t.md", text: "```dot\n```\n\n\n```dot\n```\n" })
		== Err([
			"t.md:1: ```dot: a diagram needs a title line directly above it",
			"t.md:5: ```dot: a diagram needs a title line directly above it",
		])
expect Diagrams.svg_path({ folder: "build/prepared", id: "diagram-2" }) == "build/prepared/diagram-2.svg"
expect Diagrams.dot_path({ folder: "build/prepared", id: "diagram-2" }) == "build/prepared/diagram-2.dot"
expect
	Diagrams.found({ name: "t.md", text: "```dot\ndigraph {\n```\n" })
		== Err(["t.md:1: ```dot: a diagram needs a title line directly above it"])
