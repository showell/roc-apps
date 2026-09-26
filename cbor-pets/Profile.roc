import Cbor
import ImageBlob

## The app's own type. `parser_for : _` and `encoder_for : _` ask the compiler
## to derive both, so `Cbor.parse` and `Cbor.to_bytes` just work. The field
## types do the rest: `List(U8)` becomes a CBOR array of numbers, and
## `ImageBlob` becomes a byte string because that's what an image is.
Profile := { name : Str, pet_ages : List(U8), picture : ImageBlob }.{
	parser_for : _
	encoder_for : _

	## Every pet ages by a year.
	one_year_later : Profile -> Profile
	one_year_later = |Profile.{ name, pet_ages, picture }|
		Profile.{ name, pet_ages: pet_ages.map(|age| age + 1), picture }

	edit_picture : Profile -> Profile
	edit_picture = |Profile.{ name, pet_ages, picture }|
		Profile.{ name, pet_ages, picture: picture.invert() }
}

# ---- tests ------------------------------------------------------------------
# Fixtures were checked against an independent Python encoder.

# {"name": "Ada", "pet_ages": [3, 7], "picture": h'004080FF'}
input : List(U8)
input = [0xA3, 0x64, 0x6E, 0x61, 0x6D, 0x65, 0x63, 0x41, 0x64, 0x61, 0x68, 0x70, 0x65, 0x74, 0x5F, 0x61, 0x67, 0x65, 0x73, 0x82, 0x03, 0x07, 0x67, 0x70, 0x69, 0x63, 0x74, 0x75, 0x72, 0x65, 0x44, 0x00, 0x40, 0x80, 0xFF]

# {"name": "Ada", "pet_ages": [4, 8], "picture": h'FFBF7F00'}
expected : List(U8)
expected = [0xA3, 0x64, 0x6E, 0x61, 0x6D, 0x65, 0x63, 0x41, 0x64, 0x61, 0x68, 0x70, 0x65, 0x74, 0x5F, 0x61, 0x67, 0x65, 0x73, 0x82, 0x04, 0x08, 0x67, 0x70, 0x69, 0x63, 0x74, 0x75, 0x72, 0x65, 0x44, 0xFF, 0xBF, 0x7F, 0x00]

# The whole story: decode, age the pets, edit the picture, encode.
expect {
	profile : Try(Profile, _)
	profile = Cbor.parse(input)
	profile.map_ok(|p| Cbor.to_bytes(p.one_year_later().edit_picture())) == Ok(expected)
}

# Encoding what we decoded gives back the same bytes.
expect {
	profile : Try(Profile, _)
	profile = Cbor.parse(input)
	profile.map_ok(Cbor.to_bytes) == Ok(input)
}

# notramo's distinction, as tests: swap the two encodings and decoding fails.
expect {
	pets_as_blob = input.take_first(19).concat([0x42, 0x03, 0x07]).concat(input.drop_first(22))
	profile : Try(Profile, _)
	profile = Cbor.parse(pets_as_blob)
	profile.map_ok(Cbor.to_bytes) == Err(InvalidCbor("expected an array, got a byte string"))
}

expect {
	pic_as_array = input.take_first(30).concat([0x84, 0x00, 0x18, 0x40, 0x18, 0x80, 0x18, 0xFF])
	profile : Try(Profile, _)
	profile = Cbor.parse(pic_as_array)
	profile.map_ok(Cbor.to_bytes) == Err(InvalidBlob("expected a byte string, got an array"))
}

# A missing field is reported by name.
expect {
	name_only = [0xA1, 0x64, 0x6E, 0x61, 0x6D, 0x65, 0x63, 0x41, 0x64, 0x61]
	profile : Try(Profile, _)
	profile = Cbor.parse(name_only)
	profile.map_ok(Cbor.to_bytes) == Err(MissingRequiredField("pet_ages"))
}
