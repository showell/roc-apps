## JsSyntax splits JavaScript into spans, with the classes the Roc and Shale
## lexers use: comments, strings (quoted, template literals' text and regular
## expressions), numbers, keywords, and the name right after `function` or
## `class`. Names, operators and punctuation are plain, and JavaScript has no
## types to color.
##
## Two things need more than the byte at hand. A template literal's `${` opens
## code that runs to its matching `}`, so the open braces are kept as a stack.
## A `/` starts a regular expression where a value is due, at the start or
## after an operator, a `(` or a keyword such as `return`, and divides after a
## value: a name, a number, a string, `)` or `]`.
##
## No text makes it fail: a string, comment, template or regular expression
## still open at the end stops there, a quoted string or a regular expression
## also at its line's end, and a byte no token starts with is plain.
import Span

JsSyntax :: [].{

	## The spans of `text`, covering every byte once, in order.
	spans : Str -> List(Span)
	spans = |text| {
		bytes = text.to_utf8()
		var $state = { at: 0, out: [], braces: [], before: Operator, mode: Code }
		while $state.at < bytes.len() {
			$state =
				match $state.mode {
					Code => code_step(bytes, $state)
					InTemplate => template_part(bytes, $state, $state.at)
				}
		}
		$state.out
	}
}

## How the lexer stands between two tokens.
State : {
	at : U64,
	out : List(Span),
	braces : List([Brace, Interpolation]),
	before : Before,
	mode : [Code, InTemplate],
}

## What the token before was, as far as the next one cares: a value, after
## which `/` divides; `function` or `class`, after which a name is declared; a
## `.`, after which a word is a property; or anything else, after which `/` starts a regular expression.
Before : [Value, Declarer, Dot, Operator]

keywords : List(Str)
keywords = [
	"async",
	"await",
	"break",
	"case",
	"catch",
	"class",
	"const",
	"continue",
	"debugger",
	"default",
	"delete",
	"do",
	"else",
	"export",
	"extends",
	"false",
	"finally",
	"for",
	"function",
	"if",
	"import",
	"in",
	"instanceof",
	"let",
	"new",
	"null",
	"of",
	"return",
	"super",
	"switch",
	"this",
	"throw",
	"true",
	"try",
	"typeof",
	"undefined",
	"var",
	"void",
	"while",
	"with",
	"yield",
]

## The keywords that stand for a value, so a `/` after one divides.
value_keywords : List(Str)
value_keywords = ["false", "null", "super", "this", "true", "undefined"]

## The state with the bytes from `at` up to `end` added as one token of
## `class`, and `before` as what it was.
emit : State, { class : Span.Class, end : U64, before : Before } -> State
emit = |state, { class, end, before }| {
	..state,
	out: Span.push_token(state.out, { class, start: state.at, end }),
	at: end,
	before,
}

## The state with space or a comment passed, which leaves `before` as it was.
pass : State, { class : Span.Class, end : U64 } -> State
pass = |state, { class, end }| emit(state, { class, end, before: state.before })

## The state after the token of code at `at`.
code_step : List(U8), State -> State
code_step = |bytes, state| {
	at = state.at
	byte = byte_at(bytes, at)
	next = byte_at(bytes, at + 1)
	if byte == ' ' or byte == '\t' or byte == '\r' or byte == '\n' {
		pass(state, { class: Plain, end: at + 1 })
	} else if byte == '/' and next == '/' {
		pass(state, { class: Comment, end: line_end(bytes, at) })
	} else if byte == '/' and next == '*' {
		pass(state, { class: Comment, end: block_comment_end(bytes, at + 2) })
	} else if byte == '#' and next == '!' and at == 0 {
		pass(state, { class: Comment, end: line_end(bytes, at) })
	} else if byte == '"' or byte == '\'' {
		emit(state, { class: String, end: quoted_end(bytes, { at: at + 1, quote: byte }), before: Value })
	} else if byte == '`' {
		template_part(bytes, state, at + 1)
	} else if byte == '/' and state.before != Value {
		emit(state, { class: String, end: regex_end(bytes, at + 1), before: Value })
	} else if is_digit(byte) or (byte == '.' and is_digit(next)) {
		emit(state, { class: Number, end: run_end(bytes, { at: number_end(bytes, at), keep: is_word_byte }), before: Value })
	} else if is_word_byte(byte) {
		word_step(bytes, state)
	} else if byte == '{' {
		{ ..emit(state, { class: Plain, end: at + 1, before: Operator }), braces: state.braces.append(Brace) }
	} else if byte == '}' {
		match state.braces.last() {
			Ok(Interpolation) => { ..emit(state, { class: Plain, end: at + 1, before: Value }), braces: state.braces.drop_last(1), mode: InTemplate }
			Ok(Brace) => { ..emit(state, { class: Plain, end: at + 1, before: Value }), braces: state.braces.drop_last(1) }
			Err(ListWasEmpty) => emit(state, { class: Plain, end: at + 1, before: Value })
		}
	} else if byte == '.' and next == '.' {
		emit(state, { class: Plain, end: run_end(bytes, { at, keep: |b| b == '.' }), before: Operator })
	} else if byte == '.' {
		emit(state, { class: Plain, end: at + 1, before: Dot })
	} else if byte == ')' or byte == ']' {
		emit(state, { class: Plain, end: at + 1, before: Value })
	} else {
		emit(state, { class: Plain, end: at + 1, before: Operator })
	}
}

