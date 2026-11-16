## A term in a book's index is found by its patterns, each a regular
## expression over a lowercased line of prose, as Shale's `re_find` reads one.
## Roc has no regular expressions, so this module is the subset an index's
## terms use: a byte, `.`, a class (`[a-z_]`, `[^ ]`), `\b`, `^` and `$`, the
## classes `\d`, `\w` and `\s`, a byte escaped with `\`, a group (`(...)` or
## `(?:...)`) with `|` among its alternatives, and the counts `?`, `*` and `+`.
## Anything else, such as `{2}` or a back reference, is refused by name.
##
## A pattern compiles to a small program of steps, and a line is searched by
## carrying every step the match could be at, one byte at a time, so a search
## is linear in the line's length whatever the pattern.

## One step of a compiled pattern. `Split` and `Jump` name other steps by
## their place in the program.
Step : [
	Byte(U8),
	AnyByte,
	Class({ side : [Inside, Outside], ranges : List({ low : U8, high : U8 }) }),
	Boundary,
	LineStart,
	LineEnd,
	Split(U64, U64),
	Jump(U64),
	Matched,
]

TermPattern :: List(Step).{

	## The pattern's program, or what in it this subset refuses.
	from_str : Str -> Try(TermPattern, Str)
	from_str = |text| {
		bytes = text.to_utf8()
		parsed = alternatives_at(bytes, 0)?
		if parsed.at == bytes.len() {
			Ok(TermPattern.(parsed.steps.append(Matched)))
		} else {
			Err("the pattern `${text}` has a `)` that closes no group")
		}
	}

	## Whether the pattern matches anywhere in `line`.
	is_found_in : TermPattern, Str -> Bool
	is_found_in = |TermPattern.(steps), line| {
		bytes = line.to_utf8()
		len = bytes.len()
		var $live = []
		var $at = 0
		var $found = Bool.False
		while !$found and $at <= len {
			$live = closure(steps, { live: $live.append(0), bytes, at: $at })
			if $live.any(|place| steps.get(place) == Ok(Matched)) {
				$found = Bool.True
			} else {
				byte_here = bytes.get($at)
				$live = $live.keep_if(|place| accepts(steps, { place, byte: byte_here })).map(|place| place + 1)
				$at = $at + 1
			}
		}
		$found
	}
}

## A part of a program and where the parse stopped.
Parsed : { steps : List(Step), at : U64 }

## The steps moved to start at `base` in a larger program.
shifted : List(Step), U64 -> List(Step)
shifted = |steps, base| steps.map(
	|step| match step {
		Split(first, second) => Split(first + base, second + base)
		Jump(target) => Jump(target + base)
		_ => step
	},
)

## One program after another.
joined : List(Step), List(Step) -> List(Step)
joined = |first, second| first.concat(shifted(second, first.len()))

## Either of two programs.
either : List(Step), List(Step) -> List(Step)
either = |first, second| {
	n = first.len()
	[Split(1, n + 2)]
		.concat(shifted(first, 1))
		.append(Jump(n + 2 + second.len()))
		.concat(shifted(second, n + 2))
}

## `alternative|alternative|...` from `at`, up to a `)` or the end.
alternatives_at : List(U8), U64 -> Try(Parsed, Str)
alternatives_at = |bytes, at| {
	first = sequence_at(bytes, at)?
	if bytes.get(first.at) == Ok('|') {
		rest = alternatives_at(bytes, first.at + 1)?
		Ok({ steps: either(first.steps, rest.steps), at: rest.at })
	} else {
		Ok(first)
	}
}

