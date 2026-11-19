## A truck's itinerary: its stops in order, each with what the plan
## expects there: when the truck arrives (display minutes after leaving the
## FC: artery minutes, ring walks and service so far), how many totes are
## aboard before it drops, and the route's pain so far. A truck delivers a
## neighborhood the first time its path reaches it, so a stop's arrival is
## that moment, which can be on the way to an earlier stop.
##
## These are predictions for the display. No solver decision reads them;
## they are worked out from the finished routes by the same walk the pain
## and the display minutes make, so the itinerary's totals are the route's
## (the expects below hold them equal).

import Houses
import Pain
import RoadGraph
import Route
import Seattle
import Stop

Itinerary := {
	stops : List(ExpectedStop),

	## Minutes from leaving the FC to returning there.
	expected_return : F64,

	## The route's pain, FC to FC.
	expected_pain : I64,
}.{

	## One stop and what is expected there.
	ExpectedStop : {
		stop : Stop,
		expected_arrival : F64,
		expected_totes_aboard : U64,
		expected_pain_so_far : I64,
	}

	## The itinerary of a route's stops.
	itinerary_of : List(Stop) -> Itinerary
	itinerary_of = |stops|
		if stops.is_empty() {
			{ stops: [], expected_return: 0, expected_pain: 0 }
		} else {
			walked = walk(stops)
			expected = stops.map(
				|stop| {
					reached = walked.arrivals.find_first(|a| a.nbhd == stop.nbhd) ?? crash "Itinerary.itinerary_of: the path reaches every stop"
					{
						stop,
						expected_arrival: reached.minutes,
						expected_totes_aboard: reached.aboard,
						expected_pain_so_far: reached.pain,
					}
				},
			)
			{
				stops: expected,
				expected_return: walked.minutes,
				expected_pain: walked.pain,
			}
		}

	## The route's stops, without their timings.
	route : Itinerary -> List(Stop)
	route = |itinerary| itinerary.stops.map(|e| e.stop)
}

## Each neighborhood's first arrival on the walk, and the walk's totals.
Arrival : {
	nbhd : U8,
	minutes : F64,
	aboard : U64,
	pain : I64,
}

## The route driven node by node as Pain's `pain_of` and `minutes_of` drive
## it, the same sums in the same order, noting each delivery's arrival.
walk : List(Stop) -> {
	arrivals : List(Arrival),
	minutes : F64,
	pain : I64,
}
walk = |stops| {
	nodes = Pain.path_nodes(stops)
	var $travel = 0
	var $local = 0
	var $service = 0
	var $pain = 0
	var $aboard = Route.load(stops)
	var $arrivals = []
	for i in 1..<nodes.len() {
		before = nodes.get(i - 1) ?? crash "Itinerary.walk: in range"
		node = nodes.get(i) ?? crash "Itinerary.walk: in range"
		leg = RoadGraph.minutes(before, node)
		$travel = $travel + leg
		$pain = $pain + leg * (empty_pain + tote_pain * $aboard.to_i64_wrap())
		if node != Seattle.fc and i + 1 < nodes.len() {
			after = nodes.get(i + 1) ?? crash "Itinerary.walk: in range"
			houses = stops.fold(
				Houses.empty,
				|hs, s|
					if s.nbhd == node {
						Houses.concat(hs, s.houses)
					} else {
						hs
					},
			)
			is_delivery = !houses.is_empty() and !$arrivals.any(|a| a.nbhd == node)
			visit = if is_delivery {
				houses
			} else {
				Houses.empty
			}
			if is_delivery {
				arrival = $travel.to_f64() + $local + $service.to_f64()
				$arrivals = $arrivals.append({
					nbhd: node,
					minutes: arrival,
					aboard: $aboard,
					pain: $pain,
				})
				$pain = $pain + empty_pain + tote_pain * $aboard.to_i64_wrap()
				$aboard = $aboard - houses.count()
				$service = $service + houses.count().to_i64_wrap() * RoadGraph.service_minutes
			}
			$local = $local + RoadGraph.local_minutes(
				node,
				{
					entry_angle: Seattle.gate_angle(node, before),
					exit_angle: Seattle.gate_angle(node, after),
					angles: Seattle.house_angles(node, visit.to_list()),
				},
			)
		}
	}
	{
		arrivals: $arrivals,
		minutes: $travel.to_f64() + $local + $service.to_f64(),
		pain: $pain,
	}
}

empty_pain : I64
empty_pain = 10

tote_pain : I64
tote_pain = 2

## Stops in neighborhoods by name, free to move, for the expects.
stops_in : List((Str, List(U8))) -> List(Stop)
stops_in = |named| named.map(
	|(name, houses)| Route.free_stop(Seattle.node_of(name), Houses.from_list(houses)),
)

## Routes for the expects: one stop; three on one side of the lake; and
## one that crosses it, Bellevue delivered on the way to Redmond, the
## route's first stop, so the first stop is not the first delivery.
sample_routes : List(List(Stop))
sample_routes = [
	stops_in([("Ballard", [0, 3, 5])]),
	stops_in([
		("Fremont", [1, 2]),
		("Queen Anne", [4]),
		("Downtown", [7, 8, 9]),
	]),
	stops_in([
		("Redmond", [0, 1]),
		("Bellevue", [5]),
		("Kirkland", [2, 3, 4]),
	]),
]

expect sample_routes.all(|r| Itinerary.itinerary_of(r).expected_pain == Pain.pain_of(r))
expect sample_routes.all(|r| Itinerary.itinerary_of(r).expected_return == Pain.minutes_of(r).time)
expect sample_routes.all(|r| Itinerary.itinerary_of(r).route() == r)

expect
	sample_routes.all(
		|r| {
			stops = Itinerary.itinerary_of(r).stops
			earliest = stops.fold(
				stops.first() ?? crash "Itinerary: a sample has stops",
				|e, s|
					if s.expected_arrival < e.expected_arrival {
						s
					} else {
						e
					},
			)
			earliest.expected_totes_aboard == Route.load(r) and earliest.expected_pain_so_far > 0
		},
	)

## Each stop's totes aboard less its own drop is what the next delivery
## finds aboard, and the last delivery leaves none.
expect
	sample_routes.all(
		|r| {
			by_arrival = Itinerary.itinerary_of(r).stops.sort_with(
				|p, q|
					if p.expected_arrival < q.expected_arrival {
						Before
					} else if p.expected_arrival > q.expected_arrival {
						After
					} else {
						Same
					},
			)
			left = by_arrival.fold(
				Route.load(r),
				|aboard, e|
					if e.expected_totes_aboard == aboard {
						aboard - e.stop.load()
					} else {
						aboard + 1000
					},
			)
			left == 0
		},
	)

## Bellevue, the route's second stop, is delivered first, on the way.
expect {
	crossing = stops_in([
		("Redmond", [0, 1]),
		("Bellevue", [5]),
		("Kirkland", [2, 3, 4]),
	])
	match Itinerary.itinerary_of(crossing).stops {
		[redmond, bellevue, ..] => bellevue.expected_arrival < redmond.expected_arrival
		_ => False
	}
}

expect {
	nothing = Itinerary.itinerary_of([])
	nothing.expected_return == 0 and nothing.expected_pain == 0
}
