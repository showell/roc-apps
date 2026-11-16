## This module expands a manuscript's includes, so the book quotes each file as
## it stands when the book is built. An include is a line of prose that is
## exactly one of
##
##     {{file PATH}}                     the whole file;
##     {{lines PATH from "A" to "B"}}    the lines from the one holding A
##                                       through the one holding B, each text
##                                       in the file exactly once;
##     {{function PATH NAME}}            one top-level definition of a Shale or
##                                       a Roc file, with the comment lines
##                                       right above it.
##
## A Shale function runs from its `function NAME(` line through the first line
## that is exactly `end`. A Roc definition starts at the first line that begins
## `NAME :` or `NAME =`, and runs on through every line indented under it, a
## closing bracket at the line's start, and its `NAME =` after a signature;
## a blank line between those stays in it.
##
## Each becomes a fence with the path in its title, its language from the
## path's extension. The path is the book folder's, read through the
## platform's one effect, so this module is pure: `paths_wanted` says which
## files to read, and `expanded_lines` takes what each read answered.
##
## A line of prose that holds any other `{{` (outside code spans, and other
## than a chapter reference or the `{{index}}` line) is an error, so a
## mistyped include can't reach the page. Lines inside a fence are code and
## stay as they are.
##
## A book whose includes need more than a file read (a parser, a compiler, a
## program run) has a pre-step of its own expand them, and names their kinds
## in its settings. The line `{{KIND ...}}`, KIND one of those, becomes what
## the pre-step wrote to `<folder>/line-<N>.md`, N its line: that file's first
## line is the include as written, so a stale file is refused, and the rest is
## what the line becomes, prose or fences. A missing file stops the build.
import BookText
import Manuscript
import References

Includes := [].{

	## Why a file could not be read, as the platform's `Book.read_file!` says.
	ReadProblem : [NotAFile, NotFound, NotUtf8, OutsideTheBook, ReadFailed]

	## A file an include names, and what reading it answered.
	FileRead : { path : Str, text : Try(Str, Includes.ReadProblem) }

	## A fence's language for each file extension; a path whose extension
	## isn't here is quoted as `text`.
	Language : { extension : Str, language : Str }

	## The includes a book's own pre-step expands, by their first word, and
	## the folder it writes them to.
	Prepared : [NoPrepared, Prepared({ folder : Str, kinds : List(Str) })]

	## The files the includes read, each once, in the order the manuscript
	## first names them.
	paths_wanted : List(Manuscript.Line), Includes.Prepared -> List(Str)
	paths_wanted = |lines, prepared| {
		var $paths = []
		for line in lines {
			match line_kind(line, prepared) {
				Include(directive) => {
					path = directive_path(directive)
					if !$paths.contains(path) {
						$paths = $paths.append(path)
					}
				}
				Kept | Unknown => {}
			}
		}
		$paths
	}

	## The manuscript's lines with each include expanded, or every problem
	## found, each naming the manuscript's line and the include as written. A
	## quote's lines are fenced, and each keeps the number of its include's
	## line, so a later problem names the line the writer wrote.
	expanded_lines :
		List(Manuscript.Line),
		{
			manuscript : Str,
			files : List(Includes.FileRead),
			languages : List(Includes.Language),
			prepared : Includes.Prepared,
		} -> Try(List(Manuscript.Line), List(Str))
	expanded_lines = |lines, { manuscript, files, languages, prepared }| {
		var $out = []
		var $problems = []
		for line in lines {
			include_at = "${manuscript}:${line.number.to_str()}: ${line.text}"
			match line_kind(line, prepared) {
				Kept => {
					$out = $out.append(line)
				}
				Unknown => {
					$problems = $problems.append("${include_at}: ${not_an_include}")
				}
				Include(directive) =>
					match quoted_block_lines(directive, { files, languages }) {
						Ok(block) => {
							$out = $out.concat(
								block.map(
									|placed| {
										number: line.number,
										text: placed.text,
										place: placed.place,
									},
								),
							)
						}
						Err(problem) => {
							$problems = $problems.append("${include_at}: ${problem}")
						}
					}
			}
		}
		if $problems.is_empty() {
			Ok($out)
		} else {
			Err($problems)
		}
	}

	## What went wrong with a read, in words for the person running the build.
	read_problem_text : Includes.ReadProblem -> Str
	read_problem_text = |problem|
		match problem {
			NotAFile => "is not a file"
			NotFound => "is not there"
			NotUtf8 => "is not UTF-8 text"
			OutsideTheBook => "is outside the book's folder"
			ReadFailed => "could not be read"
		}

	## The extensions a book's includes know unless it names its own.
	default_languages : List(Includes.Language)
	default_languages = [
		{ extension: "roc", language: "roc" },
		{ extension: "shale", language: "shale" },
		{ extension: "go", language: "go" },
		{ extension: "zig", language: "zig" },
		{ extension: "js", language: "javascript" },
		{ extension: "mjs", language: "javascript" },
		{ extension: "css", language: "css" },
		{ extension: "md", language: "markdown" },
		{ extension: "json", language: "json" },
		{ extension: "txt", language: "text" },
	]
}

