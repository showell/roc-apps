## SightingExpects holds the expects of what the rider sights beside the road:
## trees, rails, billboards, wildlife, towers, the pond and the truck.

import Fixtures
import game.Across
import game.Along
import game.Angle
import game.Beacon
import game.BendAnimal
import game.Billboard
import game.BillboardSighting
import game.Clock
import game.Conifer
import game.Distance
import game.Geom
import game.RiderView
import game.Lens
import game.Pipeline
import game.PigHerd
import game.Pixels
import game.Pond
import game.RailSighting
import game.RoadAhead
import game.Route
import game.Screen
import game.Segment
import game.SegmentPlace
import game.Speed
import game.Tower
import game.TowerSighting
import game.TreeSighting
import game.Truck
import game.TruckJourney
import game.TruckSighting
import game.World
import lib.Shapes

SightingExpects :: [].{}

# TreeSighting looks at the segment just behind the rider too. A tree 5 m short
# of the bend out of it stands in front of a rider at the bend once the bend is
# sharper than a right angle, and behind the rider at a gentle bend.
## The trees in view of a rider at the start of the second of two segments,
## the first holding one tree 5 m short of its bend of `degrees`.
past_bend_trees : F64 -> List(Pipeline.Sighted(Conifer))
past_bend_trees = |degrees| {
	segment_road_past_segment = {
		..Fixtures.segment_of([Fixtures.tree_at(195.0, 0.0)]),
		ending: Bends({ turn: Angle.Turn.degrees(degrees), bend_life: Animal(Elephant) }),
		encounter: QuietRoad,
	}
	rider_segment = { ..Fixtures.segment_of([]), encounter: QuietRoad }
	TreeSighting.trees_in_view(
		RoadAhead.RoadView.ahead_of(
			Route.from_segments([segment_road_past_segment, rider_segment]),
			Route.SegmentIndex.number(1),
		),
		Fixtures.origin_camera,
	)
}

## Whether `trees` is one tree, sighted on the segment just behind the rider.
is_one_tree_behind : List(Pipeline.Sighted(Conifer)) -> Bool
is_one_tree_behind = |trees|
	match trees.map(|tree| tree.spot.place()) {
		[JustBehind] => True
		_ => False
	}

expect is_one_tree_behind(past_bend_trees(150.0))
expect is_one_tree_behind(past_bend_trees(-150.0))
expect past_bend_trees(30.0).len() == 0
expect past_bend_trees(-80.0).len() == 0

# RailSighting: the rail at a bend runs along the outer edge, from 10 m before
# the bend on the segment before it to 10 m into the segment after it. On a
# 300 m segment turning right by a right angle, the outer edge is the left one.
## The road ahead of a rider at the start of a 300 m segment that turns right by
## a right angle into another.
right_angle_road : RoadAhead.RoadView
right_angle_road = Fixtures.crafted_road([
	{
		..Fixtures.segment_of([]),
		length: Distance.metres(300.0),
		ending: Bends({ turn: Angle.Turn.degrees(90.0), bend_life: Quiet }),
	},
	Fixtures.segment_of([]),
])

## Where the rail's path starts and ends, as the rider sees it. Each bar joins
## two points of the path, and the posts follow the bars, one at each point, so
## a path of `n` points makes `2n - 1` quads, and the last bar ends the path.
rail_ends : { start : RiderView.RaisedPoint, end : RiderView.RaisedPoint }
rail_ends = {
	quads = RailSighting.rail_quads_in_view(right_angle_road, { vantage: Fixtures.origin })
	last_bar = (quads.len() - 1) / 2 - 1
	corners_of = |quad_index|
		match quads.get(quad_index) {
			Ok(quad) => quad.corners
			Err(OutOfBounds) => crash "SightingExpects: the rail has a bar at each end of its path"
		}
	{ start: corners_of(0).low_start, end: corners_of(last_bar).low_end }
}

## The point on the left edge `along` metres into the segment at `place` on the
## right-angle road, as the rider sees it.
left_edge_point : SegmentPlace, F64 -> RiderView.RiderPoint
left_edge_point = |place, along|
	RoadAhead.rider_point_at(
		right_angle_road,
		{
			vantage: Fixtures.origin,
			place,
			road_point: { along: Along.metres(along), across: Geom.left_edge },
		},
	)