## A word: a keyword, the name a `function` or `class` declares, or another
## name, which is plain. A word after a `.` is a property, never a keyword.
word_step : List(U8), State -> State
word_step = |bytes, state| {
	at = state.at
	end = run_end(bytes, { at, keep: is_word_byte })
	word = Str.from_utf8(bytes.sublist({ start: at, len: end - at })) ?? crash "JsSyntax.word_step: a word holds whole characters"
	if state.before == Dot {
		emit(state, { class: Plain, end, before: Value })
	} else if word == "function" or word == "class" {
		emit(state, { class: Keyword, end, before: Declarer })
	} else if value_keywords.contains(word) {
		emit(state, { class: Keyword, end, before: Value })
	} else if keywords.contains(word) {
		emit(state, { class: Keyword, end, before: Operator })
	} else if state.before == Declarer {
		emit(state, { class: Name, end, before: Value })
	} else {
		emit(state, { class: Plain, end, before: Value })
	}
}

## The state after a part of a template literal: from `at`, its opening
## backquote or the `}` before it passed, to what ends the part, its closing
## backquote, a `${` or the end of the text. The part is one string span.
template_part : List(U8), State, U64 -> State
template_part = |bytes, state, from| {
	stop = template_text_end(bytes, from)
	if stop >= bytes.len() {
		{ ..emit(state, { class: String, end: bytes.len(), before: Value }), mode: InTemplate }
	} else if byte_at(bytes, stop) == '`' {
		{ ..emit(state, { class: String, end: stop + 1, before: Value }), mode: Code }
	} else {
		text = emit(state, { class: String, end: stop, before: Value })
		{ ..emit(text, { class: Plain, end: stop + 2, before: Operator }), mode: Code, braces: state.braces.append(Interpolation) }
	}
}

## Where a template's text from `at` stops: at its backquote, a `${` or the
## end. A backslash keeps the byte after it in the text.
template_text_end : List(U8), U64 -> U64
template_text_end = |bytes, at| {
	var $at = at
	var $stop = bytes.len()
	while $at < bytes.len() {
		byte = byte_at(bytes, $at)
		if byte == '`' or (byte == '$' and byte_at(bytes, $at + 1) == '{') {
			$stop = $at
			$at = bytes.len()
		} else if byte == '\\' {
			$at = $at + 2
		} else {
			$at = $at + 1
		}
	}
	$stop.min(bytes.len())
}

## The end of a quoted string whose text starts at `at`: just past its closing
## quote, or where its line or the text ends. A backslash keeps the byte after
## it, a newline too, as a line continuation.
quoted_end : List(U8), { at : U64, quote : U8 } -> U64
quoted_end = |bytes, { at, quote }| {
	var $at = at
	var $end = bytes.len()
	while $at < bytes.len() {
		byte = byte_at(bytes, $at)
		if byte == quote {
			$end = $at + 1
			$at = bytes.len()
		} else if byte == '\n' {
			$end = $at
			$at = bytes.len()
		} else if byte == '\\' {
			$at = $at + 2
		} else {
			$at = $at + 1
		}
	}
	$end.min(bytes.len())
}

## The end of a regular expression whose body starts at `at`: past its closing
## `/` and its flags. A `/` inside a class, `[/]`, or after a backslash doesn't
## close it, and one still open stops at its line's end.
regex_end : List(U8), U64 -> U64
regex_end = |bytes, at| {
	var $at = at
	var $in_class = Bool.False
	var $end = bytes.len()
	while $at < bytes.len() {
		byte = byte_at(bytes, $at)
		if byte == '\n' {
			$end = $at
			$at = bytes.len()
		} else if byte == '\\' and byte_at(bytes, $at + 1) != '\n' {
			$at = $at + 2
		} else if byte == '[' {
			$in_class = Bool.True
			$at = $at + 1
		} else if byte == ']' {
			$in_class = Bool.False
			$at = $at + 1
		} else if byte == '/' and !$in_class {
			$end = run_end(bytes, { at: $at + 1, keep: is_word_byte })
			$at = bytes.len()
		} else {
			$at = $at + 1
		}
	}
	$end.min(bytes.len())
}

