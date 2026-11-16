## RocSyntax splits Roc source into spans as the Safari book colors it:
## comments, strings and characters, numbers, keywords, type names and tags, and
## the names a definition gives. It reads the text a byte at a time, keeping
## only what a lexer can: which brackets are open, and the token before.
##
## The brackets say where a name is defined. At the top of a file, and in a
## type's `.{ ... }` block, a line that starts `name =` or `name :` defines
## `name`. Inside a function's body only `name :`, an annotation, does: the
## body's other names are locals. A `{` opens a body when it follows a value,
## `=`, `=>`, a lambda's closing `|` or a keyword, and a record anywhere else.
##
## A type name and the names after it that start with a capital, `Route.Index`,
## are one span, a wrapped value's type in a pattern among them,
## `|Route.Index.(n)|`.
##
## A file's header is its first token, when that is a header's word (`app`,
## `hosted`, `module`, `package` or `platform`), up to the next line that
## starts at its first column. In it, those words and a platform header's
## sections (`requires`, `exposes`, `packages`, `provides`, `hosted`,
## `targets`) are keywords, as Roc's tokenizer has them. `platform` before a
## string is one anywhere.
##
## No text makes it fail. A string still open at a newline or at the end stops
## there, and a byte no token starts with is plain.
import Bytes
import Span

RocSyntax :: [].{

	## The spans of `text`, covering every byte once, in order.
	spans : Str -> List(Span)
	spans = |text| {
		bytes = text.to_utf8()
		var $state = {
			at: 0,
			out: [],
			frames: [],
			before: Start,
			place: LineStart,
			header: NoCodeYet,
			mode: Code,
		}
		while $state.at < bytes.len() {
			$state =
				match $state.mode {
					Code => code_step(bytes, $state)
					InString(kind) => string_step(bytes, { state: $state, kind })
				}
		}
		$state.out
	}
}

## How the lexer stands between two tokens.
State : {
	at : U64,
	out : List(Span),
	frames : List(Frame),
	before : Before,
	place : [LineStart, MidLine],
	header : Header,
	mode : [Code, InString(StringKind)],
}

## Where the lexer stands in a file's header: before any token, inside a
## header, or past it (or in a file with none).
Header : [NoCodeYet, InHeader, CodeSeen]

## An open bracket: what it opened.
Frame : [
	Paren,
	Square,
	Record,
	Body,
	TypeBlock,
	LambdaArgs,
	Interpolation(StringKind),
]

StringKind : [Quoted, Multiline]

## What the token before was, as far as the next one cares.
Before : [
	Start,
	Value,
	Dot,
	Colon,
	Arrow,
	Equals,
	FatArrow,
	BarOpen,
	BarClose,
	Opener,
	Operator,
	Keyword,
]

keywords : List(Str)
keywords = [
	"and",
	"as",
	"break",
	"crash",
	"dbg",
	"else",
	"expect",
	"exposing",
	"for",
	"if",
	"import",
	"in",
	"match",
	"or",
	"return",
	"var",
	"where",
	"while",
]

## The words a file's header starts with.
header_starts : List(Str)
header_starts = ["app", "hosted", "module", "package", "platform"]

## The words that start a platform header's sections.
header_sections : List(Str)
header_sections = ["exposes", "hosted", "packages", "provides", "requires", "targets"]

## The state with the bytes from `at` up to `end` added as one run of `class`.
emit : State, { class : Span.Class, end : U64 } -> State
emit = |state, { class, end }| {
	..state,
	out: Span.push_run(state.out, { class, start: state.at, end }),
	at: end,
}

## The state after the token of code at `at`.
code_step : List(U8), State -> State
code_step = |bytes, state| {
	at = state.at
	byte = Bytes.byte_at(bytes, at)
	next = Bytes.byte_at(bytes, at + 1)
	if byte == '\n' {
		{
			..emit(state, { class: Plain, end: at + 1 }),
			place: LineStart,
			frames: without_interpolations(state.frames),
		}
	} else if byte == ' ' or byte == '\t' or byte == '\r' {
		emit(state, { class: Plain, end: at + 1 })
	} else if byte == '#' {
		{ ..emit(state, { class: Comment, end: Bytes.line_end(bytes, at) }), place: MidLine }
	} else {
		header = header_at(bytes, { at, header: state.header })
		state_header =
			if header == InHeader {
				InHeader
			} else {
				CodeSeen
			}
		token_step(
			bytes,
			{
				state: { ..state, header: state_header, place: MidLine },
				byte,
				next,
				place: state.place,
				header,
			},
		)
	}
}

