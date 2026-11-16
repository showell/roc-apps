## ShaleSyntax splits Shale source into spans as Shale's own lexer reads it
## (shale's src/script/lex.zig), and as the Shale cookbook's color_shale.shale
## colors it: comments, strings, integers and keywords, and the name right
## after `function`, with names and symbols left plain.
##
## Where Shale's lexer refuses a text, these spans still cover it: a string or
## a long string that never closes runs to the end of its line or of the text,
## a number that runs into a name stops where the name starts, and a byte no
## token starts with is plain.
import Span

ShaleSyntax :: [].{

	## The spans of `text`, covering every byte once, in order.
	spans : Str -> List(Span)
	spans = |text| {
		bytes = text.to_utf8()
		var $at = 0
		var $out = []
		var $after_function = Bool.False
		while $at < bytes.len() {
			token = token_at(bytes, $at)
			$out = Span.push_token($out, { class: class_of(token, $after_function), start: $at, end: token.end })
			$after_function = match token.kind {
				Space | Comment => $after_function
				Word(word) => word == "function"
				_ => Bool.False
			}
			$at = token.end
		}
		$out
	}
}

## The words Shale's lexer makes keywords of.
keywords : List(Str)
keywords = [
	"and",
	"break",
	"const",
	"continue",
	"do",
	"else",
	"elseif",
	"end",
	"false",
	"for",
	"function",
	"if",
	"in",
	"local",
	"nil",
	"not",
	"or",
	"return",
	"then",
	"true",
	"while",
]

## One token: what kind it is, and the index just past it.
Token : { kind : [Space, Comment, String, Number, Word(Str), Symbol], end : U64 }

## A word is a keyword, or a name, which right after `function` is the name
## that `function` declares.
class_of : Token, Bool -> Span.Class
class_of = |token, after_function| match token.kind {
	Space | Symbol => Plain
	Comment => Comment
	String => String
	Number => Number
	Word(word) =>
		if keywords.contains(word) {
			Keyword
		} else if after_function {
			Name
		} else {
			Plain
		}
}

## The token that starts at `at`, which is below the length.
token_at : List(U8), U64 -> Token
token_at = |bytes, at| {
	byte = byte_at(bytes, at)
	if is_space(byte) {
		{ kind: Space, end: at + 1 }
	} else if byte == '-' and byte_at(bytes, at + 1) == '-' {
		{ kind: Comment, end: comment_end(bytes, at) }
	} else if byte == '[' {
		match long_level(bytes, at) {
			Ok(level) => { kind: String, end: long_end(bytes, { opener: at, level }) }
			Err(NotLong) => { kind: Symbol, end: at + 1 }
		}
	} else if byte == '"' or byte == '\'' {
		{ kind: String, end: quoted_end(bytes, { at: at + 1, quote: byte }) }
	} else if is_digit(byte) {
		{ kind: Number, end: run_end(bytes, { at, keep: is_digit }) }
	} else if is_word_start(byte) {
		end = run_end(bytes, { at, keep: is_word_byte })
		word = Str.from_utf8(bytes.sublist({ start: at, len: end - at })) ?? crash "ShaleSyntax.token_at: a word is ASCII"
		{ kind: Word(word), end }
	} else if byte >= 0x80 {
		{ kind: Symbol, end: run_end(bytes, { at, keep: |b| b >= 0x80 }) }
	} else {
		{ kind: Symbol, end: at + 1 }
	}
}

## The end of the comment that starts at `at`: a block comment, `--[=[ ... ]=]`,
## runs to its closer, and any other comment to the end of its line.
comment_end : List(U8), U64 -> U64
comment_end = |bytes, at|
	match long_level(bytes, at + 2) {
		Ok(level) => long_end(bytes, { opener: at + 2, level })
		Err(NotLong) => line_end(bytes, at)
	}

## The level of a long bracket opening at `at`, `[=[` being 1, or none: a
## long string needs a level, so `[[` opens none.
long_level : List(U8), U64 -> Try(U64, [NotLong])
long_level = |bytes, at|
	if byte_at(bytes, at) != '[' {
		Err(NotLong)
	} else {
		after = run_end(bytes, { at: at + 1, keep: |b| b == '=' })
		level = after - (at + 1)
		if level > 0 and byte_at(bytes, after) == '[' {
			Ok(level)
		} else {
			Err(NotLong)
		}
	}

## The end of a long bracket opened at `opener`: just past its closer, `]`, as
## many `=` as its level, and `]`; or the end of the text.
long_end : List(U8), { opener : U64, level : U64 } -> U64
long_end = |bytes, { opener, level }| {
	var $at = opener + level + 2
	var $end = bytes.len()
	while $at < bytes.len() {
		if byte_at(bytes, $at) == ']' and is_closer(bytes, { at: $at, level }) {
			$end = $at + level + 2
			$at = bytes.len()
		} else {
			$at = $at + 1
		}
	}
	$end
}

