## This module turns a JavaScript program's text into tokens, each with the
## line and column it starts at, so the parser can say where a mistake is.
##
## A template literal is split into pieces at its substitutions: `a${x}b`
## becomes a head (`a`), the tokens of `x`, and a tail (`b`). The lexer keeps a
## stack of the brace depths at which each open substitution started, so the
## `}` that closes a substitution is told from one that closes a block inside
## it.
##
## A NUL byte is refused before lexing starts, so `byte_at` can answer 0 past
## the end of the text and mean only that.
Lexer :: [].{
	Tok : [
		Number(F64),
		Text(Str),
		Name(Str),
		Punct(Str),
		# A template with no substitution, then the three pieces of one with.
		TemplateWhole(Str),
		TemplateHead(Str),
		TemplateMiddle(Str),
		TemplateTail(Str),
		End,
	]

	# Whether a line break comes before the token: the parser's semicolon
	# insertion and its restricted productions (`return`, a postfix `++`) ask.
	Break : [SameLine, NewLine]

	Token : {
		tok : Lexer.Tok,
		line : U64,
		col : U64,
		before : Lexer.Break,
	}

	Fault : { why : Str, line : U64, col : U64 }

	# The state of the scan: where it is, the tokens so far, and the brace
	# depths of the open template substitutions.
	Scan : {
		at : U64,
		line : U64,
		line_start : U64,
		depth : U64,
		open_templates : List(U64),
		tokens : List(Lexer.Token),
		before : Lexer.Break,
	}

	tokens_of : Str -> Try(List(Lexer.Token), Lexer.Fault)
	tokens_of = |text| {
		src = text.to_utf8()
		if src.contains(0) {
			return Err({ why: "a NUL byte in the source", line: 1, col: 1 })
		}
		var $s = {
			at: 0,
			line: 1,
			line_start: 0,
			depth: 0,
			open_templates: [],
			tokens: [],
			before: NewLine,
		}
		while $s.at < src.len() {
			$s = Lexer.scan_one(src, $s)?
		}
		end = {
			tok: End,
			line: $s.line,
			col: $s.at - $s.line_start + 1,
			before: NewLine,
		}
		Ok($s.tokens.append(end))
	}

	byte_at : List(U8), U64 -> U8
	byte_at = |src, i| src.get(i) ?? 0

	fault_at : Lexer.Scan, Str -> Lexer.Fault
	fault_at = |s, why| { why: why, line: s.line, col: s.at - s.line_start + 1 }

	# The scan past one token, a run of space or one comment.
	scan_one : List(U8), Lexer.Scan -> Try(Lexer.Scan, Lexer.Fault)
	scan_one = |src, s| {
		c = Lexer.byte_at(src, s.at)
		next = Lexer.byte_at(src, s.at + 1)
		if c == '\n' {
			Ok({ ..s, at: s.at + 1, line: s.line + 1, line_start: s.at + 1, before: NewLine })
		} else if c == ' ' or c == '\t' or c == '\r' {
			Ok({ ..s, at: s.at + 1 })
		} else if c == '/' and next == '/' {
			Ok({ ..s, at: Lexer.line_end(src, s.at) })
		} else if c == '/' and next == '*' {
			Lexer.past_block_comment(src, s)
		} else if Lexer.is_digit(c) or (c == '.' and Lexer.is_digit(next)) {
			Lexer.scan_number(src, s)
		} else if Lexer.is_name_start(c) {
			Ok(Lexer.scan_name(src, s))
		} else if c == '"' or c == '\'' {
			Lexer.scan_string(src, s, c)
		} else if c == '`' {
			Lexer.scan_template(src, { ..s, at: s.at + 1 }, s, Head)
		} else if c == '}' {
			Lexer.scan_close_brace(src, s)
		} else if c >= 128 {
			Err(Lexer.fault_at(s, "unsupported: a non-ASCII character outside a string"))
		} else {
			Lexer.scan_punct(src, s)
		}
	}

	line_end : List(U8), U64 -> U64
	line_end = |src, from| {
		var $i = from
		while $i < src.len() and Lexer.byte_at(src, $i) != '\n' {
			$i = $i + 1
		}
		$i
	}

	past_block_comment : List(U8), Lexer.Scan -> Try(Lexer.Scan, Lexer.Fault)
	past_block_comment = |src, s| {
		var $i = s.at + 2
		var $line = s.line
		var $line_start = s.line_start
		var $before = s.before
		while $i < src.len() and !(
			Lexer.byte_at(src, $i) == '*' and Lexer.byte_at(
				src,
				$i + 1,
			) == '/'
		) {
			if Lexer.byte_at(src, $i) == '\n' {
				$line = $line + 1
				$line_start = $i + 1
				$before = NewLine
			}
			$i = $i + 1
		}
		if $i >= src.len() {
			Err(Lexer.fault_at(s, "a comment that never ends"))
		} else {
			Ok({ ..s, at: $i + 2, line: $line, line_start: $line_start, before: $before })
		}
	}

	is_digit : U8 -> Bool
	is_digit = |c| c >= '0' and c <= '9'

	is_name_start : U8 -> Bool
	is_name_start = |c| (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_' or c == '$'

	is_name_part : U8 -> Bool
	is_name_part = |c| Lexer.is_name_start(c) or Lexer.is_digit(c)

	# The scan with one more token, which started at `from`.
	with_token : Lexer.Scan, Lexer.Tok, U64 -> Lexer.Scan
	with_token = |s, tok, from| {
		token = {
			tok: tok,
			line: s.line,
			col: from - s.line_start + 1,
			before: s.before,
		}
		{ ..s, tokens: s.tokens.append(token), before: SameLine }
	}

	text_between : List(U8), U64, U64 -> Str
	text_between = |src, from, to| Str.from_utf8(
		src.sublist({
			start: from,
			len: to - from,
		}),
	) ?? crash "Lexer.text_between: a cut inside a character"

	scan_name : List(U8), Lexer.Scan -> Lexer.Scan
	scan_name = |src, s| {
		var $i = s.at
		while Lexer.is_name_part(Lexer.byte_at(src, $i)) {
			$i = $i + 1
		}
		{ ..Lexer.with_token(s, Name(Lexer.text_between(src, s.at, $i)), s.at), at: $i }
	}

	scan_number : List(U8), Lexer.Scan -> Try(Lexer.Scan, Lexer.Fault)
	scan_number = |src, s| {
		c = Lexer.byte_at(src, s.at)
		next = Lexer.byte_at(src, s.at + 1)
		if c == '0' and (next == 'x' or next == 'X') {
			Lexer.scan_hex(src, s)
		} else if c == '0' and (Lexer.is_digit(next) or next == 'b' or next == 'B' or next == 'o' or next == 'O') {
			Err(Lexer.fault_at(s, "unsupported: an octal or binary number"))
		} else {
			var $i = s.at
			while Lexer.is_digit(Lexer.byte_at(src, $i)) {
				$i = $i + 1
			}
			if Lexer.byte_at(src, $i) == '.' {
				$i = $i + 1
				while Lexer.is_digit(Lexer.byte_at(src, $i)) {
					$i = $i + 1
				}
			}
			e = Lexer.byte_at(src, $i)
			if e == 'e' or e == 'E' {
				$i = $i + 1
				sign = Lexer.byte_at(src, $i)
				if sign == '+' or sign == '-' {
					$i = $i + 1
				}
				if !Lexer.is_digit(Lexer.byte_at(src, $i)) {
					return Err(Lexer.fault_at(s, "a number whose exponent has no digits"))
				}
				while Lexer.is_digit(Lexer.byte_at(src, $i)) {
					$i = $i + 1
				}
			}
			after = Lexer.byte_at(src, $i)
			if after == '_' or after == 'n' {
				Err(Lexer.fault_at(s, "unsupported: a numeric separator or a BigInt"))
			} else if Lexer.is_name_start(after) {
				Err(Lexer.fault_at(s, "a name straight after a number"))
			} else {
				digits = Lexer.text_between(src, s.at, $i)
				# A literal that starts with `.` is read with a 0 before it.
				spelled = if c == '.' {
					"0${digits}"
				} else {
					digits
				}
				match F64.from_str(spelled) {
					Ok(n) => Ok({ ..Lexer.with_token(s, Number(n), s.at), at: $i })
					Err(_) => Err(Lexer.fault_at(s, "a number that does not read: ${digits}"))
				}
			}
		}
	}

	scan_hex : List(U8), Lexer.Scan -> Try(Lexer.Scan, Lexer.Fault)
	scan_hex = |src, s| {
		var $i = s.at + 2
		var $n = 0.0
		while Lexer.hex_value(Lexer.byte_at(src, $i)) < 16 {
			$n = $n * 16.0 + Lexer.hex_value(Lexer.byte_at(src, $i)).to_f64()
			$i = $i + 1
		}
		if $i == s.at + 2 {
			Err(Lexer.fault_at(s, "a hexadecimal number with no digits"))
		} else {
			Ok({ ..Lexer.with_token(s, Number($n), s.at), at: $i })
		}
	}

	# A hexadecimal digit's value, or 16 for a byte that is none.
	hex_value : U8 -> U8
	hex_value = |c|
		if Lexer.is_digit(c) {
			c - '0'
		} else if c >= 'a' and c <= 'f' {
			c - 'a' + 10
		} else if c >= 'A' and c <= 'F' {
			c - 'A' + 10
		} else {
			16
		}

	# One escape after a backslash at `at`: the bytes it stands for and where
	# the text goes on.
	Escape : { bytes : List(U8), next : U64 }

	escape_at : List(U8), Lexer.Scan, U64 -> Try(Lexer.Escape, Lexer.Fault)
	escape_at = |src, s, at| {
		c = Lexer.byte_at(src, at + 1)
		simple = |b| Ok({ bytes: [b], next: at + 2 })
		match c {
			'n' => simple('\n')
			't' => simple('\t')
			'r' => simple('\r')
			'b' => simple(8)
			'f' => simple(12)
			'v' => simple(11)
			'0' => if Lexer.is_digit(Lexer.byte_at(src, at + 2)) {
				Err(Lexer.fault_at(s, "unsupported: an octal escape"))
			} else {
				simple(0)
			}
			'x' => {
				hi = Lexer.hex_value(Lexer.byte_at(src, at + 2))
				lo = Lexer.hex_value(Lexer.byte_at(src, at + 3))
				if hi > 15 or lo > 15 {
					Err(Lexer.fault_at(s, "a \\x escape without two hexadecimal digits"))
				} else {
					Ok({ bytes: Lexer.utf8_of(hi.to_u32() * 16 + lo.to_u32()), next: at + 4 })
				}
			}
			'u' => Lexer.unicode_escape(src, s, at)
			'\n' => Ok({ bytes: [], next: at + 2 })
			_ => if c == 0 {
				Err(Lexer.fault_at(s, "a string that never ends"))
			} else {
				simple(c)
			}
		}
	}

	unicode_escape : List(U8), Lexer.Scan, U64 -> Try(Lexer.Escape, Lexer.Fault)
	unicode_escape = |src, s, at| {
		var $code = 0
		var $ok = True
		for k in [2, 3, 4, 5] {
			d = Lexer.hex_value(Lexer.byte_at(src, at + k))
			if d > 15 {
				$ok = False
			} else {
				$code = $code * 16 + d.to_u32()
			}
		}
		if !$ok {
			Err(Lexer.fault_at(s, "unsupported: a \\u escape other than four hexadecimal digits"))
		} else if $code >= 0xD800 and $code <= 0xDFFF {
			Err(Lexer.fault_at(s, "unsupported: a \\u escape of half a surrogate pair"))
		} else {
			Ok({ bytes: Lexer.utf8_of($code), next: at + 6 })
		}
	}

	# A code point below 0x10000 as UTF-8.
	utf8_of : U32 -> List(U8)
	utf8_of = |code|
		if code < 0x80 {
			[code.to_u8_wrap()]
		} else if code < 0x800 {
			[(0xC0 + code.div_trunc_by(64)).to_u8_wrap(), (0x80 + code.rem_by(64)).to_u8_wrap()]
		} else {
			[
				(0xE0 + code.div_trunc_by(4096)).to_u8_wrap(),
				(0x80 + code.div_trunc_by(64).rem_by(64)).to_u8_wrap(),
				(0x80 + code.rem_by(64)).to_u8_wrap(),
			]
		}

	scan_string : List(U8), Lexer.Scan, U8 -> Try(Lexer.Scan, Lexer.Fault)
	scan_string = |src, s, quote| {
		var $i = s.at + 1
		var $out = []
		while Lexer.byte_at(src, $i) != quote {
			c = Lexer.byte_at(src, $i)
			if c == 0 or c == '\n' {
				return Err(Lexer.fault_at(s, "a string that never ends"))
			} else if c == '\\' {
				e = Lexer.escape_at(src, s, $i)?
				$out = List.concat($out, e.bytes)
				$i = e.next
			} else {
				$out = $out.append(c)
				$i = $i + 1
			}
		}
		text = Str.from_utf8($out) ?? crash "Lexer.scan_string: escapes write whole characters"
		Ok({ ..Lexer.with_token(s, Text(text), s.at), at: $i + 1 })
	}

	# Where a template's text piece starts; the piece's kind follows from it
	# and from how the piece ends.
	Piece : [Head, Middle]

	# A template's text from `s.at` to the next `${` or closing backtick.
	# `start` is the scan where the piece's token is said to start.
	scan_template : List(U8), Lexer.Scan, Lexer.Scan, Lexer.Piece -> Try(Lexer.Scan, Lexer.Fault)
	scan_template = |src, s, start, piece| {
		var $i = s.at
		var $out = []
		var $line = s.line
		var $line_start = s.line_start
		while Lexer.byte_at(src, $i) != '`' and !(
			Lexer.byte_at(src, $i) == '$' and Lexer.byte_at(
				src,
				$i + 1,
			) == '{'
		) {
			c = Lexer.byte_at(src, $i)
			if c == 0 {
				return Err(Lexer.fault_at(start, "a template literal that never ends"))
			} else if c == '\\' {
				e = Lexer.escape_at(src, s, $i)?
				$out = List.concat($out, e.bytes)
				$i = e.next
			} else {
				if c == '\n' {
					$line = $line + 1
					$line_start = $i + 1
				}
				$out = $out.append(c)
				$i = $i + 1
			}
		}
		text = Str.from_utf8($out) ?? crash "Lexer.scan_template: escapes write whole characters"
		closes = Lexer.byte_at(src, $i) == '`'
		tok = match piece {
			Head => if closes {
				TemplateWhole(text)
			} else {
				TemplateHead(text)
			}
			Middle => if closes {
				TemplateTail(text)
			} else {
				TemplateMiddle(text)
			}
		}
		made = Lexer.with_token(start, tok, start.at)
		opened = if closes {
			made.open_templates
		} else {
			made.open_templates.append(made.depth)
		}
		after = if closes {
			$i + 1
		} else {
			$i + 2
		}
		Ok({ ..made, at: after, line: $line, line_start: $line_start, open_templates: opened })
	}

	punctuators : List(Str)
	punctuators = [
		"===",
		"!==",
		"**=",
		"...",
		"<<=",
		">>=",
		">>>",
		"&&=",
		"||=",
		"??=",
		"=>",
		"==",
		"!=",
		"<=",
		">=",
		"&&",
		"||",
		"??",
		"?.",
		"++",
		"--",
		"+=",
		"-=",
		"*=",
		"/=",
		"%=",
		"**",
		"<<",
		">>",
		"&=",
		"|=",
		"^=",
		"{",
		"(",
		")",
		"[",
		"]",
		";",
		",",
		"<",
		">",
		"+",
		"-",
		"*",
		"/",
		"%",
		"!",
		"=",
		".",
		":",
		"?",
		"&",
		"|",
		"^",
		"~",
		"@",
		"#",
	]

	scan_punct : List(U8), Lexer.Scan -> Try(Lexer.Scan, Lexer.Fault)
	scan_punct = |src, s| {
		rest = src.sublist({ start: s.at, len: 3 })
		match Lexer.punctuators.find_first(|p| rest.starts_with(p.to_utf8())) {
			Ok(p) => {
				made = Lexer.with_token(s, Punct(p), s.at)
				opened = if p == "{" {
					made.depth + 1
				} else {
					made.depth
				}
				Ok({ ..made, at: s.at + p.count_utf8_bytes(), depth: opened })
			}
			Err(NotFound) => Err(
				Lexer.fault_at(
					s,
					"a character the language has no use for: ${Lexer.text_between(src, s.at, s.at + 1)}",
				),
			)
		}
	}
	# A `}` closes a template's substitution when the brace depth is back where
	# the substitution opened; otherwise it closes a brace of the code.
	scan_close_brace : List(U8), Lexer.Scan -> Try(Lexer.Scan, Lexer.Fault)
	scan_close_brace = |src, s| {
		closes_substitution = match s.open_templates.last() {
			Ok(d) => d == s.depth
			Err(ListWasEmpty) => False
		}
		if closes_substitution {
			popped = { ..s, open_templates: s.open_templates.drop_last(1) }
			Lexer.scan_template(src, { ..popped, at: s.at + 1 }, popped, Middle)
		} else {
			made = Lexer.with_token(s, Punct("}"), s.at)
			Ok({ ..made, at: s.at + 1, depth: made.depth.minus_saturated(1) })
		}
	}
}
