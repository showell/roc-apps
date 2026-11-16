## This module expands a manuscript's includes, so the book quotes each file as
## it stands when the book is built. An include is a line of prose that is
## exactly one of
##
##     {{file PATH}}                     the whole file;
##     {{lines PATH from "A" to "B"}}    the lines from the one holding A
##                                       through the one holding B, each text
##                                       in the file exactly once.
##
## Each becomes a fence with the path in its title, its language from the
## path's extension. The path is the book folder's, read through the
## platform's one effect, so this module is pure: `paths_wanted` says which
## files to read, and `expanded` takes what each read answered.
##
## A line of prose that holds any other `{{` (outside code spans, and other
## than a chapter reference or the `{{index}}` line) is an error, so a
## mistyped include can't reach the page. Lines inside a fence are code and
## stay as they are.
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

	## The files the includes read, each once, in the order the manuscript
	## first names them.
	paths_wanted : List(Manuscript.Line) -> List(Str)
	paths_wanted = |lines| {
		var $paths = []
		for line in lines {
			match line_kind(line) {
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
	expanded :
		List(Manuscript.Line),
		{
			manuscript : Str,
			files : List(Includes.FileRead),
			languages : List(Includes.Language),
		} -> Try(List(Manuscript.Line), List(Str))
	expanded = |lines, { manuscript, files, languages }| {
		var $out = []
		var $problems = []
		for line in lines {
			include_at = "${manuscript}:${line.number.to_str()}: ${line.text}"
			match line_kind(line) {
				Kept => {
					$out = $out.append(line)
				}
				Unknown => {
					$problems = $problems.append("${include_at}: ${not_an_include}")
				}
				Include(directive) =>
					match quoted_block(directive, { files, languages }) {
						Ok(block) => {
							$out = $out.concat(block.split_on("\n").map(|text| { number: line.number, text, place: Fenced }))
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
not_an_include = "a `{{` the build doesn't know: an include is a line {{file PATH}} or {{lines PATH from \"A\" to \"B\"}}, the index is the line {{index}}, and prose may hold {{chapter Title}} and {{number N Title}}"

## What one include asks for.
Directive : [WholeFile(Str), Excerpt({ path : Str, from : Str, to : Str })]

directive_path : Directive -> Str
directive_path = |directive| match directive {
	WholeFile(path) => path
	Excerpt({ path, .. }) => path
}

## A line as the expansion sees it: kept as it is, an include, or a `{{` that
## is neither.
line_kind : Manuscript.Line -> [Kept, Include(Directive), Unknown]
line_kind = |line|
	if line.place == Fenced or line.text == "{{index}}" {
		Kept
	} else if !References.without_citations(BookText.without_code_spans(line.text)).contains("{{") {
		Kept
	} else {
		match directive_of(line.text) {
			Ok(directive) => Include(directive)
			Err(NotAnInclude) => Unknown
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

## A path is one word: not empty, and no space or tab in it.
is_plain_path : Str -> Bool
is_plain_path = |path| {
	bytes = path.to_utf8()
	!bytes.is_empty() and bytes.all(|byte| byte != ' ' and byte != '\t')
}

is_anchor : Str -> Bool
is_anchor = |text| !text.is_empty() and !text.contains("\"")

## The fence an include becomes.
quoted_block : Directive, { files : List(Includes.FileRead), languages : List(Includes.Language) } -> Try(Str, Str)
quoted_block = |directive, { files, languages }| {
	path = directive_path(directive)
	text = file_text(files, path)?
	{ quoted, label } = selection(directive, BookText.text_lines(text))?
	if quoted.any(|line| line.trim().starts_with("```")) {
		Err("${path} holds a fence of its own, and a quote can't")
	} else {
		language = language_of(path, languages)
		Ok("```${language} ${label}\n${Str.join_with(quoted, "\n")}\n```")
	}
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
			Ok({ quoted: file_lines.sublist({ start: first, len: last - first + 1 }), label: "${path}, an excerpt" })
		}
	}
}

## The text read for `path`, or why there is none.
file_text : List(Includes.FileRead), Str -> Try(Str, Str)
file_text = |files, path| match files.find_first(|file| file.path == path) {
	Ok({ text: Ok(text), .. }) => Ok(text)
	Ok({ text: Err(problem), .. }) => Err("${path} ${Includes.read_problem_text(problem)}")
	Err(NotFound) => crash "Includes.expanded: no read for ${path}, which paths_wanted names"
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
	{ path: "gone.txt", text: Err(NotFound) },
	{ path: "up.txt", text: Err(OutsideTheBook) },
]

## Lines as the text they came from.
text_of : List(Manuscript.Line) -> Str
text_of = |lines| Str.join_with(lines.map(|line| "${line.text}\n"), "")

expand_sample : Str -> Try(Str, List(Str))
expand_sample = |text| Includes.expanded(
	lines_of(text),
	{ manuscript: "book.md", files: sample_files, languages: Includes.default_languages },
).map_ok(text_of)

expect
	Includes.expanded(lines_of("A\n{{file notes}}\n"), { manuscript: "book.md", files: sample_files, languages: [] })
		== Ok([
			{ number: 1, text: "A", place: Prose },
			{ number: 2, text: "```text notes, the whole file", place: Fenced },
			{ number: 2, text: "plain", place: Fenced },
			{ number: 2, text: "```", place: Fenced },
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
	["{{fil x}}", " {{file x}}", "{{file x}} ", "{{file a b}}", "{{file }}", "{{lines x from \"a\"}}", "{{lines x from \"\" to \"b\"}}", "{{lines x from \"a\" to \"b\" }}", "{{index}} too", "a {{ b"]
		.all(|line| expand_sample("${line}\n") == Err(["book.md:1: ${line}: ${not_an_include}"]))
expect
	Includes.paths_wanted(lines_of("{{file b}}\n{{lines a from \"x\" to \"y\"}}\n{{file b}}\n```\n{{file c}}\n```\n{{file d e}}\n"))
		== ["b", "a"]
expect
	[("a.roc", "roc"), ("dir.v2/README", "text"), ("x.mjs", "javascript"), ("x.unknown", "text"), ("x", "text")]
		.all(|(path, language)| language_of(path, Includes.default_languages) == language)
expect
	[
		(NotAFile, "is not a file"),
		(NotFound, "is not there"),
		(NotUtf8, "is not UTF-8 text"),
		(OutsideTheBook, "is outside the book's folder"),
		(ReadFailed, "could not be read"),
	].all(|(problem, text)| Includes.read_problem_text(problem) == text)
