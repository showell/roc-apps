## Hex writes the hex digits that RasterFrame and ShapesFrame print. They print a frame's
## pixels as six hex digits each, for pixels_png.mjs, and RasterFrame prints
## its hash as eight.

Hex :: [].{

	## `number`'s low `digits` hex digits, lowercase and most significant
	## first, appended to `out`.
	append_digits : List(U8), { number : I64, digits : U64 } -> List(U8)
	append_digits = |out, { number, digits }| {
		var $out = out
		var $k = digits
		while $k > 0 {
			$k = $k - 1
			shift = U64.to_u8_wrap(4 * $k)
			nibble = I64.bitwise_and(I64.shr_wrap(number, shift), 15)
			# 48 is '0', and 87 is 'a' less ten.
			code = if nibble < 10 {
				nibble + 48
			} else {
				nibble + 87
			}
			$out = $out.append(I64.to_u8_wrap(code))
		}
		$out
	}
}
