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
import game.Billboard
import game.BirdFlight
import game.Cat
import game.Clock
import game.Conifer
import game.CrossingSighting
import game.BillboardSighting
import game.DepthSort
import game.Distance
import game.Fraction
import game.RoadAhead
import game.Geom
import game.Ground
import game.GroundSighting
import game.Pipeline
import game.PosedBird
import game.PosedCat
import game.RailSighting
import game.Rendered
import game.Scene
import game.SceneShapes
import game.RideInstant
import game.Rider
import game.RiderState
import game.Scenery
import game.Speed
import game.TreeSighting
import game.Trees
import game.Truck
import game.TruckSighting
import game.VehicleLimits
import game.World
import lib.Brush
import lib.RgbColor
import lib.Shapes

main! = |_args| Ok({})

## The rider at the start of a segment, in the middle of the road, looking
## straight down it.
origin : Geom.Vantage
origin = {
	along: Along.metres(0.0),
	across: Across.metres(0.0),
	yaw: Angle.straight_ahead,
}

## The first three segments, the rider at the start of the first.
road : RoadAhead.RoadView
road = {
	route_segments: [
		World.route_segment(0),
		World.route_segment(1),
		World.route_segment(2),
	],
	segments_ahead: [0, 1, 2].map(World.SegmentIndex.number),
	vantage: origin,
}

# Positions count along the road ahead, not along the route.
expect {
	third_then_first = { ..road, segments_ahead: [2, 0].map(World.SegmentIndex.number) }
	length_at = |position| RoadAhead.segment_at(third_then_first, position).length
	third_length = World.route_segment(2).length
	first_length = World.route_segment(0).length
	third_length != first_length
		and length_at(RoadAhead.Position.first) == third_length
		and length_at(RoadAhead.Position.first.next()) == first_length
}

polygon_of : Shapes.Shape -> { coordinates : List(F64), fill : Brush.Fill }
polygon_of = |shape|
	match shape {
		Poly(polygon) => polygon
		Pieces(_) | Disc(_) | Rect(_) | Blend(_) | View(_) | Image(_) | Text(_) =>
			crash "CrossModuleExpects.polygon_of: this shape is not a polygon"
	}

## A polygon's coordinates, flat as x0, y0, x1, y1, ...
coordinates_of : Shapes.Shape -> List(F64)
coordinates_of = |shape| polygon_of(shape).coordinates

## A flat polygon's colour.
flat_color_of : Shapes.Shape -> RgbColor
flat_color_of = |shape|
	match polygon_of(shape).fill {
		Flat(color) => {
			red = color.r.to_i64_wrap()
			green = color.g.to_i64_wrap()
			blue = color.b.to_i64_wrap()
			RgbColor.of(red * 65536 + green * 256 + blue)
		}
		Span(_) | Radial(_) | Linear(_) | Ellipse(_) | Glow(_) =>
			crash "CrossModuleExpects.flat_color_of: this polygon is not flat"
	}

# CrossingSighting's birds, on a straight segment with its fifth left tree 100 m along: a bird
# sits, flies and lands as the rider comes, stays where no tree is far enough to
# fly to, and is left out with no tree for it, behind the near plane or too small
# to draw.
tree_at : F64, F64 -> Trees.RoadsideTree
tree_at = |along, across| {
	along: Along.metres(along),
	across: Across.metres(across),
	kind: Conifer.Red,
}

left_trees : List(Trees.RoadsideTree)
left_trees = [20.0, 40.0, 60.0, 80.0, 100.0].map(|along| tree_at(along, -6.0))

far_tree : Trees.RoadsideTree
far_tree = { ..tree_at(130.0, 6.0), kind: Conifer.Gold }

## How high a bird perches on a left tree, and on the far tree.
left_top : F64
left_top = Conifer.Red.scenery_height().to_metres()

far_top : F64
far_top = Conifer.Gold.scenery_height().to_metres()

