## CrossModuleExpects holds the expects that can't sit beside their code. A road
## view needs a place along the road, a place across it and a turn, and most
## sightings import none of them; the scene and a ride that has finished need more
## again. No module of the game sees all of what these checks do, and the game
## shouldn't import a module for a test, so they sit here, where the gate reaches
## them as one of its roots.
app [main!] { game: "../game.roc", lib: "../../lib/main.roc" }

import game.Pixels
import game.Across
import game.Along
import game.Angle
import game.BirdFlight
import game.BirdSighting
import game.Cat
import game.CatSighting
import game.Clock
import game.Conifer
import game.CutoutSighting
import game.DepthSort
import game.Distance
import game.Fraction
import game.Chain
import game.Geom
import game.Ground
import game.GroundSighting
import game.RailSighting
import game.Scene
import game.RideInstant
import game.Rider
import game.RiderState
import game.BirdDraw
import game.Scenery
import game.Speed
import game.TowerSighting
import game.TreeSighting
import game.Trees
import game.Truck
import game.TruckSighting
import game.VehicleLimits
import game.World
import lib.Brush
import lib.Shapes

main! = |_args| Ok({})

## The rider at the start of a segment, in the middle of the road, looking
## straight down it.
origin : Geom.Vantage
origin = {
	along: Along.metres(0.0),
	across: Across.metres(0.0),
	yaw: Angle.straight_ahead,
	half_width: Distance.metres(2.0),
}

## The first three segments, the rider at the start of the first.
road : Chain.RoadView
road = {
	route: [
		World.route_segment(0),
		World.route_segment(1),
		World.route_segment(2),
	],
	chain: [0, 1, 2].map(World.SegmentIndex.number),
	vantage: origin,
}

polygon_of : Shapes.Shape -> { pts : List(F64), fill : Brush.Fill }
polygon_of = |shape|
	match shape {
		Poly(polygon) => polygon
		Pieces(_) | Disc(_) | Rect(_) | Blend(_) | View(_) | Image(_) | Text(_) =>
			crash "CrossModuleExpects.polygon_of: this shape is not a polygon"
	}

## A polygon's points, flat as x0, y0, x1, y1, ...
points_of : Shapes.Shape -> List(F64)
points_of = |shape| polygon_of(shape).pts

## A flat polygon's colour, as 0xRRGGBB.
flat_color_of : Shapes.Shape -> I64
flat_color_of = |shape|
	match polygon_of(shape).fill {
		Flat(color) => {
			red = color.r.to_i64_wrap()
			green = color.g.to_i64_wrap()
			blue = color.b.to_i64_wrap()
			red * 65536 + green * 256 + blue
		}
		Skip | Span(_) | Radial(_) | Linear(_) | Ellipse(_) | Glow(_) =>
			crash "CrossModuleExpects.flat_color_of: this polygon is not flat"
	}

# BirdSighting, on a straight segment with its fifth left tree 100 m along: a bird
# sits, flies and lands as the rider comes, stays where no tree is far enough to
# fly to, and is left out with no tree for it, behind the near plane or too small
# to draw.
tree_at : F64, F64 -> Trees.Tree
tree_at = |along, across| {
	along: Along.metres(along),
	across: Across.metres(across),
	conifer: Conifer.Red,
}

left_trees : List(Trees.Tree)
left_trees = [20.0, 40.0, 60.0, 80.0, 100.0].map(|along| tree_at(along, -6.0))

far_tree : Trees.Tree
far_tree = { ..tree_at(130.0, 6.0), conifer: Conifer.Gold }

## How high a bird perches on a left tree, and on the far tree.
left_top : F64
left_top = Conifer.Red.height().to_metres()

far_top : F64
far_top = Conifer.Gold.height().to_metres()

## A straight segment 200 m long holding only `trees`.
segment_of : List(Trees.Tree) -> World.Segment
segment_of = |trees| {
	..World.route_segment(0),
	length: Distance.metres(200.0),
	trees,
	exit_turn: Angle.straight_ahead,
	crossing: BirdFlight.crossing_among(trees),
}

## The birds on one segment of `trees`, for a rider `rider_along` metres into
## it, seen through a focal length of `cam_focal`.
birds_on : List(Trees.Tree), { rider_along : F64, cam_focal : Pixels } -> List(BirdSighting)
birds_on = |trees, seen_from| birds_on_segment(segment_of(trees), seen_from)