## Where the token at `at` stands in the file's header: a line that starts at
## its first column ends a header.
header_at : List(U8), { at : U64, header : Header } -> Header
header_at = |bytes, { at, header }|
	if header == InHeader and (at == 0 or Bytes.byte_at(bytes, at - 1) == '\n') {
		CodeSeen
	} else {
		header
	}

## The state after a token that isn't space or a comment. `place` and `header`
## are where the token stands: first on its line or not, and before, inside or
## past the file's header.
token_step :
	List(U8),
	{
		state : State,
		byte : U8,
		next : U8,
		place : [LineStart, MidLine],
		header : Header,
	} -> State
token_step = |bytes, { state, byte, next, place, header }| {
	at = state.at
	if byte == '"' {
		{ ..emit(state, { class: String, end: at + 1 }), mode: InString(Quoted) }
	} else if byte == '\'' {
		{
			..emit(
				state,
				{ class: String, end: Bytes.quoted_end(bytes, { at: at + 1, quote: '\'' }) },
			),
			before: Value,
		}
	} else if byte == '\\' and next == '\\' {
		{ ..emit(state, { class: String, end: at + 2 }), mode: InString(Multiline) }
	} else if Bytes.is_digit(byte) {
		if state.before == Dot {
			{
				..emit(
					state,
					{ class: Plain, end: Bytes.run_end(bytes, { at, keep: Bytes.is_digit }) },
				),
				before: Value,
			}
		} else {
			{ ..emit(state, { class: Number, end: number_end(bytes, at) }), before: Value }
		}
	} else if byte == '-' and Bytes.is_digit(next) and !(
		at > 0 and is_value_end(
			Bytes.byte_at(bytes, at - 1),
		)
	) {
		{ ..emit(state, { class: Number, end: number_end(bytes, at + 1) }), before: Value }
	} else if is_upper(byte) {
		type_step(bytes, state)
	} else if is_lower(byte) or byte == '_' {
		word_step(bytes, { state, place, header })
	} else if byte == '$' and Bytes.is_ascii_word_byte(next) {
		{ ..emit(state, { class: Plain, end: word_end(bytes, at + 1) }), before: Value }
	} else if byte >= 0x80 {
		{
			..emit(state, { class: Plain, end: Bytes.run_end(bytes, { at, keep: |b| b >= 0x80 }) }),
			before: Value,
		}
	} else {
		symbol_step(bytes, { state, byte, next })
	}
}

## A type's name, a tag or a module: a capitalized word and the capitalized
## words after it, joined by dots.
type_step : List(U8), State -> State
type_step = |bytes, state| {
	{ ..emit(state, { class: Type, end: type_end(bytes, state.at) }), before: Value }
}

## A word that starts in lower case: a keyword, a name a definition gives, or
## another name, which is plain.
word_step :
	List(U8),
	{
		state : State,
		place : [LineStart, MidLine],
		header : Header,
	} -> State
word_step = |bytes, { state, place, header }| {
	at = state.at
	end = word_end(bytes, at)
	word = Str.from_utf8(
		bytes.sublist({ start: at, len: end - at }),
	) ?? crash "RocSyntax.word_step: a word is ASCII"
	is_header_word = header_starts.contains(word) or header_sections.contains(word)
	if state.before == Dot {
		{ ..emit(state, { class: Plain, end }), before: Value }
	} else if keywords.contains(word) {
		{ ..emit(state, { class: Keyword, end }), before: Keyword }
	} else if header == NoCodeYet and header_starts.contains(word) {
		{
			..emit(state, { class: Keyword, end }),
			before: Keyword,
			header: InHeader,
		}
	} else if header == InHeader and is_header_word {
		{ ..emit(state, { class: Keyword, end }), before: Keyword }
	} else if word == "platform" and Bytes.byte_at(bytes, space_end(bytes, end)) == '"' {
		{ ..emit(state, { class: Keyword, end }), before: Keyword }
	} else if place == LineStart and is_defined(bytes, { end, frames: state.frames }) {
		{ ..emit(state, { class: Name, end }), before: Value }
	} else {
		{ ..emit(state, { class: Plain, end }), before: Value }
	}
}