## A straight segment 200 m long holding only `trees`.
segment_of : List(Trees.RoadsideTree) -> World.Segment
segment_of = |trees| {
	..World.route_segment(0),
	length: Distance.metres(200.0),
	trees,
	exit_turn: Angle.straight_ahead,
	crossing: BirdFlight.crossing_among(trees),
}

## The birds on one segment of `trees`, for a rider `rider_along` metres into
## it, seen through a focal length of `cam_focal`.
birds_on : List(Trees.RoadsideTree),
{
	rider_along : F64,
	cam_focal : Pixels,
} -> List(Pipeline.Sighted(PosedBird))
birds_on = |trees, seen_from| birds_on_segment(segment_of(trees), seen_from)

## The birds on `segment_index`, for a rider `rider_along` metres into it.
birds_on_segment : World.Segment,
{
	rider_along : F64,
	cam_focal : Pixels,
} -> List(Pipeline.Sighted(PosedBird))
birds_on_segment = |segment, { rider_along, cam_focal }|
	CrossingSighting.birds_in_view({
		road: {
			route_segments: [segment],
			segments_ahead: [World.SegmentIndex.first],
			vantage: { ..origin, along: Along.metres(rider_along) },
		},
		cam_focal,
	})

## The one bird that a rider `rider_along` metres in sees on the segment with
## a far tree.
bird_at : F64 -> Pipeline.Sighted(PosedBird)
bird_at = |rider_along|
	birds_on(left_trees.append(far_tree), { rider_along, cam_focal: Pixels.of(500.0) }).first()
		?? crash "CrossModuleExpects: this rider sees a bird"

## How far off a bird is, across the road and up.
place_numbers : Pipeline.Sighted(PosedBird) -> List(F64)
place_numbers = |bird| [
	bird.foot.right().to_metres(),
	bird.foot.forward().to_metres(),
	bird.kind.lift.to_metres(),
]

expect place_numbers(bird_at(0.0)) == [-6.0, 100.0, left_top]
expect place_numbers(bird_at(40.0)) == [-6.0, 60.0, left_top]

# Halfway through its flight, with the rider 37.5 m from the tree it left.
expect {
	bird = bird_at(62.5)
	[
		(bird.foot.right().to_metres(), 0.0),
		(bird.foot.forward().to_metres(), 52.5),
		(
			bird.kind.lift.to_metres(),
			(left_top + far_top) / 2.0 + BirdFlight.flight_arc.to_metres(),
		),
	].all(|(got, want)| (got - want).abs() <= 0.000000001)
}

expect place_numbers(bird_at(85.0)) == [6.0, 45.0, far_top]
expect bird_at(40.0).kind.pose == Perched
expect bird_at(62.5).kind.pose != Perched
expect bird_at(85.0).kind.pose == Perched

# With no tree far enough to fly to, the bird stays on its own however near
# the rider is.
expect {
	stays = birds_on(left_trees, { rider_along: 62.5, cam_focal: Pixels.of(500.0) })
	stays.join_map(place_numbers) == [-6.0, 37.5, left_top]
}

## How many birds there are on `trees` for each rider and focal length.
bird_count : List(Trees.RoadsideTree), { rider_along : F64, cam_focal : Pixels } -> I64
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

## Two segments on the road ahead, the rider at the start of the first.
two_segments : List(Pipeline.Sighted(PosedBird))
two_segments = CrossingSighting.birds_in_view({
	road: {
		route_segments: [segment_of(left_trees), segment_of(left_trees)],
		segments_ahead: [0, 1].map(World.SegmentIndex.number),
		vantage: {
			along: Along.metres(0.0),
			across: Across.metres(0.0),
			yaw: Angle.straight_ahead,
		},
	},
	cam_focal: Pixels.of(500.0),
})

expect
	match two_segments.map(|bird| bird.foot.forward()) {
		[near, far] => near == Distance.metres(100.0) and near < far
		_ => crash "CrossModuleExpects: each of two segments has a bird in view"
	}

