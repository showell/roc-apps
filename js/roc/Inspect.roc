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
	Ctx : {
		cells : List(Heap.Cell),
		indent : U64,
		depth_now : U64,
		seen : List(U64),
	}

	Formatted : { text : Str, depth_now : U64 }

	break_length : U64
	break_length = 80

	# The arguments of one `console.log`, as the line it prints (without its
	# newline). A string argument is written as it is; the rest are inspected.
	line_of : List(Heap.Cell), List(Heap.Val) -> Try(Str, [Unsupported(Str)])
	line_of = |cells, vals| {
		match vals.first() {
			Ok(Text(s)) if vals.len() > 1 and Inspect.has_format_directive(s) => {
				return Err(Unsupported("unsupported: console.log format directives (`%`)"))
			}
			_ => {}
		}
		var $parts = []
		for v in vals {
			text = match v {
				Text(s) => s
				_ => Inspect.inspect(cells, v)?
			}
			$parts = $parts.append(text)
		}
		Ok(Str.join_with($parts, " "))
	}

	has_format_directive : Str -> Bool
	has_format_directive = |s| {
		b = s.to_utf8()
		var $i = 0
		var $found = False
		while $i + 1 < b.len() {
			if (b.get($i) ?? crash "Inspect.has_format_directive: inside the text") == '%' and [
				's',
				'd',
				'i',
				'f',
				'j',
				'o',
				'O',
				'c',
				'%',
			].contains(b.get($i + 1) ?? crash "Inspect.has_format_directive: inside the text") {
				$found = True
			}
			$i = $i + 1
		}
		$found
	}

	# One value as `util.inspect` writes it.
	inspect : List(Heap.Cell), Heap.Val -> Try(Str, [Unsupported(Str)])
	inspect = |cells, v| {
		f = Inspect.format_value({ cells: cells, indent: 0, depth_now: 0, seen: [] }, v, 0)?
		Ok(f.text)
	}

	plain : Inspect.Ctx, Str -> Inspect.Formatted
	plain = |ctx, text| { text: text, depth_now: ctx.depth_now }

	format_value : Inspect.Ctx, Heap.Val, U64 -> Try(Inspect.Formatted, [Unsupported(Str)])
	format_value = |ctx, v, recurse|
		match v {
			Number(n) => Ok(Inspect.plain(ctx, Inspect.number_text(n)))
			Text(s) => Ok(Inspect.plain(ctx, Inspect.string_literal(s, ctx.indent)))
			Boolean(b) => Ok(
				Inspect.plain(
					ctx,
					if b {
						"true"
					} else {
						"false"
					},
				),
			)
			Null => Ok(Inspect.plain(ctx, "null"))
			Undefined => Ok(Inspect.plain(ctx, "undefined"))
			Ref(id) => Inspect.format_cell(ctx, id, recurse)
		}

	number_text : F64 -> Str
	number_text = |n|
		if n == 0.0 and 1.0 / n < 0.0 {
			"-0"
		} else {
			NumberText.of(n)
		}

	format_cell : Inspect.Ctx, U64, U64 -> Try(Inspect.Formatted, [Unsupported(Str)])
	format_cell = |ctx, id, recurse|
		match Heap.cell_at(ctx.cells, id) {
			Fun(c) => {
				name = c.fun.unbox().name
				if name == "" {
					Ok(Inspect.plain(ctx, "[Function (anonymous)]"))
				} else {
					Ok(Inspect.plain(ctx, "[Function: ${name}]"))
				}
			}
			Builtin(n, _) => Ok(Inspect.plain(ctx, "[Function: ${Heap.native_name(n)}]"))
			Namespace(
				name,
				_,
			) => Err(Unsupported("unsupported: printing the builtin object ${name}"))
			Taken => crash "Inspect.format_cell: no cell is out being written while a line is printed"
			Arr(items) => {
				if ctx.seen.contains(id) {
					Err(Unsupported("unsupported: printing a circular structure"))
				} else if items.is_empty() {
					Ok(Inspect.plain(ctx, "[]"))
				} else if recurse > 2 {
					Ok(Inspect.plain(ctx, "[Array]"))
				} else {
					Inspect.format_array(
						{ ..ctx, depth_now: recurse + 1, seen: ctx.seen.append(id) },
						items,
						recurse + 1,
					)
				}
			}
			Obj(props) => {
				if ctx.seen.contains(id) {
					Err(Unsupported("unsupported: printing a circular structure"))
				} else if props.is_empty() {
					Ok(Inspect.plain(ctx, "{}"))
				} else if recurse > 2 {
					Ok(Inspect.plain(ctx, "[Object]"))
				} else {
					Inspect.format_object(
						{ ..ctx, depth_now: recurse + 1, seen: ctx.seen.append(id) },
						props,
						recurse + 1,
					)
				}
			}
		}

	format_array : Inspect.Ctx, List(Heap.Val), U64 -> Try(Inspect.Formatted, [Unsupported(Str)])
	format_array = |ctx, items, recurse| {
		shown = items.sublist({ start: 0, len: 100 })
		var $depth_now = ctx.depth_now
		var $out = []
		for item in shown {
			f = Inspect.format_value(
				{ ..ctx, indent: ctx.indent + 2, depth_now: $depth_now },
				item,
				recurse,
			)?
			$depth_now = f.depth_now
			$out = $out.append(f.text)
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
				{ ..ctx, depth_now: $depth_now },
				{ output: output, open: "[", close: "]", kind: ArrayKind(items) },
				recurse,
			),
			depth_now: $depth_now,
		})
	}

	format_object : Inspect.Ctx, List(Heap.Prop), U64 -> Try(Inspect.Formatted, [Unsupported(Str)])
	format_object = |ctx, props, recurse| {
		var $depth_now = ctx.depth_now
		var $out = []
		for p in Inspect.props_in_key_order(props) {
			f = Inspect.format_value(
				{ ..ctx, indent: ctx.indent + 2, depth_now: $depth_now },
				p.val,
				recurse,
			)?
			$depth_now = f.depth_now
			$out = $out.append("${Inspect.key_text(p.key)}: ${f.text}")
		}
		Ok({
			text: Inspect.reduce_to_single_string(
				{ ..ctx, depth_now: $depth_now },
				{ output: $out, open: "{", close: "}", kind: ObjectKind },
				recurse,
			),
			depth_now: $depth_now,
		})
	}

	# An object's properties in JavaScript's order: the keys that are array
	# indices first, by number, then the rest as they were made.
	props_in_key_order : List(Heap.Prop) -> List(Heap.Prop)
	props_in_key_order = |props| {
		var $indexed = []
		var $named = []
		for p in props {
			match Inspect.index_of_key(p.key) {
				Ok(i) => {
					$indexed = $indexed.append({ index: i, prop: p })
				}
				Err(NotIndex) => {
					$named = $named.append(p)
				}
			}
		}
		sorted = $indexed.sort_with(
			|a, b| if a.index < b.index {
				Before
			} else if a.index > b.index {
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
		b = key.to_utf8()
		if b.is_empty() or b.len() > 10 or (b.len() > 1 and (b.get(0) ?? crash "Inspect.index_of_key: a key of two bytes or more") == '0') {
			Err(NotIndex)
		} else if b.all(|c| c >= '0' and c <= '9') {
			n = b.fold(0, |acc, c| acc * 10 + (c - '0').to_u64())
			if n < 4294967295 {
				Ok(n)
			} else {
				Err(NotIndex)
			}
		} else {
			Err(NotIndex)
		}
	}

	key_text : Str -> Str
	key_text = |key| {
		b = key.to_utf8()
		starts_well = match b.first() {
			Ok(c) => Inspect.is_key_start(c)
			Err(ListWasEmpty) => False
		}
		is_bare = starts_well and b.all(|c| Inspect.is_key_start(c) or (c >= '0' and c <= '9'))
		if is_bare {
			key
		} else {
			Inspect.escaped(key)
		}
	}

	is_key_start : U8 -> Bool
	is_key_start = |c| (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_'

	# node's `formatPrimitive` for a string: quoted and escaped, and split into
	# lines joined by ` +` when it is long enough to wrap.
	string_literal : Str, U64 -> Str
	string_literal = |s, indent| {
		length = Inspect.width(s)
		if length > 16 and length + indent + 4 > Inspect.break_length {
			pieces = Inspect.pieces_after_newlines(s)
			Str.join_with(pieces.map(Inspect.escaped), " +\n${" ".repeat(indent + 2)}")
		} else {
			Inspect.escaped(s)
		}
	}

	# The string split after each newline, each piece keeping its newline.
	pieces_after_newlines : Str -> List(Str)
	pieces_after_newlines = |s| {
		parts = s.split_on("\n")
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
	escaped = |s| {
		quote = if !s.contains("'") {
			'\''
		} else if !s.contains("\"") {
			'"'
		} else if !s.contains("`") and !s.contains("\${") {
			'`'
		} else {
			'\''
		}
		b = s.to_utf8()
		var $out = [quote]
		var $i = 0
		while $i < b.len() {
			c = b.get($i) ?? crash "Inspect.escaped: inside the text"
			next = b.get($i + 1) ?? 0
			if c == 0xC2 and next >= 0x80 and next <= 0x9F {
				$out = List.concat($out, Inspect.hex_escape(next))
				$i = $i + 2
			} else {
				$out = if c == quote and c == '\'' {
					List.concat($out, ['\\', '\''])
				} else if c == '\\' {
					List.concat($out, ['\\', '\\'])
				} else if c == 8 {
					List.concat($out, ['\\', 'b'])
				} else if c == '\t' {
					List.concat($out, ['\\', 't'])
				} else if c == '\n' {
					List.concat($out, ['\\', 'n'])
				} else if c == 12 {
					List.concat($out, ['\\', 'f'])
				} else if c == '\r' {
					List.concat($out, ['\\', 'r'])
				} else if c < 32 or c == 127 {
					List.concat($out, Inspect.hex_escape(c))
				} else {
					$out.append(c)
				}
				$i = $i + 1
			}
		}
		Str.from_utf8($out.append(quote)) ?? crash "Inspect.escaped: whole characters are copied"
	}

	hex_escape : U8 -> List(U8)
	hex_escape = |c| {
		digits = "0123456789ABCDEF".to_utf8()
		[
			'\\',
			'x',
			digits.get(c.div_trunc_by(16).to_u64()) ?? crash "Inspect.hex_escape: a digit below 16",
			digits.get(c.rem_by(16).to_u64()) ?? crash "Inspect.hex_escape: a digit below 16",
		]
	}

	# A string's length in UTF-16 code units: one a character, two for one
	# outside the Basic Multilingual Plane.
	width : Str -> U64
	width = |s|
		s.to_utf8().fold(
			0,
			|n, c|
				if c >= 0xF0 {
					n + 2
				} else if c >= 0x80 and c < 0xC0 {
					n
				} else {
					n + 1
				},
		)

	Kind : [ArrayKind(List(Heap.Val)), ObjectKind]

	Entries : { output : List(Str), open : Str, close : Str, kind : Inspect.Kind }

	# node's `reduceToSingleString`, with `ctx.compact` 3.
	reduce_to_single_string : Inspect.Ctx, Inspect.Entries, U64 -> Str
	reduce_to_single_string = |ctx, e, recurse| {
		entries = e.output.len()
		output = match e.kind {
			ArrayKind(items) if entries > 6 => Inspect.group_array_elements(ctx, e.output, items)
			_ => e.output
		}
		joined = Str.join_with(output, ", ")
		start = output.len() + ctx.indent + e.open.count_utf8_bytes() + 10
		fits = ctx.depth_now - recurse < 3 and entries == output.len() and Inspect.is_below_break_length(output, start) and !joined.contains("\n")
		if fits {
			"${e.open} ${joined} ${e.close}"
		} else {
			indentation = "\n${" ".repeat(ctx.indent)}"
			"${e.open}${indentation}  ${Str.join_with(output, ",${indentation}  ")}${indentation}${e.close}"
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
	group_array_elements : Inspect.Ctx, List(Str), List(Heap.Val) -> List(Str)
	group_array_elements = |ctx, output, items| {
		has_more = items.len() > 100
		output_length = if has_more {
			output.len() - 1
		} else {
			output.len()
		}
		data_lengths = output.sublist({ start: 0, len: output_length }).map(Inspect.width)
		total_length = data_lengths.fold(0, |t, l| t + l + 2)
		max_length = data_lengths.fold(0, |m, l| U64.max(m, l))
		actual_max = max_length + 2
		if actual_max * 3 + ctx.indent < Inspect.break_length and (total_length.to_f64() / actual_max.to_f64() > 5.0 or max_length <= 6) {
			average_bias = (actual_max.to_f64() - total_length.to_f64() / output.len().to_f64()).sqrt()
			biased_max = F64.max(actual_max.to_f64() - 3.0 - average_bias, 1.0)
			by_area = Inspect.js_round((2.5 * biased_max * output_length.to_f64()).sqrt() / biased_max)
			by_width = (Inspect.break_length - ctx.indent).div_trunc_by(actual_max)
			columns = [by_area, by_width, 12, 15].fold(15, |m, c| U64.min(m, c))
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

	grouped : List(Str), List(U64), List(Heap.Val), U64, Bool -> List(Str)
	grouped = |output, data_lengths, items, columns, has_more| {
		output_length = data_lengths.len()
		var $max_line_lengths = []
		var $col = 0
		while $col < columns {
			var $longest = 0
			var $j = $col
			while $j < output_length {
				$longest = U64.max($longest, data_lengths.get($j) ?? crash "Inspect.grouped: inside the entries")
				$j = $j + columns
			}
			$max_line_lengths = $max_line_lengths.append($longest + 2)
			$col = $col + 1
		}
		numbers_only = items.sublist({ start: 0, len: output.len() }).all(
			|v| match v {
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
					Inspect.padded(final, ($max_line_lengths.get($j - $i) ?? crash "Inspect.grouped: a column the line has") - 2, True),
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
	padded = |text, w, at_start| {
		n = Inspect.width(text)
		if n >= w {
			text
		} else if at_start {
			Str.concat(" ".repeat(w - n), text)
		} else {
			Str.concat(text, " ".repeat(w - n))
		}
	}
}