## Whether the word that ends at `end`, first on its line, is the name of a
## definition: `name : ...` wherever statements are, and `name = ...` at the
## top of a file or in a type's block. A record's `name: value` defines nothing.
is_defined : List(U8), { end : U64, frames : List(Frame) } -> Bool
is_defined = |bytes, { end, frames }| {
	after = space_end(bytes, end)
	sign = Bytes.byte_at(bytes, after)
	follow = Bytes.byte_at(bytes, after + 1)
	is_annotation = after > end and sign == ':' and follow != ':' and follow != '='
	is_assignment = sign == '=' and follow != '=' and follow != '>'
	match frames.last() {
		Err(ListWasEmpty) | Ok(TypeBlock) => is_annotation or is_assignment
		Ok(Body) => is_annotation
		_ => Bool.False
	}
}

## Punctuation and operators, which are plain; brackets and bars open and
## close frames.
symbol_step :
	List(U8),
	{
		state : State,
		byte : U8,
		next : U8,
	} -> State
symbol_step = |bytes, { state, byte, next }| {
	at = state.at
	plain = |end, before| { ..emit(state, { class: Plain, end }), before }
	if byte == '{' {
		{ ..plain(at + 1, Opener), frames: state.frames.append(brace_frame(state.before)) }
	} else if byte == '}' {
		match state.frames.last() {
			Ok(Interpolation(kind)) => {
				..plain(at + 1, Opener),
				frames: state.frames.drop_last(1),
				mode: InString(kind),
			}
			Ok(_) => { ..plain(at + 1, Value), frames: state.frames.drop_last(1) }
			Err(ListWasEmpty) => plain(at + 1, Value)
		}
	} else if byte == '(' {
		{ ..plain(at + 1, Opener), frames: state.frames.append(Paren) }
	} else if byte == '[' {
		{ ..plain(at + 1, Opener), frames: state.frames.append(Square) }
	} else if byte == ')' {
		{ ..plain(at + 1, Value), frames: without_last(state.frames, Paren) }
	} else if byte == ']' {
		{ ..plain(at + 1, Value), frames: without_last(state.frames, Square) }
	} else if byte == '|' and next == '>' {
		plain(at + 2, Operator)
	} else if byte == '|' {
		bar_step(state, plain(at + 1, Operator))
	} else if byte == '.' and next == '.' {
		plain(Bytes.run_end(bytes, { at, keep: |b| b == '.' }), Operator)
	} else if byte == '.' {
		plain(at + 1, Dot)
	} else if byte == ':' and (next == '=' or next == ':') {
		plain(at + 2, Colon)
	} else if byte == ':' {
		plain(at + 1, Colon)
	} else if byte == '-' and next == '>' {
		plain(at + 2, Arrow)
	} else if byte == '=' and next == '>' {
		plain(at + 2, FatArrow)
	} else if byte == '=' and next == '=' {
		plain(at + 2, Operator)
	} else if byte == '=' {
		plain(at + 1, Equals)
	} else if byte == ',' {
		plain(at + 1, Opener)
	} else {
		plain(at + 1, Operator)
	}
}

## A bar closes a lambda's arguments when they are open, is a pattern's `|`
## after a value, and opens a lambda's arguments anywhere else. `passed` is
## the state with the bar passed.
bar_step : State, State -> State
bar_step = |state, passed|
	match state.frames.last() {
		Ok(LambdaArgs) => {
			..passed,
			frames: state.frames.drop_last(1),
			before: BarClose,
		}
		_ =>
			if state.before == Value {
				passed
			} else {
				{
					..passed,
					frames: state.frames.append(LambdaArgs),
					before: BarOpen,
				}
			}
	}

## What a `{` opens, from the token before it.
brace_frame : Before -> Frame
brace_frame = |before| match before {
	Dot => TypeBlock
	Value | Equals | FatArrow | BarClose | Keyword => Body
	Start | Colon | Arrow | BarOpen | Opener | Operator => Record
}