expect {
	start = left_edge_point(Ahead(SegmentPlace.Position.first), 290.0)
	end = left_edge_point(Ahead(Fixtures.second_position), 10.0)
	[
		(rail_ends.start.right, start.right),
		(rail_ends.start.forward, start.forward),
		(rail_ends.end.right, end.right),
		(rail_ends.end.forward, end.forward),
	].all(|(got, want)| (got.to_metres() - want.to_metres()).abs() <= 0.000001)
		and start.right.to_metres() == -2.0
		and start.forward.to_metres() == 290.0
}

# TreeSighting keeps each segment's trees in the order they were planted,
# leaving out those behind the camera and those too small to draw, and goes
# through the segments in view in turn.
## Where each tree in view stands for a rider 10 m into `segments`, seen through
## `focal_length`: right of the camera, then ahead of it.
tree_places : List(Segment), Pixels -> List((F64, F64))
tree_places = |segments, focal_length|
	TreeSighting.trees_in_view(
		Fixtures.crafted_road(segments),
		{ vantage: { ..Fixtures.origin, along: Along.metres(10.0) }, focal_length },
	).map(|tree| (tree.spot.foot().right().to_metres(), tree.spot.foot().forward().to_metres()))

## A tree behind the rider, then a far one, then a near pair.
planted_out_of_order : Segment
planted_out_of_order = Fixtures.segment_of([
	Fixtures.tree_at(5.0, -3.5),
	Fixtures.tree_at(46.0, 3.5),
	Fixtures.tree_at(16.0, -3.5),
	Fixtures.tree_at(16.0, 3.5),
])

expect
	tree_places([planted_out_of_order], Pixels.of(500.0))
		== [
			(3.5, 36.0),
			(-3.5, 6.0),
			(3.5, 6.0),
		]
expect tree_places([planted_out_of_order], Pixels.of(1.0)) == []
# A tree past a bend is in view too. The second segment turns 15 degrees right
# about the inner edge, 2 m right and 190 m ahead, so its tree 16 m along and
# 3.5 m left stands 16 cos 15 + 5.5 sin 15 past the bend and
# 2 + 16 sin 15 - 5.5 cos 15 to the right.
expect {
	got = tree_places(
		[
			Fixtures.bending_right(Fixtures.segment_of([Fixtures.tree_at(46.0, 3.5)])),
			Fixtures.segment_of([Fixtures.tree_at(16.0, -3.5)]),
		],
		Pixels.of(500.0),
	)
	wanted = [(3.5, 36.0), (0.8285126770, 206.8783179687)]
	is_near_place = |(right, forward), (want_right, want_forward)|
		(right - want_right).abs() <= 0.000000001 and (forward - want_forward).abs() <= 0.000000001
	got.len() == wanted.len() and got.map2(wanted, is_near_place).all(|is_near| is_near)
}

# BillboardSighting: which billboards are in view, on a road of one segment
# holding one grown cow and nothing else.
one_cow_segment : Segment
one_cow_segment = {
	..Fixtures.segment_of([]),
	pigs: NoPigs,
	cows: { herd: { ..Fixtures.segment_of([]).cows.herd, cow_count: 1 }, bull: NoBull },
}

lone_cow : Geom.RoadPoint
lone_cow = match one_cow_segment.segment_cows() {
	[cow] => cow.road_point
	_ => crash "SightingExpects: the one-cow segment holds one cow"
}

## Whether the rider sees the lone cow from `forward` metres short of it and
## 2.5 m to its left.
is_cow_seen_from : F64 -> Bool
is_cow_seen_from = |forward| {
	rider = {
		along: Along.metres(lone_cow.along.to_metres() - forward),
		across: Across.metres(lone_cow.across.to_metres() - 2.5),
		yaw: Angle.straight_ahead,
	}
	cow_road = Fixtures.crafted_road([one_cow_segment])
	camera = { vantage: rider, focal_length: Lens.resting_focal_length }
	BillboardSighting.billboards_in_view(cow_road, camera).len() == 1
}

# The near plane is 0.4 m. The rider's place is worked out from the cow's, so
# the cow's distance carries a rounding, and the checks stand a little either
# side of the plane. At the lens's resting focal length the 1.4 m cow is 2
# pixels tall about 479.9 m off.
expect
	[
		(-5.0, False),
		(0.3, False),
		(0.39, False),
		(0.41, True),
		(0.5, True),
		(300.0, True),
		(479.0, True),
		(481.0, False),
		(600.0, False),
	].all(|(forward, want)| is_cow_seen_from(forward) == want)