not_an_include : Str
not_an_include = "a `{{` the build doesn't know: an include is a line {{file PATH}}, {{lines PATH from \"A\" to \"B\"}} or {{function PATH NAME}}, the index is the line {{index}}, and prose may hold {{chapter Title}} and {{number N Title}}"

## What one include asks for.
Directive : [
	WholeFile(Str),
	Excerpt(
		{
			path : Str,
			from : Str,
			to : Str,
		},
	),
	Definition({ path : Str, name : Str }),
	Ahead({ path : Str, include : Str }),
]

directive_path : Directive -> Str
directive_path = |directive| match directive {
	WholeFile(path) => path
	Excerpt({ path, .. }) => path
	Definition({ path, .. }) => path
	Ahead({ path, .. }) => path
}

## A line as the expansion sees it: kept as it is, an include, or a `{{` that
## is neither.
line_kind : Manuscript.Line, Includes.Prepared -> [Kept, Include(Directive), Unknown]
line_kind = |line, prepared|
	if line.place == Fenced or line.text == "{{index}}" {
		Kept
	} else if !References.without_citations(BookText.without_code_spans(line.text)).contains("{{") {
		Kept
	} else {
		match directive_of(line.text) {
			Ok(directive) => Include(directive)
			Err(NotAnInclude) =>
				match prepared_of(line, prepared) {
					Ok(directive) => Include(directive)
					Err(NotAnInclude) => Unknown
				}
		}
	}

## The include a pre-step expanded, when the whole line is `{{KIND ...}}` and
## the settings name KIND.
prepared_of : Manuscript.Line, Includes.Prepared -> Try(Directive, [NotAnInclude])
prepared_of = |line, prepared| match prepared {
	NoPrepared => Err(NotAnInclude)
	Prepared({ folder, kinds }) => {
		inside = line.text.drop_prefix("{{").drop_suffix("}}")
		kind =
			match inside.split_first(" ") {
				Ok({ before, .. }) => before
				Err(NotFound) => inside
			}
		is_include =
			inside != line.text
				and Str.count_utf8_bytes(inside) + 4 == Str.count_utf8_bytes(line.text)
				and kinds.contains(kind)
		if is_include {
			Ok(Ahead({ path: "${folder}/line-${line.number.to_str()}.md", include: line.text }))
		} else {
			Err(NotAnInclude)
		}
	}
}

## The include a whole line spells.
directive_of : Str -> Try(Directive, [NotAnInclude])
directive_of = |text| {
	inside = text.drop_prefix("{{").drop_suffix("}}")
	if inside == text or Str.count_utf8_bytes(inside) + 4 != Str.count_utf8_bytes(text) {
		Err(NotAnInclude)
	} else {
		match inside.split_first(" ") {
			Ok({ before: "file", after: path }) if is_plain_path(path) => Ok(WholeFile(path))
			Ok({ before: "lines", after }) => excerpt_of(after)
			Ok({ before: "function", after }) => definition_of(after)
			_ => Err(NotAnInclude)
		}
	}
}

## `PATH from "A" to "B"`, each text not empty and holding no `"`.
excerpt_of : Str -> Try(Directive, [NotAnInclude])
excerpt_of = |text| {
	{ before: path, after: anchors } = text.split_first(" from \"") ? |_| NotAnInclude
	{ before: from, after: rest } = anchors.split_first("\" to \"") ? |_| NotAnInclude
	to = rest.drop_suffix("\"")
	if is_plain_path(path) and is_anchor(from) and is_anchor(to) and to != rest {
		Ok(Excerpt({ path, from, to }))
	} else {
		Err(NotAnInclude)
	}
}

## `PATH NAME`, each one word.
definition_of : Str -> Try(Directive, [NotAnInclude])
definition_of = |text| match text.split_on(" ") {
	[path, name] if is_plain_path(path) and is_plain_path(name) => Ok(Definition({ path, name }))
	_ => Err(NotAnInclude)
}

