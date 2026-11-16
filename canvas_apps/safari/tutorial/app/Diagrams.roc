## This module finds the manuscript's diagrams. A diagram is a ```dot fence
## with its title on the line directly above it, and it is drawn by Graphviz
## in the book's pre-step, which can run programs, into
## `build/prepared/diagram-N.svg`, N counting the diagrams from one, beside its
## source as `diagram-N.dot`.
##
## The manuscript the builder reads has each fence named for its drawing,
## ```dot diagram-N, and its title line blank, since the title goes with the
## drawing as its caption. Blanking the line, rather than removing it, keeps
## every line's number, so the builder's problems name the source's lines.
## Fences are found as the builder finds them: one opens at a line that starts
## with three backticks and closes at the first line after it that is exactly
## three backticks.
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
	## a problem for each diagram with no title above it.
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
						title = $out.last() ?? ""
						if title.trim().is_empty() {
							$problems = $problems.append("${name}:${$number.to_str()}: ```dot: a diagram needs a title line directly above it")
						}
						$out = $out.drop_last(1).append("").append("```dot ${id}")
						$diagrams = $diagrams.append({ id, title, source: "" })
						$open = InDot
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

	## Where the pre-step leaves a diagram's drawing.
	svg_path : Str -> Str
	svg_path = |id| "build/prepared/${id}.svg"

	## Where the pre-step leaves the source it drew a diagram from.
	dot_path : Str -> Str
	dot_path = |id| "build/prepared/${id}.dot"
}

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
expect Diagrams.svg_path("diagram-2") == "build/prepared/diagram-2.svg"
expect Diagrams.dot_path("diagram-2") == "build/prepared/diagram-2.dot"
