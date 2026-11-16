## The solve, recorded for the page's replay (the `A` key): each move that
## changed which truck carries what, with a snapshot of the routes it left,
## the houses it touched and the caption the page shows. A snapshot's timing
## is solver.ts's at each move: a merge's before it is applied, every other
## move's after.

import Houses
import Seattle
import Stop

Replay :: [].{

	MoveKind : [Merge, Relocate, Swap, Settle, Consolidate]

	## A house, by its neighborhood and its number there.
	HouseKey : { nbhd : U8, house : U8 }

	## One recorded move: what it saved (0 for a placement or a tie-break),
	## the words after its kind in the caption, the routes it left, and the
	## houses it touched.
	Move : {
		kind : MoveKind,
		saved : I64,
		detail : Str,
		frame_routes : List(List(Stop)),
		touched : List(HouseKey),
	}

	## Every house of these stops, stop by stop.
	stop_keys : List(Stop) -> List(HouseKey)
	stop_keys = |stops| stops.join_map(|s| house_keys(s.nbhd, s.houses))

	house_keys : U8, Houses -> List(HouseKey)
	house_keys = |nbhd, houses| houses.to_list().map(|house| { nbhd, house })

	## The page's caption: the move's kind and detail, then the pain saved
	## when it saved any.
	caption : Move -> Str
	caption = |move| {
		tag =
			match move.kind {
				Merge => "merge"
				Relocate => "relocate"
				Swap => "swap"
				Settle => "settle"
				Consolidate => "consolidate"
			}
		if move.saved >= 1 {
			"${tag} · ${move.detail}  −${move.saved.to_str()} pain"
		} else {
			"${tag} · ${move.detail}"
		}
	}

	## A house key as the page names it, `Ballard#3`.
	key_name : HouseKey -> Str
	key_name = |key| "${Seattle.name_of(key.nbhd)}#${key.house.to_str()}"
}
