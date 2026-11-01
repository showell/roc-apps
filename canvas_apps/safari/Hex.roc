# THE HEX DIGITS THE NATIVE PROOF TOOLS PRINT. RasterFrame and ShapesFrame
# print a frame's pixels as six hex digits each, for ray/pixels_png.mjs, and
# RasterFrame prints its hash as eight. Hand-written, like them.

Hex :: [].{
	## `value`'s low `digits` hex digits, lowercase and most significant
	## first, appended to `out`.
	append_digits : List(U8), { value : I64, digits : U64 } -> List(U8)
	append_digits = |out, { value, digits }| {
		var $out = out
		var $k = digits
		while $k > 0 {
			$k = $k - 1
			shift = U64.to_u8_wrap(4 * $k)
			nibble = I64.bitwise_and(I64.shr_wrap(value, shift), 15)
			# 48 is '0', and 87 is 'a' less ten.
			code = if nibble < 10 { nibble + 48 } else { nibble + 87 }
			$out = $out.append(I64.to_u8_wrap(code))
		}
		$out
	}
}