## Whether a closer of `level` starts at `at`.
is_closer : List(U8), { at : U64, level : U64 } -> Bool
is_closer = |bytes, { at, level }| {
	after = run_end(bytes, { at: at + 1, keep: |b| b == '=' })
	after - (at + 1) == level and byte_at(bytes, after) == ']'
}

## The end of a quoted string whose text starts at `at`: just past the closing
## quote. A backslash keeps the byte after it in the string, unless that is a
## newline; a string still open at a newline or at the end stops there.
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
		} else if byte == '\\' and $at + 1 < bytes.len() and byte_at(bytes, $at + 1) != '\n' {
			$at = $at + 2
		} else {
			$at = $at + 1
		}
	}
	$end
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

is_space : U8 -> Bool
is_space = |b| b == ' ' or b == '\t' or b == '\r' or b == '\n'

is_digit : U8 -> Bool
is_digit = |b| b >= '0' and b <= '9'

is_word_start : U8 -> Bool
is_word_start = |b| (b >= 'a' and b <= 'z') or (b >= 'A' and b <= 'Z') or b == '_'

is_word_byte : U8 -> Bool
is_word_byte = |b| is_word_start(b) or is_digit(b)

## The runs of `text` that get a color, each with its class and its text: what
## the expects below read.
colored : Str -> List((Span.Class, Str))
colored = |text| {
	bytes = text.to_utf8()
	ShaleSyntax.spans(text)
		.keep_if(|span| span.class != Plain)
		.map(|span| (span.class, Str.from_utf8(bytes.sublist({ start: span.start, len: span.end - span.start })) ?? crash "ShaleSyntax.colored: a span ends inside a character"))
}

expect ShaleSyntax.spans("") == []

# Comments: a line's, which keeps a CR; a block's at each level; `--[=x` and
# `--[[`, which are a line's.
expect colored("x = 1 -- a\r\ny") == [(Number, "1"), (Comment, "-- a\r")]
expect colored("--[=[ a\nb ]=] 1") == [(Comment, "--[=[ a\nb ]=]"), (Number, "1")]
expect colored("--[==[ ]=] ]==]") == [(Comment, "--[==[ ]=] ]==]")]
expect colored("--[=x\n1") == [(Comment, "--[=x"), (Number, "1")]
expect colored("--[[a]]\n1") == [(Comment, "--[[a]]"), (Number, "1")]
expect colored("--") == [(Comment, "--")]
expect colored("a - -1") == [(Number, "1")]

# Strings in each quote, with escapes, and long ones, which hold a lower closer.
expect colored("x = \"a -- b\" .. 'c\\'d' .. \"e\\\\\"") == [(String, "\"a -- b\""), (String, "'c\\'d'"), (String, "\"e\\\\\"")]
expect colored("[=[a ]] b]=] [==[c ]=] d]==]") == [(String, "[=[a ]] b]=]"), (String, "[==[c ]=] d]==]")]
expect colored("\"a\"\"b\"") == [(String, "\"a\""), (String, "\"b\"")]

# Strings and long brackets that never close stop at their line or the end.
expect colored("\"ab\n1") == [(String, "\"ab"), (Number, "1")]
expect colored("'ab") == [(String, "'ab")]
expect colored("\"a\\") == [(String, "\"a\\")]
expect colored("[=[ a\nb") == [(String, "[=[ a\nb")]
expect colored("--[=[ a") == [(Comment, "--[=[ a")]
expect colored("[[a]] [=a t[1]") == [(Number, "1")]

# Numbers are digits; a float or a hexadecimal splits at what isn't one.
expect colored("1 23 1.5 0x1F 9a") == [(Number, "1"), (Number, "23"), (Number, "1"), (Number, "5"), (Number, "0"), (Number, "9")]

# Every keyword, and words that hold one.
expect
	colored("and break const continue do else elseif end false for function f if in local nil not or return then true while")
		== [
			(Keyword, "and"),
			(Keyword, "break"),
			(Keyword, "const"),
			(Keyword, "continue"),
			(Keyword, "do"),
			(Keyword, "else"),
			(Keyword, "elseif"),
			(Keyword, "end"),
			(Keyword, "false"),
			(Keyword, "for"),
			(Keyword, "function"),
			(Name, "f"),
			(Keyword, "if"),
			(Keyword, "in"),
			(Keyword, "local"),
			(Keyword, "nil"),
			(Keyword, "not"),
			(Keyword, "or"),
			(Keyword, "return"),
			(Keyword, "then"),
			(Keyword, "true"),
			(Keyword, "while"),
		]
expect colored("end_col iffy _end end1 Function use attempt") == []

# The name `function` declares, past a comment; a call or a local is no name.
expect colored("function --[=[ a ]=] f(x)\n  return f(x)\nend") == [(Keyword, "function"), (Comment, "--[=[ a ]=]"), (Name, "f"), (Keyword, "return"), (Keyword, "end")]
expect colored("local function_name = 1\nfunction (x)") == [(Keyword, "local"), (Number, "1"), (Keyword, "function")]
expect colored("+ - * // % .. == ~= < <= > >= = ( ) { } [ ] , . # ? ; @ / ~ é") == []