## The end of a block comment whose text starts at `at`: past its `*/`, or the
## end of the text.
block_comment_end : List(U8), U64 -> U64
block_comment_end = |bytes, at| {
	var $at = at
	var $end = bytes.len()
	while $at < bytes.len() {
		if byte_at(bytes, $at) == '*' and byte_at(bytes, $at + 1) == '/' {
			$end = $at + 2
			$at = bytes.len()
		} else {
			$at = $at + 1
		}
	}
	$end
}

## The end of a number's digits at `at`: `0x1F`, `0b1`, `0o7`, or digits with a
## fraction and an exponent, each with `_` separators. A BigInt's `n`, and any
## other letters run into the number, the caller takes with it.
number_end : List(U8), U64 -> U64
number_end = |bytes, at| {
	prefix = byte_at(bytes, at + 1)
	if byte_at(bytes, at) == '0' and (prefix == 'x' or prefix == 'X' or prefix == 'b' or prefix == 'B' or prefix == 'o' or prefix == 'O') {
		run_end(bytes, { at: at + 2, keep: |b| is_hex_digit(b) or b == '_' })
	} else {
		whole = run_end(bytes, { at, keep: is_digit_or_separator })
		fraction =
			if byte_at(bytes, whole) == '.' and !is_letter(byte_at(bytes, whole + 1)) {
				run_end(bytes, { at: whole + 1, keep: is_digit_or_separator })
			} else {
				whole
			}
		e = byte_at(bytes, fraction)
		sign = byte_at(bytes, fraction + 1)
		if (e == 'e' or e == 'E') and (is_digit(sign) or ((sign == '+' or sign == '-') and is_digit(byte_at(bytes, fraction + 2)))) {
			run_end(bytes, { at: fraction + 2, keep: is_digit_or_separator })
		} else {
			fraction
		}
	}
}

## The index of the newline at or after `at`, or the length.
line_end : List(U8), U64 -> U64
line_end = |bytes, at| run_end(bytes, { at, keep: |b| b != '\n' })

## The index of the first byte at or after `at` that `keep` refuses, or the
## length.
run_end : List(U8), { at : U64, keep : U8 -> Bool } -> U64
run_end = |bytes, { at, keep }| {
	var $at = at
	while $at < bytes.len() and keep(byte_at(bytes, $at)) {
		$at = $at + 1
	}
	$at
}

## The byte at `at`, or 0 past the end, which no rule here takes.
byte_at : List(U8), U64 -> U8
byte_at = |bytes, at| bytes.get(at) ?? 0

is_digit : U8 -> Bool
is_digit = |b| b >= '0' and b <= '9'

is_digit_or_separator : U8 -> Bool
is_digit_or_separator = |b| is_digit(b) or b == '_'

is_letter : U8 -> Bool
is_letter = |b| (b >= 'a' and b <= 'z') or (b >= 'A' and b <= 'Z') or b == '_' or b == '$'

is_hex_digit : U8 -> Bool
is_hex_digit = |b| is_digit(b) or (b >= 'a' and b <= 'f') or (b >= 'A' and b <= 'F')

## A byte of a name: an ASCII letter, a digit, `_`, `$`, or any byte of a
## character past ASCII, which JavaScript's names may hold.
is_word_byte : U8 -> Bool
is_word_byte = |b| is_letter(b) or is_digit(b) or b >= 0x80

## The runs of `text` that get a color, each with its class and its text: what
## the expects below read.
colored : Str -> List((Span.Class, Str))
colored = |text| {
	bytes = text.to_utf8()
	JsSyntax.spans(text)
		.keep_if(|span| span.class != Plain)
		.map(|span| (span.class, Str.from_utf8(bytes.sublist({ start: span.start, len: span.end - span.start })) ?? crash "JsSyntax.colored: a span ends inside a character"))
}

expect JsSyntax.spans("") == []

