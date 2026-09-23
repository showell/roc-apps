# Overlay -- what the board shows on top of the game while the squares are
# being analysed: for each square, a label written on it, a hint shown on
# hover, and a fill that replaces its own ("" keeps it). Indexed as
# Agent.all_locs; the page draws no overlay when the list is empty.
import Agent
import Rank
import Reach

Overlay :: [].{
	Mark : { label : Str, hint : Str, fill : Str }

	none : Overlay.Mark
	none = { label: "", hint: "", fill: "" }

	## The fewest cards to the peak on every square, and the cards that
	## start the way on hover.
	cards : List(Reach.Best) -> List(Overlay.Mark)
	cards = |best|
		List.map(
			best,
			|b|
				if b.cards >= Agent.far {
					none
				} else {
					plain = List.keep_if(Reach.cards, |c| List.contains(b.first, c))
					with_face = List.keep_if(b.first, |c| Str.contains(c, "face"))
					shown = List.map(List.concat(plain, with_face), |c| Str.replace_each(c, "4", "4 back"))
					{ label: I64.to_str(b.cards), hint: if List.is_empty(shown) { "home" } else { Str.concat("start with ", Str.join_with(shown, ", ")) }, fill: "" }
				},
		)

	## The cards that start a shortest way, for a hover: plain cards in deck
	## order, then the ways with a face card first.
	ways : Reach.Best -> Str
	ways = |b| {
		plain = List.keep_if(Reach.cards, |c| List.contains(b.first, c))
		with_face = List.keep_if(b.first, |c| Str.contains(c, "face"))
		shown = List.map(List.concat(plain, with_face), |c| Str.replace_each(Str.replace_each(c, "face+", "F+"), "4", "4 back"))
		Str.join_with(shown, ", ")
	}

	## Steve's heat map: the best square pure blue, the worst white, red and
	## green falling together as a square ranks better (Rank.places); the
	## rank on the square, 1 the best. The hover gives the square's tier --
	## how many cards from the peak (`best`, the fewest cards) -- its rank,
	## and the cards that start the way to the next tier.
	heat : Rank.Places, List(Reach.Best) -> List(Overlay.Mark)
	heat = |places, best|
		List.map_with_index(
			places.place,
			|p, i|
				if p == U64.highest {
					none
				} else {
					rg = if places.worst == 0 { 0 } else { (255 * p) // places.worst }
					b = List.get(best, i) ?? { cards: Agent.far, first: [] }
					tier =
						if b.cards >= Agent.far {
							"base"
						} else if b.cards == 1 {
							"1 card"
						} else {
							"${I64.to_str(b.cards)} cards"
						}
					start = if List.is_empty(b.first) { "" } else { " · start with ${ways(b)}" }
					{
						label: U64.to_str(p + 1),
						hint: "${tier} · rank ${U64.to_str(p + 1)} of ${U64.to_str(places.worst + 1)}${start}",
						fill: "rgb(${U64.to_str(rg)}, ${U64.to_str(rg)}, 255)",
					}
				},
		)
}