## The birds on `segment_index`, for a rider `rider_along` metres into it.
birds_on_segment : World.Segment, { rider_along : F64, cam_focal : Pixels } -> List(BirdSighting)
birds_on_segment = |segment, { rider_along, cam_focal }|
	BirdSighting.birds_in_view({
		road: {
			route: [segment],
			chain: [World.SegmentIndex.first],
			vantage: { ..origin, along: Along.metres(rider_along) },
		},
		cam_focal,
	})

## The one bird that a rider `rider_along` metres in sees on the segment with
## a far tree.
bird_at : F64 -> BirdSighting
bird_at = |rider_along|
	birds_on(left_trees.append(far_tree), { rider_along, cam_focal: Pixels.of(500.0) }).first()
		?? crash "CrossModuleExpects: this rider sees a bird"

## How far off a bird is, across the road and up.
place_of : BirdSighting -> List(F64)
place_of = |bird| [bird.right.to_metres(), bird.forward.to_metres(), bird.lift.to_metres()]

expect place_of(bird_at(0.0)) == [-6.0, 100.0, left_top]
expect place_of(bird_at(40.0)) == [-6.0, 60.0, left_top]

# Halfway through its flight, with the rider 37.5 m from the tree it left.
expect {
	bird = bird_at(62.5)
	[
		(bird.right.to_metres(), 0.0),
		(bird.forward.to_metres(), 52.5),
		(bird.lift.to_metres(), (left_top + far_top) / 2.0 + BirdFlight.flight_arc.to_metres()),
	].all(|(got, want)| (got - want).abs() <= 0.000000001)
}

expect place_of(bird_at(85.0)) == [6.0, 45.0, far_top]
expect bird_at(40.0).pose == Perched
expect bird_at(62.5).pose != Perched
expect bird_at(85.0).pose == Perched

# With no tree far enough to fly to, the bird stays on its own however near
# the rider is.
expect {
	stays = birds_on(left_trees, { rider_along: 62.5, cam_focal: Pixels.of(500.0) })
	stays.join_map(place_of) == [-6.0, 37.5, left_top]
}

## How many birds there are on `trees` for each rider and focal length.
bird_count : List(Trees.Tree), { rider_along : F64, cam_focal : Pixels } -> I64
bird_count = |trees, seen_from| birds_on(trees, seen_from).len().to_i64_wrap()

## A segment where a cat crosses, with the same trees: it has no bird.
segment_with_cat : World.Segment
segment_with_cat = { ..segment_of(left_trees), crossing: World.route_segment(3).crossing }

expect bird_count(left_trees, { rider_along: 0.0, cam_focal: Pixels.of(500.0) }) == 1
expect bird_count(left_trees.drop_last(1), { rider_along: 0.0, cam_focal: Pixels.of(500.0) }) == 0
expect bird_count(left_trees, { rider_along: 99.5, cam_focal: Pixels.of(500.0) }) == 1
expect bird_count(left_trees, { rider_along: 99.7, cam_focal: Pixels.of(500.0) }) == 0
expect bird_count(left_trees, { rider_along: 120.0, cam_focal: Pixels.of(500.0) }) == 0
expect bird_count(left_trees, { rider_along: 0.0, cam_focal: Pixels.of(91.0) }) == 1
expect bird_count(left_trees, { rider_along: 0.0, cam_focal: Pixels.of(90.0) }) == 0
expect
	birds_on_segment(segment_with_cat, { rider_along: 0.0, cam_focal: Pixels.of(500.0) }).len()
		== 0

## Two segments in the chain, the rider at the start of the first.
two_segments : List(BirdSighting)
two_segments = BirdSighting.birds_in_view({
	road: {
		route: [segment_of(left_trees), segment_of(left_trees)],
		chain: [0, 1].map(World.SegmentIndex.number),
		vantage: {
			along: Along.metres(0.0),
			across: Across.metres(0.0),
			yaw: Angle.straight_ahead,
			half_width: Distance.metres(2.0),
		},
	},
	cam_focal: Pixels.of(500.0),
})

