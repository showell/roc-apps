## This module writes values the way node's `console.log` does, for the values
## the subset has: node's `util.inspect` with its defaults (a line breaks past
## 80 columns, three levels of nesting fit on one line, depth 2 is the last
## printed, 100 items of an array are shown). The functions follow the ones of
## node's lib/internal/util/inspect.js that they are named for
## (`formatValue`, `reduceToSingleString`, `groupArrayElements`), so a
## difference from node can be found by reading the two side by side.
##
## node's `ctx.currentDepth` is a variable every nested object sets as it
## starts; here it is threaded through as `depth_now`, given to each call and
## answered back by it.
##
## Lengths are UTF-16 code units, as node measures them with `.length`.
import Heap
import NumberText

Inspect :: [].{
	Context : {
		cells : List(Heap.Cell),
		indent : U64,
		depth_now : U64,
		seen : List(U64),
	}

	Formatted : { text : Str, depth_now : U64 }

	# A value formatted, or the reason the subset can't show it.
	Shown : Try(Inspect.Formatted, [Unsupported(Str)])

	break_length : U64
	break_length = 80

	# The arguments of one `console.log`, as the line it prints (without its
	# newline). A string argument is written as it is; the rest are inspected.
	line_of : List(Heap.Cell), List(Heap.Value) -> Try(Str, [Unsupported(Str)])
	line_of = |cells, values| {
		match values.first() {
			Ok(Text(text)) if values.len() > 1 and Inspect.has_format_directive(text) => {
				return Err(Unsupported("unsupported: console.log format directives (`%`)"))
			}
			_ => {}
		}
		var $parts = []
		for subject in values {
			shown = match subject {
				Text(text) => text
				_ => Inspect.inspect(cells, subject)?
			}
			$parts = $parts.append(shown)
		}
		Ok(Str.join_with($parts, " "))
	}

	has_format_directive : Str -> Bool
	has_format_directive = |text| {
		bytes = text.to_utf8()
		var $i = 0
		var $found = False
		while $i + 1 < bytes.len() {
			if (bytes.get($i) ?? crash "Inspect.has_format_directive: inside the text") == '%' and [
				's',
				'd',
				'i',
				'f',
				'j',
				'o',
				'O',
				'c',
				'%',
			].contains(bytes.get($i + 1) ?? crash "Inspect.has_format_directive: inside the text") {
				$found = True
			}
			$i = $i + 1
		}
		$found
	}

	# One value as `util.inspect` writes it.
	inspect : List(Heap.Cell), Heap.Value -> Try(Str, [Unsupported(Str)])
	inspect = |cells, subject| {
		formatted = Inspect.format_value(
			{
				cells: cells,
				indent: 0,
				depth_now: 0,
				seen: [],
			},
			subject,
			0,
		)?
		Ok(formatted.text)
	}

	plain : Inspect.Context, Str -> Inspect.Formatted
	plain = |context, text| { text: text, depth_now: context.depth_now }

	format_value : Inspect.Context, Heap.Value, U64 -> Inspect.Shown
	format_value = |context, subject, recurse|
		match subject {
			Number(number) => Ok(Inspect.plain(context, Inspect.number_text(number)))
			Text(text) => Ok(Inspect.plain(context, Inspect.string_literal(text, context.indent)))
			Boolean(truth) => Ok(
				Inspect.plain(
					context,
					if truth {
						"true"
					} else {
						"false"
					},
				),
			)
			Null => Ok(Inspect.plain(context, "null"))
			Undefined => Ok(Inspect.plain(context, "undefined"))
			Reference(id) => Inspect.format_cell(context, id, recurse)
		}

	number_text : F64 -> Str
	number_text = |number|
		if number == 0.0 and 1.0 / number < 0.0 {
			"-0"
		} else {
			NumberText.of(number)
		}

	format_cell : Inspect.Context, U64, U64 -> Inspect.Shown
	format_cell = |context, id, recurse|
		match Heap.cell_at(context.cells, id) {
			Fun(closure) => {
				name = closure.fun.unbox().name
				if name == "" {
					Ok(Inspect.plain(context, "[Function (anonymous)]"))
				} else {
					Ok(Inspect.plain(context, "[Function: ${name}]"))
				}
			}
			Builtin(native, _) => Ok(Inspect.plain(context, "[Function: ${Heap.native_name(native)}]"))
			Namespace(
				name,
				_,
			) => Err(Unsupported("unsupported: printing the builtin object ${name}"))
			Taken => crash "Inspect.format_cell: no cell is out being written while a line is printed"
			Array(items) => {
				if context.seen.contains(id) {
					Err(Unsupported("unsupported: printing a circular structure"))
				} else if items.is_empty() {
					Ok(Inspect.plain(context, "[]"))
				} else if recurse > 2 {
					Ok(Inspect.plain(context, "[Array]"))
				} else {
					Inspect.format_array(
						{
							..context,
							depth_now: recurse + 1,
							seen: context.seen.append(id),
						},
						items,
						recurse + 1,
					)
				}
			}
			Object(properties) => {
				if context.seen.contains(id) {
					Err(Unsupported("unsupported: printing a circular structure"))
				} else if properties.is_empty() {
					Ok(Inspect.plain(context, "{}"))
				} else if recurse > 2 {
					Ok(Inspect.plain(context, "[Object]"))
				} else {
					Inspect.format_object(
						{
							..context,
							depth_now: recurse + 1,
							seen: context.seen.append(id),
						},
						properties,
						recurse + 1,
					)
				}
			}
		}

	format_array : Inspect.Context, List(Heap.Value), U64 -> Inspect.Shown
	format_array = |context, items, recurse| {
		shown = items.sublist({ start: 0, len: 100 })
		var $depth_now = context.depth_now
		var $out = []
		for item in shown {
			formatted = Inspect.format_value(
				{
					..context,
					indent: context.indent + 2,
					depth_now: $depth_now,
				},
				item,
				recurse,
			)?
			$depth_now = formatted.depth_now
			$out = $out.append(formatted.text)
		}
		more = items.len() - shown.len()
		output = if more > 0 {
			plural = if more > 1 {
				"s"
			} else {
				""
			}
			$out.append("... ${more.to_str()} more item${plural}")
		} else {
			$out
		}
		Ok({
			text: Inspect.reduce_to_single_string(
				{ ..context, depth_now: $depth_now },
				{
					output: output,
					open: "[",
					close: "]",
					kind: ArrayKind(items),
				},
				recurse,
			),
			depth_now: $depth_now,
		})
	}

	format_object : Inspect.Context, List(Heap.Property), U64 -> Inspect.Shown
	format_object = |context, properties, recurse| {
		var $depth_now = context.depth_now
		var $out = []
		for p in Inspect.properties_in_key_order(properties) {
			formatted = Inspect.format_value(
				{
					..context,
					indent: context.indent + 2,
					depth_now: $depth_now,
				},
				p.value,
				recurse,
			)?
			$depth_now = formatted.depth_now
			$out = $out.append("${Inspect.key_text(p.key)}: ${formatted.text}")
		}
		Ok({
			text: Inspect.reduce_to_single_string(
				{ ..context, depth_now: $depth_now },
				{
					output: $out,
					open: "{",
					close: "}",
					kind: ObjectKind,
				},
				recurse,
			),
			depth_now: $depth_now,
		})
	}

	# An object's properties in JavaScript's order: the keys that are array
	# indices first, by number, then the rest as they were made.
	properties_in_key_order : List(Heap.Property) -> List(Heap.Property)
	properties_in_key_order = |properties| {
		var $indexed = []
		var $named = []
		for p in properties {
			match Inspect.index_of_key(p.key) {
				Ok(position) => {
					$indexed = $indexed.append({ index: position, prop: p })
				}
				Err(NotIndex) => {
					$named = $named.append(p)
				}
			}
		}
		sorted = $indexed.sort_with(
			|left, right| if left.index < right.index {
				Before
			} else if left.index > right.index {
				After
			} else {
				Same
			},
		)
		List.concat(sorted.map(|x| x.prop), $named)
	}

	# The array index a key names: its digits with no leading zero, below
	# 2^32 - 1.
	index_of_key : Str -> Try(U64, [NotIndex])
	index_of_key = |key| {
		bytes = key.to_utf8()
		if bytes.is_empty() or bytes.len() > 10 or (bytes.len() > 1 and (bytes.get(0) ?? crash "Inspect.index_of_key: a key of two bytes or more") == '0') {
			Err(NotIndex)
		} else if bytes.all(|byte| byte >= '0' and byte <= '9') {
			parsed = bytes.fold(0, |accumulated, byte| accumulated * 10 + (byte - '0').to_u64())
			if parsed < 4294967295 {
				Ok(parsed)
			} else {
				Err(NotIndex)
			}
		} else {
			Err(NotIndex)
		}
	}

	key_text : Str -> Str
	key_text = |key| {
		bytes = key.to_utf8()
		starts_well = match bytes.first() {
			Ok(byte) => Inspect.is_key_start(byte)
			Err(ListWasEmpty) => False
		}
		is_bare = starts_well and bytes.all(|byte| Inspect.is_key_start(byte) or (byte >= '0' and byte <= '9'))
		if is_bare {
			key
		} else {
			Inspect.escaped(key)
		}
	}

	is_key_start : U8 -> Bool
	is_key_start = |byte| (byte >= 'a' and byte <= 'z') or (byte >= 'A' and byte <= 'Z') or byte == '_'

	# node's `formatPrimitive` for a string: quoted and escaped, and split into
	# lines joined by ` +` when it is long enough to wrap.
	string_literal : Str, U64 -> Str
	string_literal = |text, indent| {
		length = Inspect.width(text)
		if length > 16 and length + indent + 4 > Inspect.break_length {
			pieces = Inspect.pieces_after_newlines(text)
			Str.join_with(pieces.map(Inspect.escaped), " +\n${" ".repeat(indent + 2)}")
		} else {
			Inspect.escaped(text)
		}
	}

	# The string split after each newline, each piece keeping its newline.
	pieces_after_newlines : Str -> List(Str)
	pieces_after_newlines = |text| {
		parts = text.split_on("\n")
		last = parts.len() - 1
		var $out = []
		var $i = 0
		for part in parts {
			if $i < last {
				$out = $out.append("${part}\n")
			} else if !part.is_empty() {
				$out = $out.append(part)
			}
			$i = $i + 1
		}
		$out
	}

	# node's `strEscape`: single quotes unless the text holds one, then
	# double quotes unless it holds one, then backticks unless it holds one
	# or `${`; only the single quote is ever escaped.
	escaped : Str -> Str
	escaped = |text| {
		quote = if !text.contains("'") {
			'\''
		} else if !text.contains("\"") {
			'"'
		} else if !text.contains("`") and !text.contains("\${") {
			'`'
		} else {
			'\''
		}
		bytes = text.to_utf8()
		var $out = [quote]
		var $i = 0
		while $i < bytes.len() {
			byte = bytes.get($i) ?? crash "Inspect.escaped: inside the text"
			next = bytes.get($i + 1) ?? 0
			if byte == 0xC2 and next >= 0x80 and next <= 0x9F {
				$out = List.concat($out, Inspect.hex_escape(next))
				$i = $i + 2
			} else {
				$out = if byte == quote and byte == '\'' {
					List.concat($out, ['\\', '\''])
				} else if byte == '\\' {
					List.concat($out, ['\\', '\\'])
				} else if byte == 8 {
					List.concat($out, ['\\', 'b'])
				} else if byte == '\t' {
					List.concat($out, ['\\', 't'])
				} else if byte == '\n' {
					List.concat($out, ['\\', 'n'])
				} else if byte == 12 {
					List.concat($out, ['\\', 'f'])
				} else if byte == '\r' {
					List.concat($out, ['\\', 'r'])
				} else if byte < 32 or byte == 127 {
					List.concat($out, Inspect.hex_escape(byte))
				} else {
					$out.append(byte)
				}
				$i = $i + 1
			}
		}
		Str.from_utf8($out.append(quote)) ?? crash "Inspect.escaped: whole characters are copied"
	}

	hex_escape : U8 -> List(U8)
	hex_escape = |byte| {
		digits = "0123456789ABCDEF".to_utf8()
		[
			'\\',
			'x',
			digits.get(byte.div_trunc_by(16).to_u64()) ?? crash "Inspect.hex_escape: a digit below 16",
			digits.get(byte.rem_by(16).to_u64()) ?? crash "Inspect.hex_escape: a digit below 16",
		]
	}

	# A string's length in UTF-16 code units: one a character, two for one
	# outside the Basic Multilingual Plane.
	width : Str -> U64
	width = |text|
		text.to_utf8().fold(
			0,
			|counted, byte|
				if byte >= 0xF0 {
					counted + 2
				} else if byte >= 0x80 and byte < 0xC0 {
					counted
				} else {
					counted + 1
				},
		)

	Kind : [ArrayKind(List(Heap.Value)), ObjectKind]

	Entries : {
		output : List(Str),
		open : Str,
		close : Str,
		kind : Inspect.Kind,
	}

	# node's `reduceToSingleString`, with `ctx.compact` 3.
	reduce_to_single_string : Inspect.Context, Inspect.Entries, U64 -> Str
	reduce_to_single_string = |context, formatted_entries, recurse| {
		entries = formatted_entries.output.len()
		output = match formatted_entries.kind {
			ArrayKind(items) if entries > 6 => Inspect.group_array_elements(context, formatted_entries.output, items)
			_ => formatted_entries.output
		}
		joined = Str.join_with(output, ", ")
		start = output.len() + context.indent + formatted_entries.open.count_utf8_bytes() + 10
		fits = context.depth_now - recurse < 3 and entries == output.len() and Inspect.is_below_break_length(output, start) and !joined.contains("\n")
		if fits {
			"${formatted_entries.open} ${joined} ${formatted_entries.close}"
		} else {
			indentation = "\n${" ".repeat(context.indent)}"
			"${formatted_entries.open}${indentation}  ${Str.join_with(output, ",${indentation}  ")}${indentation}${formatted_entries.close}"
		}
	}

	is_below_break_length : List(Str), U64 -> Bool
	is_below_break_length = |output, start| {
		var $total = output.len() + start
		if $total + output.len() > Inspect.break_length {
			return False
		}
		var $fits = True
		for o in output {
			$total = $total + Inspect.width(o)
			if $total > Inspect.break_length {
				$fits = False
			}
		}
		$fits
	}

	# node's `groupArrayElements`: an array of more than six short items set
	# out in aligned columns.
	group_array_elements : Inspect.Context, List(Str), List(Heap.Value) -> List(Str)
	group_array_elements = |context, output, items| {
		has_more = items.len() > 100
		output_length = if has_more {
			output.len() - 1
		} else {
			output.len()
		}
		data_lengths = output.sublist({ start: 0, len: output_length }).map(Inspect.width)
		total_length = data_lengths.fold(0, |total, length| total + length + 2)
		max_length = data_lengths.fold(0, |most, length| U64.max(most, length))
		actual_max = max_length + 2
		if actual_max * 3 + context.indent < Inspect.break_length and (total_length.to_f64() / actual_max.to_f64() > 5.0 or max_length <= 6) {
			average_bias = (actual_max.to_f64() - total_length.to_f64() / output.len().to_f64()).sqrt()
			biased_max = F64.max(actual_max.to_f64() - 3.0 - average_bias, 1.0)
			by_area = Inspect.js_round((2.5 * biased_max * output_length.to_f64()).sqrt() / biased_max)
			by_width = (Inspect.break_length - context.indent).div_trunc_by(actual_max)
			columns = [by_area, by_width, 12, 15].fold(15, |least, candidate| U64.min(least, candidate))
			if columns <= 1 {
				output
			} else {
				Inspect.grouped(output, data_lengths, items, columns, has_more)
			}
		} else {
			output
		}
	}

	# Math.round for a non-negative number.
	js_round : F64 -> U64
	js_round = |x| (x + 0.5).floor_to_u64_try() ?? 0

	grouped : List(Str), List(U64), List(Heap.Value), U64, Bool -> List(Str)
	grouped = |output, data_lengths, items, columns, has_more| {
		output_length = data_lengths.len()
		var $max_line_lengths = []
		var $column = 0
		while $column < columns {
			var $longest = 0
			var $j = $column
			while $j < output_length {
				$longest = U64.max(
					$longest,
					data_lengths.get($j) ?? crash "Inspect.grouped: inside the entries",
				)
				$j = $j + columns
			}
			$max_line_lengths = $max_line_lengths.append($longest + 2)
			$column = $column + 1
		}
		numbers_only = items.sublist({ start: 0, len: output.len() }).all(
			|subject| match subject {
				Number(_) => True
				_ => False
			},
		)
		var $lines = []
		var $i = 0
		while $i < output_length {
			last = U64.min($i + columns, output_length)
			var $line = ""
			var $j = $i
			while $j < last - 1 {
				cell = "${output.get($j) ?? crash "Inspect.grouped: inside the entries"}, "
				pad = $max_line_lengths.get($j - $i) ?? crash "Inspect.grouped: a column the line has"
				$line = Str.concat($line, Inspect.padded(cell, pad, numbers_only))
				$j = $j + 1
			}
			final = output.get($j) ?? crash "Inspect.grouped: inside the entries"
			$line = if numbers_only {
				Str.concat(
					$line,
					Inspect.padded(
						final,
						($max_line_lengths.get($j - $i) ?? crash "Inspect.grouped: a column the line has") - 2,
						True,
					),
				)
			} else {
				Str.concat($line, final)
			}
			$lines = $lines.append($line)
			$i = $i + columns
		}
		if has_more {
			$lines.append(output.last() ?? crash "Inspect.grouped: the more-items entry is last")
		} else {
			$lines
		}
	}

	# Text padded with spaces to `width`: before it when `at_start`.
	padded : Str, U64, Bool -> Str
	padded = |text, wanted_width, at_start| {
		shown_width = Inspect.width(text)
		if shown_width >= wanted_width {
			text
		} else if at_start {
			Str.concat(" ".repeat(wanted_width - shown_width), text)
		} else {
			Str.concat(text, " ".repeat(wanted_width - shown_width))
		}
	}
}
