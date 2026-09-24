# Klondike -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CardDeck
import CceText
import ListUtils
import Maybe

Klondike :: [].{
	Pile : { pile_cards : List(I64), pile_face_up : I64 }
	KlondikeState : { kl_tableau : List(Klondike.Pile), kl_foundation : List(List(I64)), kl_stock : List(I64), kl_waste : List(I64), kl_moves : I64 }
	MoveResult : [MoveOk(Klondike.KlondikeState), MoveErr(CceText)]

	card_color : I64 -> I64
	card_color = |card| ({
		s = CardDeck.card_suit(card)
		(if (s == 0) { 0 } else { (if (s == 3) { 0 } else { 1 }) })
	})

	cards_alternate_color : I64, I64 -> Bool
	cards_alternate_color = |top, bottom| (card_color(top) != card_color(bottom))

	card_fits_tableau : I64, I64 -> Bool
	card_fits_tableau = |card, target| (cards_alternate_color(card, target) and ((CardDeck.card_rank(card) + 1) == CardDeck.card_rank(target)))

	card_fits_foundation : I64, List(I64) -> Bool
	card_fits_foundation = |card, foundation| ({
		n = U64.to_i64_wrap(List.len(foundation))
		(if (n == 0) { (CardDeck.card_rank(card) == 0) } else { ({
			top = (List.get(foundation, I64.to_u64_wrap((n - 1))) ?? crash("list-at out of range"))
			((CardDeck.card_suit(card) == CardDeck.card_suit(top)) and (CardDeck.card_rank(card) == (CardDeck.card_rank(top) + 1)))
		}) })
	})

	klondike_new : I64 -> Klondike.KlondikeState
	klondike_new = |seed| ({
		deck = CardDeck.deck_shuffle(CardDeck.deck_new, seed)
		klondike_deal(deck)
	})

	klondike_deal : List(I64) -> Klondike.KlondikeState
	klondike_deal = |deck| ({
		r0 = kl_deal_pile(deck, 0, 1)
		r1 = kl_deal_pile(r0.remaining, 1, 2)
		r2 = kl_deal_pile(r1.remaining, 2, 3)
		r3 = kl_deal_pile(r2.remaining, 3, 4)
		r4 = kl_deal_pile(r3.remaining, 4, 5)
		r5 = kl_deal_pile(r4.remaining, 5, 6)
		r6 = kl_deal_pile(r5.remaining, 6, 7)
		tableau = [r0.hand, r1.hand, r2.hand, r3.hand, r4.hand, r5.hand, r6.hand]
		piles = kl_make_piles(tableau, 0, [])
		{ kl_tableau: piles, kl_foundation: [[], [], [], []], kl_stock: r6.remaining, kl_waste: [], kl_moves: 0 }
	})

	kl_deal_pile : List(I64), I64, I64 -> CardDeck.DealResult
	kl_deal_pile = |deck, _pile_idx, count| CardDeck.deck_deal(deck, count)

	kl_make_piles : List(List(I64)), I64, List(Klondike.Pile) -> List(Klondike.Pile)
	kl_make_piles = |hands, i, acc| (if (i >= 7) { acc } else { ({
		cards = (List.get(hands, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		n = U64.to_i64_wrap(List.len(cards))
		kl_make_piles(hands, (i + 1), List.append(acc, { pile_cards: cards, pile_face_up: (n - 1) }))
	}) })

	pile_top : Klondike.Pile -> Maybe.Maybe(I64)
	pile_top = |p| ({
		n = U64.to_i64_wrap(List.len(p.pile_cards))
		(if (n == 0) { None } else { Just((List.get(p.pile_cards, I64.to_u64_wrap((n - 1))) ?? crash("list-at out of range"))) })
	})

	pile_is_empty : Klondike.Pile -> Bool
	pile_is_empty = |p| (U64.to_i64_wrap(List.len(p.pile_cards)) == 0)

	pile_size : Klondike.Pile -> I64
	pile_size = |p| U64.to_i64_wrap(List.len(p.pile_cards))

	pile_face_down_count : Klondike.Pile -> I64
	pile_face_down_count = |p| p.pile_face_up

	kl_draw : Klondike.KlondikeState -> Klondike.MoveResult
	kl_draw = |st| (if (U64.to_i64_wrap(List.len(st.kl_stock)) == 0) { (if (U64.to_i64_wrap(List.len(st.kl_waste)) == 0) { MoveErr("stock and waste empty") } else { MoveOk({ kl_tableau: st.kl_tableau, kl_foundation: st.kl_foundation, kl_stock: kl_reverse_list(st.kl_waste), kl_waste: [], kl_moves: (st.kl_moves + 1) }) }) } else { ({
		card = (List.get(st.kl_stock, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
		rest = ListUtils.list_tail(st.kl_stock)
		MoveOk({ kl_tableau: st.kl_tableau, kl_foundation: st.kl_foundation, kl_stock: rest, kl_waste: List.append(st.kl_waste, card), kl_moves: (st.kl_moves + 1) })
	}) })

	kl_waste_to_tableau : Klondike.KlondikeState, I64 -> Klondike.MoveResult
	kl_waste_to_tableau = |st, pile_idx| (if (pile_idx < 0) { MoveErr("invalid pile") } else { (if (pile_idx >= 7) { MoveErr("invalid pile") } else { (if (U64.to_i64_wrap(List.len(st.kl_waste)) == 0) { MoveErr("waste empty") } else { ({
		card = (List.get(st.kl_waste, I64.to_u64_wrap((U64.to_i64_wrap(List.len(st.kl_waste)) - 1))) ?? crash("list-at out of range"))
		pile = (List.get(st.kl_tableau, I64.to_u64_wrap(pile_idx)) ?? crash("list-at out of range"))
		top = pile_top(pile)
		fits = (match top {
			None => (CardDeck.card_rank(card) == 12)
			Just(t) => card_fits_tableau(card, t)
		})
		(if fits { ({
			new_waste = kl_list_init(st.kl_waste)
			new_pile = { pile_cards: List.append(pile.pile_cards, card), pile_face_up: pile.pile_face_up }
			new_tab = (List.set(st.kl_tableau, I64.to_u64_wrap(pile_idx), new_pile) ?? crash("list-set-at past the end"))
			MoveOk({ kl_tableau: new_tab, kl_foundation: st.kl_foundation, kl_stock: st.kl_stock, kl_waste: new_waste, kl_moves: (st.kl_moves + 1) })
		}) } else { MoveErr("card does not fit") })
	}) }) }) })

	kl_waste_to_foundation : Klondike.KlondikeState -> Klondike.MoveResult
	kl_waste_to_foundation = |st| (if (U64.to_i64_wrap(List.len(st.kl_waste)) == 0) { MoveErr("waste empty") } else { ({
		card = (List.get(st.kl_waste, I64.to_u64_wrap((U64.to_i64_wrap(List.len(st.kl_waste)) - 1))) ?? crash("list-at out of range"))
		suit = CardDeck.card_suit(card)
		foundation = (List.get(st.kl_foundation, I64.to_u64_wrap(suit)) ?? crash("list-at out of range"))
		(if card_fits_foundation(card, foundation) { ({
			new_waste = kl_list_init(st.kl_waste)
			new_found = (List.set(st.kl_foundation, I64.to_u64_wrap(suit), List.append(foundation, card)) ?? crash("list-set-at past the end"))
			MoveOk({ kl_tableau: st.kl_tableau, kl_foundation: new_found, kl_stock: st.kl_stock, kl_waste: new_waste, kl_moves: (st.kl_moves + 1) })
		}) } else { MoveErr("card does not fit foundation") })
	}) })

	kl_tableau_to_foundation : Klondike.KlondikeState, I64 -> Klondike.MoveResult
	kl_tableau_to_foundation = |st, pile_idx| (if (pile_idx < 0) { MoveErr("invalid pile") } else { (if (pile_idx >= 7) { MoveErr("invalid pile") } else { ({
		pile = (List.get(st.kl_tableau, I64.to_u64_wrap(pile_idx)) ?? crash("list-at out of range"))
		top = pile_top(pile)
		(match top {
			None => MoveErr("pile empty")
			Just(card) => ({
				suit = CardDeck.card_suit(card)
				foundation = (List.get(st.kl_foundation, I64.to_u64_wrap(suit)) ?? crash("list-at out of range"))
				(if card_fits_foundation(card, foundation) { ({
					new_pile = kl_remove_top(pile)
					new_found = (List.set(st.kl_foundation, I64.to_u64_wrap(suit), List.append(foundation, card)) ?? crash("list-set-at past the end"))
					new_tab = (List.set(st.kl_tableau, I64.to_u64_wrap(pile_idx), new_pile) ?? crash("list-set-at past the end"))
					MoveOk({ kl_tableau: new_tab, kl_foundation: new_found, kl_stock: st.kl_stock, kl_waste: st.kl_waste, kl_moves: (st.kl_moves + 1) })
				}) } else { MoveErr("card does not fit foundation") })
			})
		})
	}) }) })

	kl_tableau_to_tableau : Klondike.KlondikeState, I64, I64 -> Klondike.MoveResult
	kl_tableau_to_tableau = |st, from, to| (if (from < 0) { MoveErr("invalid source") } else { (if (from >= 7) { MoveErr("invalid source") } else { (if (to < 0) { MoveErr("invalid target") } else { (if (to >= 7) { MoveErr("invalid target") } else { ({
		src = (List.get(st.kl_tableau, I64.to_u64_wrap(from)) ?? crash("list-at out of range"))
		top = pile_top(src)
		(match top {
			None => MoveErr("source empty")
			Just(card) => ({
				dst = (List.get(st.kl_tableau, I64.to_u64_wrap(to)) ?? crash("list-at out of range"))
				dst_top = pile_top(dst)
				fits = (match dst_top {
					None => (CardDeck.card_rank(card) == 12)
					Just(t) => card_fits_tableau(card, t)
				})
				(if fits { ({
					new_src = kl_remove_top(src)
					new_dst = { pile_cards: List.append(dst.pile_cards, card), pile_face_up: dst.pile_face_up }
					tab1 = (List.set(st.kl_tableau, I64.to_u64_wrap(from), new_src) ?? crash("list-set-at past the end"))
					tab2 = (List.set(tab1, I64.to_u64_wrap(to), new_dst) ?? crash("list-set-at past the end"))
					MoveOk({ kl_tableau: tab2, kl_foundation: st.kl_foundation, kl_stock: st.kl_stock, kl_waste: st.kl_waste, kl_moves: (st.kl_moves + 1) })
				}) } else { MoveErr("card does not fit") })
			})
		})
	}) }) }) }) })

	kl_remove_top : Klondike.Pile -> Klondike.Pile
	kl_remove_top = |p| ({
		cards = kl_list_init(p.pile_cards)
		n = U64.to_i64_wrap(List.len(cards))
		fu = (if (p.pile_face_up > n) { n } else { (if (p.pile_face_up >= n) { (n - 1) } else { p.pile_face_up }) })
		adjusted = (if (fu < 0) { 0 } else { fu })
		{ pile_cards: cards, pile_face_up: adjusted }
	})

	kl_is_won : Klondike.KlondikeState -> Bool
	kl_is_won = |st| ((((U64.to_i64_wrap(List.len((List.get(st.kl_foundation, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))) == 13) and (U64.to_i64_wrap(List.len((List.get(st.kl_foundation, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))) == 13)) and (U64.to_i64_wrap(List.len((List.get(st.kl_foundation, I64.to_u64_wrap(2)) ?? crash("list-at out of range")))) == 13)) and (U64.to_i64_wrap(List.len((List.get(st.kl_foundation, I64.to_u64_wrap(3)) ?? crash("list-at out of range")))) == 13))

	kl_foundation_count : Klondike.KlondikeState -> I64
	kl_foundation_count = |st| (((U64.to_i64_wrap(List.len((List.get(st.kl_foundation, I64.to_u64_wrap(0)) ?? crash("list-at out of range")))) + U64.to_i64_wrap(List.len((List.get(st.kl_foundation, I64.to_u64_wrap(1)) ?? crash("list-at out of range"))))) + U64.to_i64_wrap(List.len((List.get(st.kl_foundation, I64.to_u64_wrap(2)) ?? crash("list-at out of range"))))) + U64.to_i64_wrap(List.len((List.get(st.kl_foundation, I64.to_u64_wrap(3)) ?? crash("list-at out of range")))))

	kl_format_waste : Klondike.KlondikeState -> CceText
	kl_format_waste = |st| ({
		n = U64.to_i64_wrap(List.len(st.kl_waste))
		(if (n == 0) { "[]" } else { CceText.concat(CceText.concat("[", CardDeck.format_card((List.get(st.kl_waste, I64.to_u64_wrap((n - 1))) ?? crash("list-at out of range")))), "]") })
	})

	kl_format_stock : Klondike.KlondikeState -> CceText
	kl_format_stock = |st| CceText.concat(CceText.concat("(", CceText.show_int(U64.to_i64_wrap(List.len(st.kl_stock)))), ")")

	kl_format_foundation : Klondike.KlondikeState -> CceText
	kl_format_foundation = |st| CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(kl_fmt_found((List.get(st.kl_foundation, I64.to_u64_wrap(0)) ?? crash("list-at out of range")), "S"), " "), kl_fmt_found((List.get(st.kl_foundation, I64.to_u64_wrap(1)) ?? crash("list-at out of range")), "H")), " "), kl_fmt_found((List.get(st.kl_foundation, I64.to_u64_wrap(2)) ?? crash("list-at out of range")), "D")), " "), kl_fmt_found((List.get(st.kl_foundation, I64.to_u64_wrap(3)) ?? crash("list-at out of range")), "C"))

	kl_fmt_found : List(I64), CceText -> CceText
	kl_fmt_found = |cards, suit| ({
		n = U64.to_i64_wrap(List.len(cards))
		(if (n == 0) { CceText.concat(CceText.concat("[", suit), "]") } else { CceText.concat(CceText.concat("[", CardDeck.format_card((List.get(cards, I64.to_u64_wrap((n - 1))) ?? crash("list-at out of range")))), "]") })
	})

	kl_format_tableau_pile : Klondike.Pile, I64 -> CceText
	kl_format_tableau_pile = |p, idx| CceText.concat(CceText.concat(CceText.show_int(idx), ": "), kl_fmt_pile_cards(p.pile_cards, p.pile_face_up, 0, U64.to_i64_wrap(List.len(p.pile_cards)), ""))

	kl_fmt_pile_cards : List(I64), I64, I64, I64, CceText -> CceText
	kl_fmt_pile_cards = |cards, face_up, i, n, acc| (if (i >= n) { (if (n == 0) { "--" } else { acc }) } else { ({
		sep = (if (i == 0) { "" } else { " " })
		card_str = (if (i < face_up) { "##" } else { CardDeck.format_card((List.get(cards, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))) })
		kl_fmt_pile_cards(cards, face_up, (i + 1), n, CceText.concat(CceText.concat(acc, sep), card_str))
	}) })

	kl_format_state : Klondike.KlondikeState -> CceText
	kl_format_state = |st| CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("Stock:", kl_format_stock(st)), " Waste:"), kl_format_waste(st)), " Found:"), kl_format_foundation(st)), " Moves:"), CceText.show_int(st.kl_moves))

	kl_format_tableau : Klondike.KlondikeState, I64 -> CceText
	kl_format_tableau = |st, idx| (if (idx >= 7) { "" } else { kl_format_tableau_pile((List.get(st.kl_tableau, I64.to_u64_wrap(idx)) ?? crash("list-at out of range")), idx) })

	kl_list_init : List(I64) -> List(I64)
	kl_list_init = |xs| kl_take_list(xs, 0, (U64.to_i64_wrap(List.len(xs)) - 1), [])

	kl_take_list : List(I64), I64, I64, List(I64) -> List(I64)
	kl_take_list = |xs, i, n, acc| (if (i >= n) { acc } else { kl_take_list(xs, (i + 1), n, List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	kl_reverse_list : List(I64) -> List(I64)
	kl_reverse_list = |xs| kl_rev_loop(xs, (U64.to_i64_wrap(List.len(xs)) - 1), [])

	kl_rev_loop : List(I64), I64, List(I64) -> List(I64)
	kl_rev_loop = |xs, i, acc| (if (i < 0) { acc } else { kl_rev_loop(xs, (i - 1), List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	eq_MoveResult : Klondike.MoveResult, Klondike.MoveResult -> Bool
	eq_MoveResult = |ex, ey| (match ex {
		MoveOk(exf0) => (match ey {
			MoveOk(eyf0) => (exf0 == eyf0)
			_ => False
		})
		MoveErr(exf0) => (match ey {
			MoveErr(eyf0) => (exf0 == eyf0)
			_ => False
		})
	})
}
