## The map the trucks drive: Seattle's neighborhoods, deliberately not to
## scale, with the roads and bridges between them, the fulfillment center
## (FC), and the fleet that works out of it. A neighborhood is a node, by
## its place in `neighborhoods`; the FC is the node after the last one.
##
## It also holds the ring geometry the solver reads: each neighborhood is a
## ring of houses its trucks enter and leave by gates, one facing each
## neighbor. Every float here is plain IEEE arithmetic on the map's own
## numbers, plus `atan2` (Roc's fdlibm port) for a gate's angle, so a gate is
## the same bits on every target; the tables of gate angles and phases are
## worked out once, as constants.
##
## geography.ts holds the same map for the page to draw. The gold's
## substrate section (`gold_check.zig`) holds the two in agreement.

Seattle :: [].{

	## One neighborhood: its name, its center on the map, its side of the
	## lake (the west is city, slower), its ring's radius, how many houses
	## stand on the ring, and whether it is an overflow neighborhood: one
	## left out of the merging and placed in the trucks' room at the end
	## (`Overflow`), one routed with the rest (`Routed`), or one the race
	## tries both ways (`EitherWay`).
	Neighborhood : {
		name : Str,
		x : F64,
		y : F64,
		side : [West, East, Island],
		ring_radius : F64,
		house_count : U8,
		overflow : [Routed, Overflow, EitherWay],
	}

	neighborhoods : List(Neighborhood)
	neighborhoods = [
		{
			name: "Ballard",
			x: 224,
			y: 146,
			side: West,
			ring_radius: 32,
			house_count: 12,
			overflow: Routed,
		},
		{
			name: "Green Lake",
			x: 360,
			y: 62,
			side: West,
			ring_radius: 34,
			house_count: 12,
			overflow: Routed,
		},
		{
			name: "Fremont",
			x: 340,
			y: 212,
			side: West,
			ring_radius: 30,
			house_count: 12,
			overflow: Routed,
		},
		{
			name: "U-District",
			x: 460,
			y: 169,
			side: West,
			ring_radius: 30,
			house_count: 12,
			overflow: Routed,
		},
		{
			name: "Magnolia",
			x: 170,
			y: 291,
			side: West,
			ring_radius: 26,
			house_count: 12,
			overflow: Routed,
		},
		{
			name: "Queen Anne",
			x: 286,
			y: 316,
			side: West,
			ring_radius: 32,
			house_count: 12,
			overflow: Routed,
		},
		{
			name: "Capitol Hill",
			x: 434,
			y: 443,
			side: West,
			ring_radius: 29,
			house_count: 12,
			overflow: Routed,
		},
		{
			name: "Eastlake",
			x: 441,
			y: 311,
			side: West,
			ring_radius: 24,
			house_count: 12,
			overflow: Routed,
		},
		{
			name: "Downtown",
			x: 300,
			y: 430,
			side: West,
			ring_radius: 30,
			house_count: 12,
			overflow: Routed,
		},
		{
			name: "Beacon Hill",
			x: 432,
			y: 555,
			side: West,
			ring_radius: 30,
			house_count: 12,
			overflow: Routed,
		},
		{
			name: "West Seattle",
			x: 211,
			y: 589,
			side: West,
			ring_radius: 30,
			house_count: 12,
			overflow: Routed,
		},
		{
			name: "Mercer Island",
			x: 548,
			y: 500,
			side: Island,
			ring_radius: 10,
			house_count: 0,
			overflow: Routed,
		},
		{
			name: "Mercer N",
			x: 548,
			y: 552,
			side: Island,
			ring_radius: 19,
			house_count: 12,
			overflow: Routed,
		},
		{
			name: "Mercer S",
			x: 548,
			y: 635,
			side: Island,
			ring_radius: 19,
			house_count: 12,
			overflow: Routed,
		},
		{
			name: "Medina",
			x: 638,
			y: 228,
			side: East,
			ring_radius: 28,
			house_count: 12,
			overflow: EitherWay,
		},
		{
			name: "Kirkland",
			x: 650,
			y: 60,
			side: East,
			ring_radius: 30,
			house_count: 12,
			overflow: Routed,
		},
		{
			name: "Redmond",
			x: 868,
			y: 200,
			side: East,
			ring_radius: 32,
			house_count: 12,
			overflow: Routed,
		},
		{
			name: "Bellevue",
			x: 740,
			y: 330,
			side: East,
			ring_radius: 34,
			house_count: 12,
			overflow: Overflow,
		},
		{
			name: "Factoria",
			x: 672,
			y: 508,
			side: East,
			ring_radius: 30,
			house_count: 12,
			overflow: Routed,
		},
		{
			name: "Issaquah",
			x: 858,
			y: 612,
			side: East,
			ring_radius: 30,
			house_count: 12,
			overflow: Routed,
		},
		{
			name: "Exit 1",
			x: 328,
			y: 570,
			side: West,
			ring_radius: 6,
			house_count: 0,
			overflow: Routed,
		},
		{
			name: "Exit 2",
			x: 377,
			y: 436,
			side: West,
			ring_radius: 6,
			house_count: 0,
			overflow: Routed,
		},
		{
			name: "Exit 3",
			x: 397,
			y: 311,
			side: West,
			ring_radius: 6,
			house_count: 0,
			overflow: Routed,
		},
		{
			name: "Exit 4",
			x: 401,
			y: 212,
			side: West,
			ring_radius: 6,
			house_count: 0,
			overflow: Routed,
		},
		{
			name: "Exit 5",
			x: 405,
			y: 169,
			side: West,
			ring_radius: 6,
			house_count: 0,
			overflow: Routed,
		},
		{
			name: "Exit 6",
			x: 414,
			y: 84,
			side: West,
			ring_radius: 6,
			house_count: 0,
			overflow: Routed,
		},
		{
			name: "5/520",
			x: 399,
			y: 262,
			side: West,
			ring_radius: 6,
			house_count: 0,
			overflow: Routed,
		},
		{
			name: "Montlake",
			x: 490,
			y: 256,
			side: West,
			ring_radius: 6,
			house_count: 0,
			overflow: Routed,
		},
	]

	## The FC's node, after every neighborhood's, and how many nodes there are.
	fc : U8
	fc = neighborhoods.len().to_u8_wrap()

	node_count : U64
	node_count = neighborhoods.len() + 1

	## The node a name names. The map's own tables use it, at compile time,
	## so a misspelled name stops the build.
	node_of : Str -> U8
	node_of = |name|
		if name == "FC" {
			fc
		} else {
			match neighborhoods.find_first_index(|n| n.name == name) {
				Ok(i) => i.to_u8_wrap()
				Err(NotFound) => crash "Seattle.node_of: no neighborhood is named ${name}"
			}
		}

	name_of : U8 -> Str
	name_of = |node|
		if node == fc {
			"FC"
		} else {
			neighborhood_of(node).name
		}

	neighborhood_of : U8 -> Neighborhood
	neighborhood_of = |node| neighborhoods.get(node.to_u64()) ?? crash "Seattle.neighborhood_of: the FC is no neighborhood"

	is_west : U8 -> Bool
	is_west = |node|
		if node == fc {
			False
		} else {
			neighborhood_of(node).side == West
		}

	## The fleet: eight trucks, a hundred orders a day, the west side's trucks
	## carrying more than the east's. Each truck is a slot, by its place here.
	truck_count : U64
	truck_count = 8

	order_count : U64
	order_count = 100

	truck_caps : List(U64)
	truck_caps = [14, 14, 14, 14, 14, 12, 12, 12]

	cap_of_slot : U64 -> U64
	cap_of_slot = |slot| truck_caps.get(slot) ?? crash "Seattle.cap_of_slot: no truck in that slot"

	## The most any truck carries: the cap of a route no anchor holds yet.
	max_cap : U64
	max_cap = 14

	## Each slot's anchor: the neighborhood its truck always serves first, if
	## the day has orders there.
	truck_anchors : List(U8)
	truck_anchors = [
		"West Seattle",
		"Magnolia",
		"Ballard",
		"Green Lake",
		"Capitol Hill",
		"Kirkland",
		"Issaquah",
		"Mercer S",
	].map(node_of)

	## The slot whose anchor a node is.
	anchor_slot : U8 -> [Anchors(U64), NoAnchor]
	anchor_slot = |node|
		match truck_anchors.find_first_index(|a| a == node) {
			Ok(slot) => Anchors(slot)
			Err(NotFound) => NoAnchor
		}

	## Medina, the SR-520 bridgehead.
	medina : U8
	medina = node_of("Medina")

	## The fleet as the solve's top level reads it: how many trucks, and
	## each one's cap and anchor, by slot.
	Fleet : {
		truck_count : U64,
		caps : List(U64),
		anchors : List(U8),
	}

	fleet : Fleet
	fleet = { truck_count, caps: truck_caps, anchors: truck_anchors }

	## The geography as the solve's top level reads it: the neighborhoods,
	## each saying whether it is an overflow neighborhood. Bellevue, on the
	## FC just across the lake, always is; Medina, the SR-520
	## bridgehead, is in half the race. The road graph and the rings are the
	## map's constants (RoadGraph.roc, this module), which every stage reads.
	Geography : { neighborhoods : List(Neighborhood) }

	geography : Geography
	geography = { neighborhoods: neighborhoods }

	## The neighborhoods whose ring is never cut into arcs.
	is_arc_exempt : U8 -> Bool
	is_arc_exempt = |node| arc_exempt.contains(node)

	is_i5_exit : U8 -> Bool
	is_i5_exit = |node| i5_exits.contains(node)

	## Surface roads, as pairs of nodes, in the order the road graph is
	## built from.
	roads : List((U8, U8))
	roads = [
		("Ballard", "Green Lake"),
		("Ballard", "Fremont"),
		("Magnolia", "Ballard"),
		("Magnolia", "Queen Anne"),
		("Green Lake", "Fremont"),
		("Fremont", "Queen Anne"),
		("Queen Anne", "Downtown"),
		("Capitol Hill", "Eastlake"),
		("Capitol Hill", "Beacon Hill"),
		("Downtown", "West Seattle"),
		("Exit 1", "West Seattle"),
		("Exit 1", "Beacon Hill"),
		("Exit 2", "Downtown"),
		("Exit 2", "Capitol Hill"),
		("Exit 3", "Eastlake"),
		("Exit 4", "Fremont"),
		("Exit 5", "U-District"),
		("Exit 6", "Green Lake"),
		("Eastlake", "Montlake"),
		("Medina", "Kirkland"),
		("Medina", "Bellevue"),
		("Kirkland", "Redmond"),
		("Bellevue", "Redmond"),
		("Bellevue", "Factoria"),
		("Bellevue", "FC"),
		("FC", "Factoria"),
		("Factoria", "Issaquah"),
		("Issaquah", "Redmond"),
		("Mercer Island", "Mercer N"),
		("Mercer N", "Mercer S"),
	].map(|(a, b)| (node_of(a), node_of(b)))

	## A bridge: its nodes in order, and the waypoints over the water between
	## each node and the next.
	Bridge : { landings : List(U8), waters : List(List(Point)) }

	Point : { x : F64, y : F64 }

	bridges : List(Bridge)
	bridges = [
		{ landings: ["5/520", "Montlake", "Medina"].map(node_of), waters: [[], []] },
		{
			landings: ["Beacon Hill", "Mercer Island", "Factoria"].map(node_of),
			waters: [[{ x: 482, y: 522 }], [{ x: 610, y: 489 }]],
		},
		{
			landings: [
				"Exit 1",
				"Exit 2",
				"Exit 3",
				"5/520",
				"Exit 4",
				"Exit 5",
				"Exit 6",
			].map(node_of),
			waters: [[], [{ x: 399, y: 373 }], [], [], [], []],
		},
	]

	## A node's place on the map: a neighborhood's center, or the FC.
	point_of : U8 -> Point
	point_of = |node|
		if node == fc {
			{ x: 802, y: 396 }
		} else {
			n = neighborhood_of(node)
			{ x: n.x, y: n.y }
		}

	## The gate where the artery toward `toward` meets `node`'s ring.
	gate_point : U8, Point -> Point
	gate_point = |node, toward|
		if node == fc {
			point_of(fc)
		} else {
			n = neighborhood_of(node)
			a = F64.atan2({ x: toward.x - n.x, y: toward.y - n.y })
			{ x: n.x + a.cos() * n.ring_radius, y: n.y + a.sin() * n.ring_radius }
		}

	## The angle, from `node`'s center, of its gate facing node `toward`; the
	## FC has no ring, so 0.
	gate_angle : U8, U8 -> F64
	gate_angle = |
		node,
		toward,
	| gate_angles.get(node.to_u64().times_wrap(node_count) + toward.to_u64()) ?? crash "Seattle.gate_angle: no such node"

	## The ring angles of a neighborhood's houses, in the order given.
	house_angles : U8, List(U8) -> List(F64)
	house_angles = |node, houses|
		if node == fc {
			[]
		} else {
			phase = phases.get(node.to_u64()) ?? crash "Seattle.house_angles: no such node"
			count = neighborhood_of(node).house_count.to_f64()
			houses.map(|h| phase + h.to_f64() / count * tau)
		}

	## An angle brought into [0, 2π): JS's `%`, whose remainder keeps the
	## dividend's sign, is Roc's `rem_by`.
	norm : F64 -> F64
	norm = |a| F64.rem_by(F64.rem_by(a, tau) + tau, tau)

	tau : F64
	tau = F64.pi * 2.0

	## A node's surface-road neighbors (bridges left out on purpose), in
	## `roads` order.
	surface_spokes : U8 -> List(U8)
	surface_spokes = |node| {
		var $out = []
		for (a, b) in roads {
			if a == node and b != fc {
				$out = $out.append(b)
			}
			if b == node and a != fc {
				$out = $out.append(a)
			}
		}
		$out
	}

	## A stop's houses cut into the ring's wedges between its surface-road
	## gates, each wedge's houses in the order given, the wedges by angle. An
	## exempt ring, one with fewer than two spokes, or no houses, stays whole.
	arc_groups : U8, List(U8) -> List(List(U8))
	arc_groups = |node, houses| {
		spokes = surface_spokes(node)
		if is_arc_exempt(node) or spokes.len() < 2 or houses.is_empty() {
			if houses.is_empty() {
				[]
			} else {
				[houses]
			}
		} else {
			gates = spokes.map(|s| norm(gate_angle(node, s))).sort_with(float_order)
			angles = house_angles(node, houses)
			last_gate = spokes.len() - 1
			arcs = angles.map(
				|ha| {
					a = norm(ha)
					var $g = last_gate
					var $i = 0
					for gate in gates {
						if gate <= a {
							$g = $i
						}
						$i = $i + 1
					}
					$g
				},
			)
			var $groups = []
			for arc in 0..<spokes.len() {
				var $group = []
				var $k = 0
				for h in houses {
					if (arcs.get($k) ?? crash "Seattle.arc_groups: an arc for every house") == arc {
						$group = $group.append(h)
					}
					$k = $k + 1
				}
				if !$group.is_empty() {
					$groups = $groups.append($group)
				}
			}
			$groups
		}
	}

	## The length in pixels of the shortest walk round `node`'s ring that
	## enters at one gate, passes every house, and leaves by the other: out
	## and back over the covered arc, or once round when both gates are one.
	ring_walk_px : U8,
	{
		entry_angle : F64,
		exit_angle : F64,
		angles : List(F64),
	} -> F64
	ring_walk_px = |node, { entry_angle: entry, exit_angle: exit, angles }|
		if node == fc {
			0
		} else {
			r = neighborhood_of(node).ring_radius
			points = [norm(entry), norm(exit)].concat(angles.map(norm)).sort_with(float_order)
			n = points.len()
			first = points.get(0) ?? crash "Seattle.ring_walk_px: the gates are points"
			var $max_gap = -1.0
			var $gap_at = 0
			var $i = 0
			for p in points {
				next = if $i + 1 < n {
					points.get($i + 1) ?? crash "Seattle.ring_walk_px: in range"
				} else {
					first + tau
				}
				if next - p > $max_gap {
					$max_gap = next - p
					$gap_at = $i
				}
				$i = $i + 1
			}
			start = points.get(($gap_at + 1) % n) ?? crash "Seattle.ring_walk_px: in range"
			covered = tau - $max_gap
			pe = arc_offset(entry, { start, covered })
			px = arc_offset(exit, { start, covered })
			is_same_gate = norm(entry - exit) < 0.000000001
			arc = if is_same_gate and 2 * covered > tau {
				tau
			} else {
				2 * covered - (pe - px).abs()
			}
			arc * r
		}
}