## A run of counted atoms from `at`, up to a `|`, a `)` or the end.
sequence_at : List(U8), U64 -> Try(Parsed, Str)
sequence_at = |bytes, start| {
	var $steps = []
	var $at = start
	var $going = Bool.True
	while $going {
		match bytes.get($at) {
			Err(OutOfBounds) => {
				$going = Bool.False
			}
			Ok(byte) if byte == '|' or byte == ')' => {
				$going = Bool.False
			}
			Ok(_) => {
				atom = atom_at(bytes, $at)?
				counted = counted_at(bytes, atom)?
				$steps = joined($steps, counted.steps)
				$at = counted.at
			}
		}
	}
	Ok({ steps: $steps, at: $at })
}

## The atom with the count after it, if any.
counted_at : List(U8), Parsed -> Try(Parsed, Str)
counted_at = |bytes, atom| {
	n = atom.steps.len()
	counted = match bytes.get(atom.at) {
		Ok('?') => Ok({ steps: [Split(1, n + 1)].concat(shifted(atom.steps, 1)), at: atom.at + 1 })
		Ok('*') => Ok({ steps: [Split(1, n + 2)].concat(shifted(atom.steps, 1)).append(Jump(0)), at: atom.at + 1 })
		Ok('+') => Ok({ steps: atom.steps.append(Split(0, n + 1)), at: atom.at + 1 })
		Ok('{') => Err("a count in braces")
		_ => Ok(atom)
	}
	match (counted, bytes.get(atom.at + 1)) {
		(Ok(done), Ok(next)) if done.at > atom.at and (next == '?' or next == '*' or next == '+' or next == '{') => Err("a count after a count")
		_ => counted
	}
}

## One atom at `at`.
atom_at : List(U8), U64 -> Try(Parsed, Str)
atom_at = |bytes, at| match bytes.get(at) {
	Ok('(') => {
		inner_start =
			if bytes.drop_first(at).starts_with(['(', '?', ':']) {
				at + 3
			} else {
				at + 1
			}
		if bytes.get(inner_start) == Ok('?') {
			Err("a group of a kind other than `(?:...)`")
		} else {
			inner = alternatives_at(bytes, inner_start)?
			if bytes.get(inner.at) == Ok(')') {
				Ok({ steps: inner.steps, at: inner.at + 1 })
			} else {
				Err("a group that never closes")
			}
		}
	}
	Ok('[') => class_at(bytes, at + 1)
	Ok('.') => Ok({ steps: [AnyByte], at: at + 1 })
	Ok('^') => Ok({ steps: [LineStart], at: at + 1 })
	Ok('$') => Ok({ steps: [LineEnd], at: at + 1 })
	Ok('\\') => escaped_at(bytes, at + 1)
	Ok(byte) if byte == '?' or byte == '*' or byte == '+' or byte == '{' or byte == '}' => Err("a `${byte_text(byte)}` with nothing to count")
	Ok(byte) => Ok({ steps: [Byte(byte)], at: at + 1 })
	Err(OutOfBounds) => crash "TermPattern.atom_at: sequence_at asks only inside the pattern"
}

byte_text : U8 -> Str
byte_text = |byte| Str.from_utf8_lossy([byte])

## The class of `\d`, `\w` or `\s`.
named_class : U8 -> Try(List({ low : U8, high : U8 }), [NotAClass])
named_class = |letter| match letter {
	'd' => Ok([{ low: '0', high: '9' }])
	'w' => Ok([{ low: 'a', high: 'z' }, { low: 'A', high: 'Z' }, { low: '0', high: '9' }, { low: '_', high: '_' }])
	's' => Ok([{ low: ' ', high: ' ' }, { low: '\t', high: '\r' }])
	_ => Err(NotAClass)
}

## What follows a `\`.
escaped_at : List(U8), U64 -> Try(Parsed, Str)
escaped_at = |bytes, at| match bytes.get(at) {
	Ok('b') => Ok({ steps: [Boundary], at: at + 1 })
	Ok(letter) =>
		match named_class(letter) {
			Ok(ranges) => Ok({ steps: [Class({ side: Inside, ranges })], at: at + 1 })
			Err(NotAClass) =>
				if is_alphanumeric(letter) {
					Err("the escape `\\${byte_text(letter)}`")
				} else {
					Ok({ steps: [Byte(letter)], at: at + 1 })
				}
		}
	Err(OutOfBounds) => Err("a `\\` at the end")
}

