## The road graph the trucks drive: every artery edge between two nodes,
## its float geometry snapped to whole minutes, then the shortest drive and
## its path between every pair of nodes (Dijkstra from each node). The
## minutes and paths are worked out once, as constants, and the solver only
## reads them.
##
## Order is semantics here, as in roadgraph.ts: the edges are the roads,
## then the bridges, each in its declared order; Dijkstra takes the first
## node of least distance and relaxes an edge only when strictly shorter, so
## of two equally short paths the gold's is the one found.

import Seattle

RoadGraph :: [].{

	Edge : { a : U8, b : U8, minutes : I64 }

	## Every artery edge, roads then bridges' spans, with its minutes.
	edges : List(Edge)
	edges = {
		roads = Seattle.roads.map(
			|(a, b)| {
				on_i5 = Seattle.is_i5_exit(a) or Seattle.is_i5_exit(b)
				points = [Seattle.gate_point(a, Seattle.point_of(b)), Seattle.gate_point(b, Seattle.point_of(a))]
				minutes = length_px(points) * factor(a, b, Surface) * min_per_px
				{
					a,
					b,
					minutes: rounded_minutes(
						minutes,
						if on_i5 {
							Ramp
						} else {
							Artery
						},
					),
				}
			},
		)
		var $out = roads
		for bridge in Seattle.bridges {
			for i in 0..<(bridge.nodes.len() - 1) {
				a = bridge.nodes.get(i) ?? crash "RoadGraph.edges: a span's first node"
				c = bridge.nodes.get(i + 1) ?? crash "RoadGraph.edges: a span's last node"
				waters = bridge.waters.get(i) ?? crash "RoadGraph.edges: a span's waters"
				first_turn = waters.first() ?? Seattle.point_of(c)
				last_turn = waters.last() ?? Seattle.point_of(a)
				points = [Seattle.gate_point(a, first_turn)].concat(waters).append(Seattle.gate_point(c, last_turn))
				on_i5 = Seattle.is_i5_exit(a) or Seattle.is_i5_exit(c)
				minutes = length_px(points) * factor(a, c, Bridge) * min_per_px
				$out = $out.append({
					a,
					b: c,
					minutes: rounded_minutes(
						minutes,
						if on_i5 {
							Ramp
						} else {
							Artery
						},
					),
				})
			}
		}
		$out
	}

	## The minutes of the shortest drive from node `a` to node `b`.
	minutes : U8, U8 -> I64
	minutes = |a, b| matrix.get(a.to_u64() * Seattle.node_count + b.to_u64()) ?? crash "RoadGraph.minutes: no such node"

	## The nodes of the shortest drive from `a` to `b`, both ends included.
	path : U8, U8 -> List(U8)
	path = |a, b| paths.get(a.to_u64() * Seattle.node_count + b.to_u64()) ?? crash "RoadGraph.path: no such node"

	## How many nodes the shortest drive from `a` to `b` passes, both ends
	## included, and the `k`th of them: `path` without a list to carry, for
	## the pain's hot loop.
	path_length : U8, U8 -> U64
	path_length = |a, b| (path_lengths.get(a.to_u64() * Seattle.node_count + b.to_u64()) ?? crash "RoadGraph.path_length: no such node").to_u64()

	path_node : U8, U8, U64 -> U8
	path_node = |a, b, k| path_store.get((a.to_u64() * Seattle.node_count + b.to_u64()) * path_most + k) ?? crash "RoadGraph.path_node: no such node"

	## Every pair's minutes, `a * node_count + b`, for the gold to compare.
	all_minutes : List(I64)
	all_minutes = matrix

	## Minutes on a neighborhood's slow ring road: the ring walk (Seattle's
	## `ring_walk_px`) at its side's arterial speed, slowed. The display's
	## clock and the one float-scored pass read it.
	local_minutes : U8, { entry : F64, exit : F64, angles : List(F64) } -> F64
	local_minutes = |node, walk| {
		arterial = if Seattle.is_west(node) {
			speed_city
		} else {
			speed_suburb
		}
		Seattle.ring_walk_px(node, walk) * arterial * neighborhood_slowdown * min_per_px
	}

	## Minutes of service per order: the same for every plan, so a wash in
	## the solver, and only the display's.
	service_minutes : I64
	service_minutes = 2
}

min_per_px : F64
min_per_px = 0.0225

speed_city : F64
speed_city = 1.6

speed_suburb : F64
speed_suburb = 1.0

speed_bridge : F64
speed_bridge = 1.2

speed_bridge520 : F64
speed_bridge520 = 1.5

speed_fast : F64
speed_fast = 0.6

speed_i5 : F64
speed_i5 = 0.8

neighborhood_slowdown : F64
neighborhood_slowdown = 2.1

length_px : List(Seattle.Point) -> F64
length_px = |points| {
	var $d = 0
	var $prev = points.first() ?? crash "RoadGraph.length_px: a road has ends"
	for p in points.drop_first(1) {
		dx = p.x - $prev.x
		dy = p.y - $prev.y
		$d = $d + (dx * dx + dy * dy).sqrt()
		$prev = p
	}
	$d
}