# Comments of both kinds, one never closed, and a script's first `#!` line.
expect colored("// a comment ends.\nconst x = a.\n  b") == [(Comment, "// a comment ends."), (Keyword, "const")]
expect colored("a // b /* c\n/* d\ne */ f") == [(Comment, "// b /* c"), (Comment, "/* d\ne */")]
expect colored("a /* b") == [(Comment, "/* b")]
expect colored("#!/usr/bin/env node\nx") == [(Comment, "#!/usr/bin/env node")]
expect colored("x # y") == []

# Quoted strings, with escapes and a line continuation; one still open stops
# at its line's end or the text's.
expect colored("f(\"a\\\"b\", 'c\\'d', \"e\\\nf\")") == [(String, "\"a\\\"b\""), (String, "'c\\'d'"), (String, "\"e\\\nf\"")]
expect colored("f(\"ab\nx = 'c") == [(String, "\"ab"), (String, "'c")]

# Template literals: their text is a string, and `${...}` is code, nested
# templates and braces too; one still open runs to the end.
expect colored("`a \${b} c`") == [(String, "`a "), (String, " c`")]
expect colored("`\${`x\${1}y`}z`") == [(String, "`"), (String, "`x"), (Number, "1"), (String, "y`"), (String, "z`")]
expect colored("`a \${ { b: 1 }.b } c`") == [(String, "`a "), (Number, "1"), (String, " c`")]
expect colored("`a\nb\\`c`") == [(String, "`a\nb\\`c`")]
expect colored("`a \${b") == [(String, "`a ")]
expect colored("`a") == [(String, "`a")]

# A `/` starts a regular expression where a value is due, and divides after one.
expect colored("x = /a\\/b[/]c/gi.test(s)") == [(String, "/a\\/b[/]c/gi")]
expect colored("f(/a/); return /b/") == [(String, "/a/"), (Keyword, "return"), (String, "/b/")]
expect colored("a / b / c; (d) / 2; e[0] / f; 4 / 2") == [(Number, "2"), (Number, "0"), (Number, "4"), (Number, "2")]
expect colored("this / 2") == [(Keyword, "this"), (Number, "2")]
expect colored("x = /ab\ny") == [(String, "/ab")]

# Numbers in every base, with exponents, separators and BigInt's `n`.
expect colored("f(1, 1.5, .5, 1., 0x1F, 0B101, 0o17, 1e10, 2.5E-3, 1_000_000, 10n, 0xFFn)") == [(Number, "1"), (Number, "1.5"), (Number, ".5"), (Number, "1."), (Number, "0x1F"), (Number, "0B101"), (Number, "0o17"), (Number, "1e10"), (Number, "2.5E-3"), (Number, "1_000_000"), (Number, "10n"), (Number, "0xFFn")]
expect colored("a1 x.b2 1..toString()") == [(Number, "1.")]

# Every keyword, and words that hold one or follow a dot.
expect
	colored("async await break case catch const continue debugger default delete do else export extends false finally for if import in instanceof let new null of return super switch this throw true try typeof undefined var void while with yield")
		== [
			(Keyword, "async"),
			(Keyword, "await"),
			(Keyword, "break"),
			(Keyword, "case"),
			(Keyword, "catch"),
			(Keyword, "const"),
			(Keyword, "continue"),
			(Keyword, "debugger"),
			(Keyword, "default"),
			(Keyword, "delete"),
			(Keyword, "do"),
			(Keyword, "else"),
			(Keyword, "export"),
			(Keyword, "extends"),
			(Keyword, "false"),
			(Keyword, "finally"),
			(Keyword, "for"),
			(Keyword, "if"),
			(Keyword, "import"),
			(Keyword, "in"),
			(Keyword, "instanceof"),
			(Keyword, "let"),
			(Keyword, "new"),
			(Keyword, "null"),
			(Keyword, "of"),
			(Keyword, "return"),
			(Keyword, "super"),
			(Keyword, "switch"),
			(Keyword, "this"),
			(Keyword, "throw"),
			(Keyword, "true"),
			(Keyword, "try"),
			(Keyword, "typeof"),
			(Keyword, "undefined"),
			(Keyword, "var"),
			(Keyword, "void"),
			(Keyword, "while"),
			(Keyword, "with"),
			(Keyword, "yield"),
		]
expect colored("iffy $if _new from x.default y.\n  then café") == []

# The name `function` or `class` declares, past a comment; a call is none.
expect colored("function /* a */ f(x) { return f(x) }") == [(Keyword, "function"), (Comment, "/* a */"), (Name, "f"), (Keyword, "return")]
expect colored("class Box extends Base {}") == [(Keyword, "class"), (Name, "Box"), (Keyword, "extends")]
expect colored("const g = function (x) {}") == [(Keyword, "const"), (Keyword, "function")]