## A path is one word: not empty, and no space or tab in it.
is_plain_path : Str -> Bool
is_plain_path = |path| {
	bytes = path.to_utf8()
	!bytes.is_empty() and bytes.all(|byte| byte != ' ' and byte != '\t')
}

is_anchor : Str -> Bool
is_anchor = |text| !text.is_empty() and !text.contains("\"")

## The lines an include becomes, each placed.
quoted_block_lines : Directive,
{
	files : List(Includes.FileRead),
	languages : List(Includes.Language),
} -> Try(List({ text : Str, place : [Prose, Fenced] }), Str)
quoted_block_lines = |directive, { files, languages }| {
	path = directive_path(directive)
	text =
		match (directive, file_text(files, path)) {
			(Ahead(_), Err(problem)) => Err("${problem}, and the book's pre-step writes it")
			(_, read) => read
		}?
	match directive {
		Ahead({ include, .. }) => expansion_lines_of(text, { path, include })
		WholeFile(_) | Excerpt(_) | Definition(_) => {
			{ quoted, label } = selection(directive, BookText.text_lines(text))?
			if quoted.any(|line| line.trim().starts_with("```")) {
				Err("${path} holds a fence of its own, and a quote can't")
			} else {
				language = language_of(path, languages)
				fenced = ["```${language} ${label}"].concat(quoted).append("```")
				Ok(fenced.map(|line| { text: line, place: Fenced }))
			}
		}
	}
}

## What a pre-step's file says an include becomes, after its first line, which
## must be the include as written.
expansion_lines_of : Str,
{ path : Str, include : Str } -> Try(
	List({ text : Str, place : [Prose, Fenced] }),
	Str,
)
expansion_lines_of = |text, { path, include }| match text.split_first("\n") {
	Ok({ before: first, after: rest }) if first == include =>
		match Manuscript.lines(rest) {
			Ok([]) => Err("${path} expands it to nothing")
			Ok(placed) => Ok(placed.map(|line| { text: line.text, place: line.place }))
			Err(UnclosedFence(at)) => Err("${path}: a fence opens at its line ${(at + 1).to_str()} and never closes")
		}
	Ok(
		{ before: first, .. },
	) => Err("${path} is the expansion of `${first}`, not this line: run the book's pre-step again")
	Err(NotFound) => Err("${path} is the expansion of `${text}`, not this line: run the book's pre-step again")
}

## The lines an include quotes from its file, and the title over them.
selection : Directive, List(Str) -> Try({ quoted : List(Str), label : Str }, Str)
selection = |directive, file_lines| match directive {
	WholeFile(path) => Ok({ quoted: file_lines, label: "${path}, the whole file" })
	Excerpt({ path, from, to }) => {
		first = anchored_line(file_lines, { anchor: from, path })?
		last = anchored_line(file_lines, { anchor: to, path })?
		if last < first {
			Err("in ${path}, `${to}` comes before `${from}`")
		} else {
			Ok({
				quoted: file_lines.sublist({ start: first, len: last - first + 1 }),
				label: "${path}, an excerpt",
			})
		}
	}
	Definition({ path, name }) => {
		span =
			match path.split_last(".") {
				Ok({ after: "shale", .. }) => shale_function_span(file_lines, name)
				Ok({ after: "roc", .. }) => roc_definition_span(file_lines, name)
				_ => Err("a {{function}} include quotes a Shale or a Roc file, and ${path} is neither")
			}?
		Ok({
			quoted: file_lines.sublist({ start: span.first, len: span.last - span.first + 1 }),
			label: "${path}, the function ${name}",
		})
	}
	Ahead(_) => crash "Includes.selection: a prepared include quotes no lines of a file"
}

## The first and last index of a Shale function's lines: the comment lines
## right above `function NAME(`, through the first line that is `end`.
shale_function_span : List(Str), Str -> Try({ first : U64, last : U64 }, Str)
shale_function_span = |file_lines, name| {
	start = file_lines.find_first_index(|line| line.starts_with("function ${name}(")) ? |_| "there is no top-level function ${name}"
	ending = file_lines.drop_first(start).find_first_index(|line| line == "end") ? |_| "the function ${name} has no `end` at the start of a line"
	Ok({ first: start - comments_above(file_lines, { start, opening: "--" }), last: start + ending })
}