# BendAnimal: an animal and its baby at each of four bends, the first and third
# turning right and the second and fourth left.
billboards_at_four_bends : List(Geom.Placed(Billboard))
billboards_at_four_bends = [
	BendAnimal.Elephant.bend_billboards(
		{ segment_length: Distance.metres(100.0), turn: Angle.Turn.degrees(50.0) },
	),
	BendAnimal.Giraffe.bend_billboards(
		{ segment_length: Distance.metres(50.0), turn: Angle.Turn.degrees(-70.0) },
	),
	BendAnimal.Zebra.bend_billboards(
		{ segment_length: Distance.metres(10.0), turn: Angle.Turn.degrees(50.0) },
	),
	BendAnimal.Rhino.bend_billboards(
		{ segment_length: Distance.metres(0.0), turn: Angle.Turn.degrees(-70.0) },
	),
].join()

expect
	billboards_at_four_bends.map(|billboard| billboard.road_point.across.to_metres())
		== [-4.9, 0.0, 5.75, 0.0, -4.3, 0.0, 4.6, 0.0]

expect
	billboards_at_four_bends.map(|billboard| billboard.kind.facing())
		== [
			FacesRight,
			FacesRight,
			FacesLeft,
			FacesLeft,
			FacesRight,
			FacesRight,
			FacesLeft,
			FacesLeft,
		]

# Tower: a tower that isn't turned stands on a square 12 m across, its corners
# 6 m to either side of its middle and 6 m before and past it. Each leg rises
# from its corner, from as high as the earth's curve hides it: 0.25 m for a
# tower 100 m straight ahead, 1/320 of the tower's 80 m. The legs taper, so
# each foot is drawn in toward the middle by 1/320 of 6 m.
shapes_of_tower_100_ahead : List(Shapes.Shape)
shapes_of_tower_100_ahead = {
	tower_road = Fixtures.crafted_road([Fixtures.segment_of([])])
	dark_beacon = Beacon.of_segment(Route.SegmentIndex.first).lit_at(Clock.start)
	plain_tower : Tower
	plain_tower = Tower.standing({ yaw: Angle.straight_ahead, beacon: dark_beacon })
	sighted =
		Pipeline.sighting_of(
			{
				road_point: { along: Along.metres(100.0), across: Across.middle },
				lift: Distance.zero,
				kind: plain_tower,
			},
			{
				road: tower_road,
				camera: Fixtures.origin_camera,
				place: Ahead(SegmentPlace.Position.first),
			},
		)
			?? crash "SightingExpects: a tower 100 m ahead is past the near plane"
	sighted.kind.scenery_picture({
		spot: sighted.spot,
		focal_length: Fixtures.origin_camera.focal_length,
		context: { road: tower_road, vantage: Fixtures.origin },
	}).to_shapes()
}

## How far right of the screen's middle the foot of leg `index` is: the middle
## of the rod's end at its corner.
leg_foot_x : U64 -> F64
leg_foot_x = |index| {
	coordinates = Fixtures.coordinates_of(
		shapes_of_tower_100_ahead.get(index) ?? crash "SightingExpects: a tower has four legs",
	)
	match (coordinates.get(0), coordinates.get(6)) {
		(Ok(near_side), Ok(far_side)) => (near_side + far_side) / 2.0 - Screen.center_x.to_f64()
		_ => crash "SightingExpects: a leg is a quad"
	}
}

## How far a leg's foot is to the side of the tower's middle, and before or
## past it.
foot_offset : F64
foot_offset = 6.0 * 319.0 / 320.0

# The legs go back left, back right, front right, front left.
expect
	[
		(leg_foot_x(0), -500.0 * foot_offset / (100.0 - foot_offset)),
		(leg_foot_x(1), 500.0 * foot_offset / (100.0 - foot_offset)),
		(leg_foot_x(2), 500.0 * foot_offset / (100.0 + foot_offset)),
		(leg_foot_x(3), -500.0 * foot_offset / (100.0 + foot_offset)),
	].all(|(got, want)| (got - want).abs() <= 0.000001)

# TowerSighting: a tower stands 160 m past the end of every segment, 20 m right
# and turned 30 degrees, and a segment longer than 1000 m has one more halfway
# along, 100 m left and not turned.
## A segment 1200 m long, holding nothing, which ends a route.
long_segment : Segment
long_segment = { ..Fixtures.segment_of([]), length: Distance.metres(1200.0) }

