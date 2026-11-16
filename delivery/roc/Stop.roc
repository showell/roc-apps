## One stop of a truck's route: the neighborhood it drives to, the houses
## it delivers there, and whether the stop is pinned to a truck's slot. An
## anchor's first houses are pinned to its truck, so no move takes them off
## it; every other stop is free to move.

import Houses

Stop := { nbhd : U8, houses : Houses, pin : [Free, Pinned(U64)] }.{

	## How many totes the stop drops: one an order, an order a house.
	load : Stop -> U64
	load = |stop| stop.houses.count()

	is_pinned : Stop -> Bool
	is_pinned = |stop|
		match stop.pin {
			Free => False
			Pinned(_) => True
		}

	is_eq : _
}
