## Elm-style CBOR encoders (RFC 8949). Each function returns the bytes for one
## data item, so you build a document by nesting calls. There is no
## intermediate tree, and nothing guesses: `bytes` writes a byte string
## (major type 2) and `array` writes an array (major type 4), even when both
## start out as a `List(U8)`.
CborEncode :: [].{
	uint : U64 -> List(U8)
	uint = |n| head(0, n)

	u8 : U8 -> List(U8)
	u8 = |n| head(0, n.to_u64())

	text : Str -> List(U8)
	text = |str| {
		utf8 = str.to_utf8()
		head(3, utf8.len()).concat(utf8)
	}

	## A blob: major type 2.
	bytes : List(U8) -> List(U8)
	bytes = |blob| head(2, blob.len()).concat(blob)

	## A list of items: major type 4, each item written by `encode_item`.
	array : List(a), (a -> List(U8)) -> List(U8)
	array = |items, encode_item| items.fold(head(4, items.len()), |acc, item| acc.concat(encode_item(item)))

	## A map with text keys. Each value is already-encoded bytes.
	map : List((Str, List(U8))) -> List(U8)
	map = |entries| entries.fold(head(5, entries.len()), |acc, (key, value)| acc.concat(CborEncode.text(key)).concat(value))
}

## Every item starts with a head byte: 3 bits of major type, then 5 bits of
## "additional info". Arguments below 24 fit in those 5 bits; bigger ones
## follow in 1, 2, 4 or 8 big-endian bytes (additional info 24, 25, 26, 27).
head : U8, U64 -> List(U8)
head = |major, n| {
	m = major.shl_wrap(5)
	if n < 24 {
		[m.bitwise_or(n.to_u8_wrap())]
	} else if n <= 0xFF {
		[m.bitwise_or(24)].concat(big_endian(n, 1))
	} else if n <= 0xFFFF {
		[m.bitwise_or(25)].concat(big_endian(n, 2))
	} else if n <= 0xFFFF_FFFF {
		[m.bitwise_or(26)].concat(big_endian(n, 4))
	} else {
		[m.bitwise_or(27)].concat(big_endian(n, 8))
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

# RFC 8949 Appendix A vectors
expect CborEncode.uint(0) == [0x00]
expect CborEncode.uint(23) == [0x17]
expect CborEncode.uint(24) == [0x18, 0x18]
expect CborEncode.uint(1000) == [0x19, 0x03, 0xE8]
expect CborEncode.uint(1000000) == [0x1A, 0x00, 0x0F, 0x42, 0x40]
expect CborEncode.uint(1000000000000) == [0x1B, 0x00, 0x00, 0x00, 0xE8, 0xD4, 0xA5, 0x10, 0x00]
expect CborEncode.text("a") == [0x61, 0x61]
expect CborEncode.bytes([1, 2, 3, 4]) == [0x44, 0x01, 0x02, 0x03, 0x04]

# The same List(U8), two different encodings:
expect CborEncode.bytes([3, 7]) == [0x42, 0x03, 0x07]
expect CborEncode.array([3, 7], CborEncode.u8) == [0x82, 0x03, 0x07]