## The towers in view at `clock` from the origin of the segment at `rider_number` on a
## route of a 200 m segment bending right into the long one.
towers_on_short_then_long : U32, Clock -> List(Pipeline.Sighted(Tower))
towers_on_short_then_long = |rider_number, clock|
	TowerSighting.towers_in_view(
		RoadAhead.RoadView.ahead_of(
			Route.from_segments([Fixtures.bending_right(Fixtures.segment_of([])), long_segment]),
			Route.SegmentIndex.number(rider_number),
		),
		{ camera: Fixtures.origin_camera, clock },
	)

## Where a tower stands on its segment, and how it is turned: along, across,
## and its turn in radians.
tower_numbers : Pipeline.Sighted(Tower) -> List(F64)
tower_numbers = |tower| [
	tower.spot.road_point().along.to_metres(),
	tower.spot.road_point().across.to_metres(),
	tower.kind.yaw().to_radians(),
]

expect {
	towers = towers_on_short_then_long(0, Clock.start)
	thirty = Angle.Turn.degrees(30.0).to_radians()
	got = towers.map(tower_numbers).join()
	want = [
		360.0,
		20.0,
		thirty,
		1360.0,
		20.0,
		thirty,
		600.0,
		-100.0,
		0.0,
	]
	towers.map(|tower| tower.spot.place())
		== [
			Ahead(SegmentPlace.Position.first),
			Ahead(Fixtures.second_position),
			Ahead(Fixtures.second_position),
		]
		and got.len() == want.len()
		and got.map2(want, |one, wanted| (one - wanted).abs() <= 0.000000001).all(|is_near| is_near)
}

# The segment just behind shows its end tower, which stands past the bend, and
# a rider far past every tower sees none.
expect
	towers_on_short_then_long(1, Clock.start).map(|tower| tower.spot.place())
		== [Ahead(SegmentPlace.Position.first), Ahead(SegmentPlace.Position.first), JustBehind]
expect
	TowerSighting.towers_in_view(
		Fixtures.crafted_road([Fixtures.segment_of([])]),
		{
			camera: {
				..Fixtures.origin_camera,
				vantage: { ..Fixtures.origin, along: Along.metres(5000.0) },
			},
			clock: Clock.start,
		},
	).len()
		== 0

## A pond's bend at the end of a segment 100 m long, turning 15° right.
right_pond_bend : Geom.Bend
right_pond_bend = { segment_length: Distance.metres(100.0), turn: Angle.Turn.degrees(15.0) }

## A pond's bend at the end of a segment 100 m long, turning 15° left.
left_pond_bend : Geom.Bend
left_pond_bend = { segment_length: Distance.metres(100.0), turn: Angle.Turn.degrees(-15.0) }

# A duck floats as far out from the road at a left turn as at a right one, on
# the other side.
expect
	Pond.placed_ducks(right_pond_bend).map(|placed| placed.road_point.across.to_metres())
		== [-10.0, -18.0, -11.0, -6.0, -14.0, -22.0]
		and Pond.placed_ducks(left_pond_bend).map(|placed| placed.road_point.across.to_metres())
			== [10.0, 18.0, 11.0, 6.0, 14.0, 22.0]

# Mirrored to the other side of the road at a left turn, each duck faces the
# other way.
expect
	Pond.placed_ducks(right_pond_bend).map(|placed| placed.kind.facing())
		== [FacesRight, FacesLeft, FacesRight, FacesRight, FacesLeft, FacesRight]
		and Pond.placed_ducks(left_pond_bend).map(|placed| placed.kind.facing())
			== [FacesLeft, FacesRight, FacesLeft, FacesLeft, FacesRight, FacesLeft]

# The pond's water and bank lie off the road on the outside of the bend,
# whichever way the road turns.
expect {
	pond_acrosses = |bend|
		Pond.pond_outlines(bend).join_map(|outline| outline.corners.map(|point| point.across))
	pond_acrosses(right_pond_bend).all(|across| across < Geom.left_edge)
		and pond_acrosses(left_pond_bend).all(|across| across > Geom.right_edge)
}

# The truck on the real route, through TruckJourney.truck_progress_at_next_step.
# TruckJourney doesn't import World. The real route's first bends are at 500 m
# and 820 m, its last at 7220 m, and it ends at 7520 m.