## A key's place in the birds' list.
bird_place : DepthSort.DepthKey -> I64
bird_place = |key|
	match key.subject {
		Bird(place) => place.to_i64()
		Tree(_) | Tower(_) | Cutout(_) | Cat(_) | Truck | Rail(_) =>
			crash "CrossModuleExpects: a bird's key names a bird"
	}

expect BirdSighting.depth_keys(two_segments).map(bird_place) == [0, 1]

expect
	match BirdSighting.depth_keys(two_segments).map(|key| key.forward) {
		[near, far] => near == Distance.metres(100.0) and near < far
		_ => crash "CrossModuleExpects: each of two segments has a bird in view"
	}

# CatSighting: which cats are in view as the rider comes on them.
## The second segment, with a cat crossing it.
cat_segment : World.Segment
cat_segment = { ..World.route_segment(1), crossing: World.route_segment(3).crossing }

cat_segments : List(World.Segment)
cat_segments = [World.route_segment(0), cat_segment, World.route_segment(2)]

## The first three segments seen from the origin, at 1 m a step.
cats_from_origin : Chain.Viewpoint
cats_from_origin = {
	road: {
		route: cat_segments,
		chain: [0, 1, 2].map(World.SegmentIndex.number),
		vantage: origin,
	},
	cam_focal: Pixels.of(500.0),
}

metre_a_step : Speed
metre_a_step = Speed.metres_a_step(1.0)

## The cats seen from the origin on a road of only `chain`.
cats_on_chain : List(World.SegmentIndex) -> List(CatSighting)
cats_on_chain = |chain| CatSighting.cats_in_view(
	{ ..cats_from_origin, road: { ..cats_from_origin.road, chain } },
	metre_a_step,
)

## The cat on the segment at `number` in the chain, if it is in view.
cat_at : U32 -> Try(CatSighting, [NoCat, OutOfView])
cat_at = |number| CatSighting.segment_cat(
	cats_from_origin,
	{ position: Chain.Position.number(number), speed: metre_a_step },
)

expect cat_segments.map(has_cat) == [False, True, False]

## Whether a segment has a cat waiting by the road.
has_cat : World.Segment -> Bool
has_cat = |seg|
	match seg.crossing {
		CatCrosses(_) => True
		BirdHere(_) | QuietRoad => False
	}

expect
	[
		(0.0, 0, 0.0),
		(0.0, 1, 500.0),
		(0.0, 2, 820.0),
		(120.0, 0, -120.0),
		(120.0, 1, 380.0),
		(120.0, 2, 700.0),
	].all(
		|
			(along, number, want),
		| {
			gap = Chain.gap_to_segment(
				{ ..cats_from_origin.road, vantage: { ..origin, along: Along.metres(along) } },
				Chain.Position.number(number),
			)
			gap.to_metres() == want
		},
	)

## The cats in view for a rider `along` metres into the first segment.
riding : F64 -> List(CatSighting)
riding = |along| CatSighting.cats_in_view(
	{
		..cats_from_origin,
		road: { ..cats_from_origin.road, vantage: { ..origin, along: Along.metres(along) } },
	},
	metre_a_step,
)

seen : List(CatSighting)
seen = riding(300.0)

## The first cat in view for a rider `along` metres in.
first_cat : F64 -> CatSighting
first_cat = |along|
	riding(along).first() ?? crash "CrossModuleExpects: the second segment's cat is in view"

