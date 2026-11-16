## The houses one stop delivers to: up to fifteen of one neighborhood's
## house numbers, in the order the stop holds them, which is semantics (the
## day's pick order, kept through every split and merge). They are packed
## into one U64, four bits a house from the low end and the count in the top
## four bits, so a stop is plain data: copying one costs no allocation and
## no reference count, and the solver copies stops by the million.

Houses :: U64.{

	empty : Houses
	empty = Houses.(0)

	## The houses of a list, in its order. A house number is under 16
	## (a ring holds 12), and a stop holds at most 15.
	from_list : List(U8) -> Houses
	from_list = |list| list.fold(Houses.empty, |hs, h| hs.append(h))

	to_list : Houses -> List(U8)
	to_list = |hs| {
		n = hs.count()
		var $out = List.with_capacity(n)
		for i in 0..<n {
			$out = $out.append(hs.house_at(i))
		}
		$out
	}

	count : Houses -> U64
	count = |Houses.(bits)| bits.shr_zf_wrap(60)

	is_empty : Houses -> Bool
	is_empty = |hs| hs.count() == 0

	## The house at a place, which must be one of the stop's.
	house_at : Houses, U64 -> U8
	house_at = |Houses.(bits), i| {
		if i >= bits.shr_zf_wrap(60) {
			crash "Houses.house_at: past the last house"
		}
		bits.shr_zf_wrap(i.to_u8_wrap().shl_wrap(2)).bitwise_and(15).to_u8_wrap()
	}

	append : Houses, U8 -> Houses
	append = |Houses.(bits), h| {
		n = bits.shr_zf_wrap(60)
		if n >= 15 or h >= 16 {
			crash "Houses.append: a stop holds at most 15 houses, each numbered under 16"
		}
		low = bits.bitwise_and(low_mask).bitwise_or(h.to_u64().shl_wrap(n.to_u8_wrap().shl_wrap(2)))
		Houses.(low.bitwise_or((n + 1).shl_wrap(60)))
	}

	## These houses, then those.
	concat : Houses, Houses -> Houses
	concat = |hs, more| {
		var $out = hs
		for i in 0..<more.count() {
			$out = $out.append(more.house_at(i))
		}
		$out
	}

	## The first `n` houses, and the rest.
	take_first : Houses, U64 -> Houses
	take_first = |Houses.(bits), n| {
		have = bits.shr_zf_wrap(60)
		k = if n < have {
			n
		} else {
			have
		}
		kept = if k == 15 {
			bits.bitwise_and(low_mask)
		} else {
			bits.bitwise_and(U64.shl_wrap(1, k.to_u8_wrap().shl_wrap(2)) - 1)
		}
		Houses.(kept.bitwise_or(k.shl_wrap(60)))
	}

	drop_first : Houses, U64 -> Houses
	drop_first = |Houses.(bits), n| {
		have = bits.shr_zf_wrap(60)
		k = if n < have {
			n
		} else {
			have
		}
		rest = bits.bitwise_and(low_mask).shr_zf_wrap(k.to_u8_wrap().shl_wrap(2))
		Houses.(rest.bitwise_or((have - k).shl_wrap(60)))
	}

	contains : Houses, U8 -> Bool
	contains = |hs, h| {
		var $found = False
		for i in 0..<hs.count() {
			if hs.house_at(i) == h {
				$found = True
			}
		}
		$found
	}

	## These houses, in order, less those in `gone`.
	without : Houses, Houses -> Houses
	without = |hs, gone| {
		var $out = Houses.empty
		for i in 0..<hs.count() {
			h = hs.house_at(i)
			if !gone.contains(h) {
				$out = $out.append(h)
			}
		}
		$out
	}

	## The houses with the one at place `i` replaced by `h`.
	with_house_at : Houses, { at : U64, house : U8 } -> Houses
	with_house_at = |Houses.(bits), { at: i, house: h }| {
		shift = i.to_u8_wrap().shl_wrap(2)
		cleared = bits.bitwise_and(U64.shl_wrap(15, shift).bitwise_not())
		Houses.(cleared.bitwise_or(h.to_u64().shl_wrap(shift)))
	}

	is_eq : _
}

## A stop's most houses, for the expects.
fifteen : List(U8)
fifteen = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0, 1, 2, 3]

## The house bits, every nibble below the count.
low_mask : U64
low_mask = U64.shl_wrap(1, 60) - 1

expect Houses.from_list([3, 7, 0, 11]).to_list() == [3, 7, 0, 11]
expect Houses.from_list([]).count() == 0
expect Houses.from_list(fifteen).to_list() == fifteen
expect Houses.from_list([4, 5]).concat(Houses.from_list([9])).to_list() == [4, 5, 9]
expect Houses.from_list([4, 5, 9, 2]).take_first(2).to_list() == [4, 5]
expect Houses.from_list([4, 5, 9, 2]).drop_first(2).to_list() == [9, 2]
expect Houses.from_list([4, 5]).take_first(9).to_list() == [4, 5]
expect Houses.from_list([4, 5]).drop_first(9).to_list() == []
expect Houses.from_list(fifteen).take_first(15).count() == 15
expect Houses.from_list([4, 5, 9, 2]).without(Houses.from_list([9, 4])).to_list() == [5, 2]
expect Houses.from_list([4, 5, 9]).contains(9) and !Houses.from_list([4, 5, 9]).contains(2)
expect Houses.from_list([4, 5, 9]).with_house_at({ at: 1, house: 11 }).to_list() == [4, 11, 9]