## The state after the string text at `at`, up to and including whatever ends
## it: its closing quote, a `${`, the end of its line or of the text.
string_step : List(U8), { state : State, kind : StringKind } -> State
string_step = |bytes, { state, kind }| {
	stop = string_text_end(bytes, { at: state.at, kind })
	text = emit(state, { class: String, end: stop })
	byte = Bytes.byte_at(bytes, stop)
	if stop >= bytes.len() {
		text
	} else if byte == '\n' {
		{ ..text, mode: Code }
	} else if byte == '"' {
		{
			..emit(text, { class: String, end: stop + 1 }),
			mode: Code,
			before: Value,
		}
	} else {
		{
			..emit(text, { class: Plain, end: stop + 2 }),
			mode: Code,
			before: Opener,
			frames: state.frames.append(Interpolation(kind)),
		}
	}
}

## Where a string's text from `at` stops: at its closing quote (a quoted
## string's), a `${`, a newline or the end. A backslash keeps the byte after it
## in the text, unless that is a newline.
string_text_end : List(U8), { at : U64, kind : StringKind } -> U64
string_text_end = |bytes, { at, kind }| {
	var $at = at
	var $stop = bytes.len()
	while $at < bytes.len() {
		byte = Bytes.byte_at(bytes, $at)
		next = Bytes.byte_at(bytes, $at + 1)
		if byte == '\n' or (byte == '"' and kind == Quoted) or (byte == '$' and next == '{') {
			$stop = $at
			$at = bytes.len()
		} else if byte == '\\' and next != '\n' and $at + 1 < bytes.len() {
			$at = $at + 2
		} else {
			$at = $at + 1
		}
	}
	$stop
}

## The end of a number whose first digit is at `at`: `0x1F` and the other
## prefixed forms, or digits with an optional fraction, then any letters that
## follow, as a type's suffix.
number_end : List(U8), U64 -> U64
number_end = |bytes, at| {
	prefix = Bytes.byte_at(bytes, at + 1)
	if Bytes.byte_at(bytes, at) == '0' and (prefix == 'x' or prefix == 'o' or prefix == 'b') {
		Bytes.run_end(bytes, { at: at + 2, keep: Bytes.is_ascii_word_byte })
	} else {
		whole = Bytes.run_end(bytes, { at, keep: |b| Bytes.is_digit(b) or b == '_' })
		fraction =
			if Bytes.byte_at(bytes, whole) == '.' and Bytes.is_digit(
				Bytes.byte_at(bytes, whole + 1),
			) {
				Bytes.run_end(bytes, { at: whole + 1, keep: |b| Bytes.is_digit(b) or b == '_' })
			} else {
				whole
			}
		Bytes.run_end(bytes, { at: fraction, keep: Bytes.is_ascii_word_byte })
	}
}

## The end of a capitalized word and the capitalized words joined to it by
## dots.
type_end : List(U8), U64 -> U64
type_end = |bytes, at| {
	var $end = Bytes.run_end(bytes, { at, keep: Bytes.is_ascii_word_byte })
	while Bytes.byte_at(bytes, $end) == '.' and is_upper(Bytes.byte_at(bytes, $end + 1)) {
		$end = Bytes.run_end(bytes, { at: $end + 1, keep: Bytes.is_ascii_word_byte })
	}
	$end
}

## The end of a word, with the `!` an effect's name ends in.
word_end : List(U8), U64 -> U64
word_end = |bytes, at| {
	end = Bytes.run_end(bytes, { at, keep: Bytes.is_ascii_word_byte })
	if Bytes.byte_at(bytes, end) == '!' {
		end + 1
	} else {
		end
	}
}

## The frames with the last closed, if it is `frame`; a stray closer closes
## nothing.
without_last : List(Frame), Frame -> List(Frame)
without_last = |frames, frame|
	if frames.last() == Ok(frame) {
		frames.drop_last(1)
	} else {
		frames
	}

## The frames outside any string's interpolation, which a newline ends: a
## string never runs past its line.
without_interpolations : List(Frame) -> List(Frame)
without_interpolations = |frames|
	match frames.find_first_index(|frame| is_interpolation(frame)) {
		Ok(index) => frames.take_first(index)
		Err(NotFound) => frames
	}

is_interpolation : Frame -> Bool
is_interpolation = |frame| match frame {
	Interpolation(_) => Bool.True
	_ => Bool.False
}

