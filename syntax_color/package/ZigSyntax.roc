## ZigSyntax splits Zig source into spans as Zig's own tokenizer reads it
## (lib/std/zig/tokenizer.zig), with the classes the other lexers use: comments
## (`//`, a `///` doc comment and a `//!` one alike), strings (quoted, a
## character, and each line of a `\\` multiline string), numbers, keywords, the
## primitive types (std/zig/primitives.zig's, `u8` and `i32` among them) as
## types, and the name right after `fn`. A builtin such as `@import` is a
## keyword, and so are `true`, `false`, `null` and `undefined`, which Zig reads
## as names. A `@"quoted identifier"` is a name like any other, one span.
## Other names, operators and punctuation are plain.
##
## A word right after a `.` is a field or an enum literal, never a keyword or a
## type: `.type` and `info.bool` are plain.
##
## No text makes it fail: a string or a quoted identifier still open stops at
## its line's end or the text's, and a byte no token starts with is plain.
import Bytes
import Span

ZigSyntax :: [].{

	## The spans of `text`, covering every byte once, in order.
	spans : Str -> List(Span)
	spans = |text| {
		bytes = text.to_utf8()
		var $at = 0
		var $out = []
		var $before = Other
		while $at < bytes.len() {
			token = token_at(bytes, $at)
			$out = Span.push_token(
				$out,
				{
					class: class_of(token, $before),
					start: $at,
					end: token.end,
				},
			)
			$before = next_before(token, $before)
			$at = token.end
		}
		$out
	}
}

## One token: what kind it is, and the index just past it.
Token : {
	kind : [
		Space,
		Comment,
		String,
		Number,
		Word(Str),
		QuotedName,
		Builtin,
		Dot,
		Symbol,
	],
	end : U64,
}

## What the token before was, as far as a word cares: `fn`, after which a name
## is declared; a `.`, after which a word is a field; or anything else.
Before : [FunctionKeyword, Dot, Other]

## Zig's keywords, but `anyframe` and `anytype`, which are types here, and the
## four primitive values Zig reads as names.
keywords : List(Str)
keywords = [
	"addrspace",
	"align",
	"allowzero",
	"and",
	"asm",
	"break",
	"callconv",
	"catch",
	"comptime",
	"const",
	"continue",
	"defer",
	"else",
	"enum",
	"errdefer",
	"error",
	"export",
	"extern",
	"false",
	"fn",
	"for",
	"if",
	"inline",
	"linksection",
	"noalias",
	"noinline",
	"nosuspend",
	"null",
	"opaque",
	"or",
	"orelse",
	"packed",
	"pub",
	"resume",
	"return",
	"struct",
	"suspend",
	"switch",
	"test",
	"threadlocal",
	"true",
	"try",
	"undefined",
	"union",
	"unreachable",
	"var",
	"volatile",
	"while",
]

## The primitive types by name, and the two keywords that stand for a type.
## The integer types, `u8` to `i65535`, are told by their spelling instead.
primitive_types : List(Str)
primitive_types = [
	"anyerror",
	"anyframe",
	"anyopaque",
	"anytype",
	"bool",
	"c_char",
	"c_int",
	"c_long",
	"c_longdouble",
	"c_longlong",
	"c_short",
	"c_uint",
	"c_ulong",
	"c_ulonglong",
	"c_ushort",
	"comptime_float",
	"comptime_int",
	"f128",
	"f16",
	"f32",
	"f64",
	"f80",
	"isize",
	"noreturn",
	"type",
	"usize",
	"void",
]

## Whether `word` names a primitive type: one of the list, or an integer type,
## `i` or `u` and then digits, as std.zig.primitives reads it.
is_primitive_type : Str -> Bool
is_primitive_type = |word| {
	bytes = word.to_utf8()
	first = Bytes.byte_at(bytes, 0)
	is_integer_type =
		bytes.len() >= 2
			and (first == 'i' or first == 'u')
			and bytes.drop_first(1).all(Bytes.is_digit)
	is_integer_type or primitive_types.contains(word)
}