## The first and last index of a Roc definition's lines: the comment lines
## right above its first line, through the last line that belongs to it.
roc_definition_span : List(Str), Str -> Try({ first : U64, last : U64 }, Str)
roc_definition_span = |file_lines, name| {
	is_head = |line| line.starts_with("${name} :") or line.starts_with("${name} =")
	start = file_lines.find_first_index(is_head) ? |_| "there is no top-level definition ${name}"
	var $last = start
	var $at = start + 1
	var $going = Bool.True
	while $going and $at < file_lines.len() {
		line = file_lines.get($at) ?? crash "Includes.roc_definition_span: the index is below the length"
		if line.trim().is_empty() {
			$at = $at + 1
		} else if is_roc_continuation(line, name) {
			$last = $at
			$at = $at + 1
		} else {
			$going = Bool.False
		}
	}
	Ok({ first: start - comments_above(file_lines, { start, opening: "#" }), last: $last })
}

## Whether a line goes on a Roc definition above it: indented under it, a
## closing bracket at the line's start, or the definition after its signature.
is_roc_continuation : Str, Str -> Bool
is_roc_continuation = |line, name|
	line.starts_with("\t")
		or line.starts_with(" ")
		or line.starts_with("}")
		or line.starts_with("]")
		or line.starts_with(")")
		or line.starts_with("${name} =")

## How many lines right above `start` open with the comment's mark.
comments_above : List(Str), { start : U64, opening : Str } -> U64
comments_above = |file_lines, { start, opening }| {
	var $count = 0
	var $going = Bool.True
	while $going and $count < start {
		line = file_lines.get(start - $count - 1) ?? crash "Includes.comments_above: the index is below the start"
		if line.starts_with(opening) {
			$count = $count + 1
		} else {
			$going = Bool.False
		}
	}
	$count
}

## The text read for `path`, or why there is none.
file_text : List(Includes.FileRead), Str -> Try(Str, Str)
file_text = |files, path| match files.find_first(|file| file.path == path) {
	Ok({ text: Ok(text), .. }) => Ok(text)
	Ok({ text: Err(problem), .. }) => Err("${path} ${Includes.read_problem_text(problem)}")
	Err(NotFound) => crash "Includes.expanded_lines: no read for ${path}, which paths_wanted names"
}

## The index of the one line holding `anchor`. It must be there exactly once,
## so an edit that removes or repeats it stops the build.
anchored_line : List(Str), { anchor : Str, path : Str } -> Try(U64, Str)
anchored_line = |file_lines, { anchor, path }| {
	var $holding = []
	var $at = 0
	for line in file_lines {
		if line.contains(anchor) {
			$holding = $holding.append($at)
		}
		$at = $at + 1
	}
	holding = $holding
	match holding {
		[at] => Ok(at)
		_ => Err("`${anchor}` is in ${path} ${holding.len().to_str()} times, and an anchor must be there once")
	}
}

## A fence's language, from the path's extension.
language_of : Str, List(Includes.Language) -> Str
language_of = |path, languages| {
	extension = match path.split_last(".") {
		Ok({ after, .. }) if !after.contains("/") => after
		_ => ""
	}
	match languages.find_first(|known| known.extension == extension) {
		Ok(known) => known.language
		Err(NotFound) => "text"
	}
}

lines_of : Str -> List(Manuscript.Line)
lines_of = |text| match Manuscript.lines(text) {
	Ok(lines) => lines
	Err(_) => crash "the test text's fences close"
}

sample_files : List(Includes.FileRead)
sample_files = [
	{ path: "code/a.roc", text: Ok("first\nstart here\nmiddle\nend here\nlast\n") },
	{ path: "code/twice.txt", text: Ok("x\nx\n") },
	{ path: "code/fenced.md", text: Ok("a\n  ```roc\nb\n") },
	{ path: "notes", text: Ok("plain") },
	{ path: "tools/a.shale", text: Ok("x = 1\n-- Says hello.\n-- Twice.\nfunction greet(x)\n  return x\nend\nfunction greeting()\nend\nfunction open()\n") },
	{ path: "lib/A.roc", text: Ok("x = 1\n\n## Adds one.\n# Kept.\nadd_one : U64 -> U64\nadd_one = |n| {\n\tm = n\n\n\tm + 1\n}\n\nexpect add_one(1) == 2\ndouble = |n| n * 2\nnext = 3\n") },
	{ path: "gone.txt", text: Err(NotFound) },
	{ path: "up.txt", text: Err(OutsideTheBook) },
]

## Lines as the text they came from.
text_of : List(Manuscript.Line) -> Str
text_of = |lines| Str.join_with(lines.map(|line| "${line.text}\n"), "")