## The index of the first byte at or after `at` that isn't a space or a tab.
space_end : List(U8), U64 -> U64
space_end = |bytes, at| Bytes.run_end(bytes, { at, keep: |b| b == ' ' or b == '\t' })

## Whether a byte ends a value, so that a `-` after it subtracts.
is_value_end : U8 -> Bool
is_value_end = |b|
	Bytes.is_ascii_word_byte(b)
		or b == ')'
		or b == ']'
		or b == '}'
		or b == '"'
		or b == '\''
		or b == '!'
		or b == '?'
		or b >= 0x80

is_upper : U8 -> Bool
is_upper = |b| b >= 'A' and b <= 'Z'

is_lower : U8 -> Bool
is_lower = |b| b >= 'a' and b <= 'z'

## The runs of `text` that get a color, each with its class and its text: what
## the expects below read.
colored : Str -> List((Span.Class, Str))
colored = |text| {
	bytes = text.to_utf8()
	RocSyntax.spans(text)
		.keep_if(|span| span.class != Plain)
		.map(
			|span| (
				span.class,
				Str.from_utf8(
					bytes.sublist({ start: span.start, len: span.end - span.start }),
				) ?? crash "RocSyntax.colored: a span ends inside a character",
			),
		)
}

expect RocSyntax.spans("") == []
expect colored("x # a comment\n## a doc") == [(Comment, "# a comment"), (Comment, "## a doc")]
expect colored("\"a # b\" # c") == [(String, "\"a # b\""), (Comment, "# c")]

# Strings: whole, with an escaped quote, cut by interpolations, nested ones too.
expect colored("f(\"ab\")") == [(String, "\"ab\"")]
expect colored("f(\"a\\\"b\")") == [(String, "\"a\\\"b\"")]
expect colored("f(\"a\${b}c\")") == [(String, "\"a"), (String, "c\"")]
expect colored("f(\"\${b}\")") == [(String, "\""), (String, "\"")]
expect colored("f(\"a\${g(\"b\${c}d\")}e\")") == [
	(String, "\"a"),
	(String, "\"b"),
	(String, "d\""),
	(String, "e\""),
]
expect colored("f(\"a\\\${b}\")") == [(String, "\"a\\\${b}\"")]
expect colored("f(\"\${ { x: 1 }.x }\")") == [
	(String, "\""),
	(Number, "1"),
	(String, "\""),
]

# A string still open stops at its newline, or at the end of the text.
expect colored("x = \"ab\ny = 1") == [
	(Name, "x"),
	(String, "\"ab"),
	(Name, "y"),
	(Number, "1"),
]
expect colored("f(\"ab") == [(String, "\"ab")]
expect colored("f(\"a\${b") == [(String, "\"a")]
expect colored("x = \"a\${f(b\ny = 1") == [
	(Name, "x"),
	(String, "\"a"),
	(Name, "y"),
	(Number, "1"),
]

# Characters, and multi-line strings, whose `\\` is a string's wherever it
# opens one: first on its line, after `=`, in a call, before an interpolation,
# and with nothing after it.
expect colored("f('a', '\\'', '\\n')") == [
	(String, "'a'"),
	(String, "'\\''"),
	(String, "'\\n'"),
]
expect colored("f('a") == [(String, "'a")]
expect colored("css =\n\t\\\\a { \${x} }\n\t\\\\b \"q\"") == [
	(Name, "css"),
	(String, "\\\\a { "),
	(String, " }"),
	(String, "\\\\b \"q\""),
]
expect colored("css = \\\\a") == [(Name, "css"), (String, "\\\\a")]
expect colored("f(\\\\a\n)") == [(String, "\\\\a")]
expect colored("x = \\\\a \${y} b\nz = 1") == [
	(Name, "x"),
	(String, "\\\\a "),
	(String, " b"),
	(Name, "z"),
	(Number, "1"),
]
expect colored("x = \\\\") == [(Name, "x"), (String, "\\\\")]

