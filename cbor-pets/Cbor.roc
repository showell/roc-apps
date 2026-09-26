## CBOR (RFC 8949) as a Roc format, the way `Json` is one.
##
## `Cbor.parse` and `Cbor.to_bytes` work for any type whose `parser_for` and
## `encoder_for` the compiler can derive: records become maps with text keys,
## lists become arrays, and strings and integers are what you'd expect. The
## caller's expected type picks the parser, just as with `Json.parse`.
##
## Two extra methods, `parse_bytes` and `encode_bytes`, read and write a CBOR
## byte string (major type 2). No derived parser calls them; a type that *is*
## a blob asks for them in its own `parser_for`/`encoder_for` (see ImageBlob).
## That keeps a blob apart from a `List(U8)` of numbers, which stays an array.
##
## Only what the Profile example needs is implemented. Adding more shapes
## (bools, other ints, tuples, dicts) is one small method each.
Cbor := [Default].{
	parse : List(U8) -> Try(a, [InvalidCbor(Str), ..errs])
		where [a.parser_for : Cbor -> (List(U8) -> Try({ value : a, rest : List(U8) }, [InvalidCbor(Str), ..errs]))]
	parse = |bytes| {
		Shape : a
		parse_shape = Shape.parser_for(Cbor.Default)
		parsed = parse_shape(bytes)?
		if parsed.rest.is_empty() {
			Ok(parsed.value)
		} else {
			Err(InvalidCbor("trailing bytes"))
		}
	}

	to_bytes : a -> List(U8)
		where [a.encoder_for : Cbor -> (a, List(U8) -> Try(List(U8), []))]
	to_bytes = |value| {
		Shape : a
		encode_shape = Shape.encoder_for(Cbor.Default)
		Ok(bytes) = encode_shape(value, [])
		bytes
	}

	# ---- parsing: the methods derived parsers call ---------------------------

	rename_field : Cbor, Str -> Str
	rename_field = |_, name| name

	parse_str : Cbor, List(U8) -> Try({ value : Str, rest : List(U8) }, [InvalidCbor(Str)])
	parse_str = |_, input| {
		h = read_head(input, 3, "a text string")?
		chunk = take(h.rest, h.arg)?
		match Str.from_utf8(chunk.value) {
			Ok(str) => Ok({ value: str, rest: chunk.rest })
			Err(_) => Err(InvalidCbor("invalid UTF-8"))
		}
	}

	parse_u8 : Cbor, List(U8) -> Try({ value : U8, rest : List(U8) }, [InvalidCbor(Str)])
	parse_u8 = |_, input| {
		h = read_head(input, 0, "an unsigned integer")?
		match h.arg.to_u8_try() {
			Ok(n) => Ok({ value: n, rest: h.rest })
			Err(OutOfRange) => Err(InvalidCbor("integer too big for U8"))
		}
	}

	parse_u64 : Cbor, List(U8) -> Try({ value : U64, rest : List(U8) }, [InvalidCbor(Str)])
	parse_u64 = |_, input| {
		h = read_head(input, 0, "an unsigned integer")?
		Ok({ value: h.arg, rest: h.rest })
	}

	## CBOR arrays are length-prefixed, so the list is always `Counted`.
	parse_list_start : Cbor, List(U8) -> Try([Counted({ len : U64, rest : List(U8) }), Uncounted(List(U8))], [InvalidCbor(Str)])
	parse_list_start = |_, input| {
		h = read_head(input, 4, "an array")?
		Ok(Counted({ len: h.arg, rest: h.rest }))
	}

	## Never reached: every list is `Counted`.
	parse_list_next : Cbor, List(U8) -> Try([Item(List(U8)), Done(List(U8))], [InvalidCbor(Str)])
	parse_list_next = |_, _| Err(InvalidCbor("indefinite-length arrays"))

	parse_list_after_item : Cbor, List(U8) -> Try([Continue(List(U8)), Done(List(U8))], [InvalidCbor(Str)])
	parse_list_after_item = |_, _| Err(InvalidCbor("indefinite-length arrays"))

	## A record is a map with text keys, also length-prefixed.
	parse_record_start : Cbor, List(U8) -> Try([Counted({ len : U64, rest : List(U8) }), Uncounted(List(U8))], [InvalidCbor(Str)])
	parse_record_start = |_, input| {
		h = read_head(input, 5, "a map")?
		Ok(Counted({ len: h.arg, rest: h.rest }))
	}

	parse_record_field : Cbor,
	Encoding.FieldName.FieldNames(_shape),
	List(U8) -> Try(
		[
			Field({ field : Encoding.FieldName(_shape), rest : List(U8) }),
			TryField({ name : Str, rest : List(U8) }),
			TryFieldCaseless({ name : Str, rest : List(U8) }),
			Continue(List(U8)),
			Done(List(U8)),
		],
		[InvalidCbor(Str)],
	)
	parse_record_field = |cbor, _, input| {
		key = Cbor.parse_str(cbor, input)?
		Ok(TryField({ name: key.value, rest: key.rest }))
	}

	## Never reached: every record is `Counted`.
	parse_record_after_field : Cbor, List(U8) -> Try([Continue(List(U8)), Done(List(U8))], [InvalidCbor(Str)])
	parse_record_after_field = |_, _| Err(InvalidCbor("indefinite-length maps"))

	## The value of a key the record doesn't have.
	skip_record_field : Cbor, List(U8) -> Try(List(U8), [InvalidCbor(Str)])
	skip_record_field = |_, input| skip(input)

	invalid_value : Cbor, List(U8) -> [InvalidCbor(Str)]
	invalid_value = |_, _| InvalidCbor("invalid value")

	# ---- encoding: the methods derived encoders call -------------------------

	encode_str : Str, List(U8) -> Try(List(U8), [])
	encode_str = |str, out| {
		utf8 = str.to_utf8()
		Ok(write_head(out, 3, utf8.len()).concat(utf8))
	}

	encode_u8 : U8, List(U8) -> Try(List(U8), [])
	encode_u8 = |n, out| Ok(write_head(out, 0, n.to_u64()))

	encode_u64 : U64, List(U8) -> Try(List(U8), [])
	encode_u64 = |n, out| Ok(write_head(out, 0, n))

	encode_list : List(U8), U64, (List(U8), (List(U8), (List(U8) -> Try(List(U8), err)) -> Try(List(U8), err)) -> Try(List(U8), err)) -> Try(List(U8), err)
	encode_list = |out, len, write_items| write_items(write_head(out, 4, len), |so_far, write_item| write_item(so_far))

	encode_record : List(U8), U64, (List(U8), (List(U8), Str, (List(U8) -> Try(List(U8), err)) -> Try(List(U8), err)) -> Try(List(U8), err)) -> Try(List(U8), err)
	encode_record = |out, len, write_fields|
		write_fields(
			write_head(out, 5, len),
			|so_far, name, write_value| {
				Ok(with_key) = Cbor.encode_str(name, so_far)
				write_value(with_key)
			},
		)

	# ---- blobs: for types that ask for them ----------------------------------

	## A byte string, major type 2. Its error is the one blob types ask for.
	parse_bytes : Cbor, List(U8) -> Try({ value : List(U8), rest : List(U8) }, [InvalidBlob(Str)])
	parse_bytes = |_, input| {
		read_blob(input).map_err(|InvalidCbor(problem)| InvalidBlob(problem))
	}

	encode_bytes : List(U8), List(U8) -> Try(List(U8), [])
	encode_bytes = |blob, out| Ok(write_head(out, 2, blob.len()).concat(blob))
}