is_alphanumeric : U8 -> Bool
is_alphanumeric = |byte| (byte >= 'a' and byte <= 'z') or (byte >= 'A' and byte <= 'Z') or (byte >= '0' and byte <= '9')

## A class's members from `at`, just past its `[`, to its `]`.
class_at : List(U8), U64 -> Try(Parsed, Str)
class_at = |bytes, start| {
	{ side, first } =
		if bytes.get(start) == Ok('^') {
			{ side: Outside, first: start + 1 }
		} else {
			{ side: Inside, first: start }
		}
	var $ranges = []
	var $at = first
	var $closed = Bool.False
	while !$closed {
		match bytes.get($at) {
			Err(OutOfBounds) => return Err("a class that never closes")
			Ok(']') if $at > first => {
				$closed = Bool.True
				$at = $at + 1
			}
			Ok('\\') =>
				match bytes.get($at + 1) {
					Ok(letter) =>
						match named_class(letter) {
							Ok(ranges) => {
								$ranges = $ranges.concat(ranges)
								$at = $at + 2
							}
							Err(NotAClass) => {
								$ranges = $ranges.append({ low: letter, high: letter })
								$at = $at + 2
							}
						}
					Err(OutOfBounds) => return Err("a class that never closes")
				}
			Ok(low) =>
				match (bytes.get($at + 1), bytes.get($at + 2)) {
					(Ok('-'), Ok(high)) if high != ']' => {
						if high < low {
							return Err("a range from `${byte_text(low)}` back to `${byte_text(high)}`")
						}
						$ranges = $ranges.append({ low, high })
						$at = $at + 3
					}
					_ => {
						$ranges = $ranges.append({ low, high: low })
						$at = $at + 1
					}
				}
		}
	}
	Ok({ steps: [Class({ side, ranges: $ranges })], at: $at })
}

## Whether a word starts or ends at `at`: a word byte on one side only.
is_boundary : List(U8), U64 -> Bool
is_boundary = |bytes, at| {
	is_word = |place| match bytes.get(place) {
		Ok(byte) => is_alphanumeric(byte) or byte == '_'
		Err(OutOfBounds) => Bool.False
	}
	before = at > 0 and is_word(at - 1)
	before != is_word(at)
}

## Every place the live places reach without reading a byte, the places that
## read one or end the match kept.
closure : List(Step), { live : List(U64), bytes : List(U8), at : U64 } -> List(U64)
closure = |steps, { live, bytes, at }| {
	var $kept = []
	var $seen = []
	var $todo = live
	while !$todo.is_empty() {
		place = $todo.last() ?? crash "TermPattern.closure: the list isn't empty"
		$todo = $todo.drop_last(1)
		if !$seen.contains(place) {
			$seen = $seen.append(place)
			match steps.get(place) {
				Ok(Split(first, second)) => {
					$todo = $todo.append(second).append(first)
				}
				Ok(Jump(target)) => {
					$todo = $todo.append(target)
				}
				Ok(Boundary) =>
					if is_boundary(bytes, at) {
						$todo = $todo.append(place + 1)
					}
				Ok(LineStart) =>
					if at == 0 {
						$todo = $todo.append(place + 1)
					}
				Ok(LineEnd) =>
					if at == bytes.len() {
						$todo = $todo.append(place + 1)
					}
				Ok(_) => {
					$kept = $kept.append(place)
				}
				Err(OutOfBounds) => crash "TermPattern.closure: a step names a place past the program"
			}
		}
	}
	$kept
}

