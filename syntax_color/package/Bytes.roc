## Bytes holds the byte-level reads every lexer here makes the same way: a
## byte by index, a run of bytes a test keeps, a line's end, and the classes
## of an ASCII byte. Each lexer's own rules (what a word, a number or a string
## is in its language) stay in its own module.
Bytes :: [].{

	## The byte at `at`, or 0 past the end, which no lexer's rule takes.
	byte_at : List(U8), U64 -> U8
	byte_at = |bytes, at| bytes.get(at) ?? 0

	## The index of the first byte at or after `at` that `keep` refuses, or the
	## length.
	run_end : List(U8), { at : U64, keep : U8 -> Bool } -> U64
	run_end = |bytes, { at, keep }| {
		var $at = at
		while $at < bytes.len() and keep(Bytes.byte_at(bytes, $at)) {
			$at = $at + 1
		}
		$at
	}

	## The index of the newline at or after `at`, or the length.
	line_end : List(U8), U64 -> U64
	line_end = |bytes, at| Bytes.run_end(bytes, { at, keep: |b| b != '\n' })

	## The end of a string quoted by `quote` whose text starts at `at`: just past
	## the closing quote, or where its line or the text ends. A backslash keeps
	## the byte after it in the string, unless that is a newline. Roc's
	## characters and Shale's strings both read this way.
	quoted_end : List(U8), { at : U64, quote : U8 } -> U64
	quoted_end = |bytes, { at, quote }| {
		var $at = at
		var $end = bytes.len()
		while $at < bytes.len() {
			byte = Bytes.byte_at(bytes, $at)
			if byte == quote {
				$end = $at + 1
				$at = bytes.len()
			} else if byte == '\n' {
				$end = $at
				$at = bytes.len()
			} else if byte == '\\' and $at + 1 < bytes.len() and Bytes.byte_at(
				bytes,
				$at + 1,
			) != '\n' {
				$at = $at + 2
			} else {
				$at = $at + 1
			}
		}
		$end
	}

	is_digit : U8 -> Bool
	is_digit = |b| b >= '0' and b <= '9'

	## An ASCII letter, a digit or `_`: a byte of a word in Roc and in Shale.
	is_ascii_word_byte : U8 -> Bool
	is_ascii_word_byte = |b|
		(b >= 'a' and b <= 'z')
			or (b >= 'A' and b <= 'Z')
			or Bytes.is_digit(b)
			or b == '_'
}

expect Bytes.byte_at([1, 2], 1) == 2
expect Bytes.byte_at([1, 2], 2) == 0
expect Bytes.run_end([1, 1, 2], { at: 0, keep: |b| b == 1 }) == 2
expect Bytes.run_end([1, 1], { at: 0, keep: |b| b == 1 }) == 2
expect Bytes.line_end("ab\nc".to_utf8(), 0) == 2
expect Bytes.line_end("ab".to_utf8(), 1) == 2
expect Bytes.quoted_end("a\\'b'c".to_utf8(), { at: 0, quote: '\'' }) == 5
expect Bytes.quoted_end("ab\nc'".to_utf8(), { at: 0, quote: '\'' }) == 2
expect Bytes.quoted_end("a\\".to_utf8(), { at: 0, quote: '\'' }) == 2
expect Bytes.quoted_end("a\\\nb'".to_utf8(), { at: 0, quote: '\'' }) == 2
expect ['0', '9'].all(Bytes.is_digit) and !['/', ':', 'a'].any(Bytes.is_digit)
expect [
	'a',
	'z',
	'A',
	'Z',
	'0',
	'_',
].all(Bytes.is_ascii_word_byte) and ![' ', '$', '!', 0xC3].any(Bytes.is_ascii_word_byte)
