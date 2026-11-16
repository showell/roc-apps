## This module colors the Roc code the book quotes from the game's files. A
## block is often part of a definition, which a lexer can't read alone, so a
## block is colored as it reads in its file: the file is colored whole, once,
## and each of the block's lines takes its range of the file's coloring. The
## pre-step's note, `build/prepared/blocks.txt`, says which lines of which
## file each block shows, a block a line: the include's line, the file's copy,
## and the parts, each `FROM,TO,INDENT,END_COL` (lines FROM to TO, each less
## its first INDENT bytes, the last ending before byte END_COL) or `cutN`, a
## cut shown after N tabs, which reads as a comment.
##
## The colorer gives a quoted block its coloring by its text, and colors a
## Roc block written in the manuscript itself alone. Other languages stay
## plain, as the book has them.
import bb.Fences
import sc.Span
import sc.SyntaxColor

QuotedColor := [].{

	## One block of the note: its include's line, its file's copy, its parts.
	Note : {
		line : U64,
		source : Str,
		parts : List(QuotedColor.Part),
	}

	Part : [
		Lines(
			{
				from : U64,
				to : U64,
				indent : U64,
				end_col : U64,
			},
		),
		Cut(U64),
	]

	## A block's text, and its text colored.
	Colored : { code : Str, html : Str }

	## The note's blocks, or what is wrong with a line of it.
	notes_of : Str -> Try(List(QuotedColor.Note), Str)
	notes_of = |text| text.split_on("\n").drop_if(|row| row.is_empty()).map_try(note_of)

	## Each block of one file, colored by the file's coloring.
	colored_blocks : {
		text : Str,
		notes : List(QuotedColor.Note),
	} -> Try(List(QuotedColor.Colored), Str)
	colored_blocks = |{ text, notes }| {
		spans = SyntaxColor.spans(SyntaxColor.roc, text)
		bytes = text.to_utf8()
		starts = line_starts(bytes)
		notes.map_try(|note| note_colored(note, { text, bytes, spans, starts }))
	}

	## The book's colorer, given the quoted blocks.
	colorer : List(QuotedColor.Colored) -> Fences.Colorer
	colorer = |blocks| |{ language, code }|
		if language != "roc" {
			Plain
		} else {
			match blocks.find_first(|block| "${block.code}\n" == code) {
				Ok(block) => Colored("${block.html}\n")
				Err(NotFound) => Colored(SyntaxColor.html(SyntaxColor.roc, code))
			}
		}
}

cut_text : Str
cut_text = "# ..."

note_of : Str -> Try(QuotedColor.Note, Str)
note_of = |row| match row.split_on("\t") {
	[line_text, source, .. as part_texts] => {
		line = U64.from_str(line_text) ? |_| "blocks.txt: a row whose line isn't a number: ${row}"
		parts = part_texts.map_try(|part| part_of(part).map_err(|_| "blocks.txt: a part that isn't FROM,TO,INDENT,END_COL or cutN: ${part}"))?
		Ok({ line, source, parts })
	}
	_ => Err("blocks.txt: a row with no file: ${row}")
}

part_of : Str -> Try(QuotedColor.Part, [NotAPart])
part_of = |text|
	if text.starts_with("cut") {
		tabs = U64.from_str(text.drop_prefix("cut")) ? |_| NotAPart
		Ok(Cut(tabs))
	} else {
		match text.split_on(",").map_try(U64.from_str) {
			Ok([from, to, indent, end_col]) => Ok(Lines({ from, to, indent, end_col }))
			_ => Err(NotAPart)
		}
	}

## Where each line of the bytes starts, the first line's at 0, and one past the
## end, as if a line followed the last.
line_starts : List(U8) -> List(U64)
line_starts = |bytes| {
	var $starts = [0]
	var $at = 0
	for byte in bytes {
		$at = $at + 1
		if byte == '\n' {
			$starts = $starts.append($at)
		}
	}
	$starts.append(bytes.len() + 1)
}

File : {
	text : Str,
	bytes : List(U8),
	spans : List(Span),
	starts : List(U64),
}

note_colored : QuotedColor.Note, File -> Try(QuotedColor.Colored, Str)
note_colored = |note, file| {
	pieces = note.parts.map_try(
		|part| part_colored(part, file),
	) ? |why| "blocks.txt: the block at line ${note.line.to_str()}, from ${note.source}: ${why}"
	Ok({
		code: Str.join_with(pieces.map(|piece| piece.code), "\n"),
		html: Str.join_with(pieces.map(|piece| piece.html), "\n"),
	})
}