expand_sample : Str -> Try(Str, List(Str))
expand_sample = |text| Includes.expanded_lines(
	lines_of(text),
	{
		manuscript: "book.md",
		files: sample_files,
		languages: Includes.default_languages,
		prepared: NoPrepared,
	},
).map_ok(text_of)

expect
	Includes.expanded_lines(
		lines_of("A\n{{file notes}}\n"),
		{
			manuscript: "book.md",
			files: sample_files,
			languages: [],
			prepared: NoPrepared,
		},
	)
		== Ok([
			{
				number: 1,
				text: "A",
				place: Prose,
			},
			{
				number: 2,
				text: "```text notes, the whole file",
				place: Fenced,
			},
			{
				number: 2,
				text: "plain",
				place: Fenced,
			},
			{
				number: 2,
				text: "```",
				place: Fenced,
			},
		])

expect
	expand_sample("A\n{{file code/a.roc}}\nB\n")
		== Ok("A\n```roc code/a.roc, the whole file\nfirst\nstart here\nmiddle\nend here\nlast\n```\nB\n")
expect
	expand_sample("{{lines code/a.roc from \"start\" to \"end h\"}}\n")
		== Ok("```roc code/a.roc, an excerpt\nstart here\nmiddle\nend here\n```\n")
expect
	expand_sample("{{lines code/a.roc from \"middle\" to \"middle\"}}\n")
		== Ok("```roc code/a.roc, an excerpt\nmiddle\n```\n")
expect expand_sample("{{file notes}}\n") == Ok("```text notes, the whole file\nplain\n```\n")
expect
	expand_sample("{{lines code/a.roc from \"end\" to \"start\"}}\n")
		== Err(["book.md:1: {{lines code/a.roc from \"end\" to \"start\"}}: in code/a.roc, `start` comes before `end`"])
expect
	expand_sample("{{lines code/twice.txt from \"x\" to \"x\"}}\n{{lines code/a.roc from \"gone\" to \"last\"}}\n")
		== Err([
			"book.md:1: {{lines code/twice.txt from \"x\" to \"x\"}}: `x` is in code/twice.txt 2 times, and an anchor must be there once",
			"book.md:2: {{lines code/a.roc from \"gone\" to \"last\"}}: `gone` is in code/a.roc 0 times, and an anchor must be there once",
		])
expect
	expand_sample("{{file gone.txt}}\n{{file up.txt}}\n{{file code/fenced.md}}\n")
		== Err([
			"book.md:1: {{file gone.txt}}: gone.txt is not there",
			"book.md:2: {{file up.txt}}: up.txt is outside the book's folder",
			"book.md:3: {{file code/fenced.md}}: code/fenced.md holds a fence of its own, and a quote can't",
		])
expect expand_sample("See `{{file x}}`, {{chapter One}} and {{number 2 Two}}.\n{{index}}\n```\n{{file x}}\n```\n") == Ok("See `{{file x}}`, {{chapter One}} and {{number 2 Two}}.\n{{index}}\n```\n{{file x}}\n```\n")
expect
	[
		"{{fil x}}",
		" {{file x}}",
		"{{file x}} ",
		"{{file a b}}",
		"{{file }}",
		"{{lines x from \"a\"}}",
		"{{lines x from \"\" to \"b\"}}",
		"{{lines x from \"a\" to \"b\" }}",
		"{{index}} too",
		"a {{ b",
		"{{function x}}",
		"{{function a b c}}",
	]
		.all(|line| expand_sample("${line}\n") == Err(["book.md:1: ${line}: ${not_an_include}"]))
expect
	Includes.paths_wanted(
		lines_of("{{file b}}\n{{lines a from \"x\" to \"y\"}}\n{{file b}}\n```\n{{file c}}\n```\n{{file d e}}\n"),
		NoPrepared,
	)
		== ["b", "a"]
expect
	[
		("a.roc", "roc"),
		("dir.v2/README", "text"),
		("x.mjs", "javascript"),
		("x.unknown", "text"),
		("x", "text"),
	]
		.all(|(path, language)| language_of(path, Includes.default_languages) == language)
expect
	[
		(NotAFile, "is not a file"),
		(NotFound, "is not there"),
		(NotUtf8, "is not UTF-8 text"),
		(OutsideTheBook, "is outside the book's folder"),
		(ReadFailed, "could not be read"),
	].all(|(problem, text)| Includes.read_problem_text(problem) == text)

