# cbor-pets

Read a profile from CBOR, age the pets, edit the picture, write it back, with
no hand-written serialization code for the profile.

    in:  {"name": "Ada", "pet_ages": [3, 7], "picture": h'004080FF'}
    out: {"name": "Ada", "pet_ages": [4, 8], "picture": h'FFBF7F00'}

Tested with `nightly-2026-09-22-e494788` (the one in `roc-nightly.txt`) and
`nightly-2026-09-25-1ab6804`:

    roc test Profile.roc     # 16 expects across the three modules
    roc main.roc             # prints the in/out bytes as hex
    roc main.roc -- Steve    # same, with a different name

## The whole boilerplate

```roc
Profile := { name : Str, pet_ages : List(U8), picture : ImageBlob }.{
	parser_for : _
	encoder_for : _
	...
}

profile : Try(Profile, _)
profile = Cbor.parse(bytes)

bytes = Cbor.to_bytes(profile)
```

`Cbor.parse` works the way `Json.parse` does: its return type is `Try(a, _)`,
the caller's expected type fixes `a = Profile`, and `Cbor.parse` calls
`Profile.parser_for(Cbor.Default)`. The compiler derives that parser from the
field types, and it calls `Cbor`'s `parse_record_start`, `parse_str`,
`parse_list_start`, `parse_u8` and so on.

## Blob or list of numbers

The field's type decides:

- `pet_ages : List(U8)` goes through the derived list parser, so it's a CBOR
  **array** (major type 4).
- `picture : ImageBlob` has its own `parser_for`/`encoder_for`, which ask the
  format for `parse_bytes`/`encode_bytes`, so it's a CBOR **byte string**
  (major type 2).

`ImageBlob` doesn't mention CBOR. It only says "I'm a blob in any format that
has blobs". Using it with a format that lacks `parse_bytes` (such as `Json`)
is a compile error, not a silent fallback to a list of numbers. Tests check
both mismatches: pets sent as a byte string, and the picture sent as an array.

## Files

- `Cbor.roc`: the format (`Cbor.parse`, `Cbor.to_bytes`, and the
  `parse_*`/`encode_*` methods derived code calls). It implements only what
  this example needs: text, `U8`/`U64`, arrays, maps with text keys, and byte
  strings.
- `ImageBlob.roc`: a pretend image library with an opaque `ImageBlob` that
  knows it's a blob.
- `Profile.roc`: the app's type, with `parser_for : _` and `encoder_for : _`.
- `main.roc`: a headerless app (echo platform) that runs the round trip.

## Two compiler workarounds in ImageBlob

Both reproduce on the 09-22 and 09-25 nightlies.

- **Its error type is a concrete `[InvalidBlob(Str)]`,** not a type variable
  passed through from the format. With a type variable, the checker closes
  it to `[]` when the blob is a record field, and the format's
  `parse_bytes` then fails to type-check. The langref's own `Token` example
  (a custom `parser_for`, generic over the format) hits the same error as a
  record field with `Json`.
- **Its bytes are in a record, `{ bytes : List(U8) }`,** rather than being
  the backing type. A custom-parsed nominal type backed directly by
  `List(U8)` makes the compiler hang when it's a field of a derived record,
  whether parsing or encoding.