part_colored : QuotedColor.Part, File -> Try(QuotedColor.Colored, Str)
part_colored = |part, file| match part {
	Cut(tabs) => {
		indent = Str.repeat("\t", tabs)
		Ok({
			code: "${indent}${cut_text}",
			html: "${indent}<span class=\"syn-comment\">${cut_text}</span>",
		})
	}
	Lines({ from, to, indent, end_col }) => {
		if from < 1 or to < from or to + 1 >= file.starts.len() {
			Err("lines ${from.to_str()} to ${to.to_str()}, which the file doesn't have")
		} else {
			var $codes = []
			var $htmls = []
			var $number = from
			while $number <= to {
				number = $number
				line_start = file.starts.get(number - 1) ?? crash "QuotedColor: a line inside the file has its start"
				line_end = (file.starts.get(number) ?? crash "QuotedColor: a line inside the file has its end") - 1
				start = (line_start + indent).min(line_end)
				end = if number == to {
					(line_start + end_col - 1).min(line_end)
				} else {
					line_end
				}
				code = Str.from_utf8(
					file.bytes.sublist({ start, len: end - start.min(end) }),
				) ? |_| "a line cut inside a character"
				$codes = $codes.append(code)
				$htmls = $htmls.append(
					SyntaxColor.range_html(file.text, { spans: file.spans, start, end }),
				)
				$number = $number + 1
			}
			Ok({ code: Str.join_with($codes, "\n"), html: Str.join_with($htmls, "\n") })
		}
	}
}

expect QuotedColor.notes_of("3\tsources/1.roc\t19,19,1,12\n4\tsources/2.roc\tcut2\t1,2,0,5\n") == Ok([
	{
		line: 3,
		source: "sources/1.roc",
		parts: [
			Lines({
				from: 19,
				to: 19,
				indent: 1,
				end_col: 12,
			}),
		],
	},
	{
		line: 4,
		source: "sources/2.roc",
		parts: [
			Cut(2),
			Lines({
				from: 1,
				to: 2,
				indent: 0,
				end_col: 5,
			}),
		],
	},
])
expect QuotedColor.notes_of("x\ty\n") == Err("blocks.txt: a row whose line isn't a number: x\ty")
expect QuotedColor.notes_of("1\ty\t1,2\n") == Err("blocks.txt: a part that isn't FROM,TO,INDENT,END_COL or cutN: 1,2")
expect QuotedColor.notes_of("1\n") == Err("blocks.txt: a row with no file: 1")
expect line_starts("ab\nc".to_utf8()) == [0, 3, 5]

zoo : Str
zoo = "Zoo :: [].{\n\tfeed = |cage| {\n\t\tamount = \"a\"\n\t\tamount\n\t}\n}\n"

expect
	QuotedColor.colored_blocks({
		text: zoo,
		notes: [
			{
				line: 1,
				source: "z",
				parts: [
					Cut(0),
					Lines({
						from: 3,
						to: 4,
						indent: 2,
						end_col: 9,
					}),
					Cut(1),
				],
			},
		],
	})
		== Ok([
			{
				code: "# ...\namount = \"a\"\namount\n\t# ...",
				html: "<span class=\"syn-comment\"># ...</span>\namount = <span class=\"syn-string\">&quot;a&quot;</span>\namount\n\t<span class=\"syn-comment\"># ...</span>",
			},
		])
expect
	QuotedColor.colored_blocks({
		text: zoo,
		notes: [
			{
				line: 7,
				source: "z",
				parts: [
					Lines({
						from: 6,
						to: 7,
						indent: 0,
						end_col: 1,
					}),
				],
			},
		],
	})
		== Err("blocks.txt: the block at line 7, from z: lines 6 to 7, which the file doesn't have")

expect (QuotedColor.colorer([{ code: "x", html: "<b>x</b>" }]))({
	language: "roc",
	code: "x\n",
}) == Colored("<b>x</b>\n")
expect (QuotedColor.colorer([]))({
	language: "roc",
	code: "\"a\"\n",
}) == Colored("<span class=\"syn-string\">&quot;a&quot;</span>\n")
expect (QuotedColor.colorer([]))({ language: "text", code: "x\n" }) == Plain
