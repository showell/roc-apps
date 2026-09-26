import CborDecode
import CborEncode
import ImageBlob

## The app's own type. Nothing in it mentions CBOR: `picture` is an
## `ImageBlob` because that's what it *is*, not to steer a serializer.
Profile := { name : Str, pet_ages : List(U8), picture : ImageBlob }.{
	birthday : Profile -> Profile
	birthday = |Profile.{ name, pet_ages, picture }|
		Profile.{ name, pet_ages: pet_ages.map(|age| age + 1), picture }

	edit_picture : Profile -> Profile
	edit_picture = |Profile.{ name, pet_ages, picture }|
		Profile.{ name, pet_ages, picture: picture.invert() }

	# ---- the boundary: this is the only place that knows the wire format ----

	from_cbor : List(U8) -> Try(Profile, CborDecode.Problem)
	from_cbor = |input| CborDecode.all(input, decoder)

	to_cbor : Profile -> List(U8)
	to_cbor = |Profile.{ name, pet_ages, picture }|
		CborEncode.map([
			("name", CborEncode.text(name)),
			("pets", CborEncode.array(pet_ages, CborEncode.u8)), # array of ints
			("pic", CborEncode.bytes(picture.to_bytes())), # blob
		])
}

decoder : CborDecode.Decoder(Profile)
decoder = |input| {
	m = CborDecode.map(input)?
	name = CborDecode.field(m.value, "name", CborDecode.text)?
	pet_ages = CborDecode.field(m.value, "pets", CborDecode.array(CborDecode.u8))? # array of ints
	pic = CborDecode.field(m.value, "pic", CborDecode.bytes)? # blob
	Ok({ value: Profile.{ name, pet_ages, picture: ImageBlob.from_bytes(pic) }, rest: m.rest })
}

# ---- tests ------------------------------------------------------------------

# {"name": "Ada", "pets": [3, 7], "pic": h'004080FF'}
input : List(U8)
input = [
	0xA3,
	0x64,
	0x6E,
	0x61,
	0x6D,
	0x65,
	0x63,
	0x41,
	0x64,
	0x61,
	0x64,
	0x70,
	0x65,
	0x74,
	0x73,
	0x82,
	0x03,
	0x07,
	0x63,
	0x70,
	0x69,
	0x63,
	0x44,
	0x00,
	0x40,
	0x80,
	0xFF,
]

# {"name": "Ada", "pets": [4, 8], "pic": h'FFBF7F00'}
expected : List(U8)
expected = [
	0xA3,
	0x64,
	0x6E,
	0x61,
	0x6D,
	0x65,
	0x63,
	0x41,
	0x64,
	0x61,
	0x64,
	0x70,
	0x65,
	0x74,
	0x73,
	0x82,
	0x04,
	0x08,
	0x63,
	0x70,
	0x69,
	0x63,
	0x44,
	0xFF,
	0xBF,
	0x7F,
	0x00,
]

# The whole story: decode, age the pets, edit the picture, encode.
expect {
	updated = Profile.from_cbor(input).map_ok(|p| p.birthday().edit_picture().to_cbor())
	updated == Ok(expected)
}

# Encoding what we decoded gives back the same bytes.
expect Profile.from_cbor(input).map_ok(|p| p.to_cbor()) == Ok(input)

# Keys can come in any order: {"pic": ..., "pets": ..., "name": ...}
expect {
	reordered = [0xA3, 0x63, 0x70, 0x69, 0x63, 0x44, 0x00, 0x40, 0x80, 0xFF, 0x64, 0x70, 0x65, 0x74, 0x73, 0x82, 0x03, 0x07, 0x64, 0x6E, 0x61, 0x6D, 0x65, 0x63, 0x41, 0x64, 0x61]
	Profile.from_cbor(reordered).map_ok(|p| p.to_cbor()) == Ok(input)
}

# notramo's distinction, as tests: swap the two encodings and decoding fails.
expect {
	pets_as_blob = input.take_first(15).concat([0x42, 0x03, 0x07]).concat(input.drop_first(18))
	Profile.from_cbor(pets_as_blob).map_ok(|p| p.to_cbor()) == Err(WrongType("expected an array, got a byte string"))
}

expect {
	pic_as_array = input.take_first(22).concat([0x84, 0x00, 0x18, 0x40, 0x18, 0x80, 0x18, 0xFF])
	Profile.from_cbor(pic_as_array).map_ok(|p| p.to_cbor()) == Err(WrongType("expected a byte string, got an array"))
}