## Whether the step at `place` reads `byte`, the line's byte there, if any.
accepts : List(Step), { place : U64, byte : Try(U8, [OutOfBounds]) } -> Bool
accepts = |steps, { place, byte }| match (steps.get(place), byte) {
	(Ok(Byte(wanted)), Ok(got)) => wanted == got
	(Ok(AnyByte), Ok(_)) => Bool.True
	(Ok(Class({ side, ranges })), Ok(got)) => {
		inside = ranges.any(|range| got >= range.low and got <= range.high)
		match side {
			Inside => inside
			Outside => !inside
		}
	}
	_ => Bool.False
}

found : Str, Str -> Bool
found = |pattern, line| match TermPattern.from_str(pattern) {
	Ok(compiled) => compiled.is_found_in(line)
	Err(why) => crash "the test pattern `${pattern}` is refused: ${why}"
}

refusal : Str -> Str
refusal = |pattern| match TermPattern.from_str(pattern) {
	Ok(_) => "accepted"
	Err(why) => why
}

expect found("gate", "the gate holds") and found("gate", "gateway") and !found("gate", "the gat e")
expect found("\\bgates?\\b", "two gates") and found("\\bgates?\\b", "a gate.") and !found("\\bgates?\\b", "gateway") and !found("\\bgates?\\b", "tailgate")
expect found("\\brepl(y|ies)\\b", "her replies") and found("\\brepl(y|ies)\\b", "a reply") and !found("\\brepl(y|ies)\\b", "replay")
expect found("anonymous function|lambda", "a lambda here") and found("anonymous function|lambda", "an anonymous function") and !found("anonymous function|lambda", "anonymous")
expect found("`[a-z_]*_limit`", "the `speed_limit` is") and found("`[a-z_]*_limit`", "`_limit`") and !found("`[a-z_]*_limit`", "`Speed_limit`")
expect found("`\\?\\?`", "use `??` here") and !found("`\\?\\?`", "use `?` here")
expect found("`\\.\\.`", "a `..` in") and !found("`\\.\\.`", "a `ab` in")
expect found("\\{\\{fails", "{{fails x}}") and !found("\\{\\{fails", "{fails")
expect found("functions? (is|as) an? (ordinary )?value", "a function as a value") and found("functions? (is|as) an? (ordinary )?value", "functions is an ordinary value") and !found("functions? (is|as) an? (ordinary )?value", "function as value")
expect found("paint(ed)? order", "painted order") and found("paint(ed)? order", "paint order") and !found("paint(ed)? order", "painting order")
expect found("^## ", "## a heading") and !found("^## ", "a ## b")
expect found("ends$", "it ends") and !found("ends$", "it ends here")
expect found("a.c", "abc") and !found("a.c", "ac")
expect found("[^ ]x", "ax") and !found("[^ ]x", " x") and !found("[^ ]x", "x")
expect found("\\d+ words", "900 words") and !found("\\d+ words", "many words")
expect found("\\w+\\s\\w", "ab c") and !found("\\w+\\s\\w", "ab  ")
expect found("(?:a|b)+c", "xbabac") and !found("(?:a|b)+c", "xc")
expect found("(a*)*b", "aaab") and !found("(a*)*b", "aaaa")
expect found("", "") and found("x?", "")
expect found("[-a]", "-") and found("[]a]", "]") and found("[a\\]]", "]") and !found("[a-c]", "d")
expect refusal("a{2}") == "a count in braces"
expect refusal("a+*") == "a count after a count"
expect refusal("*a") == "a `*` with nothing to count"
expect refusal("(?=a)") == "a group of a kind other than `(?:...)`"
expect refusal("(a") == "a group that never closes"
expect refusal("a)") == "the pattern `a)` has a `)` that closes no group"
expect refusal("[ab") == "a class that never closes"
expect refusal("[z-a]") == "a range from `z` back to `a`"
expect refusal("\\1") == "the escape `\\1`"
expect refusal("a\\") == "a `\\` at the end"
expect refusal("a}") == "a `}` with nothing to count"
expect refusal("\\bok\\b") == "accepted"
