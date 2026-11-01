# Paint one Safari frame with Raster, natively, and print it: a hash line, the
# size, then every pixel as six hex digits, for ray/pixels_png.mjs.
# Hand-written, like FrameBench.
#
#   roc build --opt=dev RasterFrame.roc --output=<bin>; <bin> [steps] | ray/pixels_png.mjs <png>
import SafariRide
import Raster
import Hex

ride_to : SafariRide.Model, I64 -> SafariRide.Model
ride_to = |m, n| if n <= 0 { m } else { ride_to(SafariRide.advance(m), n - 1) }

# FNV-1a over each pixel's four little-endian bytes. The product stays under
# 2^57, so it needs no wrapping arithmetic.
hash : List(U32) -> I64
hash = |pixels| List.fold(pixels, 2166136261, |h, p| {
	v = U32.to_i64(p)
	b0 = I64.bitwise_and(I64.bitwise_xor(h, I64.bitwise_and(v, 255)) * 16777619, 4294967295)
	b1 = I64.bitwise_and(I64.bitwise_xor(b0, I64.bitwise_and(I64.shr_wrap(v, 8), 255)) * 16777619, 4294967295)
	b2 = I64.bitwise_and(I64.bitwise_xor(b1, I64.bitwise_and(I64.shr_wrap(v, 16), 255)) * 16777619, 4294967295)
	I64.bitwise_and(I64.bitwise_xor(b2, I64.bitwise_and(I64.shr_wrap(v, 24), 255)) * 16777619, 4294967295)
})

main! = |args| {
	steps = I64.from_str(List.get(args, 0) ?? "0") ?? 0
	m = ride_to(SafariRide.init, steps)
	pixels = Raster.paint({ commands: SafariRide.commands(m), roll: SafariRide.roll(m), sky_top: SafariRide.sky_top(m), sky_horizon: SafariRide.sky_horizon(m), sun: SafariRide.sun(m) })
	var $out = List.with_capacity(List.len(pixels) * 6 + 32)
	$out = List.concat($out, Str.to_utf8("hash "))
	$out = Hex.append_digits($out, { value: hash(pixels), digits: 8 })
	$out = List.concat($out, Str.to_utf8("\n960 600\n"))
	n = List.len(pixels)
	var $k = 0
	while $k < n {
		$out = Hex.append_digits($out, { value: U32.to_i64(List.get(pixels, $k) ?? 0), digits: 6 })
		$k = $k + 1
	}
	echo!(Str.from_utf8_lossy(List.append($out, 10)))
	Ok({})
}