## A word is plain after a `.`; else a keyword, a type, the name `fn`
## declares, or a plain name.
class_of : Token, Before -> Span.Class
class_of = |token, before| match token.kind {
	Space | Dot | Symbol => Plain
	Comment => Comment
	String => String
	Number => Number
	Builtin => Keyword
	QuotedName if before == FunctionKeyword => Name
	QuotedName => Plain
	Word(word) =>
		if before == Dot {
			Plain
		} else if is_primitive_type(word) {
			Type
		} else if keywords.contains(word) {
			Keyword
		} else if before == FunctionKeyword {
			Name
		} else {
			Plain
		}
}

## What the next token sees before it: space and comments leave it as it was.
next_before : Token, Before -> Before
next_before = |token, before| match token.kind {
	Space | Comment => before
	Dot => Dot
	Word(word) if word == "fn" and before != Dot => FunctionKeyword
	_ => Other
}

## The token that starts at `at`, which is below the length.
token_at : List(U8), U64 -> Token
token_at = |bytes, at| {
	byte = Bytes.byte_at(bytes, at)
	next = Bytes.byte_at(bytes, at + 1)
	if Bytes.is_space(byte) {
		{ kind: Space, end: at + 1 }
	} else if byte == '/' and next == '/' {
		{ kind: Comment, end: Bytes.line_end(bytes, at) }
	} else if byte == '\\' and next == '\\' {
		{ kind: String, end: Bytes.line_end(bytes, at) }
	} else if byte == '"' or byte == '\'' {
		{ kind: String, end: Bytes.quoted_end(bytes, { at: at + 1, quote: byte }) }
	} else if byte == '@' and next == '"' {
		{ kind: QuotedName, end: Bytes.quoted_end(bytes, { at: at + 2, quote: '"' }) }
	} else if byte == '@' and Bytes.is_ascii_word_start(next) {
		{ kind: Builtin, end: Bytes.run_end(bytes, { at: at + 1, keep: Bytes.is_ascii_word_byte }) }
	} else if Bytes.is_digit(byte) {
		{ kind: Number, end: number_end(bytes, at) }
	} else if Bytes.is_ascii_word_start(byte) {
		end = Bytes.run_end(bytes, { at, keep: Bytes.is_ascii_word_byte })
		word = Str.from_utf8(
			bytes.sublist({ start: at, len: end - at }),
		) ?? crash "ZigSyntax.token_at: a word is ASCII"
		{ kind: Word(word), end }
	} else if byte == '.' and next == '.' and Bytes.byte_at(bytes, at + 2) == '.' {
		{ kind: Symbol, end: at + 3 }
	} else if byte == '.' and next == '.' {
		{ kind: Symbol, end: at + 2 }
	} else if byte == '.' {
		{ kind: Dot, end: at + 1 }
	} else if byte >= 0x80 {
		{ kind: Symbol, end: Bytes.run_end(bytes, { at, keep: |run_byte| run_byte >= 0x80 }) }
	} else {
		{ kind: Symbol, end: at + 1 }
	}
}

## The end of the number whose first digit is at `at`, as Zig's tokenizer reads
## one: letters, digits and `_` run on (so `0x1F`, `0o17`, `0b1`, `1_000`, and a
## malformed `9abc` too), a `+` or `-` right after an exponent's `e`, `E`, `p`
## or `P` joins it, and so does one `.` with a letter or a digit after it. Past
## a fraction's `.` or an exponent's sign, a `.` ends the number, so `0..9` is
## two numbers and `1.5.x` stops before its second `.`.
number_end : List(U8), U64 -> U64
number_end = |bytes, at| {
	var $at = at + 1
	var $part = Whole
	var $end = bytes.len()
	while $at < bytes.len() {
		byte = Bytes.byte_at(bytes, $at)
		next = Bytes.byte_at(bytes, $at + 1)
		if is_exponent_mark(byte) and (next == '+' or next == '-') {
			$at = $at + 2
			$part = Fraction
		} else if Bytes.is_ascii_word_byte(byte) {
			$at = $at + 1
		} else if byte == '.' and $part == Whole and Bytes.is_ascii_word_byte(next) {
			$at = $at + 2
			$part = Fraction
		} else {
			$end = $at
			$at = bytes.len()
		}
	}
	$end
}