expect seen.len() == 1
expect cat_at(0).is_err()
expect cat_at(2).is_err()
expect first_cat(300.0).lift.to_metres() == 0.0
expect first_cat(300.0).pose == Rest
expect
	[
		(first_cat(300.0).forward.minus(first_cat(200.0).forward).to_metres(), -100.0),
		(first_cat(400.0).forward.minus(first_cat(300.0).forward).to_metres(), -100.0),
		(first_cat(300.0).right.minus(first_cat(200.0).right).to_metres(), 0.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

expect riding(0.0).len() == 0
expect riding(200.0).len() == 1
expect riding(500.0).len() == 1
expect riding(600.0).len() == 0
expect cats_on_chain([]).len() == 0
expect cats_on_chain([World.SegmentIndex.first]).len() == 0

# One cat in view gives one key, which names the first cat; none gives none.
expect CatSighting.depth_keys(seen).map(|key| key.subject) == [Cat(0)]
expect CatSighting.depth_keys([]).len() == 0

# The sighting looks along the whole chain, and the reaction only at the rider's
# own segment. They agree because a crossing starts on its own segment: even at
# top speed it starts closer to the cat than the cat is to the segment's start,
# and a rider comes onto a segment no further along than that.
## The cats of the route, each with its segment.
route_cats : List({ segment : World.Segment, crossing : Cat.Crossing })
route_cats = World.segments.join_map(
	|segment|
		match segment.crossing {
			CatCrosses(crossing) => [{ segment, crossing }]
			BirdHere(_) | QuietRoad => []
		},
)

## How far short of a cat a crossing starts, at the fastest a rider goes.
farthest_start : Distance
farthest_start = Cat.clear_gap.plus(VehicleLimits.top_speed.distance_in(Cat.crossing_steps))

expect route_cats.len() == 3
expect farthest_start.to_metres() == 98.0
expect farthest_start < Cat.cat_along.plus(Cat.cat_beyond_tree).from_start()
expect route_cats.all(|{ crossing, .. }| farthest_start < crossing.along.from_start())

## The speed a rider leaves `segment` at: the bend's, or none at the route's end.
leaving_speed : World.Segment -> Speed
leaving_speed = |segment|
	match segment.ending {
		Continues(_) => VehicleLimits.turn_speed(segment.exit_turn.abs())
		Terminates => Speed.at_rest
	}

# The reaction ends with its segment, so the cat's hold has to have faded by then
# or it would snap to nothing there. Braking for the bend only hurries the fade.
expect
	route_cats.all(
		|{ segment, crossing }| {
			gap = crossing.along.distance_from(Along.at(segment.length))
			Cat.attention({ gap, speed: leaving_speed(segment) }).to_f64() == 0.0
		},
	)

# CutoutSighting: how far along the chain each kind of critter is sighted.
## The first six segments, chained in order.
six_segments : Chain.RoadView
six_segments = {
	route: [0, 1, 2, 3, 4, 5].map(World.route_segment),
	chain: [0, 1, 2, 3, 4, 5].map(World.SegmentIndex.number),
	vantage: origin,
}

## The world's segment `index` alone.
lone : U32 -> Chain.RoadView
lone = |index| {
	route: [World.route_segment(index)],
	chain: [0].map(World.SegmentIndex.number),
	vantage: origin,
}

farm_at : U32 -> I64
farm_at = |number| CutoutSighting.farm_sightings(
	six_segments,
	Chain.Position.number(number),
).len().to_i64_wrap()

safari_at : U32 -> I64
safari_at = |number|
	CutoutSighting.wildlife_sightings(
		six_segments,
		Chain.Position.number(number),
	).len().to_i64_wrap()

expect farm_at(0) > 0
expect farm_at(2) > 0
expect farm_at(3) == 0
expect farm_at(4) == 0
expect farm_at(5) == 0
expect safari_at(3) > 0
expect safari_at(4) > 0
expect safari_at(5) == 0
expect CutoutSighting.wildlife_sightings(lone(18), Chain.Position.first).len() == 0
expect CutoutSighting.wildlife_sightings(lone(0), Chain.Position.first).len() > 0

duck_count : U32 -> I64
duck_count = |index|
	CutoutSighting.duck_sightings(lone(index), Chain.Position.first).len().to_i64_wrap()

expect duck_count(12) > 0
expect duck_count(0) == 0
expect duck_count(4) == 0
expect duck_count(18) == 0
expect CutoutSighting.duck_sightings(six_segments, Chain.Position.number(5)).len() == 0
expect duck_count(12) == 6
expect {
	first = Chain.Position.first
	whole = CutoutSighting.sightings_at(six_segments, first).len().to_i64_wrap()
	ducks = CutoutSighting.duck_sightings(six_segments, first).len().to_i64_wrap()
	whole == farm_at(0) + safari_at(0) + ducks
}

## How many critters the segments from `position` to the chain's end hold.
count_from : U32 -> I64
count_from = |position|
	List.from_iter(U32.until(position, 6))
		.map(
			|number| CutoutSighting.sightings_at(six_segments, Chain.Position.number(number))
				.len()
				.to_i64_wrap(),
		)
		.sum()

expect CutoutSighting.sightings_ahead({ ..six_segments, chain: [] }).len() == 0
expect
	CutoutSighting.sightings_ahead(lone(0)).len()
		== CutoutSighting.sightings_at(lone(0), Chain.Position.first).len()
expect CutoutSighting.sightings_ahead(six_segments).len().to_i64_wrap() == count_from(0)
expect count_from(0) >= count_from(1)
expect count_from(1) >= count_from(2)
expect CutoutSighting.sightings_behind(six_segments, World.SegmentIndex.number(4)).len() > 0
expect CutoutSighting.ducks_behind(six_segments, World.route_segment(12)).len() > 0
expect CutoutSighting.ducks_behind(six_segments, World.route_segment(0)).len() == 0

# RailSighting's run up to a bend and out of it.
rail_point_at : List(Geom.RiderPoint), U64 -> Geom.RiderPoint
rail_point_at = |points, i|
	points.get(i) ?? crash "CrossModuleExpects: an index past the rail's end"

run_up_to_bend : List(Geom.RiderPoint)
run_up_to_bend = RailSighting.run_up(
	road,
	{
		place: InChain(Chain.Position.first),
		length: Distance.metres(500.0),
		across: Across.metres(2.0),
	},
)

expect RailSighting.run_out(
	road,
	{ place: InChain(Chain.Position.first), across: Across.metres(2.0) },
).len() == 10
expect run_up_to_bend.len() == 11
expect
	[
		(rail_point_at(run_up_to_bend, 0).forward.to_metres(), 490.0),
		(rail_point_at(run_up_to_bend, 10).forward.to_metres(), 500.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

# Scene, on the scene from the start of the route.
scene : Scene
scene = Scene.scene_in_view(
	{
		road: {
			route: World.segments,
			chain: Chain.chain_ahead(World.segments, World.SegmentIndex.first),
			vantage: origin,
		},
		cam_focal: Pixels.of(500.0),
	},
	{
		speed: VehicleLimits.base_speed,
		truck: {
			route_position: Distance.metres(500.0),
			lights: { headlights: Off, brake_lights: Off },
		},
		clock: Clock.start,
	},
)

expect {
	kind_counts = [
		TreeSighting.depth_keys(scene.trees).len(),
		TowerSighting.depth_keys(scene.towers).len(),
		CutoutSighting.depth_keys(scene.cutouts).len(),
		CatSighting.depth_keys(scene.cats).len(),
		TruckSighting.depth_keys(scene.truck).len(),
		RailSighting.depth_keys(scene.rails).len(),
		BirdSighting.depth_keys(scene.birds).len(),
	]
	scene.order.len() == kind_counts.sum()
}

expect scene.trees.len() > 0
expect scene.towers.len() > 0
expect scene.cutouts.len() > 0
expect scene.rails.len() > 0
expect scene.order.len() > 0
expect scene.towers.len().to_i64_wrap() <= TowerSighting.max_visible_towers
expect scene.cutouts.len().to_i64_wrap() <= CutoutSighting.max_visible_cutouts

## Whether no key in `keys` is farther than the one before it.
is_far_to_near : List(DepthSort.DepthKey) -> Bool
is_far_to_near = |keys|
	keys.map2(
		keys.drop_first(1),
		|before, after| DepthSort.is_farther({ this: after.forward, that: before.forward }),
	)
		.all(|is_out_of_order| !is_out_of_order)

expect is_far_to_near(scene.order)
expect is_far_to_near([])

# GroundSighting's road, chunk by chunk.
## A list of patches as a camera the drawing checks read paints them.
patch_shapes : List(Ground.Patch) -> List(Shapes.Shape)
patch_shapes = |patches| patches.join_map(|patch| Ground.draw(patch, Pixels.of(500.0)))

## Chunk `chunk_number` of the first segment's 20, which is 500 m long.
chunk_of_first : U32 -> List(Geom.RiderPoint)
chunk_of_first = |chunk_number| GroundSighting.chunk_corners(
	road,
	{
		position: Chain.Position.first,
		segment_length: Distance.metres(500.0),
		chunk_count: 20,
		chunk_number,
	},
)

corner : List(Geom.RiderPoint), U64 -> Geom.RiderPoint
corner = |corners, i| corners.get(i) ?? crash "CrossModuleExpects: a chunk has four corners"

first_chunk : List(Geom.RiderPoint)
first_chunk = chunk_of_first(0)

last_chunk : List(Geom.RiderPoint)
last_chunk = chunk_of_first(19)

expect first_chunk.len() == 4
expect last_chunk.len() == 4
expect
	[
		(0, -2.0),
		(1, 2.0),
		(2, 2.0),
		(3, -2.0),
	].all(|(i, want)| (corner(first_chunk, i).right.to_metres() - want).abs() <= 0.0001)

expect
	[
		(corner(first_chunk, 0).forward.to_metres(), 0.0),
		(corner(first_chunk, 3).forward.to_metres(), 25.0),
		(corner(last_chunk, 0).forward.to_metres(), 475.0),
		(corner(last_chunk, 3).forward.to_metres(), 500.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

expect {
	before = chunk_of_first(3)
	after = chunk_of_first(4)
	corner(before, 3).forward == corner(after, 0).forward
		and corner(before, 2).forward == corner(after, 1).forward
		and corner(before, 3).right == corner(after, 0).right
}

strip : List(Shapes.Shape)
strip = patch_shapes(GroundSighting.segment_road(road, Chain.Position.first))

expect strip.len() > 0
expect strip.len().to_u32_wrap() <= GroundSighting.chunks_along(Distance.metres(500.0))
expect patch_shapes(
	GroundSighting.segment_road(
		{ ..road, vantage: { ..origin, along: Along.metres(5000.0) } },
		Chain.Position.first,
	),
).len() == 0
last_shape : Shapes.Shape
last_shape = strip.last() ?? crash "CrossModuleExpects: the road draws"

expect flat_color_of(last_shape) == 0x34353C
expect {
	point_count = points_of(last_shape).len()
	point_count >= 6 and point_count <= 10
}

# A ride that has finished starts again.
done : RideInstant
done = {
	rider: {
		segment_index: World.SegmentIndex.number(18),
		along: Along.metres(400.0),
		across: Across.metres(0.0),
		yaw: Angle.Turn.radians(0.0),
		speed: Speed.at_rest,
		lean: Angle.Lean.radians(0.0),
		heading: Angle.Bearing.radians(0.0),
		gaze_yaw: Angle.Turn.radians(0.0),
		look_depth: Fraction.of(0.9),
	},
	truck: {
		route_position: Distance.metres(9000.0),
		speed: Speed.metres_a_step(2.0),
		brake_lights: On,
	},
	clock: Clock.at_step(12345),
}

expect {
	instant = RideInstant.next_or_restart(World.segments, done)
	instant.clock.to_f64() == 0.0
		and instant.rider.along.to_metres() == 0.0
		and instant.rider.speed.to_metres_a_step() == 0.3
		and instant.truck.route_position.to_metres() == 500.0
		and instant.rider.look_depth.to_f64() == 0.0
}

# The gaze is home at each of the ride's crossings, and it did leave home. The
# bike doesn't turn at a seam, and `gaze_yaw` is measured from the bike, so a
# crossing carries the gaze over and it has no need to be reset.
expect {
	var $rider = RiderState.initial
	var $crossings = 0
	var $is_home_at_each = True
	var $has_looked = False
	while !Rider.is_finished($rider, World.segments) {
		next = Rider.advance($rider, World.segments)
		if next.segment_index != $rider.segment_index {
			$crossings = $crossings + 1
			$is_home_at_each = $is_home_at_each and $rider.gaze_yaw == Angle.straight_ahead
		}
		$has_looked = $has_looked or next.gaze_yaw != Angle.straight_ahead
		$rider = next
	}
	$crossings == 18 and $is_home_at_each and $has_looked
}

expect Rider.is_finished(done.rider, World.segments)
expect RideInstant.next_or_restart(World.segments, done).truck.brake_lights == Off

# A frame of the ride draws.
expect {
	frame = RideInstant.shapes(World.segments, RideInstant.initial)
	first_shape = frame.first() ?? crash "CrossModuleExpects: a frame draws"
	points_of(first_shape).len() >= 6
}

expect {
	after_one_step = RideInstant.next_or_restart(World.segments, RideInstant.initial)
	RideInstant.shapes(World.segments, after_one_step).len() > 0
}