# TreeSighting looks at the segment just behind the rider too. A tree 5 m short
# of the bend out of it stands in front of a rider at the bend once the bend is
# sharper than a right angle, and behind the rider at a gentle bend.
## The trees in view of a rider at the start of the second of two segments,
## the first holding one tree 5 m short of its bend of `degrees`.
past_bend_trees : F64 -> List(Pipeline.Sighted(Conifer))
past_bend_trees = |degrees| {
	segment_behind_rider = {
		..segment_of([tree_at(195.0, 0.0)]),
		exit_turn: Angle.Turn.degrees(degrees),
		crossing: QuietRoad,
	}
	rider_segment = { ..segment_of([]), crossing: QuietRoad }
	TreeSighting.trees_in_view({
		road: {
			route_segments: [segment_behind_rider, rider_segment],
			segments_ahead: [1].map(World.SegmentIndex.number),
			vantage: origin,
		},
		cam_focal: Pixels.of(500.0),
	})
}

## Whether `trees` is one tree, sighted on the segment just behind the rider.
is_one_tree_behind : List(Pipeline.Sighted(Conifer)) -> Bool
is_one_tree_behind = |trees|
	match trees.map(|tree| tree.place) {
		[JustBehind(_)] => True
		_ => False
	}

expect is_one_tree_behind(past_bend_trees(150.0))
expect is_one_tree_behind(past_bend_trees(-150.0))
expect past_bend_trees(30.0).len() == 0
expect past_bend_trees(-80.0).len() == 0

# CrossingSighting's cats: which cats are in view as the rider comes on them.
## The second segment, with a cat crossing it.
cat_segment : World.Segment
cat_segment = { ..World.route_segment(1), crossing: World.route_segment(3).crossing }

cat_segments : List(World.Segment)
cat_segments = [World.route_segment(0), cat_segment, World.route_segment(2)]

## The first three segments seen from the origin, at 1 m a step.
cats_from_origin : RoadAhead.CameraView
cats_from_origin = {
	road: {
		route_segments: cat_segments,
		segments_ahead: [0, 1, 2].map(World.SegmentIndex.number),
		vantage: origin,
	},
	cam_focal: Pixels.of(500.0),
}

metre_a_step : Speed
metre_a_step = Speed.metres_a_step(1.0)

## The cats seen from the origin on a road of only `segments_ahead`.
cats_on_road : List(World.SegmentIndex) -> List(Pipeline.Sighted(PosedCat))
cats_on_road = |segments_ahead| CrossingSighting.cats_in_view(
	{ ..cats_from_origin, road: { ..cats_from_origin.road, segments_ahead } },
	metre_a_step,
)

## The cat on the segment at `number` on the road ahead, if it is in view.
cat_at : U32 -> Try(Pipeline.Sighted(PosedCat), [NoCat, BehindCamera, TooSmall])
cat_at = |number| CrossingSighting.segment_cat(
	cats_from_origin,
	{ in_view: numbered_segment(cats_from_origin.road, number), speed: metre_a_step },
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
			vantage = { ..origin, along: Along.metres(along) }
			road_view = { ..cats_from_origin.road, vantage }
			gap = RoadAhead.gap_to_segment(road_view, numbered_segment(road_view, number))
			gap.to_metres() == want
		},
	)

## The cats in view for a rider `along` metres into the first segment.
ride_sightings : F64 -> List(Pipeline.Sighted(PosedCat))
ride_sightings = |along| CrossingSighting.cats_in_view(
	{
		..cats_from_origin,
		road: { ..cats_from_origin.road, vantage: { ..origin, along: Along.metres(along) } },
	},
	metre_a_step,
)

seen : List(Pipeline.Sighted(PosedCat))
seen = ride_sightings(300.0)

## The first cat in view for a rider `along` metres in.
first_cat : F64 -> Pipeline.Sighted(PosedCat)
first_cat = |along|
	ride_sightings(along).first() ?? crash "CrossModuleExpects: the second segment's cat is in view"

