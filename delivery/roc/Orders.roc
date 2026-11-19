## The day's orders: `order_count` distinct houses drawn by a seeded
## shuffle, then grouped by neighborhood, as orders.ts draws them. The
## grouping keeps two orders that are semantics to the solver: the
## neighborhoods in the order each was first drawn, and each one's houses
## in the order they were drawn.

import Houses
import Seattle

Orders :: [].{

	## One neighborhood's orders: the houses to deliver to there.
	NeighborhoodOrders : { nbhd : U8, houses : Houses }

	## The day's orders for the shift whose seed is `seed`.
	day_orders : U32 -> List(NeighborhoodOrders)
	day_orders = |seed| {
		total = all_houses.len()
		n = Seattle.order_count
		var $picks = List.from_iter(U64.until(0, total))
		var $state = seed
		for i in 0..<n {
			{ state, draw } = mulberry32($state)
			$state = state
			j = i + ((draw * (total - i).to_f64()).floor_to_u64_try() ?? crash "Orders.day_orders: a draw is in [0, 1)")
			$picks = $picks.swap(i, j) ?? crash "Orders.day_orders: in range"
		}
		var $out = []
		for k in 0..<n {
			pick = $picks.get(k) ?? crash "Orders.day_orders: in range"
			house = all_houses.get(pick) ?? crash "Orders.day_orders: in range"
			$out = with_house($out, house)
		}
		$out
	}
}

## One step of mulberry32, bit for bit orders.ts's: JS's 32-bit coercions
## are wrapping U32 arithmetic, and the draw is the result over 2^32.
mulberry32 : U32 -> { state : U32, draw : F64 }
mulberry32 = |s| {
	state = s.plus_wrap(0x6d2b79f5)
	t0 = U32.bitwise_xor(state, state.shr_zf_wrap(15)).times_wrap(U32.bitwise_or(state, 1))
	mixed = U32.bitwise_xor(t0, t0.shr_zf_wrap(7)).times_wrap(U32.bitwise_or(t0, 61))
	t1 = U32.bitwise_xor(t0, t0.plus_wrap(mixed))
	{ state, draw: U32.bitwise_xor(t1, t1.shr_zf_wrap(14)).to_f64() / 4294967296.0 }
}

## Every house on the map, neighborhood by neighborhood.
House : { nbhd : U8, number : U8 }

all_houses : List(House)
all_houses = {
	var $out = []
	var $node = 0
	for n in Seattle.neighborhoods {
		for h in 0..<n.house_count {
			$out = $out.append({ nbhd: $node, number: h })
		}
		$node = $node + 1
	}
	$out
}

with_house : List(Orders.NeighborhoodOrders), House -> List(Orders.NeighborhoodOrders)
with_house = |orders, house|
	match orders.find_first_index(|o| o.nbhd == house.nbhd) {
		Ok(i) => {
			{ list, prev } = orders.replace(
				i,
				{ nbhd: house.nbhd, houses: Houses.empty },
			) ?? crash "Orders.with_house: in range"
			list.set(
				i,
				{ nbhd: prev.nbhd, houses: prev.houses.append(house.number) },
			) ?? crash "Orders.with_house: in range"
		}
		Err(NotFound) => orders.append({
			nbhd: house.nbhd,
			houses: Houses.empty.append(house.number),
		})
	}