## An edge's speed factor (lower is faster), in roadgraph.ts's order of
## checks: 520's lake span, Montlake and I-5, the 405 bypass, bridges, the
## city, the suburbs.
factor : U8, U8, [Surface, Bridge] -> F64
factor = |a, b, kind| {
	montlake = Seattle.node_of("Montlake")
	issaquah = Seattle.node_of("Issaquah")
	redmond = Seattle.node_of("Redmond")
	medina = Seattle.medina
	if (a == montlake and b == medina) or (a == medina and b == montlake) {
		speed_bridge520
	} else if a == montlake or b == montlake {
		speed_i5
	} else if Seattle.is_i5_exit(a) or Seattle.is_i5_exit(b) {
		speed_i5
	} else if (a == issaquah and b == redmond) or (a == redmond and b == issaquah) {
		speed_fast
	} else {
		match kind {
			Bridge => speed_bridge
			Surface => if Seattle.is_west(a) or Seattle.is_west(b) {
				speed_city
			} else {
				speed_suburb
			}
		}
	}
}

## Float minutes rounded to whole ones. A value within 1e-9 of a half is a
## coin-flip between engines, so it stops the build; an artery under a
## minute is a map error, and an I-5 ramp under one counts as one.
rounded_minutes : F64, [Artery, Ramp] -> I64
rounded_minutes = |x, kind| {
	r = (x + 0.5).floor_to_i64_try() ?? crash "RoadGraph.rounded_minutes: out of range"
	is_half = 0.5 - (x - r.to_f64()).abs() < 0.000000001
	match kind {
		Artery => {
			if is_half or r < 1 {
				crash "RoadGraph.rounded_minutes: ${x.to_str()} lands on a half minute, or below one"
			}
			r
		}
		Ramp =>
			if r < 1 {
				1
			} else if is_half {
				crash "RoadGraph.rounded_minutes: ${x.to_str()} lands on a half minute"
			} else {
				r
			}
	}
}

## Where Dijkstra leaves nothing: no edge, no path.
unreached : I64
unreached = 9_223_372_036_854_775_807

## Each node's edges, both ways, in edge order.
Spoke : { to : U8, minutes : I64 }

adjacency : List(List(Spoke))
adjacency = {
	var $out = List.repeat([], Seattle.node_count)
	for e in RoadGraph.edges {
		$out = with_spoke($out, e.a, { to: e.b, minutes: e.minutes })
		$out = with_spoke($out, e.b, { to: e.a, minutes: e.minutes })
	}
	$out
}

with_spoke : List(List(Spoke)), U8, Spoke -> List(List(Spoke))
with_spoke = |adj, node, spoke| {
	{ list, prev } = adj.replace(node.to_u64(), []) ?? crash "RoadGraph.with_spoke: no such node"
	list.set(node.to_u64(), prev.append(spoke)) ?? crash "RoadGraph.with_spoke: no such node"
}

## One source's Dijkstra: each node's distance and the node before it on
## the path (`n`, the source itself or none).
Reach : { dist : List(I64), prev : List(U64) }

reach_from : U64 -> Reach
reach_from = |s| {
	n = Seattle.node_count
	var $dist = List.repeat(unreached, n).set(s, 0) ?? crash "RoadGraph.reach_from: no such node"
	var $prev = List.repeat(n, n)
	var $done = List.repeat(False, n)
	var $going = True
	for _ in 0..<n {
		if $going {
			var $u = n
			var $best = unreached
			for k in 0..<n {
				d = $dist.get(k) ?? crash "RoadGraph.reach_from: in range"
				if !($done.get(k) ?? crash "RoadGraph.reach_from: in range") and d < $best {
					$best = d
					$u = k
				}
			}
			if $u == n {
				$going = False
			} else {
				u = $u
				$done = $done.set(u, True) ?? crash "RoadGraph.reach_from: in range"
				du = $dist.get(u) ?? crash "RoadGraph.reach_from: in range"
				for spoke in adjacency.get(u) ?? crash "RoadGraph.reach_from: in range" {
					to = spoke.to.to_u64()
					if du + spoke.minutes < ($dist.get(to) ?? crash "RoadGraph.reach_from: in range") {
						$dist = $dist.set(to, du + spoke.minutes) ?? crash "RoadGraph.reach_from: in range"
						$prev = $prev.set(to, u) ?? crash "RoadGraph.reach_from: in range"
					}
				}
			}
		}
	}
	{ dist: $dist, prev: $prev }
}

reaches : List(Reach)
reaches = List.from_iter(U64.until(0, Seattle.node_count)).map(reach_from)

matrix : List(I64)
matrix = reaches.join_map(|r| r.dist)

paths : List(List(U8))
paths = {
	n = Seattle.node_count
	var $out = List.with_capacity(n * n)
	var $a = 0
	for r in reaches {
		for b in 0..<n {
			$out = $out.append(path_back(r.prev, { from: $a, to: b }))
		}
		$a = $a + 1
	}
	$out
}

## Every path's nodes, `path_most` a pair, and each path's length.
path_most : U64
path_most = 32

path_store : List(U8)
path_store = paths.join_map(
	|p| {
		if p.len() > path_most {
			crash "RoadGraph.path_store: a path longer than path_most"
		}
		p.concat(List.repeat(0, path_most - p.len()))
	},
)

path_lengths : List(U8)
path_lengths = paths.map(|p| p.len().to_u8_wrap())

## The path from `from` to `to`, walked back along `prev`.
path_back : List(U64), { from : U64, to : U64 } -> List(U8)
path_back = |prev, { from, to }| {
	var $rev = [to.to_u8_wrap()]
	var $v = to
	while $v != from {
		$v = prev.get($v) ?? crash "RoadGraph.path_back: the road graph is connected"
		$rev = $rev.append($v.to_u8_wrap())
	}
	$rev.rev()
}