read_blob : List(U8) -> Try({ value : List(U8), rest : List(U8) }, [InvalidCbor(Str)])
read_blob = |input| {
	h = read_head(input, 2, "a byte string")?
	take(h.rest, h.arg)
}

## Every item starts with a head byte: 3 bits of major type, then 5 bits of
## "additional info". Arguments below 24 fit in those 5 bits; bigger ones
## follow in 1, 2, 4 or 8 big-endian bytes (additional info 24, 25, 26, 27).
write_head : List(U8), U8, U64 -> List(U8)
write_head = |out, major, n| {
	m = major.shl_wrap(5)
	if n < 24 {
		out.append(m.bitwise_or(n.to_u8_wrap()))
	} else if n <= 0xFF {
		out.append(m.bitwise_or(24)).concat(big_endian(n, 1))
	} else if n <= 0xFFFF {
		out.append(m.bitwise_or(25)).concat(big_endian(n, 2))
	} else if n <= 0xFFFF_FFFF {
		out.append(m.bitwise_or(26)).concat(big_endian(n, 4))
	} else {
		out.append(m.bitwise_or(27)).concat(big_endian(n, 8))
	}
}

big_endian : U64, U8 -> List(U8)
big_endian = |n, byte_count| {
	var $out = []
	var $i = byte_count
	while $i > 0 {
		$i = $i - 1
		$out = $out.append(n.shr_zf_wrap($i * 8).to_u8_wrap())
	}
	$out
}

