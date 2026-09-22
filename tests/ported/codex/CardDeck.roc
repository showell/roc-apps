# CardDeck -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Random
import Text

CardDeck :: [].{
	DealResult : { hand : List(I64), remaining : List(I64) }

	deck_size : I64
	deck_size = 52

	num_suits : I64
	num_suits = 4

	num_ranks : I64
	num_ranks = 13

	card_make : I64, I64 -> I64
	card_make = |suit, rank| ((suit * num_ranks) + rank)

	card_suit : I64 -> I64
	card_suit = |card| I64.div_trunc_by(card, num_ranks)

	card_rank : I64 -> I64
	card_rank = |card| (card - (I64.div_trunc_by(card, num_ranks) * num_ranks))

	suit_name : I64 -> List(U8)
	suit_name = |s| (if (s == 0) { [45, 31, 15, 22, 13, 19] } else { (if (s == 1) { [46, 13, 15, 21, 14, 19] } else { (if (s == 2) { [48, 17, 15, 26, 16, 18, 22, 19] } else { [50, 23, 25, 32, 19] }) }) })

	suit_symbol : I64 -> List(U8)
	suit_symbol = |s| (if (s == 0) { [45] } else { (if (s == 1) { [46] } else { (if (s == 2) { [48] } else { [50] }) }) })

	rank_name : I64 -> List(U8)
	rank_name = |r| (if (r == 0) { [41, 24, 13] } else { (if (r == 1) { [5] } else { (if (r == 2) { [6] } else { (if (r == 3) { [7] } else { (if (r == 4) { [8] } else { (if (r == 5) { [9] } else { (if (r == 6) { [10] } else { (if (r == 7) { [11] } else { (if (r == 8) { [12] } else { (if (r == 9) { [4, 3] } else { (if (r == 10) { [61, 15, 24, 34] } else { (if (r == 11) { [63, 25, 13, 13, 18] } else { [60, 17, 18, 29] }) }) }) }) }) }) }) }) }) }) }) })

	rank_short : I64 -> List(U8)
	rank_short = |r| (if (r == 0) { [41] } else { (if (r == 9) { [40] } else { (if (r == 10) { [61] } else { (if (r == 11) { [63] } else { (if (r == 12) { [60] } else { Text.show_int((r + 1)) }) }) }) }) })

	format_card : I64 -> List(U8)
	format_card = |card| List.concat(rank_short(card_rank(card)), suit_symbol(card_suit(card)))

	format_card_long : I64 -> List(U8)
	format_card_long = |card| List.concat(List.concat(rank_name(card_rank(card)), [2, 16, 28, 2]), suit_name(card_suit(card)))

	deck_new : List(I64)
	deck_new = deck_build(0, [])

	deck_build : I64, List(I64) -> List(I64)
	deck_build = |i, acc| (if (i >= deck_size) { acc } else { deck_build((i + 1), List.append(acc, i)) })

	deck_shuffle : List(I64), I64 -> List(I64)
	deck_shuffle = |cards, seed| fy_shuffle(cards, (U64.to_i64_wrap(List.len(cards)) - 1), seed)

	fy_shuffle : List(I64), I64, I64 -> List(I64)
	fy_shuffle = |cards, i, seed| (if (i <= 0) { cards } else { ({
		rng = fy_next_random(seed)
		j = fy_mod(rng, (i + 1))
		fy_shuffle(fy_swap(cards, i, j), (i - 1), rng)
	}) })

	fy_swap : List(I64), I64, I64 -> List(I64)
	fy_swap = |cards, i, j| (if (i == j) { cards } else { ({
		vi = (List.get(cards, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(List.set((List.set(cards, I64.to_u64_wrap(i), (List.get(cards, I64.to_u64_wrap(j)) ?? crash("list-at out of range"))) ?? crash("list-set-at past the end")), I64.to_u64_wrap(j), vi) ?? crash("list-set-at past the end"))
	}) })

	fy_next_random : I64 -> I64
	fy_next_random = |seed| ({
		h = Random.mix_bits(seed, 1)
		(if (h < 0) { (-h) } else { h })
	})

	fy_mod : I64, I64 -> I64
	fy_mod = |val, modulus| (if (modulus <= 0) { 0 } else { (val - (I64.div_trunc_by(val, modulus) * modulus)) })

	deck_deal : List(I64), I64 -> CardDeck.DealResult
	deck_deal = |cards, n| ({
		hand = deck_take(cards, 0, n, [])
		remaining = deck_drop(cards, n, U64.to_i64_wrap(List.len(cards)), [])
		{ hand: hand, remaining: remaining }
	})

	deck_take : List(I64), I64, I64, List(I64) -> List(I64)
	deck_take = |cards, i, n, acc| (if (i >= n) { acc } else { (if (i >= U64.to_i64_wrap(List.len(cards))) { acc } else { deck_take(cards, (i + 1), n, List.append(acc, (List.get(cards, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) }) })

	deck_drop : List(I64), I64, I64, List(I64) -> List(I64)
	deck_drop = |cards, i, len, acc| (if (i >= len) { acc } else { deck_drop(cards, (i + 1), len, List.append(acc, (List.get(cards, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	deck_contains : List(I64), I64 -> Bool
	deck_contains = |cards, target| deck_contains_loop(cards, target, 0, U64.to_i64_wrap(List.len(cards)))

	deck_contains_loop : List(I64), I64, I64, I64 -> Bool
	deck_contains_loop = |cards, target, i, len| (if (i >= len) { False } else { (if ((List.get(cards, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) == target) { True } else { deck_contains_loop(cards, target, (i + 1), len) }) })

	format_hand : List(I64) -> List(U8)
	format_hand = |cards| format_hand_loop(cards, 0, U64.to_i64_wrap(List.len(cards)), [])

	format_hand_loop : List(I64), I64, I64, List(U8) -> List(U8)
	format_hand_loop = |cards, i, len, acc| (if (i >= len) { acc } else { ({
		sep = (if (i == 0) { [] } else { [2] })
		format_hand_loop(cards, (i + 1), len, List.concat(List.concat(acc, sep), format_card((List.get(cards, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))
	}) })

	blackjack_value : I64 -> I64
	blackjack_value = |card| ({
		r = card_rank(card)
		(if (r == 0) { 11 } else { (if (r >= 10) { 10 } else { (r + 1) }) })
	})

	hand_total : List(I64) -> I64
	hand_total = |cards| hand_total_loop(cards, 0, U64.to_i64_wrap(List.len(cards)), 0)

	hand_total_loop : List(I64), I64, I64, I64 -> I64
	hand_total_loop = |cards, i, len, acc| (if (i >= len) { acc } else { hand_total_loop(cards, (i + 1), len, (acc + blackjack_value((List.get(cards, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })
}
