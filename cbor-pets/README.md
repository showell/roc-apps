# cbor-pets (new Roc compiler)

Read a profile from CBOR, age the pets, edit the picture, write it back.

    in:  {"name": "Ada", "pets": [3, 7], "pic": h'004080FF'}
    out: {"name": "Ada", "pets": [4, 8], "pic": h'FFBF7F00'}

Tested with `nightly-2026-09-22-e494788` (the one in `roc-nightly.txt`) and
`nightly-2026-09-25-1ab6804`:

    roc test Profile.roc     # 24 expects across all four modules
    roc main.roc             # prints the in/out bytes as hex
    roc main.roc -- Steve    # same, with a different name

## Files

- `CborEncode.roc`: encoders. Each returns one item's bytes, and you nest calls to build a document.
- `CborDecode.roc`: decoders. Each reads one item and returns `{ value, rest }`.
- `ImageBlob.roc`: a pretend image library with an opaque `ImageBlob`.
- `Profile.roc`: the app's type, plus `from_cbor`/`to_cbor`, the only code that knows the wire format.
- `main.roc`: a headerless app (echo platform) that runs the round trip.

## Where the boundary is

`Profile` is `{ name : Str, pet_ages : List(U8), picture : ImageBlob }`, and
nothing in it mentions CBOR. The wire format lives in two functions:

    decoder = |input| {
        m = CborDecode.map(input)?
        name = CborDecode.field(m.value, "name", CborDecode.text)?
        pet_ages = CborDecode.field(m.value, "pets", CborDecode.array(CborDecode.u8))?
        pic = CborDecode.field(m.value, "pic", CborDecode.bytes)?
        Ok({ value: Profile.{ name, pet_ages, picture: ImageBlob.from_bytes(pic) }, rest: m.rest })
    }

    to_cbor = |Profile.{ name, pet_ages, picture }|
        CborEncode.map([
            ("name", CborEncode.text(name)),
            ("pets", CborEncode.array(pet_ages, CborEncode.u8)),
            ("pic", CborEncode.bytes(picture.to_bytes())),
        ])

Blob or list of ints is decided per field, right there: `bytes` versus
`array(u8)`. The mismatched encoding is rejected, and tests cover both
directions.

## Why not an AST

This avoids the objection notramo raised on Zulip, that decoding into an
AST wastes memory. `CborDecode.map` doesn't decode the entries: it returns
a `MapView`, which is an entry count plus the bytes where the entries start.
`field` walks those bytes, skipping entries it doesn't want (`skip` steps over
any item without building it) and decoding the one it wants straight into its
final type. Keys can arrive in any order. The cost is that each `field` call
rescans the map from the start, which is fine for small records.

## Why not `parser_for` / `encoder_for`

A derived parser gets its instructions from the *type*. Both fields are
`List(U8)`, so the format can't give them different representations unless
one of them becomes a different type. notramo doesn't want to change program
types to steer a serializer. Here, `Profile` keeps `ImageBlob` because the
program wants that type anyway, and the CBOR choices stay in `from_cbor`/`to_cbor`.