## How far ahead the first cat in view is for a rider `along` metres in.
cat_forward : F64 -> Distance
cat_forward = |along| first_cat(along).foot.forward()

expect seen.len() == 1
expect cat_at(0).is_err()
expect cat_at(2).is_err()
expect first_cat(300.0).kind.lift.to_metres() == 0.0
expect first_cat(300.0).kind.pose == Rest
expect
	[
		(cat_forward(300.0).minus(cat_forward(200.0)).to_metres(), -100.0),
		(cat_forward(400.0).minus(cat_forward(300.0)).to_metres(), -100.0),
		(first_cat(300.0).foot.right().minus(first_cat(200.0).foot.right()).to_metres(), 0.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

expect ride_sightings(0.0).len() == 0
expect ride_sightings(200.0).len() == 1
expect ride_sightings(500.0).len() == 1
expect ride_sightings(600.0).len() == 0
expect cats_on_road([World.SegmentIndex.first]).len() == 0

# The sighting looks along the whole road ahead, and the reaction only at the
# rider's own segment. They agree because a crossing starts on its own segment: even at
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

# BillboardSighting: how far along the road ahead each kind of critter is sighted.
## The first six segments ahead, in order.
six_segments : RoadAhead.RoadView
six_segments = {
	route_segments: [0, 1, 2, 3, 4, 5].map(World.route_segment),
	segments_ahead: [0, 1, 2, 3, 4, 5].map(World.SegmentIndex.number),
	vantage: origin,
}

## The world's segment `index` alone.
lone : U32 -> RoadAhead.RoadView
lone = |index| {
	route_segments: [World.route_segment(index)],
	segments_ahead: [0].map(World.SegmentIndex.number),
	vantage: origin,
}

## The segment `number` places along the road ahead of `road_view`.
numbered_segment : RoadAhead.RoadView, U32 -> RoadAhead.SegmentInView
numbered_segment = |road_view, number|
	RoadAhead.segment_in_view_at(road_view, RoadAhead.Position.number(number))

## The world's segment `number`, as the segment just behind the rider.
segment_behind : U32 -> RoadAhead.SegmentInView
segment_behind = |number| {
	segment = World.route_segment(number)
	{
		index: World.SegmentIndex.number(number),
		segment,
		place: RoadAhead.place_behind(segment),
	}
}

farm_at : U32 -> I64
farm_at = |number|
	BillboardSighting.farm_sightings(six_segments, numbered_segment(six_segments, number))
		.len()
		.to_i64_wrap()

bend_at : U32 -> I64
bend_at = |number|
	BillboardSighting.bend_sightings(six_segments, numbered_segment(six_segments, number))
		.len()
		.to_i64_wrap()

expect farm_at(0) > 0
expect farm_at(2) > 0
expect farm_at(3) == 0
expect farm_at(4) == 0
expect farm_at(5) == 0
expect bend_at(3) > 0
expect bend_at(4) > 0
expect bend_at(5) == 0

## How many critters live at the end of the world's segment `index`, seen alone.
lone_bend_count : U32 -> I64
lone_bend_count = |index|
	BillboardSighting.bend_sightings(lone(index), numbered_segment(lone(index), 0))
		.len()
		.to_i64_wrap()

# Segment 12 ends at the duck pond, 0 and 4 at an animal and its baby, and 18,
# the road's last, quietly.
expect lone_bend_count(12) == 6
expect lone_bend_count(0) == 2
expect lone_bend_count(4) == 2
expect lone_bend_count(18) == 0
expect {
	first = numbered_segment(six_segments, 0)
	whole = BillboardSighting.segment_sightings(six_segments, first).len().to_i64_wrap()
	whole == farm_at(0) + bend_at(0)
}

## How many critters the segments from `position` to the road's end hold.
count_from : U32 -> I64
count_from = |position|
	List.from_iter(U32.until(position, 6))
		.map(
			|number| {
				in_view = numbered_segment(six_segments, number)
				BillboardSighting.segment_sightings(six_segments, in_view).len().to_i64_wrap()
			},
		)
		.sum()

expect
	BillboardSighting.billboard_fates(lone(0)).len()
		== BillboardSighting.segment_sightings(lone(0), numbered_segment(lone(0), 0)).len()
expect BillboardSighting.billboard_fates(six_segments).len().to_i64_wrap() == count_from(0)
expect count_from(0) >= count_from(1)
expect count_from(1) >= count_from(2)
expect BillboardSighting.segment_sightings(six_segments, segment_behind(4)).len() > 0
expect BillboardSighting.bend_sightings(six_segments, segment_behind(12)).len() == 6
expect {
	fates = BillboardSighting.farm_sightings(six_segments, segment_behind(0))
	fates.len() > 0 and fates.all(|fate| how_it_went(fate) == BehindCamera)
}
expect BillboardSighting.bend_sightings(six_segments, segment_behind(0)).len() == 2

## A billboard on the first segment, as the rider at its start sees it.
critter_fate : Geom.Placed(Billboard) -> BillboardSighting.Fate
critter_fate = |critter|
	BillboardSighting.sight_critter(road, { place: Ahead(RoadAhead.Position.first), critter })

## A cow 2.5 m to the right of the rider, `forward` metres ahead.
cow_fate : { forward : Distance, height : Distance } -> BillboardSighting.Fate
cow_fate = |{ forward, height }|
	critter_fate({
		along: Along.at(forward),
		across: Across.metres(2.5),
		kind: { codepoint: 128004, height, facing: FacesRight },
	})

## Which way a sighting went, whatever it carries.
how_it_went : BillboardSighting.Fate -> [Seen, BehindCamera, TooSmall]
how_it_went = |fate|
	match fate {
		Ok(_) => Seen
		Err(BehindCamera) => BehindCamera
		Err(TooSmall) => TooSmall
	}

# The near plane is 0.4 m, and a cow on it is in view. At the lens's resting
# focal length a 1 m cow is 2 pixels tall about 342.8 m off.
expect
	[
		(-5.0, 1.0, BehindCamera),
		(0.3, 1.0, BehindCamera),
		(0.39, 1.0, BehindCamera),
		(0.4, 1.0, Seen),
		(0.5, 1.0, Seen),
		(300.0, 1.0, Seen),
		(342.0, 1.0, Seen),
		(343.0, 1.0, TooSmall),
		(400.0, 1.0, TooSmall),
		(10.0, 0.0, TooSmall),
		(50.0, 0.9, Seen),
	].all(
		|(forward, height, want)| {
			fate = cow_fate({ forward: Distance.metres(forward), height: Distance.metres(height) })
			how_it_went(fate) == want
		},
	)

near_cow : Pipeline.Sighted(Billboard)
near_cow =
	cow_fate({ forward: Distance.metres(0.5), height: Distance.metres(1.0) })
		?? crash "CrossModuleExpects: a cow 0.5 m ahead is in view"

left_bull : Pipeline.Sighted(Billboard)
left_bull =
	critter_fate({
		along: Along.metres(50.0),
		across: Across.metres(-1.5),
		kind: {
			codepoint: 128002,
			height: Distance.metres(1.6),
			facing: FacesLeft,
		},
	})
		?? crash "CrossModuleExpects: a bull 50 m ahead is in view"

expect near_cow.foot.right().to_metres() == 2.5
expect near_cow.foot.forward().to_metres() == 0.5
expect near_cow.kind.height.to_metres() == 1.0
expect left_bull.foot.right().to_metres() == -1.5
expect left_bull.foot.forward().to_metres() == 50.0
expect left_bull.kind.height.to_metres() == 1.6

expect near_cow.kind.codepoint == 128004
expect left_bull.kind.codepoint == 128002
expect near_cow.kind.facing == FacesRight
expect left_bull.kind.facing == FacesLeft

expect BillboardSighting.min_critter_px.to_f64() == 2.0

## How many of `in_view` critters are drawn, among `out_of_view` others before
## them. Every one in view is drawn, and none out of view.
drawn_count : { out_of_view : U64, in_view : U64 } -> U64
drawn_count = |{ out_of_view, in_view }|
	BillboardSighting.billboards_to_draw(
		List.repeat(Err(TooSmall), out_of_view).concat(List.repeat(Ok(near_cow), in_view)),
	).len()

expect
	[
		({ out_of_view: 0, in_view: 5 }, 5),
		({ out_of_view: 400, in_view: 5 }, 5),
		({ out_of_view: 400, in_view: 0 }, 0),
		({ out_of_view: 0, in_view: 0 }, 0),
	].all(|(counts, want)| drawn_count(counts) == want)

# RailSighting's run up to a bend and out of it.
rail_point_at : List(Geom.RiderPoint), U64 -> Geom.RiderPoint
rail_point_at = |points, i|
	points.get(i) ?? crash "CrossModuleExpects: an index past the rail's end"

runup_points_to_bend : List(Geom.RiderPoint)
runup_points_to_bend = RailSighting.runup_points(
	road,
	{
		place: Ahead(RoadAhead.Position.first),
		length: Distance.metres(500.0),
		across: Across.metres(2.0),
	},
)

expect RailSighting.run_out_points(
	road,
	{ place: Ahead(RoadAhead.Position.first), across: Across.metres(2.0) },
).len() == 10
expect runup_points_to_bend.len() == 11
expect
	[
		(rail_point_at(runup_points_to_bend, 0).forward.to_metres(), 490.0),
		(rail_point_at(runup_points_to_bend, 10).forward.to_metres(), 500.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

# Scene, on the scene from the start of the route.
scene_view : RoadAhead.CameraView
scene_view = {
	road: {
		route_segments: World.segments,
		segments_ahead: RoadAhead.indices_ahead(World.segments, World.SegmentIndex.first),
		vantage: origin,
	},
	cam_focal: Pixels.of(500.0),
}

scene : Scene
scene = Scene.scene_in_view(
	scene_view,
	{
		speed: VehicleLimits.base_speed,
		truck: {
			route_position: Distance.metres(500.0),
			truck_ahead: { headlights: Off, brake_lights: Off },
		},
		clock: Clock.start,
	},
)

scene_lists : SceneShapes.ThingLists(Rendered)
scene_lists = SceneShapes.scene_renderings(scene, scene_view)

scene_renderings : List(Rendered)
scene_renderings = Rendered.depth_sorted_renderings(SceneShapes.things_in_tie_order(scene_lists))

# Each thing in view has its rendering. The start of the route has a truck
# ahead, so `trucks` holds one.
expect scene_lists.trees.len() == scene.trees.len()
expect scene_lists.towers.len() == scene.towers.len()
expect scene_lists.billboards.len() == scene.billboards.len()
expect scene_lists.cats.len() == scene.cats.len()
expect scene_lists.rails.len() == scene.rails.len()
expect scene_lists.birds.len() == scene.birds.len()
expect scene_lists.trucks.len() == 1
expect
	scene_renderings.len()
		== [
			scene.trees.len(),
			scene.towers.len(),
			scene.billboards.len(),
			scene.cats.len(),
			scene_lists.trucks.len(),
			scene.rails.len(),
			scene.birds.len(),
		].sum()

expect scene.trees.len() > 0
expect scene.towers.len() > 0
expect scene.billboards.len() > 0
expect scene.rails.len() > 0
expect scene_renderings.len() > 0

# A segment of the road ahead shows at most two towers, the one past its end and
# the one halfway along, and the segment just behind shows one.
expect scene.towers.len() <= 2 * RoadAhead.most_segments_ahead.to_u64() + 1

## Whether no rendering in `renderings` is farther than the one before it.
is_far_to_near : List(Rendered) -> Bool
is_far_to_near = |renderings|
	renderings.map2(
		renderings.drop_first(1),
		|before, after| DepthSort.is_farther({ this: after.depth, that: before.depth }),
	)
		.all(|is_out_of_order| !is_out_of_order)

expect is_far_to_near(scene_renderings)
expect is_far_to_near([])

# GroundSighting's road, chunk by chunk.
## A list of patches as a camera the drawing checks read paints them.
patch_shapes : List(Ground.Patch) -> List(Shapes.Shape)
patch_shapes = |patches| patches.keep_oks(|patch| Ground.patch_shape(patch, Pixels.of(500.0)))

## Chunk `chunk_number` of the first segment's 20, which is 500 m long.
corners_of_chunk : U32 -> List(Geom.RiderPoint)
corners_of_chunk = |chunk_number| GroundSighting.chunk_corners(
	road,
	{
		place: Ahead(RoadAhead.Position.first),
		segment_length: Distance.metres(500.0),
		chunk_count: 20,
		chunk_number,
	},
)

corner : List(Geom.RiderPoint), U64 -> Geom.RiderPoint
corner = |corners, i| corners.get(i) ?? crash "CrossModuleExpects: a chunk has four corners"

first_chunk_corners : List(Geom.RiderPoint)
first_chunk_corners = corners_of_chunk(0)

last_chunk_corners : List(Geom.RiderPoint)
last_chunk_corners = corners_of_chunk(19)

expect first_chunk_corners.len() == 4
expect last_chunk_corners.len() == 4
expect
	[
		(0, -2.0),
		(1, 2.0),
		(2, 2.0),
		(3, -2.0),
	].all(|(i, want)| (corner(first_chunk_corners, i).right.to_metres() - want).abs() <= 0.0001)

expect
	[
		(corner(first_chunk_corners, 0).forward.to_metres(), 0.0),
		(corner(first_chunk_corners, 3).forward.to_metres(), 25.0),
		(corner(last_chunk_corners, 0).forward.to_metres(), 475.0),
		(corner(last_chunk_corners, 3).forward.to_metres(), 500.0),
	].all(|(got, want)| (got - want).abs() <= 0.0001)

expect {
	before = corners_of_chunk(3)
	after = corners_of_chunk(4)
	corner(before, 3).forward == corner(after, 0).forward
		and corner(before, 2).forward == corner(after, 1).forward
		and corner(before, 3).right == corner(after, 0).right
}

strip_shapes : List(Shapes.Shape)
strip_shapes = patch_shapes(GroundSighting.road_patches(road, numbered_segment(road, 0)))

expect strip_shapes.len() > 0
expect strip_shapes.len().to_u32_wrap() <= GroundSighting.chunks_along(Distance.metres(500.0))
expect patch_shapes(
	GroundSighting.road_patches(
		{ ..road, vantage: { ..origin, along: Along.metres(5000.0) } },
		numbered_segment(road, 0),
	),
).len() == 0
last_shape : Shapes.Shape
last_shape = strip_shapes.last() ?? crash "CrossModuleExpects: the road draws"

expect flat_color_of(last_shape) == RgbColor.of(0x34353C)
expect {
	coordinate_count = coordinates_of(last_shape).len()
	coordinate_count >= 6 and coordinate_count <= 10
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
		pace: Slowing,
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
		next = Rider.rider_state_at_next_step($rider, World.segments)
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
expect RideInstant.next_or_restart(World.segments, done).truck.pace == NotSlowing

# A frame of the ride draws.
expect {
	frame = RideInstant.frame_content(World.segments, RideInstant.initial)
	first_shape = frame.shapes.first() ?? crash "CrossModuleExpects: a frame draws"
	coordinates_of(first_shape).len() >= 6
}

expect {
	after_one_step = RideInstant.next_or_restart(World.segments, RideInstant.initial)
	RideInstant.frame_content(World.segments, after_one_step).shapes.len() > 0
}
