## The one cost the solver compares, and the minutes the page's clock
## shows.
##
## **Pain** is an integer: each minute of artery driving costs 10, plus 2
## for every tote still aboard, and entering a neighborhood to deliver costs
## one such minute more. A truck delivers a neighborhood the first time its
## path reaches it, even passing through on the way to another, so the order
## of stops and the road graph's paths both shape it. Being integer, it is
## the same on every engine, and so are the greedy tie-breaks that read it.
##
## **The display minutes** are the page's: the artery minutes, the ring
## walks inside each neighborhood (float geometry), and the service minutes.
## No solver decision reads them.

import Houses
import RoadGraph
import Seattle
import Stop

Pain :: [].{

	## The pain of driving these stops in order, out of the FC and back.
	pain_of : List(Stop) -> I64
	pain_of = |stops| pain_of_view(stops, Whole)

	## A route as a candidate move would leave it, read in place rather than
	## built: whole, with a run of stops reversed (2-opt's candidate), or
	## with a stop inserted. A scan prices thousands of candidates and keeps
	## one, so only the one it keeps is ever built.
	View : [Whole, Reversed({ first : U64, last : U64 }), Inserted({ at : U64, stop : Stop })]

	## The pain of the route `view` makes of `stops`.
	##
	## It is the solver's hot loop, so it is one function over numbers: no
	## helper takes the list (each would count it up and down, atomically),
	## and the paths are read a node at a time.
	pain_of_view : List(Stop), View -> I64
	pain_of_view = |stops, view| priced(stops, view).pain

	## `pain_of_view`, with the route handed back: a scan threads its route
	## through each candidate's pricing, so the route has one owner and is
	## never counted up and down (atomically) a candidate.
	priced : List(Stop), View -> { stops : List(Stop), pain : I64 }
	priced = |stops, view| {
		count = stops.len()
		{ n, extra } =
			match view {
				Inserted({ stop, .. }) => { n: count + 1, extra: stop }
				Whole | Reversed(_) => { n: count, extra: { nbhd: Seattle.fc, houses: Houses.empty, pin: Free } }
			}
		# The stops are read by index, never by `for s in stops`: a `for` over
		# a list counts the list up and down, atomically, each time it runs.
		var $aboard = extra.houses.count().to_i64_wrap()
		var $served = 0
		for j in 0..<count {
			s = stops.get(j) ?? crash "Pain.priced: in range"
			$aboard = $aboard + s.houses.count().to_i64_wrap()
			$served = $served.bitwise_or(U64.shl_wrap(1, s.nbhd))
		}
		if extra.nbhd != Seattle.fc {
			$served = $served.bitwise_or(U64.shl_wrap(1, extra.nbhd))
		}
		var $pain = 0
		var $last = Seattle.fc
		var $delivered = 0
		var $from = Seattle.fc
		for i in 0..=n {
			to =
				if i == n {
					Seattle.fc
				} else {
					match view {
						Whole => (stops.get(i) ?? crash "Pain.pain_of_view: in range").nbhd
						Reversed({ first, last }) =>
							if i >= first and i <= last {
								(stops.get(first + last - i) ?? crash "Pain.pain_of_view: in range").nbhd
							} else {
								(stops.get(i) ?? crash "Pain.pain_of_view: in range").nbhd
							}

						Inserted({ at, stop }) =>
							if i < at {
								(stops.get(i) ?? crash "Pain.pain_of_view: in range").nbhd
							} else if i == at {
								stop.nbhd
							} else {
								(stops.get(i - 1) ?? crash "Pain.pain_of_view: in range").nbhd
							}
					}
				}
			for k in 0..<RoadGraph.path_length($from, to) {
				node = RoadGraph.path_node($from, to, k)
				if node != $last {
					$pain = $pain + RoadGraph.minutes($last, node) * (empty_pain + tote_pain * $aboard)
					$last = node
					bit = U64.shl_wrap(1, node)
					if $served.bitwise_and(bit) != 0 and $delivered.bitwise_and(bit) == 0 {
						$pain = $pain + ring_unit * (empty_pain + tote_pain * $aboard)
						$delivered = $delivered.bitwise_or(bit)
						for j in 0..<count {
							s = stops.get(j) ?? crash "Pain.priced: in range"
							if s.nbhd == node {
								$aboard = $aboard - s.houses.count().to_i64_wrap()
							}
						}
						if extra.nbhd == node {
							$aboard = $aboard - extra.houses.count().to_i64_wrap()
						}
					}
				}
			}
			$from = to
		}
		if n == 0 {
			{ stops, pain: 0 }
		} else {
			{ stops, pain: $pain }
		}
	}

	## The nodes these stops' route drives, FC to FC, the shortest paths
	## between them laid end to end with each repeat of a node in a row
	## dropped.
	path_nodes : List(Stop) -> List(U8)
	path_nodes = |stops| {
		var $out = [Seattle.fc]
		var $from = Seattle.fc
		for to in stops.map(|s| s.nbhd).append(Seattle.fc) {
			for node in RoadGraph.path($from, to) {
				if node != ($out.last() ?? crash "Pain.path_nodes: the route starts at the FC") {
					$out = $out.append(node)
				}
			}
			$from = to
		}
		$out
	}

	## A route's display minutes: artery minutes (whole), the ring walks'
	## (float), the service minutes, and their sum.
	Minutes : { travel : I64, local : F64, service : I64, time : F64 }

	minutes_of : List(Stop) -> Minutes
	minutes_of = |stops|
		if stops.is_empty() {
			{ travel: 0, local: 0, service: 0, time: 0 }
		} else {
			nodes = path_nodes(stops)
			var $travel = 0
			var $local = 0
			var $delivered = []
			for i in 1..<nodes.len() {
				before = nodes.get(i - 1) ?? crash "Pain.minutes_of: in range"
				node = nodes.get(i) ?? crash "Pain.minutes_of: in range"
				$travel = $travel + RoadGraph.minutes(before, node)
				if node != Seattle.fc and i + 1 < nodes.len() {
					after = nodes.get(i + 1) ?? crash "Pain.minutes_of: in range"
					houses = houses_at(stops, node)
					visit = if houses.is_empty() or $delivered.contains(node) {
						Houses.empty
					} else {
						houses
					}
					$local = $local + RoadGraph.local_minutes(
						node,
						{
							entry: Seattle.gate_angle(node, before),
							exit: Seattle.gate_angle(node, after),
							angles: Seattle.house_angles(node, visit.to_list()),
						},
					)
					if !visit.is_empty() {
						$delivered = $delivered.append(node)
					}
				}
			}
			service = total_load(stops).to_i64_wrap() * RoadGraph.service_minutes
			{ travel: $travel, local: $local, service, time: $travel.to_f64() + $local + service.to_f64() }
		}
}

total_load : List(Stop) -> I64
total_load = |stops| stops.fold(0, |n, s| n + s.load().to_i64_wrap())

## Every house the stops deliver in one neighborhood, in stop order.
houses_at : List(Stop), U8 -> Houses
houses_at = |stops, node| stops.fold(
	Houses.empty,
	|hs, s| if s.nbhd == node {
		hs.concat(s.houses)
	} else {
		hs
	},
)

empty_pain : I64
empty_pain = 10

tote_pain : I64
tote_pain = 2

ring_unit : I64
ring_unit = 1