# Numbers, with the `-` of a negative one, and not of a subtraction.
expect colored("f(1, 1.5, 0x1F, 0b101, 1_000, 12u8, -1.0, [-2])") == [
	(Number, "1"),
	(Number, "1.5"),
	(Number, "0x1F"),
	(Number, "0b101"),
	(Number, "1_000"),
	(Number, "12u8"),
	(Number, "-1.0"),
	(Number, "-2"),
]
expect colored("f(a - 1, a-1, b) - 2") == [
	(Number, "1"),
	(Number, "1"),
	(Number, "2"),
]
expect colored("f(pair.0, 1..2, 2.0.to_str())") == [
	(Number, "1"),
	(Number, "2"),
	(Number, "2.0"),
]

# Every keyword, and words that only hold one or follow a dot or a `$`.
expect
	colored("f = and as break crash dbg else expect exposing for if import in match or return var where while")
		== [
			(Name, "f"),
			(Keyword, "and"),
			(Keyword, "as"),
			(Keyword, "break"),
			(Keyword, "crash"),
			(Keyword, "dbg"),
			(Keyword, "else"),
			(Keyword, "expect"),
			(Keyword, "exposing"),
			(Keyword, "for"),
			(Keyword, "if"),
			(Keyword, "import"),
			(Keyword, "in"),
			(Keyword, "match"),
			(Keyword, "or"),
			(Keyword, "return"),
			(Keyword, "var"),
			(Keyword, "where"),
			(Keyword, "while"),
		]
expect colored("f(iffy, x.if, $in, in_view, for_each!)") == []

# A header's first word is a keyword, and so is `platform` before its string;
# the same words elsewhere are not.
expect colored("app [main!] { pf: platform \"p.roc\" }") == [
	(Keyword, "app"),
	(Keyword, "platform"),
	(String, "\"p.roc\""),
]
expect colored("# a comment first\npackage [A] {}") == [
	(Comment, "# a comment first"),
	(Keyword, "package"),
	(Type, "A"),
]
expect colored("x = 1\nf(app, package, platform)") == [(Name, "x"), (Number, "1")]

# A platform header's sections are keywords to the line that starts at its
# first column, and the same words past it, or after a dot, are not.
expect
	colored("platform \"\"\n\trequires {\n\t\tmain! : I8\n\t}\n\texposes [Echo]\n\tpackages {}\n\tprovides { \"m\": Echo.provides }\n\thosted {}\n\ttargets: {\n\t\tdir: \"t/\",\n\t}\n\nimport Echo\nrequires = 1\nf(exposes, packages, provides, hosted, targets)")
		== [
			(Keyword, "platform"),
			(String, "\"\""),
			(Keyword, "requires"),
			(Name, "main!"),
			(Type, "I8"),
			(Keyword, "exposes"),
			(Type, "Echo"),
			(Keyword, "packages"),
			(Keyword, "provides"),
			(String, "\"m\""),
			(Type, "Echo"),
			(Keyword, "hosted"),
			(Keyword, "targets"),
			(String, "\"t/\""),
			(Keyword, "import"),
			(Type, "Echo"),
			(Name, "requires"),
			(Number, "1"),
		]

# `module` and `hosted` start a header too, and a header's words are plain
# when the file starts with anything else.
expect colored("module [f]\n\nf = 1") == [
	(Keyword, "module"),
	(Name, "f"),
	(Number, "1"),
]
expect colored("hosted [Echo]\nexposes = 1") == [
	(Keyword, "hosted"),
	(Type, "Echo"),
	(Name, "exposes"),
	(Number, "1"),
]
expect colored("import A\n\texposes [B]\nmodule = 1") == [
	(Keyword, "import"),
	(Type, "A"),
	(Type, "B"),
	(Name, "module"),
	(Number, "1"),
]

# An app header's indented lines are in it, to the line that starts at its
# first column: a stacked header's closing brace, or the code after it.
expect colored("app [main!] { pf: platform \"p\" }\n\tx: provides\nrequires = 1") == [
	(Keyword, "app"),
	(Keyword, "platform"),
	(String, "\"p\""),
	(Keyword, "provides"),
	(Name, "requires"),
	(Number, "1"),
]
expect colored("app [main!] {\n\tpf: platform \"p\",\n\tx: provides,\n}\nmain! = 1") == [
	(Keyword, "app"),
	(Keyword, "platform"),
	(String, "\"p\""),
	(Keyword, "provides"),
	(Name, "main!"),
	(Number, "1"),
]

