## Stand-in for a real image library. The point is its signature: it takes an
## `ImageBlob`, not a `List(U8)`, so nobody can hand it a list of pet ages.
## `::` makes the type opaque: other modules can't see the bytes inside.
ImageBlob :: List(U8).{
	from_bytes : List(U8) -> ImageBlob
	from_bytes = |bytes| ImageBlob.(bytes)

	to_bytes : ImageBlob -> List(U8)
	to_bytes = |ImageBlob.(bytes)| bytes

	## Pretend the blob is raw 8-bit grayscale pixels and make a negative.
	invert : ImageBlob -> ImageBlob
	invert = |ImageBlob.(pixels)| ImageBlob.(pixels.map(|p| 255 - p))
}

expect ImageBlob.from_bytes([0, 64, 255]).invert().to_bytes() == [255, 191, 0]
