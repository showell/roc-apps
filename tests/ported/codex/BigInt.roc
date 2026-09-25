# BigInt -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText
import Maybe

BigInt :: [].{
	BigInt := { bi_sign : I64, bi_limbs : List(I64) }.{
		is_eq : BigInt.BigInt, BigInt.BigInt -> Bool
		is_eq = |a, b| a.bi_sign == b.bi_sign and a.bi_limbs == b.bi_limbs
	}

	bigint_base : I64
	bigint_base = 10000

	bigint_zero : BigInt.BigInt
	bigint_zero = BigInt.BigInt.{ bi_sign: 0, bi_limbs: [0] }

	bigint_one : BigInt.BigInt
	bigint_one = BigInt.BigInt.{ bi_sign: 1, bi_limbs: [1] }

	bigint_from_integer : I64 -> BigInt.BigInt
	bigint_from_integer = |n| (if (n == 0) { bigint_zero } else { (if (n > 0) { BigInt.BigInt.{ bi_sign: 1, bi_limbs: bigint_split_limbs(n, []) } } else { BigInt.BigInt.{ bi_sign: (-1), bi_limbs: bigint_split_limbs((-n), []) } }) })

	bigint_split_limbs : I64, List(I64) -> List(I64)
	bigint_split_limbs = |n, acc| (if (n == 0) { (if (U64.to_i64_wrap(List.len(acc)) == 0) { [0] } else { acc }) } else { bigint_split_limbs(I64.div_trunc_by(n, bigint_base), List.append(acc, (n - (I64.div_trunc_by(n, bigint_base) * bigint_base)))) })

	bigint_is_zero : BigInt.BigInt -> Bool
	bigint_is_zero = |a| (a.bi_sign == 0)

	bigint_negate : BigInt.BigInt -> BigInt.BigInt
	bigint_negate = |a| (if (a.bi_sign == 0) { a } else { BigInt.BigInt.{ bi_sign: (-a.bi_sign), bi_limbs: a.bi_limbs } })

	bigint_abs : BigInt.BigInt -> BigInt.BigInt
	bigint_abs = |a| (if (a.bi_sign >= 0) { a } else { BigInt.BigInt.{ bi_sign: 1, bi_limbs: a.bi_limbs } })

	bigint_compare : BigInt.BigInt, BigInt.BigInt -> I64
	bigint_compare = |a, b| (if (a.bi_sign < b.bi_sign) { (-1) } else { (if (a.bi_sign > b.bi_sign) { 1 } else { (if (a.bi_sign == 0) { 0 } else { (if (a.bi_sign > 0) { bigint_compare_limbs(a.bi_limbs, b.bi_limbs) } else { bigint_compare_limbs(b.bi_limbs, a.bi_limbs) }) }) }) })

	bigint_compare_limbs : List(I64), List(I64) -> I64
	bigint_compare_limbs = |a, b| ({
		la : I64
		la = U64.to_i64_wrap(List.len(a))
		lb : I64
		lb = U64.to_i64_wrap(List.len(b))
		(if (la < lb) { (-1) } else { (if (la > lb) { 1 } else { bigint_compare_limbs_rev(a, b, (la - 1)) }) })
	})

	bigint_compare_limbs_rev : List(I64), List(I64), I64 -> I64
	bigint_compare_limbs_rev = |a, b, i| (if (i < 0) { 0 } else { ({
		da : I64
		da = (List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		db : I64
		db = (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (da < db) { (-1) } else { (if (da > db) { 1 } else { bigint_compare_limbs_rev(a, b, (i - 1)) }) })
	}) })

	bigint_eq : BigInt.BigInt, BigInt.BigInt -> Bool
	bigint_eq = |a, b| (bigint_compare(a, b) == 0)

	bigint_lt : BigInt.BigInt, BigInt.BigInt -> Bool
	bigint_lt = |a, b| (bigint_compare(a, b) < 0)

	bigint_gt : BigInt.BigInt, BigInt.BigInt -> Bool
	bigint_gt = |a, b| (bigint_compare(a, b) > 0)

	bigint_add : BigInt.BigInt, BigInt.BigInt -> BigInt.BigInt
	bigint_add = |a, b| (if (a.bi_sign == 0) { b } else { (if (b.bi_sign == 0) { a } else { (if (a.bi_sign == b.bi_sign) { BigInt.BigInt.{ bi_sign: a.bi_sign, bi_limbs: bigint_add_limbs(a.bi_limbs, b.bi_limbs, 0) } } else { ({
		cmp : I64
		cmp = bigint_compare_limbs(a.bi_limbs, b.bi_limbs)
		(if (cmp == 0) { bigint_zero } else { (if (cmp > 0) { BigInt.BigInt.{ bi_sign: a.bi_sign, bi_limbs: bigint_sub_limbs(a.bi_limbs, b.bi_limbs, 0) } } else { BigInt.BigInt.{ bi_sign: b.bi_sign, bi_limbs: bigint_sub_limbs(b.bi_limbs, a.bi_limbs, 0) } }) })
	}) }) }) })

	bigint_add_limbs : List(I64), List(I64), I64 -> List(I64)
	bigint_add_limbs = |a, b, carry| bigint_add_limbs_loop(a, b, carry, 0, bigint_max_len(a, b), [])

	bigint_add_limbs_loop : List(I64), List(I64), I64, I64, I64, List(I64) -> List(I64)
	bigint_add_limbs_loop = |a, b, carry, i, len, acc| (if (i >= len) { (if (carry > 0) { List.append(acc, carry) } else { acc }) } else { ({
		da : I64
		da = (if (i < U64.to_i64_wrap(List.len(a))) { (List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) } else { 0 })
		db : I64
		db = (if (i < U64.to_i64_wrap(List.len(b))) { (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) } else { 0 })
		s : I64
		s = ((da + db) + carry)
		bigint_add_limbs_loop(a, b, I64.div_trunc_by(s, bigint_base), (i + 1), len, List.append(acc, (s - (I64.div_trunc_by(s, bigint_base) * bigint_base))))
	}) })

	bigint_max_len : List(I64), List(I64) -> I64
	bigint_max_len = |a, b| ({
		la : I64
		la = U64.to_i64_wrap(List.len(a))
		lb : I64
		lb = U64.to_i64_wrap(List.len(b))
		(if (la > lb) { la } else { lb })
	})

	bigint_sub : BigInt.BigInt, BigInt.BigInt -> BigInt.BigInt
	bigint_sub = |a, b| bigint_add(a, bigint_negate(b))

	bigint_sub_limbs : List(I64), List(I64), I64 -> List(I64)
	bigint_sub_limbs = |a, b, borrow| bigint_strip_zeros(bigint_sub_limbs_loop(a, b, borrow, 0, U64.to_i64_wrap(List.len(a)), []))

	bigint_sub_limbs_loop : List(I64), List(I64), I64, I64, I64, List(I64) -> List(I64)
	bigint_sub_limbs_loop = |a, b, borrow, i, len, acc| (if (i >= len) { acc } else { ({
		da : I64
		da = (List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		db : I64
		db = (if (i < U64.to_i64_wrap(List.len(b))) { (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) } else { 0 })
		d : I64
		d = ((da - db) - borrow)
		(if (d < 0) { bigint_sub_limbs_loop(a, b, 1, (i + 1), len, List.append(acc, (d + bigint_base))) } else { bigint_sub_limbs_loop(a, b, 0, (i + 1), len, List.append(acc, d)) })
	}) })

	bigint_strip_zeros : List(I64) -> List(I64)
	bigint_strip_zeros = |limbs| ({
		len : I64
		len = bigint_find_top(limbs, U64.to_i64_wrap(List.len(limbs)))
		(if (len == U64.to_i64_wrap(List.len(limbs))) { limbs } else { bigint_copy_limbs(limbs, 0, len, []) })
	})

	bigint_find_top : List(I64), I64 -> I64
	bigint_find_top = |limbs, len| (if (len <= 1) { len } else { (if ((List.get(limbs, I64.to_u64_wrap((len - 1))) ?? crash("list-at out of range")) == 0) { bigint_find_top(limbs, (len - 1)) } else { len }) })

	bigint_copy_limbs : List(I64), I64, I64, List(I64) -> List(I64)
	bigint_copy_limbs = |src, i, len, acc| (if (i >= len) { acc } else { bigint_copy_limbs(src, (i + 1), len, List.append(acc, (List.get(src, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	bigint_mul : BigInt.BigInt, BigInt.BigInt -> BigInt.BigInt
	bigint_mul = |a, b| (if (a.bi_sign == 0) { bigint_zero } else { (if (b.bi_sign == 0) { bigint_zero } else { BigInt.BigInt.{ bi_sign: (a.bi_sign * b.bi_sign), bi_limbs: bigint_mul_limbs(a.bi_limbs, b.bi_limbs) } }) })

	bigint_mul_limbs : List(I64), List(I64) -> List(I64)
	bigint_mul_limbs = |a, b| ({
		bigint_mul_outer_v1 = bigint_mul_outer(a, b, 0, bigint_make_zeros((U64.to_i64_wrap(List.len(a)) + U64.to_i64_wrap(List.len(b)))))
		bigint_mul_outer_v1.0
	})

	bigint_mul_outer : List(I64), List(I64), I64, List(I64) -> (List(I64), List(I64))
	bigint_mul_outer = |a, b, i, acc| (if (i >= U64.to_i64_wrap(List.len(a))) { (bigint_strip_zeros(acc), acc) } else { ({
		bigint_mul_inner_v3 = bigint_mul_inner(a, b, i, 0, 0, acc)
		acc_v4 : List(I64)
		acc_v4 = bigint_mul_inner_v3.1
		bigint_mul_outer_v5 = bigint_mul_outer(a, b, (i + 1), bigint_mul_inner_v3.0)
		(bigint_mul_outer_v5.0, acc_v4)
	}) })

	bigint_mul_inner : List(I64), List(I64), I64, I64, I64, List(I64) -> (List(I64), List(I64))
	bigint_mul_inner = |a, b, i, j, carry, acc| (if (j >= U64.to_i64_wrap(List.len(b))) { (if (carry > 0) { bigint_limb_add(acc, (i + j), carry) } else { (acc, acc) }) } else { ({
		prod : I64
		prod = ((((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) * (List.get(b, I64.to_u64_wrap(j)) ?? crash("list-at out of range"))) + (List.get(acc, I64.to_u64_wrap((i + j))) ?? crash("list-at out of range"))) + carry)
		limb : I64
		limb = (prod - (I64.div_trunc_by(prod, bigint_base) * bigint_base))
		acc_v1 : List(I64)
		acc_v1 = (List.set(acc, I64.to_u64_wrap((i + j)), limb) ?? crash("list-set-at past the end"))
		bigint_mul_inner(a, b, i, (j + 1), I64.div_trunc_by(prod, bigint_base), acc_v1)
	}) })

	bigint_limb_add : List(I64), I64, I64 -> (List(I64), List(I64))
	bigint_limb_add = |limbs, pos, val| (if (pos >= U64.to_i64_wrap(List.len(limbs))) { (List.append(limbs, val), limbs) } else { ({
		cur : I64
		cur = (List.get(limbs, I64.to_u64_wrap(pos)) ?? crash("list-at out of range"))
		s : I64
		s = (cur + val)
		(if (s < bigint_base) { ({
			limbs_v1 : List(I64)
			limbs_v1 = (List.set(limbs, I64.to_u64_wrap(pos), s) ?? crash("list-set-at past the end"))
			(limbs_v1, limbs_v1)
		}) } else { ({
			limbs_v2 : List(I64)
			limbs_v2 = (List.set(limbs, I64.to_u64_wrap(pos), (s - bigint_base)) ?? crash("list-set-at past the end"))
			bigint_limb_add(limbs_v2, (pos + 1), 1)
		}) })
	}) })

	bigint_make_zeros : I64 -> List(I64)
	bigint_make_zeros = |n| bigint_make_zeros_loop(n, 0, [])

	bigint_make_zeros_loop : I64, I64, List(I64) -> List(I64)
	bigint_make_zeros_loop = |n, i, acc| (if (i >= n) { acc } else { bigint_make_zeros_loop(n, (i + 1), List.append(acc, 0)) })

	bigint_divmod : BigInt.BigInt, BigInt.BigInt -> BigInt.BigInt
	bigint_divmod = |a, b| (if (b.bi_sign == 0) { bigint_zero } else { (if (a.bi_sign == 0) { bigint_zero } else { ({
		qa = bigint_abs(a)
		qb = bigint_abs(b)
		result = bigint_div_unsigned(qa, qb)
		BigInt.BigInt.{ bi_sign: (a.bi_sign * b.bi_sign), bi_limbs: result.bi_limbs }
	}) }) })

	bigint_div_unsigned : BigInt.BigInt, BigInt.BigInt -> BigInt.BigInt
	bigint_div_unsigned = |a, b| (if bigint_lt(a, b) { bigint_zero } else { (if bigint_eq(a, b) { bigint_one } else { bigint_div_slow(a, b, bigint_zero) }) })

	bigint_div_slow : BigInt.BigInt, BigInt.BigInt, BigInt.BigInt -> BigInt.BigInt
	bigint_div_slow = |rem, divisor, quot| (if bigint_lt(rem, divisor) { quot } else { bigint_div_slow(bigint_sub(rem, divisor), divisor, bigint_add(quot, bigint_one)) })

	bigint_to_integer : BigInt.BigInt -> Maybe.Maybe(I64)
	bigint_to_integer = |a| (if (a.bi_sign == 0) { Just(0) } else { ({
		val : I64
		val = bigint_limbs_to_int(a.bi_limbs, 0, 1, 0)
		(if (val < 0) { None } else { (if (a.bi_sign < 0) { Just((-val)) } else { Just(val) }) })
	}) })

	bigint_limbs_to_int : List(I64), I64, I64, I64 -> I64
	bigint_limbs_to_int = |limbs, i, mult, acc| (if (i >= U64.to_i64_wrap(List.len(limbs))) { acc } else { bigint_limbs_to_int(limbs, (i + 1), (mult * bigint_base), (acc + ((List.get(limbs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) * mult))) })

	bigint_to_text : BigInt.BigInt -> CceText
	bigint_to_text = |a| (if (a.bi_sign == 0) { "0" } else { ({
		digits : CceText
		digits = bigint_limbs_to_text(a.bi_limbs, (U64.to_i64_wrap(List.len(a.bi_limbs)) - 1), True)
		(if (a.bi_sign < 0) { CceText.concat("-", digits) } else { digits })
	}) })

	bigint_limbs_to_text : List(I64), I64, Bool -> CceText
	bigint_limbs_to_text = |limbs, i, first| (if (i < 0) { "" } else { ({
		limb : I64
		limb = (List.get(limbs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		s : CceText
		s = CceText.show_int(limb)
		padded : CceText
		padded = (if first { s } else { bigint_pad4(s) })
		CceText.concat(padded, bigint_limbs_to_text(limbs, (i - 1), False))
	}) })

	bigint_pad4 : CceText -> CceText
	bigint_pad4 = |s| ({
		len : I64
		len = CceText.len(s)
		(if (len >= 4) { s } else { (if (len == 3) { CceText.concat("0", s) } else { (if (len == 2) { CceText.concat("00", s) } else { (if (len == 1) { CceText.concat("000", s) } else { "0000" }) }) }) })
	})

	bigint_pow : BigInt.BigInt, I64 -> BigInt.BigInt
	bigint_pow = |base, exp| (if (exp <= 0) { bigint_one } else { (if (exp == 1) { base } else { ({
		half = bigint_pow(base, I64.div_trunc_by(exp, 2))
		sq = bigint_mul(half, half)
		(if ((exp - (I64.div_trunc_by(exp, 2) * 2)) == 0) { sq } else { bigint_mul(sq, base) })
	}) }) })

	bigint_factorial : I64 -> BigInt.BigInt
	bigint_factorial = |n| (if (n <= 1) { bigint_one } else { bigint_factorial_loop(n, 2, bigint_one) })

	bigint_factorial_loop : I64, I64, BigInt.BigInt -> BigInt.BigInt
	bigint_factorial_loop = |n, i, acc| (if (i > n) { acc } else { bigint_factorial_loop(n, (i + 1), bigint_mul(acc, bigint_from_integer(i))) })

	bigint_gcd : BigInt.BigInt, BigInt.BigInt -> BigInt.BigInt
	bigint_gcd = |a, b| (if bigint_is_zero(b) { bigint_abs(a) } else { ({
		aa = bigint_abs(a)
		ab = bigint_abs(b)
		bigint_gcd_loop(aa, ab)
	}) })

	bigint_gcd_loop : BigInt.BigInt, BigInt.BigInt -> BigInt.BigInt
	bigint_gcd_loop = |a, b| (if bigint_is_zero(b) { a } else { bigint_gcd_loop(b, bigint_mod(a, b)) })

	bigint_mod : BigInt.BigInt, BigInt.BigInt -> BigInt.BigInt
	bigint_mod = |a, b| bigint_sub(a, bigint_mul(bigint_divmod(a, b), b))
}