# web.roc's header, which roc-ast's tree can't color: the header is colored as
# any other, and the definitions after it are too.
expect
	colored("app [Model, program] { lib: \"l.roc\", pf: platform \"p.roc\" }\n\nimport lib.W\nModel : W.Model\nprogram = W.program")
		== [
			(Keyword, "app"),
			(Type, "Model"),
			(String, "\"l.roc\""),
			(Keyword, "platform"),
			(String, "\"p.roc\""),
			(Keyword, "import"),
			(Type, "W"),
			(Type, "Model"),
			(Type, "W.Model"),
			(Name, "program"),
			(Type, "W"),
		]

# Types and tags, a qualified name as one span, and a module before a function.
expect colored("f(Ok(Str), Bool.True, Str.concat, lib.Shapes)") == [
	(Type, "Ok"),
	(Type, "Str"),
	(Type, "Bool.True"),
	(Type, "Str"),
	(Type, "Shapes"),
]
expect colored("f(A.B.c, A.(1))") == [
	(Type, "A.B"),
	(Type, "A"),
	(Number, "1"),
]

# A wrapped value's type is a type, qualified or not, in a lambda's arguments
# and out of them.
expect colored("f(|A.(x)|, |A.B.(x)|, |(A.B.(x), y)|, |{ a: A.B.C.(x) }|)") == [
	(Type, "A"),
	(Type, "A.B"),
	(Type, "A.B"),
	(Type, "A.B.C"),
]
expect colored("f(A.(x), A.B.(x))") == [(Type, "A"), (Type, "A.B")]
expect colored("f(|x| A.B.(x))") == [(Type, "A.B")]

# Names: the top level and a type's block define with `=` and `:`; a body
# only with `:`; records and expressions define nothing.
expect colored("x = 1\ny : U8\nmain! = |_| {}") == [
	(Name, "x"),
	(Number, "1"),
	(Name, "y"),
	(Type, "U8"),
	(Name, "main!"),
]
expect colored("T := [].{\n\tx = 1\n\ty : U8\n}") == [
	(Type, "T"),
	(Name, "x"),
	(Number, "1"),
	(Name, "y"),
	(Type, "U8"),
]
expect colored("f = |a| {\n\tb = a\n\tc : U8\n\tc = b\n\tc\n}") == [
	(Name, "f"),
	(Name, "c"),
	(Type, "U8"),
]
expect colored("f = |a|\n\tif a {\n\t\tb = 1\n\t\tb\n\t} else {\n\t\tc : U8\n\t\tc = 2\n\t\tc\n\t}") == [
	(Name, "f"),
	(Keyword, "if"),
	(Number, "1"),
	(Keyword, "else"),
	(Name, "c"),
	(Type, "U8"),
	(Number, "2"),
]
expect colored("x = {\n\ty : U8\n\ty = 1\n\ty\n}") == [
	(Name, "x"),
	(Name, "y"),
	(Type, "U8"),
	(Number, "1"),
]
expect colored("r = {\n\ta: 1,\n\tb: 2,\n}") == [
	(Name, "r"),
	(Number, "1"),
	(Number, "2"),
]
expect colored("R : {\n\ta : U8,\n}\nf : {\n\tb : U8,\n} -> U8") == [
	(Type, "R"),
	(Type, "U8"),
	(Name, "f"),
	(Type, "U8"),
	(Type, "U8"),
]
expect colored("x == 1\nx => 1\ny := 1\nz :: 1") == [
	(Number, "1"),
	(Number, "1"),
	(Number, "1"),
	(Number, "1"),
]
expect colored("  x = 1") == [(Name, "x"), (Number, "1")]
expect colored("f(\n\tx = 1\n)") == [(Number, "1")]
expect colored("expect {\n\tx = 1\n\tx == 1\n}") == [
	(Keyword, "expect"),
	(Number, "1"),
	(Number, "1"),
]
expect colored("f = |{ a, b }| {\n\tc : U8\n\tc\n}") == [
	(Name, "f"),
	(Name, "c"),
	(Type, "U8"),
]
expect colored("f = |x| match x {\n\tA | B => {\n\t\ty : U8\n\t\ty = 1\n\t\ty\n\t}\n}") == [
	(Name, "f"),
	(Keyword, "match"),
	(Type, "A"),
	(Type, "B"),
	(Name, "y"),
	(Type, "U8"),
	(Number, "1"),
]
