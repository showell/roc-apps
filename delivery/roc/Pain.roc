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
	pain_of = |stops|
		if stops.is_empty() {
			0
		} else {
			start = { pain: 0, aboard: total_load(stops), last: Seattle.fc, delivered: 0 }
			var $walk = start
			var $from = Seattle.fc
			for stop in stops {
				$walk = leg_onto($walk, { stops, from: $from, to: stop.nbhd })
				$from = stop.nbhd
			}
			done = leg_onto($walk, { stops, from: $from, to: Seattle.fc })
			done.pain
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
houses_at = |stops, node| stops.fold(Houses.empty, |hs, s| if s.nbhd == node { hs.concat(s.houses) } else { hs })

## The route's pain so far, as it drives: the totes aboard, the last node
## it reached, and the neighborhoods delivered, a bit a node.
Walk : { pain : I64, aboard : I64, last : U8, delivered : U64 }

## The walk on along the shortest path from `from` to `to`.
leg_onto : Walk, { stops : List(Stop), from : U8, to : U8 } -> Walk
leg_onto = |walk, { stops, from, to }| {
	var $w = walk
	for node in RoadGraph.path(from, to) {
		if node != $w.last {
			driven = $w.pain + RoadGraph.minutes($w.last, node) * (empty_pain + tote_pain * $w.aboard)
			bit = U64.shl_wrap(1, node)
			if node != Seattle.fc and $w.delivered.bitwise_and(bit) == 0 {
				served = houses_at(stops, node).count().to_i64_wrap()
				if served > 0 {
					$w = {
						pain: driven + ring_unit * (empty_pain + tote_pain * $w.aboard),
						aboard: $w.aboard - served,
						last: node,
						delivered: $w.delivered.bitwise_or(bit),
					}
				} else {
					$w = { ..$w, pain: driven, last: node }
				}
			} else {
				$w = { ..$w, pain: driven, last: node }
			}
		}
	}
	$w
}

empty_pain : I64
empty_pain = 10

tote_pain : I64
tote_pain = 2

ring_unit : I64
ring_unit = 1
