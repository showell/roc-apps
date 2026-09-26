import Cbor
import ImageBlob
import Profile

main! = |args| {
	# Pretend these bytes came from a file or the network.
	# (Taking the name from the command line keeps the compiler from
	# evaluating the whole program at compile time.)
	name = args.first().ok_or("Ada")
	start : Profile
	start = { name, pet_ages: [3, 7], picture: ImageBlob.from_bytes([0x00, 0x40, 0x80, 0xFF]) }
	input = Cbor.to_bytes(start)
	echo!("in:  ${hex(input)}\n")

	profile : Try(Profile, _)
	profile = Cbor.parse(input)

	match profile {
		Ok(p) => echo!("out: ${hex(Cbor.to_bytes(p.one_year_later().edit_picture()))}\n")
		Err(problem) => echo!("could not decode: ${Str.inspect(problem)}\n")
	}

	Ok({})
}

hex : List(U8) -> Str
hex = |bytes| bytes.fold(
	"",
	|acc, b| {
		digits = "0123456789abcdef".to_utf8()
		hi = digits.get(b.shr_zf_wrap(4).to_u64()).ok_or(0)
		lo = digits.get(b.bitwise_and(0x0F).to_u64()).ok_or(0)
		Str.concat(acc, Str.from_utf8([hi, lo]).ok_or("?"))
	},
)
