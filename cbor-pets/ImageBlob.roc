## Stand-in for a real image library. The point is its signature: it takes an
## `ImageBlob`, not a `List(U8)`, so nobody can hand it a list of pet ages.
## `::` makes the type opaque: other modules can't see the bytes inside.
##
## The bytes sit in a record rather than being the backing type directly:
## nightly-2026-09-22 hangs compiling a derived record whose field is a
## custom-parsed nominal backed by a bare `List(U8)`.
ImageBlob :: { bytes : List(U8) }.{
	from_bytes : List(U8) -> ImageBlob
	from_bytes = |bytes| ImageBlob.{ bytes }

	to_bytes : ImageBlob -> List(U8)
	to_bytes = |ImageBlob.{ bytes }| bytes

	## Pretend the blob is raw 8-bit grayscale pixels and make a negative.
	invert : ImageBlob -> ImageBlob
	invert = |ImageBlob.{ bytes }| ImageBlob.{ bytes: bytes.map(|p| 255 - p) }

	## An image is a blob in any format that has one (like CBOR's byte
	## strings). A format without `parse_bytes`/`encode_bytes` is a compile
	## error, not a silent fallback to a list of numbers.
	##
	## The error is a concrete `InvalidBlob(Str)` rather than whatever the
	## format uses: with a type variable there, nightly-2026-09-22 closes the
	## error to `[]` when the blob is a record field (the langref's `Token`
	## example hits the same thing with `Json`).
	parser_for : encoding -> (state -> Try({ value : ImageBlob, rest : state }, [InvalidBlob(Str)]))
		where [encoding.parse_bytes : encoding, state -> Try({ value : List(U8), rest : state }, [InvalidBlob(Str)])]
	parser_for = |encoding| {
		Encoding : encoding
		|state| {
			parsed = Encoding.parse_bytes(encoding, state)?
			Ok({ value: ImageBlob.{ bytes: parsed.value }, rest: parsed.rest })
		}
	}

	encoder_for : encoding -> (ImageBlob, state -> Try(state, encode_err))
		where [encoding.encode_bytes : List(U8), state -> Try(state, encode_err)]
	encoder_for = |_| {
		Encoding : encoding
		|ImageBlob.{ bytes }, state| Encoding.encode_bytes(bytes, state)
	}
}

expect ImageBlob.from_bytes([0, 64, 255]).invert().to_bytes() == [255, 191, 0]
