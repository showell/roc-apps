## Elm-style CBOR decoders (RFC 8949). A decoder reads one data item from the
## front of the input and returns `{ value, rest }`.
##
## No intermediate tree is built. `map` doesn't decode the map's entries; it
## hands back a `MapView` (an entry count plus the bytes where the entries
## start), and `field` walks those bytes, skipping entries it doesn't want and
## decoding the one it does straight into its final type.
##
## Unlike derived parsing, the caller picks the representation per field:
## `bytes` accepts only a byte string (major type 2), and `array(u8)` accepts
## only an array (major type 4). Sending one where the other is expected is an
## error, not a silent conversion.
CborDecode :: [].{
	MapView := { count : U64, entries : List(U8) }

	Problem : [UnexpectedEnd, Unsupported(Str), WrongType(Str), InvalidUtf8, MissingField(Str), TrailingBytes]

	## Reads one item from the front of the input.
	Decoder(a) : List(U8) -> Try({ value : a, rest : List(U8) }, CborDecode.Problem)

	uint : CborDecode.Decoder(U64)
	uint = |input| {
		h = read_head(input)?
		if h.major != 0 {
			return Err(WrongType("expected an unsigned integer"))
		}
		Ok({ value: h.arg, rest: h.rest })
	}

	u8 : CborDecode.Decoder(U8)
	u8 = |input| {
		r = CborDecode.uint(input)?
		match r.value.to_u8_try() {
			Ok(n) => Ok({ value: n, rest: r.rest })
			Err(OutOfRange) => Err(WrongType("expected an integer 0-255"))
		}
	}

	text : CborDecode.Decoder(Str)
	text = |input| {
		h = read_head(input)?
		if h.major != 3 {
			return Err(WrongType("expected a text string"))
		}
		chunk = take(h.rest, h.arg)?
		match Str.from_utf8(chunk.value) {
			Ok(str) => Ok({ value: str, rest: chunk.rest })
			Err(_) => Err(InvalidUtf8)
		}
	}

	## A blob: major type 2 only.
	bytes : CborDecode.Decoder(List(U8))
	bytes = |input| {
		h = read_head(input)?
		match h.major {
			2 => take(h.rest, h.arg)
			4 => Err(WrongType("expected a byte string, got an array"))
			_ => Err(WrongType("expected a byte string"))
		}
	}

	## A list: major type 4 only, each item read by `decode_item`.
	array : CborDecode.Decoder(a) -> CborDecode.Decoder(List(a))
	array = |decode_item| |input| {
		h = read_head(input)?
		match h.major {
			4 => {
				var $items = []
				var $rest = h.rest
				var $remaining = h.arg
				while $remaining > 0 {
					r = decode_item($rest)?
					$items = $items.append(r.value)
					$rest = r.rest
					$remaining = $remaining - 1
				}
				Ok({ value: $items, rest: $rest })
			}
			2 => Err(WrongType("expected an array, got a byte string"))
			_ => Err(WrongType("expected an array"))
		}
	}

	## A map, without decoding its entries. `rest` is the input after the map.
	map : CborDecode.Decoder(CborDecode.MapView)
	map = |input| {
		h = read_head(input)?
		if h.major != 5 {
			return Err(WrongType("expected a map"))
		}
		after = skip_items(h.rest, h.arg, 2)?
		Ok({ value: MapView.{ count: h.arg, entries: h.rest }, rest: after })
	}

	## Find the entry whose key is `key` and decode its value with `decode_value`.
	field : CborDecode.MapView, Str, CborDecode.Decoder(a) -> Try(a, CborDecode.Problem)
	field = |MapView.{ count, entries }, key, decode_value| {
		var $rest = entries
		var $remaining = count
		while $remaining > 0 {
			k = CborDecode.text($rest)?
			if k.value == key {
				r = decode_value(k.rest)?
				return Ok(r.value)
			}
			$rest = skip(k.rest)?
			$remaining = $remaining - 1
		}
		Err(MissingField(key))
	}

	## Run a decoder on a whole document, rejecting anything left over.
	all : List(U8), CborDecode.Decoder(a) -> Try(a, CborDecode.Problem)
	all = |input, decode| {
		r = decode(input)?
		if r.rest.is_empty() Ok(r.value) else Err(TrailingBytes)
	}
}

## Split an item's head into major type, argument and the bytes that follow.
read_head : List(U8) -> Try({ major : U8, arg : U64, rest : List(U8) }, CborDecode.Problem)
read_head = |input| match input {
	[] => Err(UnexpectedEnd)
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
				_ => return Err(Unsupported("indefinite-length items"))
			}
			n = take(rest, size)?
			Ok({ major, arg: n.value.fold(0, |acc, b| acc.shl_wrap(8).bitwise_or(b.to_u64())), rest: n.rest })
		}
	}
}

take : List(U8), U64 -> Try({ value : List(U8), rest : List(U8) }, CborDecode.Problem)
take = |input, n| {
	if input.len() < n {
		Err(UnexpectedEnd)
	} else {
		Ok({ value: input.take_first(n), rest: input.drop_first(n) })
	}
}

## Step over one complete item of any type without decoding it.
skip : List(U8) -> Try(List(U8), CborDecode.Problem)
skip = |input| {
	h = read_head(input)?
	match h.major {
		2 | 3 => take(h.rest, h.arg).map_ok(|r| r.rest)
		4 => skip_items(h.rest, h.arg, 1)
		5 => skip_items(h.rest, h.arg, 2)
		6 => skip(h.rest) # a semantic tag wraps exactly one item
		_ => Ok(h.rest)
	}
}

skip_items : List(U8), U64, U8 -> Try(List(U8), CborDecode.Problem)
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

# ---- tests ----------------------------------------------------------------

expect CborDecode.uint([0x19, 0x03, 0xE8]) == Ok({ value: 1000, rest: [] })
expect CborDecode.text([0x61, 0x61, 0xFF]) == Ok({ value: "a", rest: [0xFF] })
expect CborDecode.uint([0x19, 0x03]) == Err(UnexpectedEnd)

# The same numbers, two different encodings, and each decoder takes only its own.
expect CborDecode.bytes([0x42, 0x03, 0x07]) == Ok({ value: [3, 7], rest: [] })
expect CborDecode.array(CborDecode.u8)([0x82, 0x03, 0x07]) == Ok({ value: [3, 7], rest: [] })
expect CborDecode.bytes([0x82, 0x03, 0x07]) == Err(WrongType("expected a byte string, got an array"))
expect CborDecode.array(CborDecode.u8)([0x42, 0x03, 0x07]) == Err(WrongType("expected an array, got a byte string"))

# `field` skips entries it doesn't want, including nested ones:
# {"skip": [1, {"x": h'00'}], "want": 5}
expect {
	doc = [0xA2, 0x64, 0x73, 0x6B, 0x69, 0x70, 0x82, 0x01, 0xA1, 0x61, 0x78, 0x41, 0x00, 0x64, 0x77, 0x61, 0x6E, 0x74, 0x05]
	CborDecode.all(
		doc,
		|input| {
			m = CborDecode.map(input)?
			want = CborDecode.field(m.value, "want", CborDecode.uint)?
			Ok({ value: want, rest: m.rest })
		},
	) == Ok(5)
}
