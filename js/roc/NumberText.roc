# This module writes a number the way JavaScript's `String(n)` does
# (ECMAScript's Number::toString): the shortest digits that read back as the
# same number, with an exponent only below 1e-6 or from 1e21 up.
#
# Roc's own `F64.to_str` already finds the shortest digits; this module only
# moves the decimal point and the exponent to where JavaScript puts them.
NumberText :: [].{
	# The text of a number, as `String(n)` gives it: -0 is "0".
	of : F64 -> Str
	of = |n|
		if n.is_nan() {
			"NaN"
		} else if n.is_infinite() {
			if n > 0.0 {
				"Infinity"
			} else {
				"-Infinity"
			}
		} else if n == 0.0 {
			"0"
		} else if n < 0.0 {
			"-${NumberText.of_positive(-n)}"
		} else {
			NumberText.of_positive(n)
		}

	# The shortest digits of a positive finite number, and its exponent `n` as
	# ECMAScript names it: the number is 0.d1d2... times 10 to the `n`.
	Digits : { digits : List(U8), point : I64 }

	digits_of : F64 -> NumberText.Digits
	digits_of = |n| {
		text = n.to_str()
		{ mantissa, exponent } = match text.split_first("e") {
			Ok({ before, after }) => {
				mantissa: before,
				exponent: I64.from_str(after) ?? crash "NumberText.digits_of: F64.to_str wrote an exponent that is no integer",
			}
			Err(NotFound) => { mantissa: text, exponent: 0 }
		}
		{ whole, fraction } = match mantissa.split_first(".") {
			Ok({ before, after }) => { whole: before.to_utf8(), fraction: after.to_utf8() }
			Err(NotFound) => { whole: mantissa.to_utf8(), fraction: [] }
		}
		all = whole.concat(fraction)
		leading = NumberText.leading_zero_count(all)
		trimmed = NumberText.without_trailing_zeros(all.drop_first(leading))
		{
			digits: trimmed,
			point: whole.len().to_i64_wrap() - leading.to_i64_wrap() + exponent,
		}
	}

	is_zero_at : List(U8), U64 -> Bool
	is_zero_at = |bytes, i| match bytes.get(i) {
		Ok(b) => b == '0'
		Err(OutOfBounds) => False
	}

	leading_zero_count : List(U8) -> U64
	leading_zero_count = |bytes| {
		var $i = 0
		while NumberText.is_zero_at(bytes, $i) {
			$i = $i + 1
		}
		$i
	}

	without_trailing_zeros : List(U8) -> List(U8)
	without_trailing_zeros = |bytes| {
		var $n = bytes.len()
		while $n > 0 and NumberText.is_zero_at(bytes, $n - 1) {
			$n = $n - 1
		}
		bytes.sublist({ start: 0, len: $n })
	}

	of_positive : F64 -> Str
	of_positive = |x| {
		{ digits, point } = NumberText.digits_of(x)
		k = digits.len().to_i64_wrap()
		text = if k <= point and point <= 21 {
			digits.concat(List.repeat('0', (point - k).to_u64_wrap()))
		} else if 0 < point and point <= 21 {
			at = point.to_u64_wrap()
			digits.sublist({ start: 0, len: at }).append('.').concat(digits.drop_first(at))
		} else if -6 < point and point <= 0 {
			['0', '.'].concat(List.repeat('0', (-point).to_u64_wrap())).concat(digits)
		} else {
			exponent = point - 1
			sign = if exponent < 0 {
				"-"
			} else {
				"+"
			}
			first = digits.sublist({ start: 0, len: 1 })
			rest = digits.drop_first(1)
			mantissa = if rest.is_empty() {
				first
			} else {
				first.append('.').concat(rest)
			}
			mantissa.concat("e${sign}${exponent.abs().to_str()}".to_utf8())
		}
		Str.from_utf8(text) ?? crash "NumberText.of_positive: digits are ASCII"
	}

	expect NumberText.of(0.1 + 0.2) == "0.30000000000000004"
	expect NumberText.of(3.0) == "3"
	expect NumberText.of(-0.0) == "0"
	expect NumberText.of(1.0e21) == "1e+21"
	expect NumberText.of(123456789012345680000.0) == "123456789012345680000"
	expect NumberText.of(0.000001) == "0.000001"
	expect NumberText.of(0.0000001) == "1e-7"
	expect NumberText.of(1.5e-10) == "1.5e-10"
	expect NumberText.of(-2.5) == "-2.5"
	expect NumberText.of(100.0) == "100"
	expect NumberText.of(1234.5678) == "1234.5678"
}