prepared : Includes.Prepared
prepared = Prepared({ folder: "pre", kinds: ["code", "row"] })

prepared_files : List(Includes.FileRead)
prepared_files = [
	{ path: "pre/line-2.md", text: Ok("{{code A.b}}\n```roc A.roc\nb = 1\n```\n") },
	{ path: "pre/line-3.md", text: Ok("{{row x}}\n| a | b |\n") },
	{ path: "pre/line-4.md", text: Ok("{{code C.d}}\n```roc C.roc\nd = 1\n```\n") },
	{ path: "pre/line-5.md", text: Ok("{{code A.e}}\n") },
	{ path: "pre/line-6.md", text: Ok("{{code A.f}}\n```roc\nf\n") },
	{ path: "pre/line-7.md", text: Err(NotFound) },
]

expand_prepared : Str -> Try(List(Manuscript.Line), List(Str))
expand_prepared = |text| Includes.expanded_lines(
	lines_of(text),
	{
		manuscript: "book.md",
		files: prepared_files,
		languages: [],
		prepared,
	},
)

expect
	expand_prepared("A\n{{code A.b}}\n{{row x}}\n")
		== Ok([
			{
				number: 1,
				text: "A",
				place: Prose,
			},
			{
				number: 2,
				text: "```roc A.roc",
				place: Fenced,
			},
			{
				number: 2,
				text: "b = 1",
				place: Fenced,
			},
			{
				number: 2,
				text: "```",
				place: Fenced,
			},
			{
				number: 3,
				text: "| a | b |",
				place: Prose,
			},
		])
expect
	expand_prepared("A\nB\nC\n{{code A.x}}\n{{code A.e}}\n{{code A.f}}\n{{code A.g}}\n")
		== Err([
			"book.md:4: {{code A.x}}: pre/line-4.md is the expansion of `{{code C.d}}`, not this line: run the book's pre-step again",
			"book.md:5: {{code A.e}}: pre/line-5.md expands it to nothing",
			"book.md:6: {{code A.f}}: pre/line-6.md: a fence opens at its line 2 and never closes",
			"book.md:7: {{code A.g}}: pre/line-7.md is not there, and the book's pre-step writes it",
		])
expect
	["{{other A.b}}", "x {{code A.b}}", "{{code A.b}} "].all(
		|line| Includes.expanded_lines(
			lines_of("${line}\n"),
			{ manuscript: "book.md", files: [], languages: [], prepared },
		) == Err(["book.md:1: ${line}: ${not_an_include}"]),
	)
expect Includes.expanded_lines(
	lines_of("{{code A.b}}\n"),
	{
		manuscript: "book.md",
		files: [],
		languages: [],
		prepared: NoPrepared,
	},
) == Err(["book.md:1: {{code A.b}}: ${not_an_include}"])
expect Includes.paths_wanted(
	lines_of("{{code A.b}}\n{{file x}}\n```\n{{row y}}\n```\n{{row z}}\n"),
	prepared,
) == ["pre/line-1.md", "x", "pre/line-6.md"]
expect
	expand_sample("{{function tools/a.shale greet}}\n")
		== Ok("```shale tools/a.shale, the function greet\n-- Says hello.\n-- Twice.\nfunction greet(x)\n  return x\nend\n```\n")
expect
	expand_sample("{{function lib/A.roc add_one}}\n")
		== Ok("```roc lib/A.roc, the function add_one\n## Adds one.\n# Kept.\nadd_one : U64 -> U64\nadd_one = |n| {\n\tm = n\n\n\tm + 1\n}\n```\n")
expect
	expand_sample("{{function lib/A.roc double}}\n{{function tools/a.shale greeting}}\n")
		== Ok("```roc lib/A.roc, the function double\ndouble = |n| n * 2\n```\n```shale tools/a.shale, the function greeting\nfunction greeting()\nend\n```\n")
expect
	expand_sample("{{function tools/a.shale gone}}\n{{function tools/a.shale open}}\n{{function lib/A.roc gone}}\n{{function notes x}}\n{{function gone.txt x}}\n")
		== Err([
			"book.md:1: {{function tools/a.shale gone}}: there is no top-level function gone",
			"book.md:2: {{function tools/a.shale open}}: the function open has no `end` at the start of a line",
			"book.md:3: {{function lib/A.roc gone}}: there is no top-level definition gone",
			"book.md:4: {{function notes x}}: a {{function}} include quotes a Shale or a Roc file, and notes is neither",
			"book.md:5: {{function gone.txt x}}: gone.txt is not there",
		])
