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
	TokenKind : [
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
		kind : Lexer.TokenKind,
		line : U64,
		column : U64,
		before : Lexer.Break,
	}

	Fault : {
		why : Str,
		line : U64,
		column : U64,
	}

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
			return Err({
				why: "a NUL byte in the source",
				line: 1,
				column: 1,
			})
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
			kind: End,
			line: $s.line,
			column: $s.at - $s.line_start + 1,
			before: NewLine,
		}
		Ok($s.tokens.append(end))
	}

	byte_at : List(U8), U64 -> U8
	byte_at = |src, position| src.get(position) ?? 0

	fault_at : Lexer.Scan, Str -> Lexer.Fault
	fault_at = |scanner, why| {
		why: why,
		line: scanner.line,
		column: scanner.at - scanner.line_start + 1,
	}

	# The scan past one token, a run of space or one comment.
	scan_one : List(U8), Lexer.Scan -> Try(Lexer.Scan, Lexer.Fault)
	scan_one = |src, scanner| {
		byte = Lexer.byte_at(src, scanner.at)
		next = Lexer.byte_at(src, scanner.at + 1)
		if byte == '\n' {
			Ok({
				..scanner,
				at: scanner.at + 1,
				line: scanner.line + 1,
				line_start: scanner.at + 1,
				before: NewLine,
			})
		} else if byte == ' ' or byte == '\t' or byte == '\r' {
			Ok({ ..scanner, at: scanner.at + 1 })
		} else if byte == '/' and next == '/' {
			Ok({ ..scanner, at: Lexer.line_end(src, scanner.at) })
		} else if byte == '/' and next == '*' {
			Lexer.past_block_comment(src, scanner)
		} else if Lexer.is_digit(byte) or (byte == '.' and Lexer.is_digit(next)) {
			Lexer.scan_number(src, scanner)
		} else if Lexer.is_name_start(byte) {
			Ok(Lexer.scan_name(src, scanner))
		} else if byte == '"' or byte == '\'' {
			Lexer.scan_string(src, scanner, byte)
		} else if byte == '`' {
			Lexer.scan_template(
				src,
				{ ..scanner, at: scanner.at + 1 },
				scanner,
				Head,
			)
		} else if byte == '}' {
			Lexer.scan_close_brace(src, scanner)
		} else if byte >= 128 {
			Err(Lexer.fault_at(scanner, "unsupported: a non-ASCII character outside a string"))
		} else {
			Lexer.scan_punct(src, scanner)
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
	past_block_comment = |src, scanner| {
		var $i = scanner.at + 2
		var $line = scanner.line
		var $line_start = scanner.line_start
		var $before = scanner.before
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
			Err(Lexer.fault_at(scanner, "a comment that never ends"))
		} else {
			Ok({
				..scanner,
				at: $i + 2,
				line: $line,
				line_start: $line_start,
				before: $before,
			})
		}
	}

	is_digit : U8 -> Bool
	is_digit = |byte| byte >= '0' and byte <= '9'

	is_name_start : U8 -> Bool
	is_name_start = |byte| (byte >= 'a' and byte <= 'z') or (byte >= 'A' and byte <= 'Z') or byte == '_' or byte == '$'

	is_name_part : U8 -> Bool
	is_name_part = |byte| Lexer.is_name_start(byte) or Lexer.is_digit(byte)

	# The scan with one more token, which started at `from`.
	with_token : Lexer.Scan, Lexer.TokenKind, U64 -> Lexer.Scan
	with_token = |scanner, kind, from| {
		token = {
			kind: kind,
			line: scanner.line,
			column: from - scanner.line_start + 1,
			before: scanner.before,
		}
		{
			..scanner,
			tokens: scanner.tokens.append(token),
			before: SameLine,
		}
	}

	text_between : List(U8), U64, U64 -> Str
	text_between = |src, from, to| Str.from_utf8(
		src.sublist({ start: from, len: to - from }),
	) ?? crash "Lexer.text_between: a cut inside a character"

	scan_name : List(U8), Lexer.Scan -> Lexer.Scan
	scan_name = |src, scanner| {
		var $i = scanner.at
		while Lexer.is_name_part(Lexer.byte_at(src, $i)) {
			$i = $i + 1
		}
		{ ..Lexer.with_token(
			scanner,
			Name(Lexer.text_between(src, scanner.at, $i)),
			scanner.at,
		), at: $i }
	}

	scan_number : List(U8), Lexer.Scan -> Try(Lexer.Scan, Lexer.Fault)
	scan_number = |src, scanner| {
		byte = Lexer.byte_at(src, scanner.at)
		next = Lexer.byte_at(src, scanner.at + 1)
		if byte == '0' and (next == 'x' or next == 'X') {
			Lexer.scan_hex(src, scanner)
		} else if byte == '0' and (Lexer.is_digit(next) or next == 'b' or next == 'B' or next == 'o' or next == 'O') {
			Err(Lexer.fault_at(scanner, "unsupported: an octal or binary number"))
		} else {
			var $i = scanner.at
			while Lexer.is_digit(Lexer.byte_at(src, $i)) {
				$i = $i + 1
			}
			if Lexer.byte_at(src, $i) == '.' {
				$i = $i + 1
				while Lexer.is_digit(Lexer.byte_at(src, $i)) {
					$i = $i + 1
				}
			}
			exponent_mark = Lexer.byte_at(src, $i)
			if exponent_mark == 'e' or exponent_mark == 'E' {
				$i = $i + 1
				sign = Lexer.byte_at(src, $i)
				if sign == '+' or sign == '-' {
					$i = $i + 1
				}
				if !Lexer.is_digit(Lexer.byte_at(src, $i)) {
					return Err(Lexer.fault_at(scanner, "a number whose exponent has no digits"))
				}
				while Lexer.is_digit(Lexer.byte_at(src, $i)) {
					$i = $i + 1
				}
			}
			after = Lexer.byte_at(src, $i)
			if after == '_' or after == 'n' {
				Err(Lexer.fault_at(scanner, "unsupported: a numeric separator or a BigInt"))
			} else if Lexer.is_name_start(after) {
				Err(Lexer.fault_at(scanner, "a name straight after a number"))
			} else {
				digits = Lexer.text_between(src, scanner.at, $i)
				# A literal that starts with `.` is read with a 0 before it.
				spelled = if byte == '.' {
					"0${digits}"
				} else {
					digits
				}
				match F64.from_str(spelled) {
					Ok(number) => Ok({ ..Lexer.with_token(scanner, Number(number), scanner.at), at: $i })
					Err(_) => Err(Lexer.fault_at(scanner, "a number that does not read: ${digits}"))
				}
			}
		}
	}

	scan_hex : List(U8), Lexer.Scan -> Try(Lexer.Scan, Lexer.Fault)
	scan_hex = |src, scanner| {
		var $i = scanner.at + 2
		var $n = 0.0
		while Lexer.hex_value(Lexer.byte_at(src, $i)) < 16 {
			$n = $n * 16.0 + Lexer.hex_value(Lexer.byte_at(src, $i)).to_f64()
			$i = $i + 1
		}
		if $i == scanner.at + 2 {
			Err(Lexer.fault_at(scanner, "a hexadecimal number with no digits"))
		} else {
			Ok({ ..Lexer.with_token(scanner, Number($n), scanner.at), at: $i })
		}
	}

	# A hexadecimal digit's value, or 16 for a byte that is none.
	hex_value : U8 -> U8
	hex_value = |byte|
		if Lexer.is_digit(byte) {
			byte - '0'
		} else if byte >= 'a' and byte <= 'f' {
			byte - 'a' + 10
		} else if byte >= 'A' and byte <= 'F' {
			byte - 'A' + 10
		} else {
			16
		}

	# One escape after a backslash at `at`: the bytes it stands for and where
	# the text goes on.
	Escape : { bytes : List(U8), next : U64 }

	escape_at : List(U8), Lexer.Scan, U64 -> Try(Lexer.Escape, Lexer.Fault)
	escape_at = |src, scanner, at| {
		byte = Lexer.byte_at(src, at + 1)
		simple = |single| Ok({ bytes: [single], next: at + 2 })
		match byte {
			'n' => simple('\n')
			't' => simple('\t')
			'r' => simple('\r')
			'b' => simple(8)
			'f' => simple(12)
			'v' => simple(11)
			'0' => if Lexer.is_digit(Lexer.byte_at(src, at + 2)) {
				Err(Lexer.fault_at(scanner, "unsupported: an octal escape"))
			} else {
				simple(0)
			}
			'x' => {
				high = Lexer.hex_value(Lexer.byte_at(src, at + 2))
				low = Lexer.hex_value(Lexer.byte_at(src, at + 3))
				if high > 15 or low > 15 {
					Err(Lexer.fault_at(scanner, "a \\x escape without two hexadecimal digits"))
				} else {
					Ok({ bytes: Lexer.utf8_of(high.to_u32() * 16 + low.to_u32()), next: at + 4 })
				}
			}
			'u' => Lexer.unicode_escape(src, scanner, at)
			'\n' => Ok({ bytes: [], next: at + 2 })
			_ => if byte == 0 {
				Err(Lexer.fault_at(scanner, "a string that never ends"))
			} else {
				simple(byte)
			}
		}
	}

	unicode_escape : List(U8), Lexer.Scan, U64 -> Try(Lexer.Escape, Lexer.Fault)
	unicode_escape = |src, scanner, at| {
		var $code = 0
		var $ok = True
		for k in [2, 3, 4, 5] {
			digit = Lexer.hex_value(Lexer.byte_at(src, at + k))
			if digit > 15 {
				$ok = False
			} else {
				$code = $code * 16 + digit.to_u32()
			}
		}
		if !$ok {
			Err(Lexer.fault_at(scanner, "unsupported: a \\u escape other than four hexadecimal digits"))
		} else if $code >= 0xD800 and $code <= 0xDFFF {
			Err(Lexer.fault_at(scanner, "unsupported: a \\u escape of half a surrogate pair"))
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
	scan_string = |src, scanner, quote| {
		var $i = scanner.at + 1
		var $out = []
		while Lexer.byte_at(src, $i) != quote {
			byte = Lexer.byte_at(src, $i)
			if byte == 0 or byte == '\n' {
				return Err(Lexer.fault_at(scanner, "a string that never ends"))
			} else if byte == '\\' {
				escaped = Lexer.escape_at(src, scanner, $i)?
				$out = List.concat($out, escaped.bytes)
				$i = escaped.next
			} else {
				$out = $out.append(byte)
				$i = $i + 1
			}
		}
		text = Str.from_utf8($out) ?? crash "Lexer.scan_string: escapes write whole characters"
		Ok({ ..Lexer.with_token(scanner, Text(text), scanner.at), at: $i + 1 })
	}

	# Where a template's text piece starts; the piece's kind follows from it
	# and from how the piece ends.
	Piece : [Head, Middle]

	# A template's text from `s.at` to the next `${` or closing backtick.
	# `start` is the scan where the piece's token is said to start.
	scan_template : List(U8), Lexer.Scan, Lexer.Scan, Lexer.Piece -> Try(Lexer.Scan, Lexer.Fault)
	scan_template = |src, scanner, start, piece| {
		var $i = scanner.at
		var $out = []
		var $line = scanner.line
		var $line_start = scanner.line_start
		while Lexer.byte_at(src, $i) != '`' and !(
			Lexer.byte_at(src, $i) == '$' and Lexer.byte_at(
				src,
				$i + 1,
			) == '{'
		) {
			byte = Lexer.byte_at(src, $i)
			if byte == 0 {
				return Err(Lexer.fault_at(start, "a template literal that never ends"))
			} else if byte == '\\' {
				escaped = Lexer.escape_at(src, scanner, $i)?
				$out = List.concat($out, escaped.bytes)
				$i = escaped.next
			} else {
				if byte == '\n' {
					$line = $line + 1
					$line_start = $i + 1
				}
				$out = $out.append(byte)
				$i = $i + 1
			}
		}
		text = Str.from_utf8($out) ?? crash "Lexer.scan_template: escapes write whole characters"
		closes = Lexer.byte_at(src, $i) == '`'
		kind = match piece {
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
		made = Lexer.with_token(start, kind, start.at)
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
		Ok({
			..made,
			at: after,
			line: $line,
			line_start: $line_start,
			open_templates: opened,
		})
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
	scan_punct = |src, scanner| {
		rest = src.sublist({ start: scanner.at, len: 3 })
		match Lexer.punctuators.find_first(|punctuator| rest.starts_with(punctuator.to_utf8())) {
			Ok(punctuator) => {
				made = Lexer.with_token(scanner, Punct(punctuator), scanner.at)
				opened = if punctuator == "{" {
					made.depth + 1
				} else {
					made.depth
				}
				Ok({
					..made,
					at: scanner.at + punctuator.count_utf8_bytes(),
					depth: opened,
				})
			}
			Err(NotFound) => Err(
				Lexer.fault_at(
					scanner,
					"a character the language has no use for: ${Lexer.text_between(src, scanner.at, scanner.at + 1)}",
				),
			)
		}
	}
	# A `}` closes a template's substitution when the brace depth is back where
	# the substitution opened; otherwise it closes a brace of the code.
	scan_close_brace : List(U8), Lexer.Scan -> Try(Lexer.Scan, Lexer.Fault)
	scan_close_brace = |src, scanner| {
		closes_substitution = match scanner.open_templates.last() {
			Ok(open_depth) => open_depth == scanner.depth
			Err(ListWasEmpty) => False
		}
		if closes_substitution {
			popped = { ..scanner, open_templates: scanner.open_templates.drop_last(1) }
			Lexer.scan_template(
				src,
				{ ..popped, at: scanner.at + 1 },
				popped,
				Middle,
			)
		} else {
			made = Lexer.with_token(scanner, Punct("}"), scanner.at)
			Ok({
				..made,
				at: scanner.at + 1,
				depth: made.depth.minus_saturated(1),
			})
		}
	}
}
