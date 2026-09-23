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

	## Steve's heat map: the best square blue 255, the worst 0, by rank
	## (Rank.places); the rank on the square, 1 the best.
	heat : Rank.Places -> List(Overlay.Mark)
	heat = |places|
		List.map(
			places.place,
			|p|
				if p == U64.highest {
					none
				} else {
					blue = if places.worst == 0 { 255 } else { (255 * (places.worst - p)) // places.worst }
					{ label: U64.to_str(p + 1), hint: "rank ${U64.to_str(p + 1)} of ${U64.to_str(places.worst + 1)}", fill: "rgb(0, 0, ${U64.to_str(blue)})" }
				},
		)
}