## The truck a step after one at `route_position` metres going `speed` metres a
## step, with the rider at the start of the real route, where the tease is 500 m
## ahead.
truck_after : F64, F64 -> TruckJourney.TruckProgress
truck_after = |route_position, speed|
	TruckJourney.truck_progress_at_next_step(
		{
			..TruckJourney.initial,
			route_position: Distance.metres(route_position),
			speed: Speed.metres_a_step(speed),
		},
		{ rider_distance: Distance.zero, route: World.route },
	)

chasing_truck : TruckJourney.TruckProgress
chasing_truck = truck_after(100.0, 0.3)

expect
	[
		(chasing_truck.speed.to_metres_a_step(), 0.311),
		(chasing_truck.route_position.to_metres(), 100.311),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

truck_past_tease : TruckJourney.TruckProgress
truck_past_tease = truck_after(600.0, 0.5)

truck_short_of_tease : TruckJourney.TruckProgress
truck_short_of_tease = truck_after(400.0, 0.5)

expect
	[
		(truck_past_tease.speed.to_metres_a_step(), 0.5),
		(truck_past_tease.route_position.to_metres(), 600.5),
		(truck_short_of_tease.speed.to_metres_a_step(), 0.511),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

# The chase holds a truck to one top speed, whatever it was going.
expect truck_after(100.0, 5.0).speed == truck_after(100.0, 9.0).speed
expect truck_after(100.0, 5.0).speed < Speed.metres_a_step(5.0)
expect chasing_truck.pace == NotSlowing

## A truck 50 m short of the first bend.
braking_truck : TruckJourney.TruckProgress
braking_truck = truck_after(450.0, 0.3)

expect
	[
		(braking_truck.speed.to_metres_a_step(), 0.2994154176),
		(braking_truck.route_position.to_metres() - 450.0, 0.2994154176),
	].all(|(got, want)| (got - want).abs() <= 0.000000000001)

expect braking_truck.pace == Slowing

settled_truck : TruckJourney.TruckProgress
settled_truck = TruckJourney.truck_progress_at_next_step(
	{
		route_position: Distance.metres(450.0),
		speed: Speed.metres_a_step(0.1776),
		pace: Slowing,
	},
	{ rider_distance: Distance.zero, route: World.route },
)

expect settled_truck.pace == NotSlowing
expect F64.to_bits(settled_truck.speed.to_metres_a_step()) == F64.to_bits(0.1776)

# The truck brakes for a bend from 60 m short of it, and not a metre sooner.
expect truck_after(440.0, 0.3).speed < Speed.metres_a_step(0.3)
expect !(truck_after(439.0, 0.3).speed < Speed.metres_a_step(0.3))

# Short of a bend the truck brakes for it. At a bend's own end the next bend is
# the one ahead, and past the last bend, with only the route's end ahead, the
# truck brakes for nothing: past the tease, it holds its speed.
expect [499.0, 800.0, 7219.0].all(|route_position| truck_after(route_position, 0.3).pace == Slowing)
expect
	[500.0, 820.0, 7220.0, 7519.0, 7600.0].all(
		|route_position| truck_after(route_position, 0.3).speed == Speed.metres_a_step(0.3),
	)

## What becomes of a truck `lead` metres ahead of a rider on the three-segment road's
## first segment, seen from `vantage`, with its lights off. On the first
## segment the rider's distance along the route is the vantage's `along`.
truck_seen_from : Geom.Vantage, F64 -> TruckSighting.TruckFate
truck_seen_from = |vantage, lead|
	TruckSighting.truck_in_view(
		Fixtures.three_segment_road,
		{
			camera: { ..Fixtures.origin_camera, vantage },
			truck: {
				route_position: Distance.metres(vantage.along.to_metres() + lead),
				truck: { headlights: Off, brake_lights: Off },
			},
		},
	)

## What becomes of a truck `lead` metres ahead of a rider at `origin`.
truck_lead_of : F64 -> TruckSighting.TruckFate
truck_lead_of = |lead| truck_seen_from(Fixtures.origin, lead)

## Where the truck is, for a lead that puts it in view.
sighted_truck_of : F64 -> Pipeline.Sighted(Truck)
sighted_truck_of = |lead| truck_lead_of(lead) ?? crash "SightingExpects: this lead puts the truck in view"

# The truck is in view on the road ahead, and not past its end or behind the
# rider.
expect
	[
		(100.0, True),
		(499.0, True),
		(600.0, True),
		(900.0, True),
		(2000.0, False),
		(0.0, False),
		(-50.0, False),
	].all(|(lead, want)| truck_lead_of(lead).is_ok() == want)

# A truck past a segment's end stands on a later segment, measured from its
# start.
expect
	[
		(100.0, SegmentPlace.Position.first),
		(499.0, SegmentPlace.Position.first),
		(600.0, Fixtures.second_position),
		(900.0, Fixtures.second_position.next()),
	].all(|(lead, want)| sighted_truck_of(lead).spot.place() == Ahead(want))

expect
	[
		(100.0, 100.0),
		(499.0, 499.0),
		(600.0, 100.0),
		(900.0, 80.0),
	].all(|(lead, want)| sighted_truck_of(lead).spot.road_point().along.to_metres() == want)

# The route's herds, through World. PigHerd and CowHerd don't import World. The
# route's big herd is seven rows of seven, and its two-row herd four pigs in front
# and six behind; in each, the third pig of the front row stands out. Its cow
# herd is fourteen cows in columns of three.
## Where the route's herds of pigs stand along the road, for these expects.
route_herd_along : Along
route_herd_along = Along.metres(940.0)

## The route's herds of pigs, in the order the rider meets them.
route_pig_herds : List(PigHerd)
route_pig_herds =
	World.route.route_segments().join_map(
		|segment|
			match segment.pigs {
				Herd({ herd, .. }) => [herd]
				NoPigs => []
			},
	)

## Whether `herd` is a big herd rather than one of two rows.
is_big_herd : PigHerd -> Bool
is_big_herd = |herd|
	match herd {
		BigHerd(_) => True
		TwoRows => False
	}

## The route's first herd of `shape`.
route_herd_of : [Big, TwoRows] -> PigHerd
route_herd_of = |shape| {
	want_big = shape == Big
	route_pig_herds.find_first(|herd| is_big_herd(herd) == want_big)
		?? crash "SightingExpects: the route has a herd of each shape"
}

route_big_herd_pigs : List(Geom.Placed(Billboard))
route_big_herd_pigs = route_herd_of(Big).herd_pigs(route_herd_along)

route_big_standout : Geom.Placed(Billboard)
route_big_standout = route_herd_of(Big).standout_pig(route_herd_along)

expect route_big_herd_pigs.len() == 49
expect route_big_herd_pigs.get(2) == Ok(route_big_standout)
expect route_big_herd_pigs.count_if(|herd_member| herd_member == route_big_standout) == 1

# The third pig of the row nearest the road, strayed from its place.
expect (route_big_standout.road_point.along.to_metres() - 940.80757).abs() <= 0.00001
expect (route_big_standout.road_point.across.to_metres() - 11.0332).abs() <= 0.00001

route_two_row_pigs : List(Geom.Placed(Billboard))
route_two_row_pigs = route_herd_of(TwoRows).herd_pigs(route_herd_along)

route_two_row_standout : Geom.Placed(Billboard)
route_two_row_standout = route_herd_of(TwoRows).standout_pig(route_herd_along)

expect
	route_two_row_pigs.map(|critter| critter.road_point.along.to_metres())
		== [
			934.0,
			938.0,
			942.0,
			946.0,
			930.0,
			934.0,
			938.0,
			942.0,
			946.0,
			950.0,
		]

expect
	route_two_row_pigs.map(|critter| critter.road_point.across.to_metres())
		== [
			12.0,
			12.0,
			12.0,
			12.0,
			18.0,
			18.0,
			18.0,
			18.0,
			18.0,
			18.0,
		]

expect route_two_row_standout.road_point.along.to_metres() == 942.0
expect route_two_row_standout.road_point.across.to_metres() == 12.0
expect route_two_row_pigs.get(2) == Ok(route_two_row_standout)

## The route's cows behind 24 m, without a bull.
route_cows : List(Geom.Placed(Billboard))
route_cows =
	World.route.segment_at(Route.SegmentIndex.first).cows.herd.herd_cows(
		{ herd_along: Along.metres(24.0), bull: NoBull },
	)

# Fourteen cows in columns of three, each within the jitter of its row.
expect {
	places = [
		-12.0,
		-17.0,
		-22.0,
		-12.0,
		-17.0,
		-22.0,
		-12.0,
		-17.0,
		-22.0,
		-12.0,
		-17.0,
		-22.0,
		-12.0,
		-17.0,
	]
	misses = route_cows.map2(places, |one, place| (one.road_point.across.to_metres() - place).abs())
	route_cows.len() == 14 and misses.all(|miss| miss <= 1.2)
}