## A gate's offset along the covered arc from `start`, snapped to the nearer
## end of the arc when float drift has put it in the gap.
arc_offset : F64, { start : F64, covered : F64 } -> F64
arc_offset = |a, { start, covered }| {
	o = Seattle.norm(a - start)
	if o <= covered {
		o
	} else if Seattle.tau - o < o - covered {
		0
	} else {
		covered
	}
}

## Ascending order for floats the solver sorts; none is NaN.
float_order : F64, F64 -> [Before, Same, After]
float_order = |p, q|
	if p < q {
		Before
	} else if p > q {
		After
	} else {
		Same
	}

i5_exits : List(U8)
i5_exits = [
	"Exit 1",
	"Exit 2",
	"Exit 3",
	"Exit 4",
	"Exit 5",
	"Exit 6",
	"5/520",
].map(Seattle.node_of)

arc_exempt : List(U8)
arc_exempt = [
	"West Seattle",
	"Magnolia",
	"Kirkland",
	"Issaquah",
	"Mercer S",
	"U-District",
].map(Seattle.node_of)

## Every gate's angle, `node * node_count + toward`.
gate_angles : List(F64)
gate_angles = {
	n = Seattle.node_count
	var $out = List.with_capacity(n * n)
	for node in 0..<n {
		for toward in 0..<n {
			$out = $out.append(gate_angle_of(node.to_u8_wrap(), toward.to_u8_wrap()))
		}
	}
	$out
}

gate_angle_of : U8, U8 -> F64
gate_angle_of = |node, toward|
	if node == Seattle.fc {
		0
	} else {
		n = Seattle.neighborhood_of(node)
		p = Seattle.point_of(toward)
		F64.atan2({ x: p.x - n.x, y: p.y - n.y })
	}

## Each node's ring phase: a hash of its name, in whole degrees, as radians.
phases : List(F64)
phases = Seattle.neighborhoods.map(|n| name_phase(n.name))

name_phase : Str -> F64
name_phase = |name| {
	var $h = 0
	for c in name.to_utf8() {
		$h = U32.plus_wrap(U32.times_wrap($h, 31), c.to_u32())
	}
	($h % 360).to_f64() * (F64.pi / 180.0)
}