## Read a head of the expected major type.
read_head : List(U8), U8, Str -> Try({ arg : U64, rest : List(U8) }, [InvalidCbor(Str)])
read_head = |input, expected_major, what| {
	h = read_any_head(input)?
	if h.major == expected_major {
		Ok({ arg: h.arg, rest: h.rest })
	} else {
		Err(InvalidCbor("expected ${what}, got ${major_name(h.major)}"))
	}
}

read_any_head : List(U8) -> Try({ major : U8, arg : U64, rest : List(U8) }, [InvalidCbor(Str)])
read_any_head = |input| match input {
	[] => Err(InvalidCbor("unexpected end of input"))
	[initial, .. as rest] => {
		major = initial.shr_zf_wrap(5)
		info = initial.bitwise_and(0x1F)
		if info < 24 {
			Ok({ major, arg: info.to_u64(), rest })
		} else {
			size = match info {
				24 => 1
				25 => 2
				26 => 4
				27 => 8
				_ => return Err(InvalidCbor("indefinite-length items"))
			}
			n = take(rest, size)?
			Ok({ major, arg: n.value.fold(0, |acc, b| acc.shl_wrap(8).bitwise_or(b.to_u64())), rest: n.rest })
		}
	}
}

major_name : U8 -> Str
major_name = |major| match major {
	0 => "an unsigned integer"
	1 => "a negative integer"
	2 => "a byte string"
	3 => "a text string"
	4 => "an array"
	5 => "a map"
	6 => "a tag"
	_ => "a simple value or float"
}

take : List(U8), U64 -> Try({ value : List(U8), rest : List(U8) }, [InvalidCbor(Str)])
take = |input, n| {
	if input.len() < n {
		Err(InvalidCbor("unexpected end of input"))
	} else {
		Ok({ value: input.take_first(n), rest: input.drop_first(n) })
	}
}

## Step over one complete item of any type without decoding it.
skip : List(U8) -> Try(List(U8), [InvalidCbor(Str)])
skip = |input| {
	h = read_any_head(input)?
	match h.major {
		2 | 3 => take(h.rest, h.arg).map_ok(|r| r.rest)
		4 => skip_items(h.rest, h.arg, 1)
		5 => skip_items(h.rest, h.arg, 2)
		6 => skip(h.rest)
		_ => Ok(h.rest)
	}
}

skip_items : List(U8), U64, U8 -> Try(List(U8), [InvalidCbor(Str)])
skip_items = |input, count, per_entry| {
	var $rest = input
	var $remaining = count
	while $remaining > 0 {
		var $i = per_entry
		while $i > 0 {
			$rest = skip($rest)?
			$i = $i - 1
		}
		$remaining = $remaining - 1
	}
	Ok($rest)
}

# ---- tests (RFC 8949 Appendix A vectors) -----------------------------------------

expect Cbor.to_bytes(0.U64) == [0x00]
expect Cbor.to_bytes(24.U64) == [0x18, 0x18]
expect Cbor.to_bytes(1000.U64) == [0x19, 0x03, 0xE8]
expect Cbor.to_bytes(1000000000000.U64) == [0x1B, 0x00, 0x00, 0x00, 0xE8, 0xD4, 0xA5, 0x10, 0x00]
expect Cbor.to_bytes("a") == [0x61, 0x61]
expect Cbor.to_bytes([1.U8, 2, 3]) == [0x83, 0x01, 0x02, 0x03]

expect {
	result : Try(U64, _)
	result = Cbor.parse([0x19, 0x03, 0xE8])
	result == Ok(1000)
}

expect {
	result : Try({ a : U64, b : List(U64) }, _)
	result = Cbor.parse([0xA2, 0x61, 0x61, 0x01, 0x61, 0x62, 0x82, 0x02, 0x03])
	result == Ok({ a: 1, b: [2, 3] })
}

# A key the record doesn't have is skipped, however deeply nested its value.
# {"skip": [1, {"x": h'00'}], "want": 5}
expect {
	result : Try({ want : U64 }, _)
	result = Cbor.parse([0xA2, 0x64, 0x73, 0x6B, 0x69, 0x70, 0x82, 0x01, 0xA1, 0x61, 0x78, 0x41, 0x00, 0x64, 0x77, 0x61, 0x6E, 0x74, 0x05])
	result == Ok({ want: 5 })
}

expect {
	result : Try(U64, _)
	result = Cbor.parse([0x19, 0x03])
	result == Err(InvalidCbor("unexpected end of input"))
}
