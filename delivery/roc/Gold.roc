## The facts the gold corpus (solver_gold.json, minted by goldgen.ts from
## the TypeScript reference) pins for one shift, as JSON in the corpus's own
## shape, for `gold_check.zig` to compare: the fleet, the race's variant
## labels and the road graph, then the shift's demand, every race variant's
## pain, the winner, and the winning plan's routes with each one's pain.

import JsonOut
import Orders
import Pain
import RoadGraph
import Route
import Seattle
import Solve
import Stop

Gold :: [].{

	gold_of : U32 -> JsonOut
	gold_of = |seed| {
		orders = Orders.day_orders(seed)
		race = Solve.race(orders)
		JsonOut.ordered_object([
			("fleet", fleet),
			("raceVariants", JsonOut.array(Solve.variants.map(|v| JsonOut.string(v.label)))),
			("substrate", substrate),
			(
				"shift",
				JsonOut.ordered_object([
					("seed", JsonOut.int(seed.to_i64())),
					("demand", demand_of(orders)),
					(
						"race",
						JsonOut.ordered_object([
							("winner", JsonOut.string(race.winner)),
							(
								"pains",
								JsonOut.array(
									race.pains.map(
										|p| JsonOut.ordered_object([
											("label", JsonOut.string(p.label)),
											("pain", JsonOut.int(p.pain)),
										]),
									),
								),
							),
						]),
					),
					("routes", JsonOut.array(race.best.slot_routes.map(gold_route))),
					(
						"totalPain",
						JsonOut.int(race.best.slot_routes.fold(0, |n, r| n + Pain.pain_of(r))),
					),
				]),
			),
		])
	}
}

fleet : JsonOut
fleet = JsonOut.ordered_object([
	("trucks", JsonOut.int(Seattle.truck_count.to_i64_wrap())),
	("orders", JsonOut.int(Seattle.order_count.to_i64_wrap())),
	("caps", JsonOut.array(Seattle.truck_caps.map(|c| JsonOut.int(c.to_i64_wrap())))),
	("anchors", JsonOut.array(Seattle.truck_anchors.map(node_name))),
])

node_name : U8 -> JsonOut
node_name = |node| JsonOut.string(Seattle.name_of(node))

all_nodes : List(U8)
all_nodes = List.from_iter(U64.until(0, Seattle.node_count)).map(|n| n.to_u8_wrap())

substrate : JsonOut
substrate = JsonOut.ordered_object([
	("nodes", JsonOut.array(all_nodes.map(node_name))),
	(
		"edges",
		JsonOut.array(
			RoadGraph.edges.map(
				|e| JsonOut.ordered_object([
					("a", node_name(e.a)),
					("b", node_name(e.b)),
					("minutes", JsonOut.int(e.minutes)),
				]),
			),
		),
	),
	(
		"matrix",
		JsonOut.array(
			all_nodes.map(
				|a| JsonOut.array(all_nodes.map(|b| JsonOut.int(RoadGraph.minutes(a, b)))),
			),
		),
	),
	(
		"paths",
		JsonOut.array(
			all_nodes.map(
				|a| JsonOut.array(
					all_nodes.map(|b| JsonOut.array(RoadGraph.path(a, b).map(node_name))),
				),
			),
		),
	),
])

## The demand by neighborhood name, sorted by name, each with its houses in
## the order drawn.
demand_of : List(Orders.NeighborhoodOrders) -> JsonOut
demand_of = |orders| {
	named = orders.map(|o| { name: Seattle.name_of(o.nbhd), houses: o.houses })
	sorted = named.sort_with(|p, q| bytes_order(p.name.to_utf8(), q.name.to_utf8()))
	JsonOut.array(
		sorted.map(
			|o| JsonOut.array([
				JsonOut.string(o.name),
				JsonOut.array(o.houses.to_list().map(|h| JsonOut.int(h.to_i64()))),
			]),
		),
	)
}

## Two names' order by their bytes, as JS's `<` on these ASCII names.
bytes_order : List(U8), List(U8) -> [Before, Same, After]
bytes_order = |a, b|
	match (a, b) {
		([], []) => Same
		([], _) => Before
		(_, []) => After
		([x, .. as xs], [y, .. as ys]) =>
			if x < y {
				Before
			} else if x > y {
				After
			} else {
				bytes_order(xs, ys)
			}
	}

gold_route : List(Stop) -> JsonOut
gold_route = |stops|
	JsonOut.ordered_object([
		("stops", JsonOut.array(stops.map(gold_stop))),
		("orders", JsonOut.int(Route.load(stops).to_i64_wrap())),
		("pain", JsonOut.int(Pain.pain_of(stops))),
	])

gold_stop : Stop -> JsonOut
gold_stop = |stop| {
	members = [
		("nbhd", node_name(stop.nbhd)),
		("houses", JsonOut.array(stop.houses.to_list().map(|h| JsonOut.int(h.to_i64())))),
	]
	match stop.pin {
		Free => JsonOut.ordered_object(members)
		Pinned(slot) => JsonOut.ordered_object(
			members.append(("pin", JsonOut.int(slot.to_i64_wrap()))),
		)
	}
}