## An exponent's letter: `e` or `E` for a decimal number, `p` or `P` for a
## hexadecimal one. The tokenizer takes either in any base.
is_exponent_mark : U8 -> Bool
is_exponent_mark = |byte| byte == 'e' or byte == 'E' or byte == 'p' or byte == 'P'

## The runs of `text` that get a color, each with its class and its text: what
## the expects below read.
colored_spans : Str -> List((Span.Class, Str))
colored_spans = |text| {
	bytes = text.to_utf8()
	ZigSyntax.spans(text)
		.keep_if(|span| span.class != Plain)
		.map(
			|span| (
				span.class,
				Str.from_utf8(
					bytes.sublist({ start: span.start, len: span.end - span.start }),
				) ?? crash "ZigSyntax.colored_spans: a span ends inside a character",
			),
		)
}

expect ZigSyntax.spans("") == []

# Comments of every kind, a CR kept, a quote inside, and one at the very end.
expect colored_spans("//! a file\n/// a decl\r\n//// four\n// \"x\" 'y'\nx") == [
	(Comment, "//! a file"),
	(Comment, "/// a decl\r"),
	(Comment, "//// four"),
	(Comment, "// \"x\" 'y'"),
]
expect colored_spans("a / b //") == [(Comment, "//")]
expect colored_spans("a / b") == []

# Strings and characters, with escapes; one still open stops at its line's end
# or the text's, a backslash at the end included.
expect colored_spans("f(\"a\\\"b\\\\\", \"\\x41\\u{1F600}\\n\")") == [
	(String, "\"a\\\"b\\\\\""),
	(String, "\"\\x41\\u{1F600}\\n\""),
]
expect colored_spans("f('a', '\\'', '\\\\', '\\u{1F600}', 'é')") == [
	(String, "'a'"),
	(String, "'\\''"),
	(String, "'\\\\'"),
	(String, "'\\u{1F600}'"),
	(String, "'é'"),
]
expect colored_spans("x = \"ab\ny = 1") == [(String, "\"ab"), (Number, "1")]
expect colored_spans("x = 'a") == [(String, "'a")]
expect colored_spans("x = \"a\\") == [(String, "\"a\\")]

# A multiline string is a span a line, each to its line's end, whatever it
# holds; a lone backslash is plain.
expect colored_spans("const s =\n    \\\\a \"b\" // c\n    \\\\\n;") == [
	(Keyword, "const"),
	(String, "\\\\a \"b\" // c"),
	(String, "\\\\"),
]
expect colored_spans("x\\\\") == [(String, "\\\\")]
expect colored_spans("a \\ b \\") == []

# Numbers in every base, with separators, fractions, exponents and hex floats.
expect
	colored_spans("f(1, 1_000, 0x1F, 0xff_ff, 0o17, 0b1010, 1.5, 1e10, 1.5e-3, 2E+4, 0x1.8p3, 0x1p-3, 0x10P+1, 9abc)")
		== [
			(Number, "1"),
			(Number, "1_000"),
			(Number, "0x1F"),
			(Number, "0xff_ff"),
			(Number, "0o17"),
			(Number, "0b1010"),
			(Number, "1.5"),
			(Number, "1e10"),
			(Number, "1.5e-3"),
			(Number, "2E+4"),
			(Number, "0x1.8p3"),
			(Number, "0x1p-3"),
			(Number, "0x10P+1"),
			(Number, "9abc"),
		]

# A `.` joins a number once, and only with a letter or digit after it.
expect colored_spans("0..10 x[1..] 1.5.y 1e+5.3 1e5.3 a1") == [
	(Number, "0"),
	(Number, "10"),
	(Number, "1"),
	(Number, "1.5"),
	(Number, "1e+5"),
	(Number, "3"),
	(Number, "1e5.3"),
]

# Numbers that end partway: each is what the tokenizer took.
expect [
	"0x",
	"1e",
	"1e+",
	"1.5e",
	"0x1p-",
	"1_",
].all(|text| colored_spans(text) == [(Number, text)])
expect colored_spans("1.") == [(Number, "1")]
expect colored_spans("1e-x") == [(Number, "1e-x")]

# Every keyword, each its own span, and words that hold one or follow a dot.
expect
	"addrspace align allowzero and asm break callconv catch comptime const continue defer else enum errdefer error export extern false fn for if inline linksection noalias noinline nosuspend null opaque or orelse packed pub resume return struct suspend switch test threadlocal true try undefined union unreachable var volatile while"
		.split_on(" ")
		.all(|word| colored_spans(word) == [(Keyword, word)])
expect colored_spans("iffy fnord _fn const_x Fn TRUE async await usingnamespace") == []
expect colored_spans("x.type .bool info.true .{ .x = true } std.fn") == [(Keyword, "true")]
expect colored_spans("a[1..] orelse b") == [(Number, "1"), (Keyword, "orelse")]
expect colored_spans("'a'...'z' => true, 0...9") == [
	(String, "'a'"),
	(String, "'z'"),
	(Keyword, "true"),
	(Number, "0"),
	(Number, "9"),
]

# The primitive types, the integer types at any width, and near misses.
expect
	"u8 i32 u0 i65535 usize isize bool void type anytype anyframe anyerror anyopaque noreturn f16 f32 f64 f80 f128 comptime_int comptime_float c_char c_short c_ushort c_int c_uint c_long c_ulong c_longlong c_ulonglong c_longdouble"
		.split_on(" ")
		.all(|word| colored_spans(word) == [(Type, word)])
expect colored_spans("u i u8x U8 ux8 _u8 c_bool f8x") == []

# Builtins are keywords; a `@` with no name after it is plain.
expect colored_spans("@import(\"std\") @as(u8, 1) @This()") == [
	(Keyword, "@import"),
	(String, "\"std\""),
	(Keyword, "@as"),
	(Type, "u8"),
	(Number, "1"),
	(Keyword, "@This"),
]
expect colored_spans("@ x @1 @") == [(Number, "1")]

# A quoted identifier is a plain name, one span, even when it spells a keyword;
# one still open stops at its line's end.
expect colored_spans("const @\"a b\" = @\"if\" + @\"a\\\"b\";") == [(Keyword, "const")]
expect colored_spans("x = @\"ab\nfn") == [(Keyword, "fn")]

# The name `fn` declares, past space and a comment, a quoted one too; a type
# after `fn` is still a type, and a call is no name.
expect colored_spans("pub fn main() void {}") == [
	(Keyword, "pub"),
	(Keyword, "fn"),
	(Name, "main"),
	(Type, "void"),
]
expect colored_spans("fn // c\n  f() void { return f(); }") == [
	(Keyword, "fn"),
	(Comment, "// c"),
	(Name, "f"),
	(Type, "void"),
	(Keyword, "return"),
]
expect colored_spans("fn @\"my fn\"() void") == [
	(Keyword, "fn"),
	(Name, "@\"my fn\""),
	(Type, "void"),
]
expect colored_spans("const F = *const fn (u8) bool;") == [
	(Keyword, "const"),
	(Keyword, "const"),
	(Keyword, "fn"),
	(Type, "u8"),
	(Type, "bool"),
]
expect colored_spans("fn u8") == [(Keyword, "fn"), (Type, "u8")]
expect colored_spans("fn") == [(Keyword, "fn")]
expect colored_spans("+ - * / % = == != < <= > >= ( ) { } [ ] , ; : ! ? & | ^ ~ # $ ` é") == []
